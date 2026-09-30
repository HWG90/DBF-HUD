-- ModOptionsMenu API 1; only main settings and placement are exposed.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local self={status='Mod Options Menu not installed'}
    local placement={left_mount_x=true,left_mount_y=true,left_mount_z=true,fp_mount_x=true,fp_mount_y=true,fp_mount_z=true,
        mount_x=true,mount_y=true,mount_z=true,world_position_smooth=true,world_rotation_smooth=true,world_max_lag=true,
        weapon_offset_x=true,weapon_offset_y=true,weapon_settle=true,weapon_lag=true,offset_x=true,offset_y=true,
        follow=true,travel=true,settle=true}
    local function option_id(k)if k=='font' then return 'dbf_hud_v4.font_nerd' end;return (placement[k] and 'dbf_hud_placement.' or 'dbf_hud_v4.')..k end
    local function font_index()for i,name in ipairs(HUD.config.fonts) do if name==hud.config.font then return i end end;return 1 end
    local function decoration_index()for i,name in ipairs(HUD.config.decorations) do if name==hud.config.decoration then return i end end;return 1 end
    local sliders={
        {'mount_x','3D right shoulder: left / right',-2,2,0.01},{'mount_y','3D right shoulder: forward / back',-2,2,0.01},{'mount_z','3D right shoulder: up / down',-2,2,0.01},
        {'left_mount_x','3D left shoulder: left / right',-2,2,0.01},{'left_mount_y','3D left shoulder: forward / back',-2,2,0.01},{'left_mount_z','3D left shoulder: up / down',-2,2,0.01},
        {'fp_mount_x','3D first person: left / right',-2,2,0.01},{'fp_mount_y','3D first person: forward / back',-2,2,0.01},{'fp_mount_z','3D first person: up / down',-2,2,0.01},
        {'world_position_smooth','3D position damping',0,0.5,0.005},{'world_rotation_smooth','3D rotation damping',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_offset_x','2D hybrid: horizontal offset',-1920,1920,1},{'weapon_offset_y','2D hybrid: vertical offset',-1080,1080,1},
        {'weapon_settle','2D hybrid: settling time',0.04,1,0.01},{'weapon_lag','2D hybrid: maximum lag',0,160,1},
        {'offset_x','2D crosshair: horizontal offset',-1920,1920,1},{'offset_y','2D crosshair: vertical offset',-1080,1080,1},
        {'follow','2D crosshair: reticle follow',0,1,0.01},{'travel','2D crosshair: maximum travel',1,160,1},{'settle','2D crosshair: settling time',0.04,1,0.01},
        {'scale','HUD scale',0.5,2,0.05},{'opacity','HUD opacity',0.1,1,0.01},{'panel_opacity','Panel tint',0,1,0.01},{'flash_hz','Heat warning pulse rate',0.5,3,0.5}}
    -- Mesh-only emission, texture cap and CRT sliders are intentionally archived.
    -- Their configuration and implementations remain in source for future work.
    local function set(k,v) assert(api.set(option_id(k),v)) end
    function self.sync()
        if not api or not attempted or retired then return end
        for _,s in ipairs(sliders) do set(s[1],hud.config[s[1]]) end
        set('display_mode',hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2))
        set('always_show_3d',hud.config.occlusion_mode=='gui')
        set('frosted',hud.config.frosted)
        set('decoration',decoration_index())
        set('debug_logging',hud.config.debug_logging)
        set('font',font_index())
    end
    function self.poll()
        if attempted or retired then return end
        api=rawget(_G,'ModOptionsMenu')
        if not api or api.api~=1 then return end
        for _,k in ipairs({'register_option','on_change','set'}) do if type(api[k])~='function' then return end end
        attempted=true;api.dbf_hud_routes=api.dbf_hud_routes or {};routes=api.dbf_hud_routes
        -- Old rows may remain visible until restart, but cannot apply stale settings.
        for id,route in pairs(routes) do
            if not id:find('dbf_hud_v4.',1,true) and not id:find('dbf_hud_placement.',1,true) then route.callback=nil;route.owner=nil end
        end
        local function add(k,spec,callback)
            spec.mod=placement[k] and 'DBF-HUD Placement' or 'DBF-HUD'
            local id=option_id(k)
            local exists=routes[id] or (type(api.get)=='function' and api.get(id)~=nil)
            if not exists then local ok,err=api.register_option(id,spec);assert(ok,err) end
            if not routes[id] then
                local route={};routes[id]=route
                assert(api.on_change(id,function(v)if route.callback then route.callback(v) end end))
            end
            routes[id].owner=self;routes[id].callback=callback
        end
        local ok,err=pcall(function()
            add('display_mode',{type='choice',label='Display mode',choices={'2D, Anchor to Weapon (Hybrid)','2D, Anchor to HUD/Crosshair','3D, WorldGUI'},
                default=hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2)},function(v)
                hud.configure({anchor_mode=v==1 and 'weapon' or (v==3 and 'world' or 'crosshair')});hud.save_tuning()
            end)
            add('always_show_3d',{type='toggle',label='Always Show HUD (3D)',default=hud.config.occlusion_mode=='gui',
                description='On: draw through characters and scenery. Off: scene geometry hides the 3D HUD.'},function(v)
                hud.configure({always_show_3d=v});hud.save_tuning()
            end)
            for _,s in ipairs(sliders) do
                local k=s[1];add(k,{type='slider',label=s[2],min=s[3],max=s[4],step=s[5],default=hud.config[k]},function(v)
                    hud.configure({[k]=v});hud.save_tuning()
                end)
            end
            add('decoration',{type='choice',label='Decorations',choices={'None','Thin outline','Corner brackets','Helldivers HUD','Double frame'},default=decoration_index()},function(v)
                hud.configure({decoration=assert(HUD.config.decorations[v])});hud.save_tuning()
            end)
            add('font',{type='choice',label='HUD font',choices={'BigBlue Terminal (pixel)','Original debug font','JetBrainsMono Nerd Font','FiraCode Nerd Font','Meslo Nerd Font','Hack Nerd Font','CascadiaCode Nerd Font','Iosevka Nerd Font','0xProto Nerd Font','SourceCodePro Nerd Font','FiraMono Nerd Font','CascadiaMono Nerd Font'},default=font_index()},function(v)
                hud.configure({font=assert(HUD.config.fonts[v])});hud.save_tuning()
            end)
            add('frosted',{type='toggle',label='Frosted background (2D)',default=hud.config.frosted},function(v)
                hud.configure({frosted=v});hud.save_tuning()
            end)
            add('debug_logging',{type='toggle',label='Debug logging',default=hud.config.debug_logging,
                description='Enable research traces and capability inspection. Errors are always logged.'},function(v)
                hud.configure({debug_logging=v});hud.save_tuning()
            end)
            self.sync()
        end)
        self.status=ok and 'Options > Mods > DBF-HUD' or ('menu unavailable: '..tostring(err));if not ok then api=nil end
    end
    function self.retire()
        retired=true
        for _,route in pairs(routes or {}) do if route.owner==self then route.callback=nil;route.owner=nil end end
    end
    return self
end
return M
