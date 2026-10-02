-- ModOptionsMenu API 1; only main settings and placement are exposed.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local self={status='Mod Options Menu not installed'}
    local font_host,font_handle
    local binding_host,binding_down
    local binding_id='dbf_hud_debug.force_occlusion'
    local notice,notice_until
    function self.overlay(w,h,font)
        if not notice or (hud.clock or 0)>=notice_until then return {} end
        local s=h/1080
        return {{type='text',text=notice,font=font,x=32*s,y=h-215*s,size=18*s,c={255,255,255},a=1}}
    end
    function self.poll_bindings()
        if retired then return end
        local host=rawget(_G,'ModBindingsMenu')
        if not host or type(host.register_binding)~='function' or type(host.is_down)~='function' then return end
        if binding_host~=host then
            local ok,registered=pcall(host.register_binding,binding_id,'Force occlusion',nil,{category='Debug tools - DBF HUD'})
            if not ok or not registered then return end
            binding_host=host;binding_down=false
        end
        local ok,down=pcall(host.is_down,binding_id)
        if not ok then return end
        down=down==true
        if down and not binding_down then
            hud.configure({force_occlusion=not hud.config.force_occlusion})
            hud.save_tuning()
            notice='[DEBUG] Occlusion '..(hud.config.force_occlusion and 'ON' or 'OFF')
            notice_until=(hud.clock or 0)+3
        end
        binding_down=down
    end
    local placement={keep_hud_upright=true,fp_auto_side=true,placement_mode=true,left_mount_x=true,left_mount_y=true,left_mount_z=true,fp_mount_x=true,fp_mount_y=true,fp_mount_z=true,
        mount_x=true,mount_y=true,mount_z=true,world_position_smooth=true,world_rotation_smooth=true,world_max_lag=true,
        weapon_offset_x=true,weapon_offset_y=true,weapon_settle=true,weapon_lag=true,offset_x=true,offset_y=true,
        follow=true,travel=true,settle=true}
    local function option_id(k)if k:match('^editor_') then return 'dbf_hud_editor.'..k end;if k=='font' then return 'dbf_hud_v6.font_native' end;if k:match('^font_page_') then return 'dbf_hud_v6.'..k end;return (placement[k] and 'dbf_hud_placement.' or 'dbf_hud_v4.')..k end
    local font_choices={}
    for i,name in ipairs(HUD.config.fonts) do font_choices[i]=HUD.native_font_data.faces[name].label or name end
    local function font_index()for i,name in ipairs(HUD.config.fonts) do if name==hud.config.font then return i end end;return 1 end
    local function decoration_index()for i,name in ipairs(HUD.config.decorations) do if name==hud.config.decoration then return i end end;return 1 end
    local sliders={
        {'world_position_smooth','3D position damping',0,0.5,0.005},{'world_rotation_smooth','3D rotation damping',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_offset_x','2D hybrid: horizontal offset',-1920,1920,1},{'weapon_offset_y','2D hybrid: vertical offset',-1080,1080,1},
        {'weapon_settle','2D hybrid: settling time',0.04,1,0.01},{'weapon_lag','2D hybrid: maximum lag',0,160,1},
        {'offset_x','2D crosshair: horizontal offset',-1920,1920,1},{'offset_y','2D crosshair: vertical offset',-1080,1080,1},
        {'follow','2D crosshair: reticle follow',0,1,0.01},{'travel','2D crosshair: maximum travel',1,160,1},{'settle','2D crosshair: settling time',0.04,1,0.01},
        {'scale','HUD scale',0.5,2,0.05},{'opacity','HUD opacity',0.1,1,0.01},{'panel_opacity','Panel tint',0,1,0.01},{'flash_hz','Heat warning pulse rate',0.5,3,0.5}}
    -- Mesh-only emission, texture cap and CRT sliders are intentionally archived.
    -- Their configuration and implementations remain in source for future work.
    local function set(k,v) assert(api.set(option_id(k),v)) end
    local function sync_editor()
        if not hud.layout_editor then return end
        local e=hud.layout_editor;local x,y,z=e.values()
        set('editor_enabled',e.active);set('editor_view',e.view=='right' and 1 or 2)
        set('editor_x',x);set('editor_y',y);set('editor_z',z)
        set('editor_scale',e.scale())
        set('editor_save',false);set('editor_reset',false)
    end
    function self.sync()
        if not api or not attempted or retired then return end
        for _,s in ipairs(sliders) do set(s[1],hud.config[s[1]]) end
        set('display_mode',hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2))
        set('fp_auto_side',hud.config.fp_auto_side=='right' and 2 or 1)
        set('keep_hud_upright',hud.config.keep_hud_upright)
        set('fade_3d_unless_aiming',hud.config.fade_3d_unless_aiming)
        set('force_occlusion',hud.config.force_occlusion)
        set('style_3d',hud.config.style_3d=='hologram' and 2 or 1)
        set('frosted',hud.config.frosted)
        set('decoration',decoration_index())
        set('debug_logging',hud.config.debug_logging)
        local selected=font_index()
        for page=1,math.ceil(#font_choices/16) do
            local first=(page-1)*16+1
            set(page==1 and 'font' or ('font_page_'..page),selected>=first and selected<first+16 and selected-first+1 or 1)
        end
    end
    function self.poll()
        self.poll_bindings()
        if retired then return end
        local host=rawget(_G,'DBFMCM')
        if host and type(host.register)=='function' and host~=font_host then
            if font_handle then font_handle.unregister();font_handle=nil end
            font_handle=host.register({id='dbf_hud_fonts',name='DBF-HUD Fonts',
                description='All native HUD font families.',pages={{id='fonts',name='Fonts',controls={{
                    id='family',type='choice',label='HUD font',choices=font_choices,default=font_index(),
                    on_change=function(v)if not retired then hud.configure({font=HUD.config.fonts[v]});hud.save_tuning()end end
                }}}}})
            font_host=host
        end
        if attempted then return end
        api=rawget(_G,'ModOptionsMenu')
        if not api or api.api~=1 then return end
        for _,k in ipairs({'register_option','on_change','set'}) do if type(api[k])~='function' then return end end
        attempted=true;api.dbf_hud_routes=api.dbf_hud_routes or {};routes=api.dbf_hud_routes
        -- Old rows may remain visible until restart, but cannot apply stale settings.
        for id,route in pairs(routes) do
            if not id:find('dbf_hud_v4.',1,true) and not id:find('dbf_hud_placement.',1,true) and not id:find('dbf_hud_editor.',1,true) then route.callback=nil;route.owner=nil end
        end
        if routes['dbf_hud_v4.always_visible'] then routes['dbf_hud_v4.always_visible'].callback=nil end
        for id,route in pairs(routes) do if id=='dbf_hud_v4.font_nerd' or id:find('dbf_hud_v4.font_page_',1,true) then route.callback=nil end end
        if routes['dbf_hud_v4.show_3d'] then routes['dbf_hud_v4.show_3d'].callback=nil end
        if routes['dbf_hud_v4.always_show_3d'] then routes['dbf_hud_v4.always_show_3d'].callback=nil end
        local function add(k,spec,callback)
            spec.mod=k:match('^editor_') and 'DBF-HUD Layout Editor' or (placement[k] and 'DBF-HUD Placement' or 'DBF-HUD')
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
            if hud.layout_editor then
                local e=hud.layout_editor
                add('editor_enabled',{type='toggle',label='Edit equipped weapon',default=false,
                    description='Equip and aim first. Enable and APPLY to lock this weapon for editing. Disable before selecting another weapon.'},function(v)
                    if v then e.bind() else e.active=false end;sync_editor()
                end)
                add('editor_view',{type='choice',label='Editing view',choices={'Third person','First person'},default=1,
                    description='Laser weapons with shared mounts change both views together.'},function(v)e.set_view(v==2);sync_editor()end)
                for _,row in ipairs({{'x','Right / left (inches)'},{'y','Forward / back (inches)'},{'z','Up / down (inches)'}}) do
                    local axis=row[1]
                    add('editor_'..axis,{type='slider',label=row[2],min=-72,max=72,step=.25,default=0,
                        description='Additional position from the automatic mount. APPLY, close the menu, and inspect while aiming.'},function(v)e.set(axis,v)end)
                end
                add('editor_scale',{type='slider',label='Weapon view scale',min=.25,max=3,step=.05,default=1,
                    description='Size multiplier for this weapon and view. F7 or Save layout keeps it.'},function(v)e.set_scale(v)end)
                add('editor_save',{type='toggle',label='Save layout',default=false,
                    description='Turn on and APPLY to save all weapon positions. A backup is kept.'},function(v)if v then e.save() end;set('editor_save',false)end)
                add('editor_reset',{type='toggle',label='Restore starting position',default=false,
                    description='Restore this weapon to its position when editing was enabled. Save afterward to keep it.'},function(v)if v then e.reset() end;sync_editor()end)
                sync_editor()
            end
            add('display_mode',{type='choice',label='Display mode',choices={'2D, Anchor to Weapon (Hybrid)','2D, Anchor to HUD/Crosshair','3D, WorldGUI'},
                default=hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2)},function(v)
                hud.configure({anchor_mode=v==1 and 'weapon' or (v==3 and 'world' or 'crosshair')});hud.save_tuning()
            end)
            add('keep_hud_upright',{type='toggle',label='Keep HUD upright',default=hud.config.keep_hud_upright,description='Remove sideways roll in every 3D view while preserving facing direction.'},function(v)
                hud.configure({keep_hud_upright=v});hud.save_tuning()
            end)
            add('fp_auto_side',{type='choice',label='Auto first-person HUD side',choices={'Left','Right'},default=hud.config.fp_auto_side=='right' and 2 or 1},function(v)
                hud.configure({fp_auto_side=v==2 and 'right' or 'left'});hud.save_tuning()
            end)
            for _,s in ipairs(sliders) do
                local k=s[1];add(k,{type='slider',label=s[2],min=s[3],max=s[4],step=s[5],default=hud.config[k]},function(v)
                    hud.configure({[k]=v});hud.save_tuning()
                end)
            end
            add('decoration',{type='choice',label='Decorations',choices={'None','Thin outline','Corner brackets','Helldivers HUD','Double frame'},default=decoration_index()},function(v)
                hud.configure({decoration=assert(HUD.config.decorations[v])});hud.save_tuning()
            end)
            -- ModOptionsMenu accepts at most sixteen names per choice.
            for page=1,math.ceil(#font_choices/16) do
                local first=(page-1)*16+1
                local choices={}
                for i=first,math.min(first+15,#font_choices) do choices[#choices+1]=font_choices[i] end
                local key=page==1 and 'font' or ('font_page_'..page)
                local selected=font_index()
                add(key,{type='choice',label='HUD font '..page,choices=choices,
                    default=selected>=first and selected<first+16 and selected-first+1 or 1,
                    description='Choose a font from any group. Only the most recently chosen font is active.'},function(v)
                    hud.configure({font=assert(HUD.config.fonts[first+v-1])});hud.save_tuning()
                end)
            end
            add('fade_3d_unless_aiming',{type='toggle',label='Fade 3D HUD when not aiming',default=hud.config.fade_3d_unless_aiming},function(v)
                hud.configure({fade_3d_unless_aiming=v});hud.save_tuning()
            end)
            add('force_occlusion',{type='toggle',label='Force occlusion',default=hud.config.force_occlusion,
                description='Use depth occlusion on every 3D weapon HUD, including while aiming.'},function(v)
                hud.configure({force_occlusion=v});hud.save_tuning()
            end)
            add('style_3d',{type='choice',label='3D HUD style',choices={'Standard','Hologram'},default=hud.config.style_3d=='hologram' and 2 or 1},function(v)
                hud.configure({style_3d=v==2 and 'hologram' or 'standard'});hud.save_tuning()
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
        if font_handle then font_handle.unregister();font_handle=nil end
        for _,route in pairs(routes or {}) do if route.owner==self then route.callback=nil;route.owner=nil end end
    end
    return self
end
return M
