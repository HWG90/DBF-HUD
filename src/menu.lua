-- ModOptionsMenu API 1; only main settings and placement are exposed.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local self={status='Mod Options Menu not installed'}
    local font_host,font_handle
    local panel_weapon,panel_refresh,panel_revision,panel_guard
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
            local ok,registered=pcall(host.register_binding,binding_id,'Force occlusion',nil,{category='Developer - DBF HUD'})
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
    local function option_id(k)if k:match('^editor_') then return 'dbf_hud_editor.'..k end;if k=='style_3d' then return 'dbf_hud_v6.style_3d' end;if k=='font' then return 'dbf_hud_v6.font_native' end;if k:match('^font_page_') then return 'dbf_hud_v6.'..k end;return (placement[k] and 'dbf_hud_placement.' or 'dbf_hud_v4.')..k end
    local font_choices={}
    for i,name in ipairs(HUD.config.fonts) do font_choices[i]=HUD.native_font_data.faces[name].label or name end
    local function font_index()for i,name in ipairs(HUD.config.fonts) do if name==hud.config.font then return i end end;return 1 end
    local function decoration_index()for i,name in ipairs(HUD.config.decorations) do if name==hud.config.decoration then return i end end;return 1 end
    local sliders={
        {'world_position_smooth','3D position damping',0,0.5,0.005},{'world_rotation_smooth','3D rotation damping',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_settle','2D hybrid: settling time',0.04,1,0.01},{'weapon_lag','2D hybrid: maximum lag',0,160,1},
        {'follow','2D crosshair: reticle follow',0,1,0.01},{'travel','2D crosshair: maximum travel',1,160,1},{'settle','2D crosshair: settling time',0.04,1,0.01},
        {'scale','HUD scale',0.5,2,0.05},{'panel_opacity','Panel tint',0,1,0.01},{'flash_hz','Heat warning pulse rate',0.5,3,0.5}}
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
        set('keep_hud_upright',hud.config.keep_hud_upright)
        set('fade_3d_unless_aiming',hud.config.fade_3d_unless_aiming)
        set('force_occlusion',hud.config.force_occlusion)
        local style_index=1;for i,name in ipairs(HUD.config.styles) do if name==hud.config.style_3d then style_index=i end end
        set('style_3d',style_index)
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
            local function save(key,value)
                if not retired then hud.configure({[key]=value});hud.save_tuning() end
            end
            local styles={'Standard','Hologram','Instrument','Blueprint','Retro CRT'}
            local selected_style=1;for i,name in ipairs(HUD.config.styles)do if name==hud.config.style_3d then selected_style=i end end
            local preset_choices=hud.list_presets and hud.list_presets() or {}
            if #preset_choices==0 then preset_choices={'No saved presets'} end
            local placement_controls={
                {id='equipped_weapon_hud',type='toggle',label='Show equipped weapon HUD',require_confirmation=false,default=true,on_change=function(v)local ok,message=hud.blacklist_equipped(not v);assert(ok,message)end}}
            local developer_motion_controls={}
            for _,row in ipairs(sliders)do
                if placement[row[1]] then
                    local key=row[1]
                    developer_motion_controls[#developer_motion_controls+1]={id=key,type='slider',label=row[2],min=row[3],max=row[4],step=row[5],default=hud.config[key],on_change=function(v)save(key,v)end}
                end
            end
            local function refresh_presets()
                preset_choices=hud.list_presets and hud.list_presets() or {}
                if #preset_choices==0 then preset_choices={'No saved presets'}end
                local mod=host.mods and host.mods.dbf_hud_fonts
                if mod then for _,page in ipairs(mod.pages)do
                    if page.id=='presets' then for _,control in ipairs(page.controls)do
                        if control.id=='saved_preset' then control.choices=preset_choices end
                    end end
                end end
                if font_handle then font_handle.set('saved_preset',1)end
            end
            local function selected_preset()
                local name=preset_choices[font_handle.get('saved_preset')]
                assert(name~='No saved presets','Save a preset first')
                return name
            end
            local function save_preset()
                local name=font_handle.get('preset_name')
                local overwrite=false
                for _,existing in ipairs(hud.list_presets()) do
                    if existing:lower()==name:lower() then overwrite=true end
                end
                local ok,err=hud.save_preset(name)
                assert(ok,err)
                refresh_presets()
                if overwrite then return 'Overwrote '..name..'.layout' end
            end
            local function load_preset()
                local ok,err=hud.load_preset(selected_preset())
                assert(ok,err)
            end
            local function delete_preset()
                local ok,err=hud.delete_preset(selected_preset())
                assert(ok,err)
                refresh_presets()
            end
            local function reset_defaults()
                local ok,err=hud.reset_defaults()
                assert(ok,err)
            end
            local panel_controls={{type='text',label='Press Fetch to select the equipped weapon',id='weapon_heading'},
                {id='fetch_weapon_appearance',type='button',label='Fetch current weapon appearance',description='Reload the equipped weapon settings, including inherited global options.',on_activate=function()
                    assert(hud.appearance_weapon and hud.appearance_weapon(),'Equip a weapon first')
                    if panel_refresh then panel_refresh(true)end;if panel_guard then panel_guard()end
                    local fetched=hud.appearance_weapon()
                    local state=host.mods and host.mods.dbf_hud_fonts
                    assert(state,'Appearance registration unavailable; reload HUD')
                    local settings=hud.panel_settings()
                    return 'Fetched '..(HUD.weapon_names[fetched] or fetched)..' appearance. '..hud.shader_status()
                end},
                {id='panel_inherit',type='button',label='Use global appearance',on_activate=function()
                    assert(hud.appearance_weapon and hud.appearance_weapon()==panel_weapon,'Press Fetch for the equipped weapon first');hud.configure_panel(false,panel_weapon);hud.save_tuning()
                end}}
            local weapon_fonts={'Use global font'};for _,name in ipairs(font_choices)do weapon_fonts[#weapon_fonts+1]=name end
            local shader_choices={'Automatic weapon theme','None'};local shader_ids={'auto','none'}
            for _,entry in ipairs(HUD.shader_catalog)do shader_choices[#shader_choices+1]=entry.title..(entry.frozen and ' (frozen sample)' or '');shader_ids[#shader_ids+1]=entry.id end
            local panel_definitions={
                {'theme_shader','Theme shader (3D)','choice',shader_choices},
                {'theme_shader_scale','Panel pattern size','slider',.25,4,.05},
                {'theme_shader_animate','Animate panel shader','toggle'},
                {'theme_shader_speed','Panel animation speed','slider',.1,3,.1},
                {'effect_shader','Effect shader (3D)','choice',shader_choices},
                {'effect_shader_scale','Effect pattern size','slider',.25,4,.05},
                {'effect_shader_animate','Animate effect shader','toggle'},
                {'effect_shader_speed','Effect animation speed','slider',.1,3,.1},
                {'font','Weapon font','choice',weapon_fonts},
                {'background_color','Panel color','color'},{'text_color','Text color','color'},{'decoration_color','Decoration color','color'},
                {'panel_opacity','Panel opacity','slider',0,1,.01},{'text_opacity','Text opacity','slider',0,1,.01},
                {'effect_scanline_count','Scanline count','slider',1,80,1},
                {'effect_sweep_speed','Sweep speed','slider',.05,2,.05},{'effect_sweep_density','Sweep density','slider',1,12,1},
                {'effect_scanlines','Scanlines','toggle'},{'effect_flicker','Flicker','toggle'},{'effect_sweep','Sweep','toggle'},{'frosted','Frosted background (2D)','toggle'},
                {'decoration','Decorations','choice',{'None','Thin outline','Corner brackets','Helldivers HUD','Double frame','Deadeye receiver'}},
                {'style_3d','Visual style','choice',styles}}
            local function panel_value(key)
                local cfg=panel_weapon and hud.panel_settings and hud.panel_settings() or hud.config
                local v=cfg[key]
                if key=='theme_shader' or key=='effect_shader' then for i,id in ipairs(shader_ids)do if id==v then return i end end;return key=='theme_shader' and 1 or 2 end
                if key=='font' then local own=(hud.config.weapon_panels or {})[panel_weapon or ''];if not own or not own.font then return 1 end;for i,name in ipairs(HUD.config.fonts)do if name==own.font then return i+1 end end;return 1 end
                if key=='decoration' then for i,n in ipairs(HUD.config.decorations)do if n==v then return i end end end
                if key=='style_3d' then for i,n in ipairs(HUD.config.styles)do if n==v then return i end end end
                if v==nil then v=HUD.config.defaults[key] end
                return v
            end
            for _,def in ipairs(panel_definitions)do
                local key=def[1];local c={id='weapon_'..key,type=def[3],label=def[2],default=panel_value(key)}
                if key=='theme_shader' or key=='effect_shader' then c.presentation='dropdown';c.description=key=='theme_shader' and 'Native shader on the in-world HUD and preview when Display mode is 3D. Explicit shaders override the frosted-background skip. Automatic preserves the weapon theme; None uses normal fill. Missing assets fall back. Animation is controlled by Animate panel shader.' or 'Native 3D shader for existing scanline/sweep bands: enable Scanlines or Sweep. No extra geometry. None keeps normal bands. Animation is controlled by Animate effect shader; preview uses native materials in 3D mode.' end
                if key=='theme_shader_scale' or key=='effect_shader_scale' then c.description='Pattern spacing only: below 1 is tighter; above 1 is larger. Does not resize the HUD. World and preview use the same panel coordinates.' end
                if key=='theme_shader_animate' or key=='effect_shader_animate' then c.description='Animate the selected shader. Off keeps the static sample. Requires animated native assets; no new panel geometry.' end
                if key=='theme_shader_speed' or key=='effect_shader_speed' then c.description='Animation speed multiplier. 1 is normal. Pattern size remains independent.' end
                if c.type=='choice' then c.choices=def[4]elseif c.type=='slider' then c.min,c.max,c.step=def[4],def[5],def[6]end
                c.on_change=function(v)
                    if key=='theme_shader' or key=='effect_shader' then v=shader_ids[v] end
                    if key=='font' then if v==1 then v=false else v=HUD.config.fonts[v-1] end end
                    if key=='decoration' then v=HUD.config.decorations[v]elseif key=='style_3d' then v=HUD.config.styles[v]end
                    assert(hud.appearance_weapon and hud.appearance_weapon()==panel_weapon,'Equipped weapon changed; press Fetch again')
                    hud.configure_panel({[key]=v},panel_weapon);hud.save_tuning()
                end
                panel_controls[#panel_controls+1]=c
            end
            local function panel_control(mod,id)
                if mod.controls and mod.controls[id] then return mod.controls[id]end
                for _,page in ipairs(mod.pages or {})do if page.id=='weapon_appearance' then for _,c in ipairs(page.controls)do if c.id==id then return c end end end end
            end
            panel_refresh=function(force)
                local id=hud.appearance_weapon and hud.appearance_weapon()
                if not force and id==panel_weapon and panel_revision==hud.appearance_revision then return end
                panel_weapon=id;panel_revision=hud.appearance_revision
                local mod=host.mods and host.mods.dbf_hud_fonts
                if not mod then return end
                for _,c in ipairs(panel_controls)do
                    local registered=panel_control(mod,c.id)
                    if registered then
                        registered.disabled=id==nil
                        if c.id=='weapon_heading' then registered.label=id and ('Editing: '..(HUD.weapon_names[id] or id)) or 'Equip a weapon to edit its appearance'
                        elseif c.id:sub(1,7)=='weapon_' then mod.values[c.id]=panel_value(c.id:sub(8)) end
                    end
                end
            end
            panel_guard=function()
                local id=hud.appearance_weapon and hud.appearance_weapon()
                local mod=host.mods and host.mods.dbf_hud_fonts;if not mod then return end
                local ready=id~=nil and id==panel_weapon
                for _,c in ipairs(panel_controls)do local registered=panel_control(mod,c.id)
                    if registered then
                        if c.id=='fetch_weapon_appearance' then registered.disabled=id==nil
                        elseif c.id=='weapon_heading' then registered.label=panel_weapon and ('Editing: '..(HUD.weapon_names[panel_weapon] or panel_weapon)..(ready and '' or ' - equip this weapon or press Fetch again')) or 'Press Fetch to select the equipped weapon'
                        else registered.disabled=not ready end
                    end
                end
            end
            font_handle=host.register({id='dbf_hud_fonts',name='DBF-HUD',
                description='Native fonts, styles and color wheels.',pages={{id='appearance',name='Global Options',require_confirmation=false,render_preview=hud.appearance_preview,preview_popout=true,controls={
                    {id='fade_when_not_aiming',type='toggle',label='Fade when not aiming',default=hud.config.fade_3d_unless_aiming,
                        on_change=function(v)save('fade_3d_unless_aiming',v)end},


                    {id='family',type='choice',presentation='dropdown',label='Global HUD font',choices=font_choices,default=font_index(),
                        on_change=function(v)save('font',HUD.config.fonts[v])end},
                    {id='style',type='choice',label='Global HUD style',choices=styles,default=selected_style,
                        on_change=function(v)save('style_3d',HUD.config.styles[v])end},
                    {id='decoration',type='choice',presentation='dropdown',label='Global decorations',choices={'None','Thin outline','Corner brackets','Helldivers HUD','Double frame','Deadeye receiver'},default=decoration_index(),
                        on_change=function(v)save('decoration',HUD.config.decorations[v])end},
                    {id='panel_color',type='color',label='Global panel color',default=hud.config.background_color,
                        on_change=function(v)save('background_color',v)end},
                    {id='text_color',type='color',label='Global text color',default=hud.config.text_color,
                        on_change=function(v)save('text_color',v)end},
                    {id='decoration_color',type='color',label='Global decoration color',default=hud.config.decoration_color,
                        on_change=function(v)save('decoration_color',v)end},
}},{id='weapon_appearance',name='Weapon Appearance',require_confirmation=false,render_preview=hud.appearance_preview,preview_popout=true,controls=(function()
                local controls,theme,effects={},{},{}
                local effect_keys={weapon_effect_shader_animate=true,weapon_effect_shader_speed=true,weapon_effect_shader_scale=true,weapon_effect_shader=true,weapon_effect_scanlines=true,weapon_effect_flicker=true,weapon_effect_sweep=true,weapon_effect_scanline_count=true,weapon_effect_sweep_speed=true,weapon_effect_sweep_density=true,weapon_frosted=true}
                for _,c in ipairs(panel_controls)do
                    if c.id and c.id:sub(1,7)=='weapon_' and c.id~='weapon_heading' then
                        local group=effect_keys[c.id] and effects or theme;group[#group+1]=c
                    else controls[#controls+1]=c end
                end
                controls[#controls+1]={id='weapon_theme',type='section',label='Theme',collapsed=false,children=theme}
                controls[#controls+1]={id='weapon_effects',type='section',label='Effects',collapsed=false,children=effects}
                return controls
            end)()},{id='developer',name='Developer',controls=(function()local controls={
{id='render_sync_trial',type='toggle',label='Render-synchronized HUD',require_confirmation=false,description='Sample weapon pose and camera before the existing render callback. Defaults on; can be disabled here. No smoothing or offset changes. Falls back to update when the render bridge is unavailable.',default=hud.config.render_sync_trial,on_change=function(v)save('render_sync_trial',v)end},
{id='senator_style',type='choice',require_confirmation=false,label='Senator appearance (3D)',choices={'Cylinder','Upright bullets'},description='2D always uses upright bullets.',default=hud.config.senator_style=='upright' and 2 or 1,
                        on_change=function(v)save('senator_style',v==2 and 'upright' or 'cylinder')end},

{id='display_mode',type='choice',label='Display mode',choices={'2D, Anchor to Weapon (Hybrid)','2D, Anchor to HUD/Crosshair','3D, WorldGUI'},
                        default=hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2),
                        on_change=function(v)save('anchor_mode',v==1 and 'weapon' or v==3 and 'world' or 'crosshair')end},
{id='hud_scale',type='slider',label='HUD scale',min=.5,max=2,step=.05,default=hud.config.scale,
                        on_change=function(v)save('scale',v)end},
{id='keep_upright',type='toggle',label='Keep HUD upright',default=hud.config.keep_hud_upright,on_change=function(v)save('keep_hud_upright',v)end},


{id='debug_hud_timing',type='toggle',label='Show HUD timing',description='Bottom-right CPU timing for HUD updates and draw calls. Includes this debug display; not GPU timing.',default=hud.config.debug_hud_timing,on_change=function(v)save('debug_hud_timing',v)end},
{id='zoom_compensation',type='toggle',label='Debug: Zoom compensation',default=hud.config.zoom_compensation,on_change=function(v)save('zoom_compensation',v)end},
{id='debug_occlusion',type='toggle',label='Debug: force occlusion',default=hud.config.force_occlusion,on_change=function(v)save('force_occlusion',v)end},
{id='debug_sight_root_orientation',type='toggle',label='Debug: sight + root orientation',default=hud.config.debug_sight_root_orientation,on_change=function(v)save('debug_sight_root_orientation',v)end},
{id='debug_logging',type='toggle',label='Debug logging',default=hud.config.debug_logging,on_change=function(v)save('debug_logging',v)end},

{id='effect_scanlines',type='toggle',label='HUD effect: Scanlines',default=hud.config.effect_scanlines,
                        on_change=function(v)save('effect_scanlines',v)end},
{id='mg43_easter_egg',type='toggle',label='MG-43: Get some! Easter egg',default=hud.config.mg43_easter_egg,
                        on_change=function(v)save('mg43_easter_egg',v)end},
{id='effect_flicker',type='toggle',label='HUD effect: Flicker',default=hud.config.effect_flicker,
                        on_change=function(v)save('effect_flicker',v)end},
{id='effect_sweep',type='toggle',label='HUD effect: Scanning sweep',default=hud.config.effect_sweep,
                        on_change=function(v)save('effect_sweep',v)end},
{id='effect_sweep_speed',type='slider',label='Sweep speed',min=.05,max=2,step=.05,default=hud.config.effect_sweep_speed,on_change=function(v)save('effect_sweep_speed',v)end},
{id='effect_sweep_density',type='slider',label='Sweep density',min=1,max=12,step=1,default=hud.config.effect_sweep_density,on_change=function(v)save('effect_sweep_density',v)end}
};for _,c in ipairs(developer_motion_controls)do controls[#controls+1]=c end;for _,c in ipairs(placement_controls)do controls[#controls+1]=c end;return controls end)()},{id='presets',name='Presets',require_confirmation=true,controls={
                    {id='preset_name',type='input',label='Preset filename',default='My preset'},
                    {id='saved_preset',type='choice',presentation='dropdown',label='Saved presets',choices=preset_choices,default=1},
                    {id='save_preset',type='button',button_label='Save preset',label='Save named preset',description='Save settings and layouts. An existing name is overwritten after Apply; its previous file is backed up.',on_activate=save_preset},
                    {id='load_preset',type='button',button_label='Load preset',label='Load selected preset',on_activate=load_preset},
                    {id='delete_preset',type='button',button_label='Delete preset',label='Delete selected preset',description='Delete the selected saved file after applying confirmation. Current HUD settings stay unchanged.',on_activate=delete_preset},
                    {type='text',label=''},
                    {type='text',label=''},
                    {type='text',label=''},
                    {type='text',label='Reset all settings and weapon layouts'},
                    {id='default_setup',type='button',button_label='Reset defaults',label='Reset to Default setup',
                        description='Restore bundled settings and weapon layouts. Previous files are backed up.',
                        on_activate=reset_defaults}
                }}}})
            font_host=host;self.status='MCM > DBF-HUD'
        end
        if panel_guard then panel_guard()end
        local visibility_mod=host and host.mods and host.mods.dbf_hud_fonts
        local visibility_control=visibility_mod and visibility_mod.controls and visibility_mod.controls.equipped_weapon_hud
        if visibility_control then
            local resource=hud.equipped_resource()
            visibility_control.disabled=resource==nil
            visibility_mod.values.equipped_weapon_hud=resource~=nil and not HUD.config.is_blacklisted(hud.config,resource)
        end
        -- Native MCM owns HUD settings; do not also publish Bingus rows.
        if font_handle then
            if not self.scale_controls_reported then
                self.scale_controls_reported=true
                local mod=font_host and font_host.mods and font_host.mods.dbf_hud_fonts
                local found={};local seen={}
                local function inspect(node)
                    if type(node)~='table' or seen[node] then return end;seen[node]=true
                    if node.id=='weapon_theme_shader_scale' or node.id=='weapon_effect_shader_scale' then found[node.id]=node.label end
                    for _,v in pairs(node)do if type(v)=='table' then inspect(v)end end
                end
                inspect(mod)
                local f=io.open(((os.getenv('LOCALAPPDATA') or '.')..'/LLL/Helldivers2/Logs/Pattern-scale-registration.log'),'w')
                if f then f:write('panel='..tostring(found.weapon_theme_shader_scale)..' effect='..tostring(found.weapon_effect_shader_scale)..' native_dependency=existing_mapped_programs\n');f:close() end
            end
            if routes then for _,route in pairs(routes) do if route.owner==self then route.callback=nil;route.owner=nil end end end
            return
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
            spec.mod=(k:match('^debug_') or k=='zoom_compensation' or k=='force_occlusion' or (placement[k] and k~='keep_hud_upright')) and 'DBF-HUD Developer' or k:match('^editor_') and 'DBF-HUD Layout Editor' or (placement[k] and 'DBF-HUD Placement' or 'DBF-HUD')
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
                add('editor_scale',{type='slider',label='Weapon view scale',min=.05,max=3,step=.05,default=1,
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
            for _,s in ipairs(sliders) do
                local k=s[1];add(k,{type='slider',label=s[2],min=s[3],max=s[4],step=s[5],default=hud.config[k]},function(v)
                    hud.configure({[k]=v});hud.save_tuning()
                end)
            end
            add('decoration',{type='choice',presentation='dropdown',label='Decorations',choices={'None','Thin outline','Corner brackets','Helldivers HUD','Double frame','Deadeye receiver'},default=decoration_index()},function(v)
                hud.configure({decoration=assert(HUD.config.decorations[v])});hud.save_tuning()
            end)
            -- ModOptionsMenu accepts at most sixteen names per choice.
            for page=1,math.ceil(#font_choices/16) do
                local first=(page-1)*16+1
                local choices={}
                for i=first,math.min(first+15,#font_choices) do choices[#choices+1]=font_choices[i]:sub(1,48) end
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
            add('style_3d',{type='choice',label='3D HUD style',choices={'Standard','Hologram','Instrument','Blueprint','Retro CRT'},default=(function()for i,name in ipairs(HUD.config.styles)do if name==hud.config.style_3d then return i end end;return 1 end)()},function(v)
                hud.configure({style_3d=assert(HUD.config.styles[v])});hud.save_tuning()
            end)
            add('frosted',{type='toggle',label='Frosted background (2D)',default=hud.config.frosted},function(v)
                hud.configure({frosted=v});hud.save_tuning()
            end)
            add('debug_logging',{type='toggle',label='Debug logging',default=hud.config.debug_logging,
                description='Enable research traces and capability inspection. Errors are always logged.'},function(v)
                hud.configure({debug_logging=v});hud.save_tuning()
            end)
            add('debug_sight_root_orientation',{type='toggle',label='Debug: sight + root orientation',default=hud.config.debug_sight_root_orientation,
                description='Restore attachment positioning in weapon-root axes and legacy root orientation.'},function(v)
                hud.configure({debug_sight_root_orientation=v});hud.save_tuning()
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
