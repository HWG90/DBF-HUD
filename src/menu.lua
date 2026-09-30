-- Optional ModOptionsMenu API 1 integration. Never bundles or patches its implementation.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local target=1;local self={status='Mod Options Menu not installed'}
    local prefix='astra_ammo_v3.'
    local sliders={
        {'world_position_smooth','3D position smoothing',0,0.5,0.005},{'world_rotation_smooth','3D rotation smoothing',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_offset_x','Weapon panel horizontal offset',-1920,1920,1},{'weapon_offset_y','Weapon panel vertical offset',-1080,1080,1},
        {'weapon_settle','Weapon settling time',0.04,1,0.01},{'weapon_lag','Maximum weapon lag',0,160,1},
        {'mount_x','Weapon local X',-2,2,0.01},{'mount_y','Weapon local Y',-2,2,0.01},{'mount_z','Weapon local Z',-2,2,0.01},
        {'offset_x','Horizontal position',-1920,1920,1},{'offset_y','Vertical position (up)',-1080,1080,1},
        {'scale','HUD scale',0.5,2,0.05},{'opacity','HUD opacity',0.1,1,0.01},
        {'panel_opacity','Panel tint',0,1,0.01},{'follow','Reticle follow',0,1,0.01},
        {'travel','Maximum travel',1,160,1},{'settle','Settling time',0.04,1,0.01},
        {'flash_hz','Overheat flash rate',0.5,3,0.5}}
    local function set(k,v) assert(api.set(prefix..k,v)) end
    function self.sync()
        if not api or not attempted or retired then return end
        for _,s in ipairs(sliders) do set(s[1],hud.config[s[1]]) end
        set('frosted',hud.config.frosted)
        set('anchor_mode_v2',hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2))
        set('pose_marker',hud.config.pose_marker)
        set('world_probe',hud.config.world_probe)
        set('font',hud.config.font=='bigblue' and 1 or 2)
        local hex=hud.config[AA.config.colors[target]]:sub(2)
        for i=1,6 do set('hex'..i,tonumber(hex:sub(i,i),16)+1) end
    end
    function self.poll()
        if attempted or retired then return end
        api=rawget(_G,'ModOptionsMenu')
        if not api or api.api~=1 then return end
        for _,k in ipairs({'register_option','on_change','set'}) do if type(api[k])~='function' then return end end
        attempted=true
        -- Keep one dispatcher per option across reloads; retiring releases HUD closures.
        api.astra_ammo_routes=api.astra_ammo_routes or {}
        routes=api.astra_ammo_routes
        local function add(k,spec,callback)
            spec.mod='Astra Ammo'
            local id=prefix..k
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
                description='Edit #RRGGBB using the six hexadecimal digit rows. Apply the target before editing its digits.'},function(v)
                target=v;self.sync()
            end)
            local digits={};for i=0,15 do digits[#digits+1]=string.format('%X',i) end
            for i=1,6 do
                local index=i
                add('hex'..i,{type='choice',label=({'Hex R high','Hex R low','Hex G high','Hex G low','Hex B high','Hex B low'})[i],
                    choices=digits,default=tonumber(hud.config.text_color:sub(i+1,i+1),16)+1},function(v)
                    local key=AA.config.colors[target];local h=hud.config[key]:sub(2)
                    hud.configure({[key]='#'..h:sub(1,index-1)..string.format('%X',v-1)..h:sub(index+1)})
                    hud.save_tuning()
                end)
            end
            set('color_target',target);self.sync()
        end)
        self.status=ok and 'Options > Mods > Astra Ammo' or ('menu unavailable: '..tostring(err))
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
