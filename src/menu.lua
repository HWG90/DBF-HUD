-- Optional ModOptionsMenu API 1 integration. Never bundles or patches its implementation.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local target=1;local self={status='Mod Options Menu not installed'}
    local prefix='dbf_hud_v3.'
    local effects={saturation=true,scanline_strength=true,texture_refresh_hz=true,emissive_intensity=true}
    local placement={left_mount_x=true,left_mount_y=true,left_mount_z=true,fp_mount_x=true,fp_mount_y=true,fp_mount_z=true,
        mount_x=true,mount_y=true,mount_z=true,world_position_smooth=true,world_rotation_smooth=true,world_max_lag=true}
    local legacy={weapon_offset_x=true,weapon_offset_y=true,weapon_settle=true,weapon_lag=true,
        offset_x=true,offset_y=true,follow=true,travel=true,settle=true,scale=true,opacity=true}
    local function option_id(k)return (placement[k] and 'dbf_hud_placement.' or legacy[k] and 'dbf_hud_legacy.' or effects[k] and 'dbf_hud_effects.' or prefix)..k end
    local sliders={
        {'saturation','Panel color saturation',0,2.5,0.05},
        {'left_mount_x','Left shoulder: left / right',-2,2,0.01},{'left_mount_y','Left shoulder: forward / back',-2,2,0.01},{'left_mount_z','Left shoulder: up / down',-2,2,0.01},
        {'fp_mount_x','First-person left / right',-2,2,0.01},{'fp_mount_y','First-person forward / back',-2,2,0.01},{'fp_mount_z','First-person up / down',-2,2,0.01},
        {'scanline_strength','CRT scanline strength',0,0.6,0.02},
        {'texture_refresh_hz','Texture update cap (0 = every frame)',0,120,10},
        {'emissive_intensity','3D panel emission',0,10,0.1},
        {'world_position_smooth','3D position smoothing',0,0.5,0.005},{'world_rotation_smooth','3D rotation smoothing',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_offset_x','Weapon panel horizontal offset',-1920,1920,1},{'weapon_offset_y','Weapon panel vertical offset',-1080,1080,1},
        {'weapon_settle','Weapon settling time',0.04,1,0.01},{'weapon_lag','Maximum weapon lag',0,160,1},
        {'mount_x','Weapon local X',-2,2,0.01},{'mount_y','Weapon local Y',-2,2,0.01},{'mount_z','Weapon local Z',-2,2,0.01},
        {'offset_x','Horizontal position',-1920,1920,1},{'offset_y','Vertical position (up)',-1080,1080,1},
        {'scale','HUD scale',0.5,2,0.05},{'opacity','HUD opacity',0.1,1,0.01},
        {'panel_opacity','Panel tint',0,1,0.01},{'follow','Reticle follow',0,1,0.01},
        {'travel','Maximum travel',1,160,1},{'settle','Settling time',0.04,1,0.01},
        {'flash_hz','Overheat flash rate',0.5,3,0.5}}
    local function set(k,v) assert(api.set(option_id(k),v)) end
    function self.sync()
        if not api or not attempted or retired then return end
        for _,s in ipairs(sliders) do set(s[1],hud.config[s[1]]) end
        set('frosted',hud.config.frosted)
        set('anchor_mode_v2',hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2))
        set('pose_marker',hud.config.pose_marker)
        set('world_probe',hud.config.world_probe)
        set('font',hud.config.font=='bigblue' and 1 or 2)
        local key=HUD.config.colors[target];local rgb=HUD.config.rgb(hud.config[key])
        for i=1,3 do set('rgba'..i,rgb[i]) end
        set('rgba4',key=='background_color' and math.floor(hud.config.panel_opacity*255+0.5) or hud.config[key..'_alpha'])
    end
    function self.poll()
        if attempted or retired then return end
        api=rawget(_G,'ModOptionsMenu')
        if not api or api.api~=1 then return end
        for _,k in ipairs({'register_option','on_change','set'}) do if type(api[k])~='function' then return end end
        attempted=true
        -- Keep one dispatcher per option across reloads; retiring releases HUD closures.
        api.dbf_hud_routes=api.dbf_hud_routes or {}
        routes=api.dbf_hud_routes
        local function add(k,spec,callback)
            spec.mod=placement[k] and 'DBF-HUD Placement' or legacy[k] and 'DBF-HUD Legacy Controls' or effects[k] and 'DBF-HUD Effects' or 'DBF-HUD'
            local id=option_id(k)
            -- API 1 treats a changed default as a different registration. Reuse
            -- our stable option IDs when taking over from the boot addon too.
            local exists=routes[id] or (type(api.get)=='function' and api.get(id)~=nil)
            if not exists then local ok,err=api.register_option(id,spec);assert(ok,err) end
            if not routes[id] then
                local route={};routes[id]=route
                assert(api.on_change(id,function(v) if route.callback then route.callback(v) end end))
            end
            routes[id].owner=self;routes[id].callback=callback
        end
        local ok,err=pcall(function()
            for _,s in ipairs(sliders) do
                local k=s[1]
                add(k,{type='slider',label=s[2],min=s[3],max=s[4],step=s[5],default=hud.config[k]},function(v)
                    hud.configure({[k]=v});hud.save_tuning()
                end)
            end
            add('anchor_mode_v2',{type='choice',label='Attach HUD to',choices={'Weapon (hybrid)','Crosshair','Weapon (3D plane)'},
                default=hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2)},function(v)
                hud.configure({anchor_mode=v==1 and 'weapon' or (v==3 and 'world' or 'crosshair')});hud.save_tuning()
            end)
            add('world_probe',{type='toggle',label='Experimental 3D rectangle',default=hud.config.world_probe},function(v)
                hud.configure({world_probe=v});hud.save_tuning()
            end)
            add('pose_marker',{type='toggle',label='Show attachment marker',default=hud.config.pose_marker},function(v)
                hud.configure({pose_marker=v});hud.save_tuning()
            end)
            add('font',{type='choice',label='HUD font',choices={'BigBlue Terminal (pixel)','Original debug font'},
                default=hud.config.font=='bigblue' and 1 or 2},function(v)
                hud.configure({font=v==1 and 'bigblue' or 'debug'});hud.save_tuning()
            end)
            add('frosted',{type='toggle',label='Native frosted panel',default=hud.config.frosted},function(v)
                hud.configure({frosted=v});hud.save_tuning()
            end)
            add('color_target',{type='choice',label='Color to edit',default=1,
                choices={'Text / accents','Panel tint','Heat white','Heat yellow','Heat red'},
                description='Choose a color, then edit red, green, blue and alpha from 0 to 255.'},function(v)
                target=v;self.sync()
            end)
            for i=1,4 do
                local index=i
                add('rgba'..i,{type='slider',label=({'Red','Green','Blue','Alpha'})[i],min=0,max=255,step=1,default=255},function(v)
                    local key=HUD.config.colors[target]
                    if index==4 then
                        if key=='background_color' then hud.configure({panel_opacity=v/255})
                        else hud.configure({[key..'_alpha']=v}) end
                    else
                        local rgb=HUD.config.rgb(hud.config[key]);rgb[index]=v
                        hud.configure({[key]=string.format('#%02X%02X%02X',rgb[1],rgb[2],rgb[3])})
                    end
                    hud.save_tuning()
                end)
            end
            set('color_target',target);self.sync()
        end)
        self.status=ok and 'Options > Mods > DBF-HUD' or ('menu unavailable: '..tostring(err))
        if not ok then api=nil end
    end
    function self.retire()
        retired=true
        for _,route in pairs(routes or {}) do
            if route.owner==self then route.callback=nil;route.owner=nil end
        end
    end
    return self
end
return M
