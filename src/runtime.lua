local M={draw_budget_ms=2.5}
function M.rebase_commands(commands,left,bottom)
    for _,v in ipairs(commands) do
        v.x=v.x-left;v.y=v.y-bottom
        if v.texture_art_box then
            local b=v.texture_art_box
            v.texture_art_box={x=b.x-left,y=b.y-bottom,w=b.w,h=b.h}
        end
        if v.readout_zone then
            local z=v.readout_zone;v.readout_zone={cx=z.cx-left,cy=z.cy-bottom,w=z.w,h=z.h}
        end
    end
    return commands
end
function M.timing_ink(draw_ms,clock)
    if draw_ms and draw_ms>M.draw_budget_ms and math.floor((clock or 0)*4)%2==0 then return {255,55,65}end
    return {190,235,210}
end
function M.start(sr,backend,options)
    local managed=options and options.managed==true
    -- Compatibility: retire a previous-brand instance during live upgrade.
    local legacy=rawget(_G,'AstraAmmo');if legacy and legacy.retire then legacy.retire() end
    local old=rawget(_G,'DBFHUD');if old and old.retire then old.retire() end
    local self={version='0.3.42',status='starting',anchor_status='starting native anchor',clock=0,hidden=false}
    local texture_swaps
    function self.runtime_texture_swaps()
        if not texture_swaps then texture_swaps=HUD.runtime_texture_bridge.new(sr,backend)end
        return texture_swaps
    end
    function self.reload_runtime_textures()
        if not texture_swaps then return true,'No runtime artwork registered' end
        local ok,err=pcall(texture_swaps.reload_files)
        return ok,ok and 'Runtime artwork queued for render bridge' or tostring(err)
    end
    local hot_panel_art=HUD.hot_panel_art.new(sr,backend,assert(os.getenv('LOCALAPPDATA'))..'/DBF/HotTextures')
    function self.reload_panel_art()local ok,result=pcall(hot_panel_art.reload);return ok,tostring(result)end
    function self.restore_panel_art()return hot_panel_art.restore()end
    function self.panel_art_progress()return hot_panel_art.progress()end
    function self.panel_art_stats()return hot_panel_art.stats()end
    local appearance_selection
    local faithful_states={}
    local faithful_full_states={}
    local frame_trial
    local profile={elapsed=0,frames=0,total=0,max=0,buckets={}}
    local function timed(name,fn)
        return function(...)
            local active=(frame_trial and frame_trial.collecting) and frame_trial or profile
            if not active and not self.timing_active then return fn(...) end
            local started=os.clock()
            local function finish(...)
                local cost=os.clock()-started
                if self.timing_active and (name=='depth_draw' or name=='world_draw' or name=='screen_draw') then self.timing_draw=(self.timing_draw or 0)+cost end
                if active then
                    if name=='depth_draw' and select(1,...)==true then active.drew=true end
                    local bucket=active.buckets[name] or {total=0,calls=0,max=0};active.buckets[name]=bucket
                    bucket.total=bucket.total+cost;bucket.calls=bucket.calls+1;bucket.max=math.max(bucket.max,cost)
                end
                return ...
            end
            return finish(fn(...))
        end
    end
    local compose_raw=timed('layout',function(m,x,y,scale,opacity,cfg,clock,measure,native_art)
        if cfg.weapon_panel_overrides then
            local resolved={};for k,v in pairs(cfg)do resolved[k]=v end;for k,v in pairs(cfg.weapon_panel_overrides)do resolved[k]=v end;cfg=resolved
        end
        cfg=HUD.config.texture_policy(cfg)
        if cfg.presentation_view=='third' then return HUD.view_presentation.compose(m,x,y,scale,opacity,cfg)end
        if cfg.shader_layers~=nil then cfg.effect_scanlines=false;cfg.effect_flicker=false;cfg.effect_sweep=false;cfg.theme_shader='none';cfg.effect_shader='none' end
        local family=HUD.ballistic_family.compose(m,x,y,scale,opacity,cfg,hot_panel_art.resource)
        if family then return family end
        if m.resource_hex=='72170a55a1f37ff1' then
            local retro=HUD.df_retro_panel.compose(m,x,y,scale,opacity,cfg,hot_panel_art.resource)
            if retro then return HUD.layout.decorate_textures(retro,scale,cfg,opacity)end
            if cfg.texture_art_trial==false or cfg.texture_art_variant=='original' then return HUD.df_retro_panel.primitive(m,x,y,scale,opacity,cfg)end
        end
        if m.resource_hex=='72170a55a1f37ff1' and cfg.texture_art_trial~=false and cfg.texture_art_variant~='original' and HUD.df_designer_texture.ready(hot_panel_art.resource) then return HUD.layout.decorate_textures(HUD.df_designer_texture.compose(m,x,y,scale,opacity,cfg,measure or HUD.font.measure),scale,cfg,opacity)end
        local out=HUD.layout.compose(m,x,y,scale,opacity,cfg,clock,measure)
        local mechanical=false
        if m.resource_hex=='72170a55a1f37ff1' and cfg.texture_art_trial~=false and cfg.mechanical_art_enabled~=false and cfg.texture_art_variant=='faithful' then
            -- Readiness is checked against the atlas's distinct hot resource, never the legacy image.
            if hot_panel_art.resource('mods/dbf_hud/textures/df_neogeo_shell_states_v2') and hot_panel_art.resource('mods/dbf_hud/textures/df_neogeo_backing_preview_v2') and hot_panel_art.resource('mods/dbf_hud/textures/df_neogeo_rim_neutral') then
                local ok,art=pcall(HUD.df_neogeo_atlas.compose,m,x-20*scale,y-19*scale,scale,opacity,cfg,measure or HUD.font.measure)
                if ok then out=art elseif not self.neo_geo_error then self.neo_geo_error=true;log('NEOGEO_PANEL_FALLBACK '..tostring(art))end
            end
            mechanical=true -- Pending/failed artwork retains the known-working original layout.
        end
        if not mechanical and native_art and HUD.mechanical_art and type(sr.Application.can_get)=='function' then
            out,mechanical=HUD.mechanical_art.compose(out,m,x,y,scale,opacity,cfg,clock,measure,sr.Application.can_get,hot_panel_art.resource)
            if mechanical and not self.mechanical_seen then self.mechanical_seen={} end
            if mechanical and not self.mechanical_seen[m.resource_hex] then
                self.mechanical_seen[m.resource_hex]=true
                if backend.log then pcall(backend.log,'MECHANICAL_TEXTURE_ACTIVE weapon='..tostring(m.resource_hex)..' live_readouts=true')end
            end
        end
        local faithful=HUD.faithful_fragment_assets and HUD.faithful_fragment_assets[m.resource_hex]
        if not mechanical and native_art and faithful and HUD.faithful_fragments and cfg.texture_art_trial and cfg.texture_art_variant=='faithful' and type(sr.Application.can_get)=='function' then
            local original=out
            out=HUD.faithful_fragments.prepare(out,faithful.spec,faithful.assets,x,y,scale,opacity,cfg,sr.Application.can_get)
            local count=0;for _,v in ipairs(out)do if v.faithful_fragment then count=count+1 end end
            faithful_states[m.resource_hex]={count=count,opacity=opacity,panel=cfg.panel_opacity,fallback=out==original}
            faithful_states[m.resource_hex].revision=self.appearance_revision
            if math.abs(opacity-1)<=1e-6 then faithful_full_states[m.resource_hex]=faithful_states[m.resource_hex] end
        end
        if not mechanical and native_art and HUD.bespoke_texture_panel and type(sr.Application.can_get)=='function' then
            out=HUD.bespoke_texture_panel.compose(out,m,x,y,scale,opacity,cfg,clock,measure,sr.Application.can_get)
        end
        local override=cfg.weapon_panel_overrides
        if override then for _,v in ipairs(out)do
            if v.type=='text' and override.font then v.font=override.font end
            if v.type=='panel' and override.background_color then v.c=HUD.config.rgb(override.background_color)end
            if v.type=='text' and override.text_color and not v.weapon_label and not m.warning and v.text~='UNSAFE' then v.c=HUD.config.rgb(override.text_color)end
        end end
        return HUD.layout.decorate_textures(out,scale,cfg,opacity)
    end)
    local function compose(m,x,y,scale,opacity,cfg,clock,measure,native_art)
        return HUD.font_scale.apply(compose_raw(m,x,y,scale,opacity,cfg,clock,measure,native_art),cfg,measure or HUD.font.measure)
    end
    local mg_easter=HUD.mg_easter.new()
    local df_reload_state=HUD.df_reload_state.new();local df_shell_state=HUD.df_shell_state.new()
    local recoilless_state=HUD.recoilless_state.new()
    local senator_state=HUD.senator_state.new()
    local melta_effect={}
    local scorcher_effect={}
    self.config=HUD.config.new()
    local attached=HUD.motion.new();local attachment_active=false
    local motion=HUD.motion.new();local reader=HUD.reader.new(backend);local view=HUD.view.new(sr)
    reader.poll=timed('weapon_read',reader.poll);view.draw=timed('screen_draw',view.draw)
    local native=HUD.anchor.new(backend);self.native_anchor=native
    local pose=HUD.pose.new(backend);local next_pose_log=0;local last_pose_status
    pose.poll=timed('pose_read',pose.poll)
    local original=rawget(_G,'update');local shutdown=rawget(_G,'shutdown')
    if not managed and type(original)~='function' then self.status='update callback missing';return self end
    local projection=HUD.projection.new(backend);local binding_base;local next_projection_log=0
    projection.poll=timed('camera_projection',projection.poll)
    local latest_raw;local next_sample=0;local model;local anchor;local anchor_at=-10;local provider;local failures=0
    function self.texture_commands()
        if not model then return nil end
        local cfg=HUD.config.effective(self.config,model.resource_hex)
        cfg.font='bigblue';cfg.frosted=false
        local commands=compose(model,0,0,2,1,cfg,self.clock)
        return commands
    end
    function self.appearance_preview(bounds)
        -- A presentation-only example keeps Appearance useful on the ship.
        local preview_model=self.appearance_model(self.appearance_weapon())
        local cfg=HUD.config.effective(self.config,preview_model.resource_hex)
        cfg.presentation_view=cfg.hud_presentation=='practical' and 'third' or (cfg.hud_presentation=='weapon_specific' and 'first' or self.presentation_view or 'first')
        if cfg.presentation_view=='third' then cfg.style_3d='standard';cfg.shader_layers={};cfg.theme_shader='none';cfg.effect_shader='none' end
        if cfg.anchor_mode~='world' then cfg.style_3d='standard' end
        cfg.frosted=false;cfg.placement_mode='manual'
        local commands=compose(preview_model,0,0,2,1,cfg,self.clock)
        commands=HUD.world_style.prepare(commands,{first_person=false},cfg)
        local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
        for _,c in ipairs(commands)do
            minx=math.min(minx,c.x);miny=math.min(miny,c.y)
            maxx=math.max(maxx,c.x+(c.w or #(c.text or '')*(c.size or 0)*.65))
            maxy=math.max(maxy,c.y+(c.h or c.size or 0))
        end
        if maxx<=minx or maxy<=miny then return {} end
        local factor=math.min(bounds.w/(maxx-minx),bounds.h/(maxy-miny),bounds.scale*1.5)
        local x=bounds.x+(bounds.w-(maxx-minx)*factor)/2
        local y=bounds.y+(bounds.h-(maxy-miny)*factor)/2
        local preview_frames={}
        for _,entry in ipairs(commands)do if entry.type=='panel' then
            local key=(entry.child or entry.fold_child) and 'child' or 'main'
            preview_frames[key]=preview_frames[key] or entry
        end end
        local viewport_width,viewport_height=sr.Gui.resolution()
        local result={}
        for _,c in ipairs(commands)do
            local v={};for k,value in pairs(c)do v[k]=value end
            v.x=x+(c.x-minx)*factor;v.y=y+(c.y-miny)*factor
            if v.w then v.w=v.w*factor end;if v.h then v.h=v.h*factor end
            if v.size then v.size=v.size*factor end
            if self.config.anchor_mode=='world' then
                local selected=v.type=='panel' and cfg.theme_shader or ((v.df_effect_sweep or v.scanline_layer or v.effect_shader_band) and cfg.effect_shader)
                local material
                if selected=='auto' then material=({['11c27d3babb38956']='mods/dbf_hud/materials/lab_brushed_steel',['a6a735accb4a327f']='mods/dbf_hud/materials/lab_brushed_steel',['2152d5147b0ac418']='mods/dbf_hud/materials/lab_gunmetal',['89c5493e08ca4207']='mods/dbf_hud/materials/lab_brushed_steel',['4d58c77087b774c5']='mods/dbf_hud/materials/lab_ceramic',['cdf28be026bb7d84']='mods/dbf_hud/materials/lab_crt_scan',['e8d5f49ad7780e54']='mods/dbf_hud/materials/lab_glass_sheen'})[preview_model.resource_hex]
                elseif selected and selected~='none' then for _,entry in ipairs(HUD.shader_catalog)do if entry.id==selected then material=entry.material;break end end end
                if material then
                    local child=c.child or c.fold_child
                    local effect=c.type~='panel'
                    local mapped=material:gsub('/lab_','/mapped_')
                    local frame=preview_frames[child and 'child' or 'main'] or preview_frames.main
                    if frame and sr.Application.can_get('material',mapped) then
                        material=mapped
                        local scale=tonumber(cfg[effect and 'effect_shader_scale' or 'theme_shader_scale']) or 1
                        if scale~=scale then scale=1 end;scale=math.max(.25,math.min(4,scale))
                        local fx,fy=x+(frame.x-minx)*factor,y+(frame.y-miny)*factor
                        local fw,fh=math.max(.001,frame.w*factor),math.max(.001,frame.h*factor)
                        v.preview_mapping={viewport_width/fw/scale,0,-fx/fw/scale,0,viewport_height/fh/scale,(fy+fh-viewport_height)/fh/scale,0,0,1}
                        v.preview_role=(child and 'child_' or 'main_')..(effect and 'effect' or 'panel')
                        v.preview_time,v.preview_animation=HUD.config.shader_animation_values(cfg,effect and 'effect' or 'panel',self.clock)
                    end
                    local ok,available=pcall(sr.Application.can_get,'material',material)
                    if ok and available then v.preview_material=material;if v.type=='panel' and selected~='auto' and math.max(v.c[1],v.c[2],v.c[3])<16 then v.c={48,48,48} end end
                end
            end
            if v.type=='panel' then v.type='rect';v.a=cfg.panel_opacity end
            if v.type=='text' then
                v.font_resource,v.font_material=HUD.native_font.resolve(sr,v.font,false)
                for _,part in ipairs(HUD.font.numeric_parts(v))do
                    local t={};for k,value in pairs(v)do t[k]=value end
                    t.text=part.text;t.c=part.c or v.c;t.x=v.x+part.dx;t.a=v.a*part.alpha;result[#result+1]=t
                end
            else result[#result+1]=v end
        end
        return result
    end
    local retired=false;local cleaned=false;local alpha=0;local last_id;local width,height
    local manual_until=-1;local anchor_source;local next_log=0;local last_log_status
    local last_binding
    local function log(line) if backend.log then pcall(backend.log,string.format('[%.3f] %s',self.clock,line)) end end
    do
        local caps={}
        for _,namespace in ipairs({'Profiler','Window','Application'})do
            local object=sr[namespace];local entries={}
            if type(object)=='table' then for name,value in pairs(object)do
                if namespace=='Profiler' or namespace=='Window' or tostring(name):lower():find('console',1,true) or tostring(name):lower():find('profil',1,true) or tostring(name):lower():find('render',1,true) then entries[#entries+1]=tostring(name)..':'..type(value)end
            end end
            table.sort(entries);caps[#caps+1]=namespace..'='..type(object)..'['..table.concat(entries,',')..']'
        end
        log('NATIVE_PROFILER_CAPABILITY '..table.concat(caps,' '))
    end
    local function research_log(line)
        if self.config.debug_logging or line:find('failure',1,true) or line:find('missing',1,true) or line:find('stopped',1,true) then log(line) end
    end
    local world_probe=HUD.world_probe.new(sr,research_log)
    local world_display=HUD.scene_test.new(sr,research_log)
    local screen_scene=HUD.screen_scene and HUD.screen_scene.new(sr,log,hot_panel_art)
    do
        local available,total=0,0
        for _,entry in ipairs(HUD.shader_catalog) do
            local name=entry.material:gsub('/lab_','/local_')
            local ok,value=pcall(sr.Application.can_get,'material',name)
            total=total+1;if ok and value then available=available+1 end
        end
        log('PANEL_LOCAL_MATERIALS available='..available..' total='..total)
    end
    world_display.draw=timed('world_draw',world_display.draw)
    if screen_scene then screen_scene.draw=timed('depth_draw',screen_scene.draw) end
    self.screen_scene_hud=true -- Auto-migrate only when the new shader package is available.
    local bone_marker=HUD.world_probe.new(sr,research_log,true)
    local bone_marker_position
    local depth_marker=HUD.depth_marker and HUD.depth_marker.new(sr,log)
    self.bone_marker_enabled=false -- Tracking diagnostics disabled; not saved in tuning.
    self.screen_bone_hud=options and options.screen_bone_hud==true -- Trial, opt-in by adapter.
    function self.set_bone_marker(enabled)
        self.bone_marker_enabled=enabled==true
        if not self.bone_marker_enabled then bone_marker.release() end
    end
    local function draw_bone_marker(dt)
        bone_marker_position=nil
        local p=self.weapon_pose
        if not self.bone_marker_enabled or not p then bone_marker.release();return end
        local m=p.matrix
        local anchor=p.attach_point=='root' and {x=0,y=0,z=0} or p.sight
        if not anchor then bone_marker.release();return end
        local x,y,z=anchor.x,anchor.y,anchor.z
        local marker={matrix=m,x=p.x+m[1]*x+m[5]*y+m[9]*z,
            y=p.y+m[2]*x+m[6]*y+m[10]*z,z=p.z+m[3]*x+m[7]*y+m[11]*z,
            id=p.id,candidate='bone diagnostic',gui_pose=true}
        bone_marker_position={x=marker.x,y=marker.y,z=marker.z}
        -- Keep the sampled anchor for the magenta experiment without drawing cyan.
        bone_marker.release();return
    end
    log('START DBFHUD '..self.version..' native crosshair enabled; movement visibility filter removed')
    local art_materials,art_textures=0,0
    for _,variant in ipairs({'faithful','realistic'})do for _,layer in ipairs({'underlay','recesses','details'})do
        if sr.Application.can_get and sr.Application.can_get('material','mods/dbf_hud/materials/texture_liberator_'..variant..'_'..layer) then art_materials=art_materials+1 end
        if sr.Application.can_get and sr.Application.can_get('texture','mods/dbf_hud/textures/liberator_'..variant..'_'..layer) then art_textures=art_textures+1 end
    end end
    log('TEXTURE_LIBERATOR_BUILD 20261004-native-v1 materials='..art_materials..'/6 textures='..art_textures..'/6')
    if HUD.bespoke_texture_specs and sr.Application.can_get then
        local available=0
        for _,spec in pairs(HUD.bespoke_texture_specs) do
            if sr.Application.can_get('material',spec.material) and sr.Application.can_get('texture',spec.texture) then available=available+1 end
        end
        log('TEXTURE_BESPOKE_BUILD six-studies available='..available..'/6; unavailable retains accepted primitives')
    end
    local function research_snapshot()
    if not self.config.debug_logging then return end
    -- Availability check only: never invokes unverified world GUI functions.
    local capabilities={}
    for _,entry in ipairs({{'World','create_world_gui'},{'World','destroy_gui'},
        {'Gui','move'},{'Gui','rect'},{'Gui','bitmap'},
        {'Matrix4x4','from_axes'},{'Matrix4x4','from_quaternion_position'},
        {'Matrix4x4','identity'},{'Matrix4x4','set_translation'},
        {'Matrix4x4','set_x'},{'Matrix4x4','set_y'},{'Matrix4x4','set_z'}}) do
        local namespace=sr[entry[1]]
        local ok,value=pcall(function()return namespace and namespace[entry[2]]end)
        capabilities[#capabilities+1]=entry[1]..'.'..entry[2]..'='..(ok and type(value) or 'unavailable')
    end
    log('WORLD_GUI_CAPABILITIES '..table.concat(capabilities,' '))
    -- Inspect C binding entry points without invoking the bindings themselves.
    local jit_ok,jit_util=pcall(require,'jit.util')
    for _,entry in ipairs({{'World','create_world_gui'},{'Gui','move'},{'Unit','set_mesh_visibility'},{'Viewport','set_output_render_target'},
        {'Viewport','register_render_resource'},{'Application','create_viewport'},
        {'Application','render_world'},{'Renderer','update_texture_base64'},
        {'Mesh','material'},{'Gui','material'},{'Gui','bitmap'},{'Gui','bitmap_3d'},{'Gui','update_bitmap'},{'Material','set_resource'}}) do
        local ok,address=pcall(function()
            assert(jit_ok,'jit.util unavailable')
            local ns=sr[entry[1]];local fn=ns and ns[entry[2]]
            assert(type(fn)=='function','binding unavailable')
            local info=jit_util.funcinfo(fn);assert(type(info.addr)=='number','no native entry')
            return string.format('0x%X',info.addr)
        end)
        log('SCREEN_BINDING '..entry[1]..'.'..entry[2]..' '..(ok and address or 'unavailable'))
    end
    -- Enumerate exposed names rather than guessing the game's custom bindings.
    for _,namespace in ipairs({'Camera','Application','Viewport','Renderer','Material','Unit','Gui','World'}) do
        local ok,names=pcall(function()
            local ns=sr[namespace];local found={}
            if type(ns)~='table' then return {'namespace='..type(ns)} end
            for name,value in pairs(ns) do
                if type(name)=='string' and type(value)=='function' and
                    (namespace~='Unit' or name:find('material',1,true) or name:find('mesh',1,true)) then
                    found[#found+1]=name
                end
            end
            table.sort(found);return found
        end)
        log('SCREEN_API_NAMES '..namespace..' '..(ok and table.concat(names,' ') or 'unavailable'))
    end
    -- Lookup only: do not allocate resources or invoke rendering from update.
    local screen_apis={
        Renderer={'create_resource','destroy_resource'},
        Material={'set_resource','set_texture','set_scalar','set_vector4'},
        Application={'create_viewport','destroy_viewport','render_world','new_world','release_world'},
        Viewport={'set_render_targets','set_render_target','set_rect'},
        World={'spawn_unit','destroy_unit','create_screen_gui','destroy_gui'},
        Unit={'material','set_material','set_local_pose','set_local_scale'},
        Gui={'create_material','material','bitmap','bitmap_3d'}
    }
    for namespace,entries in pairs(screen_apis) do
        local result={}
        for _,name in ipairs(entries) do
            local ok,value=pcall(function()local ns=sr[namespace];return ns and ns[name]end)
            result[#result+1]=name..'='..(ok and type(value) or 'unavailable')
        end
        log('SCREEN_CAPABILITIES '..namespace..' '..table.concat(result,' '))
    end
    for _,resource in ipairs({
        {'shader_library_group','core/stingray_renderer/shader_libraries/default_shaders'},
        {'shader_library','mods/dbf_hud/shaders/gui_depth_state_test_loader_control'},
        {'material','mods/dbf_hud/materials/depth_state_test_loader_control'},
        {'unit','content/env_ship/hologram/units/plane'},
        {'unit','content/env_ship/hologram/units/hologram_cylinder'},
        {'material','content/fac_helldivers/equipment/primary_weapons/assault_rifle_nacho/materials/weapon_screen'}
    }) do
        local ok,available=pcall(function()return sr.Application.can_get(resource[1],resource[2])end)
        log('SCREEN_RESOURCE '..resource[1]..' '..resource[2]..' '..(ok and tostring(available) or 'lookup unavailable'))
    end
    end
    -- Integration contract: normalized viewport coordinates, origin top-left.
    -- Only a verified adapter should supply the actual game's dynamic reticle.
    function self.push_anchor(x,y,visible)
        assert(type(x)=='number' and type(y)=='number' and x==x and y==y and x>=0 and x<=1 and y>=0 and y<=1,'invalid anchor')
        anchor={x=x,y=y,visible=visible~=false};anchor_at=self.clock
        manual_until=self.clock+0.15;anchor_source='external provider'
    end
    function self.set_anchor_provider(fn) assert(fn==nil or type(fn)=='function');provider=fn end
    local menu
    function self.configure(values)
        local was_debug=self.config.debug_logging
        if HUD.config.apply(self.config,values)then self.texture_styles_dirty=true end;self.appearance_revision=(self.appearance_revision or 0)+1;self.config.placement_mode='auto';self.config.show_3d='aiming'
        if self.config.debug_logging and not was_debug then research_snapshot() end
        if menu then menu.sync() end
    end
    function self.appearance_weapon()if self.config.appearance_follow_equipped~=false then return model and model.resource_hex end;return appearance_selection or (model and model.resource_hex)end
    function self.select_appearance_weapon(resource)
        self.config.appearance_follow_equipped=false
        assert(resource and HUD.weapon_names[resource],'Unknown weapon');appearance_selection=resource
        self.appearance_revision=(self.appearance_revision or 0)+1
    end
    function self.appearance_model(resource)
        if model and model.resource_hex==resource then return model end
        local sample=HUD.model.normalize({id='appearance_sample',kind='magazine',rounds=24,capacity=30,reserve=4,reserve_kind='mags',label='ROUNDS',fire_mode='AUTO'})
        sample.resource_hex=resource;return sample
    end
    function self.faithful_status(resource)
        local selected=HUD.config.effective(self.config,resource)
        if selected.texture_art_trial~=false and selected.texture_art_variant=='faithful' and selected.mechanical_art_enabled~=false and HUD.mechanical_art.enabled and HUD.mechanical_art.layouts[resource] then return 'HUD Texture: '..(HUD.mechanical_art.status[resource] or 'awaiting visible weapon sample') end
        local cfg=HUD.config.effective(self.config,resource);local art=HUD.faithful_fragment_assets and HUD.faithful_fragment_assets[resource]
        if not cfg.texture_art_trial or cfg.texture_art_variant~='faithful' then return 'Faithful inactive: selected alternative / artwork disabled' end
        if not art then return 'No fragment adapter: existing native art / original rendering' end
        local available,total=0,0
        for _,asset in pairs(art.assets)do for _,kind in ipairs({'material','texture'})do total=total+1;local ok,value=pcall(sr.Application.can_get,kind,asset[kind]);if ok and value then available=available+1 end end end
        local prefix='Native resources '..available..'/'..total..'. '
        if math.abs((cfg.panel_opacity or 1)-1)>1e-6 then return prefix..'Original shapes: panel opacity must be 100% for baked art' end
        if available<total then return prefix..'Original shapes: native resources unavailable' end
        local state=faithful_states[resource]
        local full=faithful_full_states[resource]
        if full and full.revision~=self.appearance_revision then full=nil end
        if resource~=self.equipped_resource()then return prefix..'Not equipped; preview uses original shapes' end
        if not state then return prefix..'Waiting for an in-world draw; preview uses original shapes' end
        if state.count>0 then return prefix..'Faithful active: '..state.count..' fragments in last composition' end
        if math.abs(state.opacity-1)>1e-6 then
            local previous=full and (full.count>0 and ('last fully visible composition: '..full.count..' faithful fragments') or 'last fully visible composition: original shapes') or 'no fully visible sample for current settings'
            return prefix..string.format('Current visibility %.1f%% (menu/aim fade), panel %.0f%%; ',state.opacity*100,(cfg.panel_opacity or 1)*100)..previous
        end
        return prefix..'Original shapes: runtime artwork differs from baked reference'
    end
    function self.equipped_resource()return latest_raw and latest_raw.resource_hex end
    function self.shader_status()
        local cfg=HUD.config.effective(self.config,self.appearance_weapon())
        if cfg.shader_layers~=nil then
            local status=HUD.shader_layers.status(cfg,sr.Application.can_get)
            local note=HUD.screen_scene.shader_layer_status and HUD.screen_scene.shader_layer_status[self.appearance_weapon()]
            return status..(note and ('; '..note)or '')
        end
        local function state(key)
            local selected=cfg[key] or (key=='theme_shader' and 'auto' or 'none')
            if selected=='auto' then return 'automatic weapon theme (may use plain fill)' end
            if selected=='none' then return 'normal fill' end
            for _,entry in ipairs(HUD.shader_catalog)do if entry.id==selected then
                local ok,available=pcall(sr.Application.can_get,'material',entry.material)
                return entry.title..(ok and available and ' [material available]' or ' [UNAVAILABLE: normal fill fallback]')..(entry.frozen and ' [frozen sample]' or '')
            end end
            return 'unknown selection'
        end
        return 'Theme: '..state('theme_shader')..'; Effects: '..state('effect_shader')..(not cfg.effect_scanlines and not cfg.effect_sweep and ' [inactive: enable Scanlines or Sweep]' or '')..(self.config.anchor_mode~='world' and ' [3D renderer only; 2D preview uses normal fill]' or '')
    end
    function self.follow_equipped_appearance(enabled)
        self.config.appearance_follow_equipped=enabled~=false;if enabled then appearance_selection=nil end;self.appearance_revision=(self.appearance_revision or 0)+1
    end
    function self.panel_settings(resource)
        resource=resource or self.appearance_weapon()
        local cfg=HUD.config.effective(self.config,resource)
        local selected_model=self.appearance_model(resource)
        -- Read the actual themed commands; fetching is presentation-only, never a save.
        local commands=compose(selected_model,0,0,2,1,cfg,self.clock)
        commands=HUD.world_style.prepare(commands,{first_person=self.first_person},cfg)
        local frame,ink,border
        for _,v in ipairs(commands) do
            if v.type=='panel' and not v.child and not v.charge_meter and not frame then frame=v end
            if v.type=='text' and not v.weapon_label and (not ink or (v.size or 0)>(ink.size or 0)) then ink=v end
            if v.decoration and not v.charge_meter and not border then border=v end
        end
        local function color(v,fallback)
            if not v or not v.c then return fallback end
            return string.format('#%02X%02X%02X',math.max(0,math.min(255,math.floor(v.c[1]+.5))),math.max(0,math.min(255,math.floor(v.c[2]+.5))),math.max(0,math.min(255,math.floor(v.c[3]+.5))))
        end
        -- Explicit saved colors are authoritative. Texture bounds often use an
        -- invisible black frame, which is geometry metadata rather than a palette.
        local own=cfg.weapon_panel_overrides or {}
        if own.background_color==nil and frame and (frame.a or 0)>0 then cfg.background_color=color(frame,cfg.background_color)end
        if own.text_color==nil then cfg.text_color=color(ink,cfg.text_color)end
        if own.decoration_color==nil then cfg.decoration_color=color(border,cfg.decoration_color)end
        -- Opacity is authoritative configuration, not a themed frame alpha.
        if frame then cfg.frosted=frame.frosted==true end
        return cfg
    end
    function self.configure_panel(values,resource)
        HUD.config.set_panel(self.config,resource or self.appearance_weapon(),values);self.appearance_revision=(self.appearance_revision or 0)+1
    end
    function self.export_tuning() return HUD.config.serialize(self.config) end
    function self.save_tuning()
        if not backend.write_tuning then self.tuning_status='file writer unavailable';return false end
        local ok,result=pcall(backend.write_tuning,self.export_tuning())
        self.tuning_status=ok and ('saved '..result) or tostring(result)
        if not ok then log('TUNING '..self.tuning_status)else self.texture_styles_dirty=false end
        return ok,result
    end
    function self.reload_tuning()
        if not backend.read_tuning then return false end
        local ok,result=pcall(function()local values=backend.read_tuning();if values then self.configure(values) end;return values~=nil end)
        self.tuning_status=ok and (result and 'loaded tuning file' or 'defaults; no tuning file') or tostring(result)
        log('TUNING '..self.tuning_status)
        if ok and result and self.texture_styles_dirty then local saved,why=self.save_tuning();if not saved then self.tuning_status=tostring(why);return false end end
        return ok and result
    end
    self.reload_tuning()
    self.weapon_clearance=HUD.weapon_offsets.load(backend,log)
    function self.reload_settings()
        local failure
        local profiles=HUD.weapon_offsets.load(backend,function(message)
            log(message);if message:find('rejected:',1,true) then failure=message end
        end)
        if failure then return false,failure end
        if not self.reload_tuning() then return false,self.tuning_status end
        self.weapon_clearance=profiles
        self.auto_mounts={}
        if self.layout_editor and self.layout_editor.active then self.layout_editor.bind() end
        log('SETTINGS_RELOAD settings and weapon layouts loaded from disk')
        local art_ok,art_status=self.reload_runtime_textures()
        if not art_ok then log('TEXTURE_RELOAD '..art_status)end
        return true,'Settings and layouts reloaded from disk'
    end
    function self.blacklist_equipped(hidden)
        local resource=latest_raw and latest_raw.resource_hex
        if not resource then return false,'Equip a weapon first' end
        local previous=self.config.weapon_blacklist
        self.configure({weapon_blacklist=HUD.config.blacklist_value(self.config,resource,hidden)})
        local ok,err=self.save_tuning()
        if not ok then self.configure({weapon_blacklist=previous});return false,err end
        return true,(hidden and 'HUD hidden for ' or 'HUD enabled for ')..((HUD.weapon_names or {})[resource] or 'equipped weapon')
    end
    do
        local weapons,views=0,0
        for _,entries in pairs(self.weapon_clearance) do
            weapons=weapons+1
            for _ in pairs(entries) do views=views+1 end
        end
        log('WEAPON_OFFSETS active profiles: '..weapons..' weapons, '..views..' views')
    end
    function self.list_presets()local ok,names=pcall(backend.list_presets);return ok and names or {} end
    function self.delete_preset(name)
        if not backend.delete_preset then return false,'Preset deletion unavailable' end
        local ok,result=pcall(backend.delete_preset,name)
        log(ok and ('PRESET deleted: '..name) or ('PRESET delete failed: '..tostring(result)))
        return ok,result
    end
    function self.save_preset(name)
        if not backend.write_preset then return false,'Preset writer unavailable' end
        local settings=self.export_tuning():gsub('return {','settings = {',1)
        local layouts=HUD.weapon_offsets.serialize(self.weapon_clearance):gsub('return {','layouts = {',1)
        local body='-- DBF-HUD named preset: settings and all weapon layouts.\nreturn {\n'..settings..',\n'..layouts..',\n}\n'
        local ok,result=pcall(backend.write_preset,name,body)
        log(ok and ('PRESET saved: '..name) or ('PRESET save failed: '..tostring(result)))
        return ok,result
    end
    function self.load_preset(name)
        if not backend.read_preset or not backend.write_tuning or not backend.write_weapon_offsets then return false,'Preset storage unavailable' end
        local ok,result=pcall(function()
            local preset=backend.read_preset(name)
            local config=HUD.config.new();HUD.config.apply(config,preset.settings)
            local rejected
            local profiles=HUD.weapon_offsets.load({read_weapon_offsets=function()return preset.layouts end},function(err)rejected=err end)
            assert(not rejected,rejected)
            local layouts=HUD.weapon_offsets.serialize(profiles)
            backend.write_weapon_offsets(layouts);backend.write_tuning(HUD.config.serialize(config))
            self.config=config;self.appearance_revision=(self.appearance_revision or 0)+1;self.weapon_clearance=profiles;self.auto_mounts={}
            self.hybrid_scale_weapon=nil;self.hybrid_scale_depth=nil
            self.layout_editor.active=false;if menu then menu.sync() end
            return name
        end)
        log(ok and ('PRESET loaded: '..name) or ('PRESET load failed: '..tostring(result)))
        return ok,result
    end
    function self.reset_defaults()
        if not backend.write_tuning or not backend.write_weapon_offsets then return false,'Settings writer unavailable' end
        local function clone(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table' and clone(v) or v end;return out end
        local defaults=HUD.config.new()
        local profiles=clone(HUD.config.weapon_clearance)
        local ok,err=pcall(function()
            backend.write_weapon_offsets(HUD.weapon_offsets.serialize(profiles))
            backend.write_tuning(HUD.config.serialize(defaults))
        end)
        if not ok then log('PRESET Default setup failed: '..tostring(err));return false,err end
        self.config=defaults;self.appearance_revision=(self.appearance_revision or 0)+1;self.weapon_clearance=profiles;self.auto_mounts={}
        self.hybrid_scale_weapon=nil;self.hybrid_scale_depth=nil
        if self.layout_editor then self.layout_editor.active=false end
        if menu then menu.sync() end
        log('PRESET Default setup applied; previous settings and layouts backed up')
        return true
    end
    self.layout_editor=HUD.layout_editor.new(self,backend,log)
    menu=HUD.menu.new(self)
    local function screen_overlay(w,h)
        local commands=self.layout_editor.overlay(w,h,self.config.font)
        for _,c in ipairs(menu.overlay(w,h,self.config.font)) do commands[#commands+1]=c end
        if self.bone_marker_enabled and bone_marker_position and projection.camera_matrix then
            local p=bone_marker_position
            local ok,point=pcall(HUD.projection.project,projection.camera_matrix,p.x,p.y,p.z,
                projection.camera_fov,w/h,projection.camera_near)
            if ok and point then
                local native_point=projection.native_point(p.x,p.y,p.z)
                if native_point and self.clock>=(self.next_native_projection_log or 0) then
                    self.next_native_projection_log=self.clock+1
                    log(string.format('CAMERA_PROJECTION_COMPARE manual=%.6f,%.6f native=%.6f,%.6f,%.6f',
                        point.x,point.y,native_point.x,native_point.y,native_point.depth))
                end
                local x,y,s=point.x*w,point.y*h,h/1080
                -- Hollow magenta square shares the cyan cross's center; no smoothing.
                for _,edge in ipairs({{-9,-9,18,1.5},{-9,7.5,18,1.5},{-9,-9,1.5,18},{7.5,-9,1.5,18}}) do
                    commands[#commands+1]={type='rect',x=x+edge[1]*s,y=y+edge[2]*s,
                        w=edge[3]*s,h=edge[4]*s,c={255,0,255},a=1}
                end
            end
        end
        if self.config.debug_hud_timing then
            local s=h/1080;local t=self.hud_timing
            local label=t and string.format('HUD CPU %.2f ms | draw avg %.2f / %.1f ms | peak %.2f ms%s',t.cpu_ms,t.draw_ms,M.draw_budget_ms,t.peak_ms,t.draw_ms>M.draw_budget_ms and ' OVER BUDGET' or '') or 'HUD CPU timing: sampling...'
            local size=13*s;local a,b,e=HUD.font.measure(label,size,self.config.font)
            commands[#commands+1]={type='text',text=label,font=self.config.font,x=math.max(12*s,w-20*s-(e-a))-a,y=20*s,size=size,c=M.timing_ink(t and t.draw_ms,self.clock),a=1}
        end
        return commands
    end
    local next_weapon_screen_lookup=0;local last_weapon_screen_available
    function self.frame(dt)
        if retired then return end
        if type(dt)~='number' or dt~=dt or dt<0 or dt==math.huge then dt=1/60 end
        self.clock=self.clock+dt
        self.railgun_frame_delay=math.max(1/120,math.min(.25,dt), (self.railgun_frame_delay or 1/60)*.995)
        if self.config.debug_logging and self.clock>=next_weapon_screen_lookup then
            next_weapon_screen_lookup=self.clock+5
            local ok,available=pcall(function()
                return sr.Application.can_get('material','content/fac_helldivers/equipment/primary_weapons/assault_rifle_nacho/materials/weapon_screen')
            end)
            local state=ok and tostring(available) or 'lookup unavailable'
            if state~=last_weapon_screen_available then
                log('WEAPON_SCREEN_AVAILABILITY '..state);last_weapon_screen_available=state
            end
        end
        if not self.native_stats_sampled and self.clock>=2 then
            self.native_stats_sampled=true
            local ok,stats=pcall(function()return sr.Profiler.render_stats(sr.Window.get_main_window())end)
            local fields={}
            local function scan(value,path,depth)
                if #fields>=200 then return end
                if type(value)=='table' and depth<4 then for k,v in pairs(value)do scan(v,path..'.'..tostring(k),depth+1)end
                elseif type(value)=='number' or type(value)=='boolean' or type(value)=='string' then fields[#fields+1]=path..'='..tostring(value):sub(1,180)end
            end
            if ok then scan(stats,'stats',0);table.sort(fields);log('NATIVE_RENDER_STATS '..table.concat(fields,' '))else log('NATIVE_RENDER_STATS unavailable: '..tostring(stats))end
        end
        menu.poll();if self.menu_status~=menu.status then log('MENU '..menu.status) end;self.menu_status=menu.status
        if provider then
            local ok,x,y,visible=pcall(provider)
            if ok and x~=nil then local accepted=pcall(self.push_anchor,x,y,visible);if not accepted then self.anchor_status='invalid provider' end end
        end
        if self.clock>=next_sample then
            next_sample=self.clock+1/30
            local raw=reader.poll()


            if raw and raw.resource_hex=='ccfae6d4a601c741' then
                if self.snowball_unit~=raw.unit_ref then self.snowball_unit=raw.unit_ref;self.snowball_pickups=(self.snowball_pickups or 0)+1 end
            end -- Returning to the gun between throws is not another pickup.
            self.sample_weapon=raw and raw.resource_hex
            latest_raw=raw;binding_base=raw and raw.binding and raw.binding.module_base;model=HUD.model.normalize(raw);if model then model.charge_sample_clock=self.clock;model.charge_frame_delay=self.railgun_frame_delay;model.snow_party=raw.resource_hex=='ccfae6d4a601c741' and (self.snowball_pickups or 0)>=3;if raw.resource_hex=='ccfae6d4a601c741' and not model.snow_party then model=nil end end;self.status=reader.status
            if raw and raw.resource_hex=='e8d5f49ad7780e54' and raw.binding then
                self.epoch_probe_start=self.epoch_probe_start or self.clock
                if self.clock-self.epoch_probe_start<300 and (self.epoch_probe_count or 0)<200 and self.clock>=(self.epoch_probe_next or 0) then
                    local value,timer=raw.binding.epoch_charge_candidate,raw.binding.epoch_charge_timer
                    local sig=string.format('%s/%s/%s',tostring(raw.rounds),type(value)=='number' and string.format('%.5f',value) or 'missing',type(timer)=='number' and string.format('%.5f',timer) or 'missing')
                    if sig~=self.epoch_probe_signature then
                        self.epoch_probe_signature=sig;self.epoch_probe_count=(self.epoch_probe_count or 0)+1
                        log('EPOCH_CHARGE_RESEARCH count/raw/timer='..sig..' native normalized charge; safety unverified')
                    end
                    self.epoch_probe_next=self.clock+.2
                end
            end
            if self.clock<60 and raw and raw.resource_hex=='6cfcc7f8801a0266' and raw.binding then
                local signature=tostring(raw.rounds)..'/'..tostring(raw.binding.melta_charge_candidate)
                if signature~=self.melta_candidate and self.clock>=(self.next_melta_candidate or 0) then
                    self.melta_candidate=signature;self.next_melta_candidate=self.clock+.1
                    log('MELTA_CHARGE_CANDIDATE count/candidate='..signature..' (research only)')
                end
            end
            if raw and raw.resource_hex=='3828e2051aa9e897' then
                local sig=tostring(raw.rounds)..'/'..tostring(raw.capacity)..'/'..tostring(raw.reserve)
                if sig~=self.speargun_sample then self.speargun_sample=sig;log('SPEARGUN_NATIVE rounds/capacity/reserve='..sig) end
            end
            if raw and raw.resource_hex=='9f80d67a12a7e40f' then
                local sig=tostring(raw.rounds)..'/'..tostring(raw.capacity)..'/'..tostring(raw.reserve)..'/'..tostring(raw.ammo_mode)
                if sig~=self.recoilless_sample then self.recoilless_sample=sig;log('RECOILLESS_NATIVE rounds/capacity/reserve/mode='..sig) end
            end
            HUD.df_reload_state.step(df_reload_state,model,raw and raw.weapon_reload_event)
            HUD.df_shell_state.step(df_shell_state,model)
            HUD.recoilless_state.step(recoilless_state,model)
            HUD.senator_state.step(senator_state,model,self.clock)
            HUD.melta_panel.step(melta_effect,model,self.clock)
            local mg_flash=HUD.mg_easter.step(mg_easter,model,self.clock,self.config.mg43_easter_egg)
            if model then model.mg43_flash=mg_flash;model.mg43_flash_start=mg_flash and (mg_easter.until_at-1.1) or nil end
            if raw and raw.resource_hex=='72170a55a1f37ff1' and raw.binding and raw.binding.ammo_controls then
                local value=raw.binding.ammo_controls:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
                if value~=self.last_double_mode then log('DOUBLE_FREEDOM_CONTROL '..value);self.last_double_mode=value end
            end
            if self.config.debug_logging and self.clock<90 and raw and raw.label=='FUEL' then
                local entry=string.format('FUEL_GAUGE weapon=%s count=%s capacity=%s fraction=%s',raw.resource_hex,tostring(raw.rounds),tostring(raw.capacity),tostring(model and model.fraction))
                if entry~=self.last_fuel_trace then log(entry);self.last_fuel_trace=entry end
            end
            if self.config.debug_logging and self.clock<90 and raw and raw.binding and raw.binding.ammo_state then
                local b=raw.binding
                local function hex(s)return s:gsub('.',function(ch)return string.format('%02X',ch:byte())end)end
                local entry=string.format('AMMO_RELOAD weapon=%s count=%d capacity=%s chamber=%s flags=%X state=%s runtime=%s driver=%s types=%s projectile=%s',raw.resource_hex,raw.rounds or -1,tostring(raw.capacity),tostring(raw.chamber_rounds),b.driver_flags,hex(b.ammo_state),hex(b.ammo_runtime),hex(b.driver_state),b.ammo_types and hex(b.ammo_types) or '-',tostring(raw.projectile_type))
                if entry~=self.last_ammo_trace then log(entry);self.last_ammo_trace=entry end
            end
            if self.config.debug_logging and self.clock>=next_pose_log then
                if self.weapon_pose then
                    local p=self.weapon_pose;local m=p.matrix
                    log(string.format('POSE weapon=%d handle=0x%X nodes=%d position=%.4f,%.4f,%.4f axis_x=%.4f,%.4f,%.4f',
                        p.id,p.candidate,p.node_count,p.x,p.y,p.z,m[1],m[2],m[3]))
                elseif self.pose_status~=last_pose_status then log('POSE unavailable: '..self.pose_status) end
                last_pose_status=self.pose_status;next_pose_log=self.clock+1
            end
            if raw and raw.resource_hex=='26e40437ea275296' and raw.binding and raw.binding.ammo_controls then
                local control=raw.binding.ammo_controls:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
                if control~=self.last_airburst_control then
                    log('AIRBURST_CONTROL '..control);self.last_airburst_control=control
                end
            end
            if raw and raw.resource_hex=='14d5d4506056c7a4' and raw.binding and raw.binding.ammo_controls then
                local control=raw.binding.ammo_controls:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
                if control~=self.last_missile_control then
                    log('MISSILE_CONTROL '..control);self.last_missile_control=control
                end
            end
            if self.config.debug_logging and raw and raw.binding then
                local b=raw.binding
                if raw.resource_hex=='9f80d67a12a7e40f' and b.ammo_controls then
                    local bytes=b.ammo_controls:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
                    local state=tostring(raw.rounds)..':'..tostring(raw.reserve)..':'..bytes
                    if state~=self.last_recoilless_trace then
                        log('RECOILLESS_STATE count='..tostring(raw.rounds)..' reserve='..tostring(raw.reserve)..' controls='..bytes)
                        self.last_recoilless_trace=state
                    end
                end
                local identity=string.format('weapon=%d native=%d candidate=0x%X record=0x%X resource=%s avatar=%d avatar_native=%d avatar_candidate=0x%X avatar_record=0x%X game_base=0x%X',
                    raw.id,raw.unit_ref,b.candidate,b.record,raw.resource_hex,b.avatar_id,raw.avatar_unit_ref,b.avatar_candidate,b.avatar_record,b.module_base)
                if identity~=last_binding then log('BINDING '..identity);last_binding=identity end
            elseif self.config.debug_logging and last_binding~=nil then
                log('BINDING unavailable: '..self.status);last_binding=nil
            end
            if model and model.id~=last_id then
                motion.ready=false;attached.ready=false;last_id=model.id
                if anchor_source=='native crosshair' then anchor=nil end
            end
        end
        HUD.layout.scorcher_step(scorcher_effect,model,self.clock)
        -- Pose follows the render/update cadence; ammo discovery remains at 30 Hz.
        -- Holding pose samples caused stepped targets and lag-limit corrections.
        local native_first,mode_status=HUD.camera_mode.read(backend,latest_raw)
        if native_first~=nil then self.first_person=native_first;self.native_view_seen=true end
        local profiles=latest_raw and self.weapon_clearance[latest_raw.resource_hex]
        local active_view=self.first_person and ('first_'..self.config.fp_auto_side) or 'right'
        local selected_view=(profiles and profiles[active_view] and profiles[active_view].attach_point) and active_view or (self.placement_view_parity and 'right' or active_view)
        local selected_profile=profiles and profiles[selected_view]
        local attach_point=selected_profile and selected_profile.attach_point
        if not attach_point then attach_point='root' end
        local anchor_hash=attach_point and attach_point:match('^node:(%x+)$')
        if attach_point=='sight' then anchor_hash='527c9c73' end
        local melta_probe=latest_raw and latest_raw.resource_hex=='6cfcc7f8801a0266' and self.clock<30 and self.clock>=(self.melta_probe_at or 0)
        if melta_probe then self.melta_probe_at=self.clock+.1 end
        self.weapon_pose=latest_raw and pose.poll(latest_raw,anchor_hash and tonumber(anchor_hash,16),self.layout_editor.active or melta_probe) or nil
        if melta_probe and self.clock>=(self.melta_report_at or 0) then
            self.melta_report_at=self.clock+2
            local entries={};for hash,delta in pairs(pose.melta_changes or {}) do entries[#entries+1]=string.format('%08x:%.5f',hash,delta) end
            table.sort(entries);log('MELTA_BONE_RELATIVE max_axis_change_from_initial='..table.concat(entries,','))
        end
        if self.weapon_pose then self.weapon_pose.attach_point=attach_point end
        -- Bounded transition-only attachment diagnostics; no rendering changes.
        if self.clock<60 then
            local sig=tostring(self.weapon_pose~=nil)..':'..tostring(pose.status)..':'..tostring(self.anchor_status)
            if self.attachment_probe_sig~=sig then
                self.attachment_probe_sig=sig
                log('ATTACHMENT_SYNC pose='..tostring(self.weapon_pose~=nil)..' pose_status='..tostring(pose.status)..' previous_renderer='..tostring(self.anchor_status))
            end
        end
        draw_bone_marker(dt)
        self.pose_status=latest_raw and pose.status or 'no weapon'
        local w,h=sr.Gui.resolution()
        -- Screen GUI coordinates use Gui.resolution(), not the output back buffer.
        -- Upscaling can make the latter larger and displace the whole hybrid panel.
        if type(w)~='number' or type(h)~='number' or w<=0 or h<=0 then view.clear();return end
        if w~=width or h~=height then motion.ready=false;attached.ready=false;width,height=w,h end
        if model and not provider and self.clock>=manual_until then
            local point=native.poll()
            if point then anchor=point;anchor_at=self.clock;anchor_source='native crosshair' end
        elseif not model then anchor=nil;motion.ready=false end
        local live=anchor and self.clock-anchor_at<0.15
        self.anchor_status=live and anchor_source or ('center fallback: '..native.status)
        local target=live and {x=(anchor.x-0.5)*w*1080/h,y=(0.5-anchor.y)*1080} or nil
        local point
        if self.weapon_pose then
            local p=self.weapon_pose;local m=p.matrix;local c=self.config
            local mount={x=p.x+m[1]*c.mount_x+m[5]*c.mount_y+m[9]*c.mount_z,
                y=p.y+m[2]*c.mount_x+m[6]*c.mount_y+m[10]*c.mount_z,
                z=p.z+m[3]*c.mount_x+m[7]*c.mount_y+m[11]*c.mount_z}
            point=projection.poll(binding_base,mount,w/h)
        end
        if depth_marker then depth_marker.draw(self.bone_marker_enabled and bone_marker_position or nil,
            projection.camera_matrix,projection.camera_fov,h,w) end
        if native_first~=nil then self.first_person=native_first
        elseif not self.native_view_seen then self.first_person=HUD.projection.first_person(self.first_person,projection.camera_distance,projection.camera_fov) end
        self.camera_mode_status=mode_status
        self.left_shoulder=false
        HUD.placement.update(self,pose,projection,latest_raw,log)
        self.editor_camera_matrix=projection.camera_matrix
        self.layout_editor.tick(dt)
        local locked_bone_point
        if self.screen_bone_hud and bone_marker_position and projection.camera_matrix then
            local p=bone_marker_position
            local ok,result=pcall(HUD.projection.project,projection.camera_matrix,p.x,p.y,p.z,
                projection.camera_fov,w/h,projection.camera_near)
            if ok then locked_bone_point=result end
        end
        if self.config.anchor_mode=='weapon' and self.weapon_pose then
            local p=self.weapon_pose;local m=p.matrix
            local x,y,z
            if p.sight then x,y,z=p.sight.x,p.sight.y,p.sight.z
            else x,y,z=HUD.scene_test.mount(p,self.config) end
            point=projection.poll(binding_base,{x=p.x+m[1]*x+m[5]*y+m[9]*z,
                y=p.y+m[2]*x+m[6]*y+m[10]*z,
                z=p.z+m[3]*x+m[7]*y+m[11]*z},w/h)
        end
        if self.config.debug_logging and projection.camera_distance and self.clock>=(self.next_camera_sample or 0) then
            log(string.format('CAMERA placement distance=%.3f fov=%.3f lateral=%.3f first_person=%s source=%s',projection.camera_distance,projection.camera_fov,projection.camera_lateral,tostring(self.first_person),mode_status))
            self.next_camera_sample=self.clock+1
        end
        self.projection_status=projection.status
        if self.screen_bone_hud then point=locked_bone_point end
        local use_weapon=(self.screen_bone_hud or self.config.anchor_mode=='weapon') and point~=nil and not provider and self.clock>=manual_until
        if use_weapon~=attachment_active then motion.ready=false;attached.ready=false;attachment_active=use_weapon end
        local attachment_view=self.first_person and 'first' or 'third'
        if self.hybrid_view~=attachment_view then
            attached.ready=false;self.hybrid_view=attachment_view
        end
        local x,y
        if use_weapon then
            if self.screen_bone_hud then
                x,y=(point.x-.5)*w*1080/h,(point.y-.5)*1080
            else x,y=HUD.motion.attach(attached,{x=(point.x-.5)*w*1080/h,y=(point.y-.5)*1080},dt,self.config) end
            self.anchor_status='weapon attachment'
        else
            x,y=HUD.motion.step(motion,target,dt,self.config)
            self.attachment_status='reticle fallback: '..projection.status
        end
        -- Movement must not control alpha. Native reticle hiding only changes the anchor.
        local visible=model and not self.hidden and not (live and not anchor.visible)
        if sr.Window and sr.Window.show_cursor then
            local ok,cursor=pcall(sr.Window.show_cursor);if ok and cursor then visible=false end
        end
        local wanted=visible and 1 or 0
        alpha=wanted+(alpha-wanted)*math.exp(-math.min(dt,0.35)/(visible and 0.06 or 0.10))
        self.opacity=alpha;self.motion_x=x;self.motion_y=y
        if self.config.debug_logging then
        local diagnostic=self.status..' | '..self.anchor_status..' | '..(view.material_status or 'material not sampled')..' | font: '..self.config.font
        if self.clock>=next_log then
            if diagnostic~=last_log_status or live then
                log(string.format('%s viewport=%dx%d state=%s pos=%.1f,%.1f samples=%d',diagnostic,w,h,
                    tostring(native.native_state),x,y,native.samples))
                last_log_status=diagnostic
            end
            next_log=self.clock+2
        end
        end
        if self.frame_stage==4 then return end
        if self.scene_test_only then world_probe.draw(nil,self.config);view.clear();return end
        if not model or alpha<0.01 or HUD.config.is_blacklisted(self.config,(latest_raw or {}).resource_hex) then if screen_scene then screen_scene.release() end;world_display.release();world_probe.draw(nil,self.config);view.draw(screen_overlay(w,h));return end
        if model.resource_hex=='72170a55a1f37ff1' or HUD.ballistic_family.specs[model.resource_hex] then
            model.compass_heading=HUD.compass.heading(projection.camera_matrix)
        elseif model.resource_hex=='4dbd74f49c8ffc13' or (HUD.mechanical_art.layouts[model.resource_hex] and HUD.mechanical_art.layouts[model.resource_hex].zones.compass) then
            local matrix=self.weapon_pose and self.weapon_pose.matrix
            model.compass_heading=matrix and (math.deg(math.atan2(matrix[5],matrix[6]))%360) or nil
        end
        model.chamber_rounds=(latest_raw or {}).chamber_rounds
        local aiming=HUD.camera_mode.read_aiming(backend,latest_raw)
        self.presentation_view,self.presentation_status=HUD.view_presentation.select(native_first,aiming,self.config.hud_presentation)
        local aim_opacity=1
        if self.config.fade_3d_unless_aiming then
            local wanted=aiming==true and 1 or 0
            local previous=self.aim_opacity or wanted
            aim_opacity=wanted+(previous-wanted)*math.exp(-math.max(0,dt)/.15)
        end
        self.aim_opacity=aim_opacity
        if self.presentation_view=='third' then
            world_display.release();if screen_scene then screen_scene.release()end
            local cfg=HUD.config.effective(self.config,model.resource_hex);cfg.presentation_view='third'
            local unit=h/1080;local scale=unit*self.config.scale*self.config.third_person_scale
            local px=w/2+(self.config.offset_x+(self.motion_x or 0))*unit
            local py=h/2+(self.config.offset_y+(self.motion_y or 0))*unit
            px=math.max(4*unit,math.min(w-64*scale-4*unit,px));py=math.max(4*unit,math.min(h-86*scale-4*unit,py))
            local commands=compose(model,px,py,scale,alpha*aim_opacity,cfg,self.clock)
            for _,v in ipairs(screen_overlay(w,h))do commands[#commands+1]=v end
            view.draw(commands);self.anchor_status='floating Simple HUD';return
        end
        if self.config.anchor_mode=='world' and self.weapon_pose and not self.screen_bone_hud then
            local world_config=HUD.config.effective(self.config,model.resource_hex)
            world_config.presentation_view=self.presentation_view
            world_config.scale=self.config.scale*(self.profile_scale or 1)
            if self.presentation_view=='third' then
                world_config.scale=world_config.scale*self.config.third_person_scale
                world_config.style_3d='standard';world_config.shader_layers={}
                world_config.theme_shader='none';world_config.effect_shader='none'
                world_config.effect_scanlines=false;world_config.effect_sweep=false;world_config.effect_flicker=false
            end
            local appearance_id=(model.resource_hex or '')..'/'..tostring(self.appearance_revision or 0)
            if appearance_id~=self.logged_appearance then
                self.logged_appearance=appearance_id
                log('WEAPON_APPEARANCE resource='..tostring(model.resource_hex)..' override='..tostring(world_config.weapon_panel_overrides~=nil)..' panel_opacity='..tostring(world_config.panel_opacity)..' scanlines='..tostring(world_config.effect_scanlines)..' density='..tostring(world_config.effect_scanline_count))
            end
            world_config.visibility_alpha=alpha*aim_opacity
            world_config.panel_rotation=self.profile_rotation or 0
            world_config.panel_pitch=self.profile_pitch or 0
            world_config.panel_yaw=self.profile_yaw or 0
            world_config.first_person_zoom_demo=self.first_person and self.config.zoom_compensation
            world_config.style_clock=self.clock
            world_config.profile_skip_text=self.frame_stage==2
            world_config.profile_skip_geometry=self.frame_stage==3
            world_config.occlusion_mode=self.config.force_occlusion and 'gui_depth' or 'gui'
            world_config.keep_hud_upright=self.config.keep_hud_upright and aiming==true
            if aim_opacity<.01 then if screen_scene then screen_scene.release() end;world_display.release();view.draw(screen_overlay(w,h));return end
            local world_commands=compose(model,0,0,2*world_config.scale,alpha*aim_opacity,world_config,self.clock,nil,true)
            local f=world_commands[1];local left,bottom=f.x,f.y
            M.rebase_commands(world_commands,left,bottom)
            if self.screen_scene_hud and screen_scene and screen_scene.draw(self.weapon_pose,world_config,world_commands,
                projection.camera_matrix,projection.camera_fov,w,h,projection.camera_near) then
                world_display.release();view.draw(screen_overlay(w,h));self.anchor_status='screen-projected scene-depth HUD';return
            end
            if screen_scene then screen_scene.release() end
            if world_display.draw(self.weapon_pose,world_config,nil,dt,nil,world_commands) then
                view.draw(screen_overlay(w,h))
                self.anchor_status='weapon 3D WorldGUI';return
            end
        end
        world_display.release()
        if screen_scene then screen_scene.release() end
        if aim_opacity<.01 then view.draw(screen_overlay(w,h));return end
        local s=h/1080
        local offset_x,offset_y=self.config.offset_x,self.config.offset_y
        if use_weapon then offset_x,offset_y=20,-15 end
        if self.screen_bone_hud then offset_x,offset_y=0,0 end
        if self.config.anchor_mode=='weapon' and self.first_person then
            offset_x=use_weapon and 80 or self.config.offset_x+75
        end
        local screen_key='screen_'..self.config.anchor_mode..'_'..(self.first_person and 'first' or 'third')
        local screen_profile=((self.weapon_clearance[(latest_raw or {}).resource_hex] or {})[screen_key] or {})
        offset_x=offset_x+(screen_profile.x or 0)*1000
        offset_y=offset_y+(screen_profile.z or 0)*1000
        x=w/2+(x+offset_x)*s;y=h/2+(y+offset_y)*s
        -- Screen HUD size is independent of per-view 3D mount corrections.
        local scale=.5*s*self.config.scale*(screen_profile.scale or 1)
        if self.config.anchor_mode=='weapon' and use_weapon and point and point.depth and point.depth>.05 then
            local key=(latest_raw or {}).resource_hex
            if self.hybrid_scale_weapon~=key then
                self.hybrid_scale_weapon=key;self.hybrid_scale_depth=point.depth
            end
            -- Preserve the initial size, then follow perspective as the camera approaches.
            scale=scale*math.max(.25,math.min(4,(self.hybrid_scale_depth or point.depth)/point.depth))
        end
        if self.config.anchor_mode=='weapon' and self.first_person then scale=scale*2 end
        local screen_config=HUD.config.effective(self.config,model.resource_hex)
        screen_config.presentation_view=self.presentation_view
        if self.presentation_view=='third' then
            scale=scale*self.config.third_person_scale
            screen_config.style_3d='standard';screen_config.shader_layers={}
            screen_config.theme_shader='none';screen_config.effect_shader='none'
            screen_config.effect_scanlines=false;screen_config.effect_sweep=false;screen_config.effect_flicker=false
        end
        screen_config.senator_style='upright' -- Also covers a failed WorldGUI falling back to screen.
        local commands=compose(model,x,y,scale,alpha*aim_opacity,screen_config,self.clock)
        local frame=commands[1]
        local frame_bottom=frame.y
        for _,command in ipairs(commands) do if command.type=='panel' then frame_bottom=math.min(frame_bottom,command.y) end end
        local margin=4*scale
        local dx=math.max(margin,math.min(w-margin-frame.w,frame.x))-frame.x
        local dy=math.max(margin,math.min(h-margin-frame.h,frame.y))-frame.y
        dy=math.max(dy,margin-frame_bottom)
        for _,c in ipairs(commands) do c.x=c.x+dx;c.y=c.y+dy end
        if self.config.debug_logging and self.config.pose_marker then
            self.projection_status=projection.status
            if self.clock>=next_projection_log then
                log(point and string.format('PROJECT x=%.4f y=%.4f depth=%.3f',point.x,point.y,point.depth)
                    or ('PROJECT unavailable: '..projection.status))
                next_projection_log=self.clock+2
            end
            if point then
                local px,py=point.x*w,point.y*h
                commands[#commands+1]={type='rect',x=px-7*s,y=py-1*s,w=14*s,h=2*s,a=alpha,c={229,231,226}}
                commands[#commands+1]={type='rect',x=px-1*s,y=py-7*s,w=2*s,h=14*s,a=alpha,c={229,231,226}}
            end
        end
        for _,command in ipairs(screen_overlay(w,h)) do commands[#commands+1]=command end
        view.draw(commands)
        if self.config.debug_logging then world_probe.draw(self.weapon_pose,self.config,nil,dt) else world_probe.release() end
    end
    -- Short startup timing trial; one aggregate line, no per-frame logging.

    frame_trial=options and options.frame_trial and {elapsed=0,phase=1,frames=0,max=0,over33=0,over50=0,total=0,cpu_max=0,buckets={}} or nil
    if frame_trial then profile=nil end
    local control_requests=HUD.control_requests.new(self,assert(os.getenv('LOCALAPPDATA'))..'/DBF')
    function self.tick(dt)
        if not retired then control_requests.poll()end
        if frame_trial and not retired then
            local t=frame_trial;local delta=math.max(0,dt or 0)
            local eligible=self.first_person and (self.opacity or 0)>.9 and self.sample_weapon
            t.collecting=eligible and true or false
            if eligible then
                if t.weapon and t.weapon~=self.sample_weapon then
                    log('STAGE_RESET weapon changed; restarting comparison')
                    t={elapsed=0,phase=1,frames=0,max=0,over33=0,over50=0,total=0,cpu_max=0,buckets={},collecting=true};frame_trial=t
                end
                if not t.weapon then t.weapon=self.sample_weapon;log('STAGE_BEGIN phase='..t.phase..' weapon='..t.weapon..' first_person=true') end
                t.elapsed=t.elapsed+delta;t.frames=t.frames+1;t.total=t.total+delta;t.max=math.max(t.max,delta)
                if delta>.033 then t.over33=t.over33+1 end
                if delta>.05 then t.over50=t.over50+1 end
            end
            if t.elapsed>=8 then
                log(string.format('FRAME_TRIAL phase=%d bypass=%s frames=%d avg_ms=%.3f max_ms=%.3f over33=%d over50=%d cpu_max_ms=%.3f heap_kb=%.0f',t.phase,tostring(t.phase==4),t.frames,1000*t.total/t.frames,1000*t.max,t.over33,t.over50,1000*t.cpu_max,collectgarbage('count')))
                if screen_scene and screen_scene.resource_stats then local a,b,c,d,e,f,g=screen_scene.resource_stats();log(string.format('FRAME_RESOURCES created=%d destroyed=%d released_with_gui=%d live=%d bookkeeping_allocated=%d bookkeeping_reused=%d triangle_updates=%d',a,b,c,d,e,f,g or 0)) end
                for name,b in pairs(t.buckets) do log(string.format('STAGE_COST phase=%d name=%s per_frame_ms=%.3f max_ms=%.3f',t.phase,name,1000*b.total/t.frames,1000*b.max)) end
                if t.phase==5 then frame_trial=nil else
                    frame_trial={elapsed=0,phase=t.phase+1,frames=0,max=0,over33=0,over50=0,total=0,cpu_max=0,buckets={},weapon=t.weapon}
                    if frame_trial.phase==4 then pcall(screen_scene.release);pcall(view.release) end
                end
            end
            self.frame_stage=frame_trial and frame_trial.phase or nil
        end
        if not retired then
            if not profile and not self.senator_profile_done and self.sample_weapon=='8d3d52a3b2f19402' then profile={elapsed=0,frames=0,total=0,max=0,buckets={}} end
            if profile and profile.weapon and (profile.weapon~=self.sample_weapon or profile.view~=self.first_person) then
                profile={elapsed=0,frames=0,total=0,max=0,buckets={}}
            end
            if profile then profile.drew=false end
            self.timing_active=self.config.debug_hud_timing==true
            self.timing_draw=0
            if not self.timing_active then self.timing_window=nil;self.hud_timing=nil end
            local started=(profile or frame_trial or self.timing_active) and os.clock()
            HUD.native_font.begin_frame()
            local ok,err=pcall(self.frame,dt)
            HUD.native_font.end_frame()
            if self.timing_active and ok then
                local cost=os.clock()-started
                local t=self.timing_window or {elapsed=0,frames=0,cpu=0,draw=0,peak=0};self.timing_window=t
                t.elapsed=t.elapsed+math.max(0,dt or 0);t.frames=t.frames+1;t.cpu=t.cpu+cost;t.draw=t.draw+(self.timing_draw or 0);t.peak=math.max(t.peak,cost)
                if t.elapsed>=.25 then self.hud_timing={cpu_ms=1000*t.cpu/t.frames,draw_ms=1000*t.draw/t.frames,peak_ms=1000*t.peak};self.timing_window=nil end
            end
            if frame_trial and frame_trial.collecting then frame_trial.cpu_max=math.max(frame_trial.cpu_max,os.clock()-started) end
            if profile and profile.drew then
                profile.dt_total=(profile.dt_total or 0)+math.max(0,dt or 0);profile.dt_max=math.max(profile.dt_max or 0,dt or 0)
                profile.weapon=self.sample_weapon;profile.view=self.first_person
                local cost=os.clock()-started
                profile.elapsed=profile.elapsed+math.max(0,dt or 0)
                profile.frames=profile.frames+1;profile.total=profile.total+cost;profile.max=math.max(profile.max,cost)
                profile.intervals=profile.intervals or {}
                local second=math.floor(profile.elapsed)
                if second>(profile.last_second or -1) then
                    profile.last_second=second
                    profile.intervals[#profile.intervals+1]=string.format('%d:%.2f/%.2f/%.0f',second,1000*(profile.interval_dt_max or 0),1000*(profile.interval_cpu_max or 0),collectgarbage('count'))
                    profile.interval_dt_max,profile.interval_cpu_max=0,0
                end
                profile.interval_dt_max=math.max(profile.interval_dt_max or 0,dt or 0)
                profile.interval_cpu_max=math.max(profile.interval_cpu_max or 0,cost)
                if profile.elapsed>=20 then
                    log(string.format('PROFILE HUD frames=%d avg_ms=%.3f max_ms=%.3f view=%s mode=%s',profile.frames,1000*profile.total/profile.frames,1000*profile.max,self.first_person and 'first' or 'third',tostring(self.config.anchor_mode)))
                    for name,bucket in pairs(profile.buckets) do
                        log(string.format('PROFILE_PHASE %s per_frame_ms=%.3f per_call_ms=%.3f max_ms=%.3f calls=%d',name,1000*bucket.total/profile.frames,1000*bucket.total/bucket.calls,1000*bucket.max,bucket.calls))
                    end
                    log(string.format('VISIBLE_SAMPLE weapon=%s avg_frame_ms=%.3f max_frame_ms=%.3f',tostring(profile.weapon),1000*profile.dt_total/profile.frames,1000*profile.dt_max))
                    if screen_scene and screen_scene.resource_stats then
                        local a,b,c,d,e,f,g=screen_scene.resource_stats()
                        log(string.format('VISIBLE_RESOURCES created=%d destroyed=%d released=%d live=%d allocated=%d reused=%d bitmap_updates=%d',a,b,c,d,e,f,g or 0))
                    end
                    log('VISIBLE_INTERVALS second:max_frame_ms/max_hud_cpu_ms/shared_heap_kb '..table.concat(profile.intervals,' '))
                    if profile.weapon=='8d3d52a3b2f19402' then self.senator_profile_done=true end
                    profile=nil
                end
            end
            if profile and not profile.drew then profile={elapsed=0,frames=0,total=0,max=0,buckets={}} end
            if not ok then self.status=tostring(err);failures=failures+1;log('ERROR '..self.status);pcall(view.clear)
                if failures>=10 then self.status='disabled: '..self.status;self.retire() end
            else failures=0 end
        end
    end
    local wrapper
    wrapper=function(...)
        -- frame dt belongs to update's arguments, not its return values.
        local dt=select(1,...)
        local function after(...)
            self.tick(dt)
            return ...
        end
        return after(original(...))
    end
    local shutdown_wrapper
    shutdown_wrapper=function(...)
        self.retire()
        if shutdown then return shutdown(...) end
    end
    function self.retire()
        if cleaned then return end
        cleaned=true
        if texture_swaps then texture_swaps.close()end
        if backend.close and hot_panel_art.after_close then hot_panel_art.after_close(function()pcall(backend.close)end)end
        hot_panel_art.close()
        retired=true;menu.retire();if depth_marker then pcall(depth_marker.release) end;if screen_scene then pcall(screen_scene.release) end;pcall(bone_marker.release);pcall(world_display.release);pcall(world_probe.release);pcall(view.release)
        if backend.close and not hot_panel_art.after_close then pcall(backend.close) end
        if not managed then
            if rawget(_G,'update')==wrapper then rawset(_G,'update',original) end
            if rawget(_G,'shutdown')==shutdown_wrapper then rawset(_G,'shutdown',shutdown) end
        end
    end
    if not managed then
        rawset(_G,'update',wrapper);rawset(_G,'shutdown',shutdown_wrapper);rawset(_G,'DBFHUD',self)
    end
    return self
end
return M
