local M={}
function M.start(sr,backend,options)
    local managed=options and options.managed==true
    -- Compatibility: retire a previous-brand instance during live upgrade.
    local legacy=rawget(_G,'AstraAmmo');if legacy and legacy.retire then legacy.retire() end
    local old=rawget(_G,'DBFHUD');if old and old.retire then old.retire() end
    local self={version='0.3.40',status='starting',anchor_status='starting native anchor',clock=0,hidden=false}
    self.config=HUD.config.new()
    local attached=HUD.motion.new();local attachment_active=false
    local motion=HUD.motion.new();local reader=HUD.reader.new(backend);local view=HUD.view.new(sr)
    local native=HUD.anchor.new(backend);self.native_anchor=native
    local pose=HUD.pose.new(backend);local next_pose_log=0;local last_pose_status
    local original=rawget(_G,'update');local shutdown=rawget(_G,'shutdown')
    if not managed and type(original)~='function' then self.status='update callback missing';return self end
    local projection=HUD.projection.new(backend);local binding_base;local next_projection_log=0
    local latest_raw;local next_sample=0;local model;local anchor;local anchor_at=-10;local provider;local failures=0
    function self.texture_commands()
        if not model then return nil end
        local cfg={};for k,v in pairs(self.config) do cfg[k]=v end
        cfg.font='bigblue';cfg.frosted=false
        local commands=HUD.layout.compose(model,0,0,2,1,cfg,self.clock)
        return commands
    end
    local retired=false;local cleaned=false;local alpha=0;local last_id;local width,height
    local manual_until=-1;local anchor_source;local next_log=0;local last_log_status
    local last_binding
    local function log(line) if backend.log then pcall(backend.log,string.format('[%.3f] %s',self.clock,line)) end end
    local function research_log(line)
        if self.config.debug_logging or line:find('failure',1,true) or line:find('missing',1,true) or line:find('stopped',1,true) then log(line) end
    end
    local world_probe=HUD.world_probe.new(sr,research_log)
    local world_display=HUD.scene_test.new(sr,research_log)
    log('START DBFHUD '..self.version..' native crosshair enabled; movement visibility filter removed')
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
    for _,namespace in ipairs({'Viewport','Renderer','Material','Unit','Gui','World'}) do
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
        HUD.config.apply(self.config,values);self.config.placement_mode='auto'
        if self.config.debug_logging and not was_debug then research_snapshot() end
        if menu then menu.sync() end
    end
    function self.export_tuning() return HUD.config.serialize(self.config) end
    function self.save_tuning()
        if not backend.write_tuning then self.tuning_status='file writer unavailable';return false end
        local ok,result=pcall(backend.write_tuning,self.export_tuning())
        self.tuning_status=ok and ('saved '..result) or tostring(result)
        if not ok then log('TUNING '..self.tuning_status) end
        return ok,result
    end
    function self.reload_tuning()
        if not backend.read_tuning then return false end
        local ok,result=pcall(function()local values=backend.read_tuning();if values then self.configure(values) end;return values~=nil end)
        self.tuning_status=ok and (result and 'loaded tuning file' or 'defaults; no tuning file') or tostring(result)
        log('TUNING '..self.tuning_status);return ok and result
    end
    self.reload_tuning()
    self.weapon_clearance=HUD.weapon_offsets.load(backend,log)
    menu=HUD.menu.new(self)
    local next_weapon_screen_lookup=0;local last_weapon_screen_available
    function self.frame(dt)
        if retired then return end
        if type(dt)~='number' or dt~=dt or dt<0 or dt==math.huge then dt=1/60 end
        self.clock=self.clock+dt
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
        menu.poll();if self.menu_status~=menu.status then log('MENU '..menu.status) end;self.menu_status=menu.status
        if provider then
            local ok,x,y,visible=pcall(provider)
            if ok and x~=nil then local accepted=pcall(self.push_anchor,x,y,visible);if not accepted then self.anchor_status='invalid provider' end end
        end
        if self.clock>=next_sample then
            next_sample=self.clock+1/30
            local raw=reader.poll();latest_raw=raw;binding_base=raw and raw.binding and raw.binding.module_base;model=HUD.model.normalize(raw);self.status=reader.status
            if self.config.debug_logging and self.clock>=next_pose_log then
                if self.weapon_pose then
                    local p=self.weapon_pose;local m=p.matrix
                    log(string.format('POSE weapon=%d handle=0x%X nodes=%d position=%.4f,%.4f,%.4f axis_x=%.4f,%.4f,%.4f',
                        p.id,p.candidate,p.node_count,p.x,p.y,p.z,m[1],m[2],m[3]))
                elseif self.pose_status~=last_pose_status then log('POSE unavailable: '..self.pose_status) end
                last_pose_status=self.pose_status;next_pose_log=self.clock+1
            end
            if self.config.debug_logging and raw and raw.binding then
                local b=raw.binding
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
        -- Pose follows the render/update cadence; ammo discovery remains at 30 Hz.
        -- Holding pose samples caused stepped targets and lag-limit corrections.
        self.weapon_pose=latest_raw and pose.poll(latest_raw) or nil
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
        local native_first,mode_status=HUD.camera_mode.read(backend,latest_raw)
        if native_first~=nil then self.first_person=native_first
        else self.first_person=HUD.projection.first_person(self.first_person,projection.camera_distance,projection.camera_fov) end
        self.camera_mode_status=mode_status
        local native_left,shoulder_status=HUD.camera_mode.read_shoulder(backend,latest_raw)
        if self.first_person then self.left_shoulder=false
        elseif native_left~=nil then self.left_shoulder=native_left
        else self.left_shoulder=HUD.projection.left_shoulder(self.left_shoulder,projection.camera_lateral,false) end
        self.shoulder_mode_status=shoulder_status
        -- Aim-only unoccluded rendering makes shoulder-clearance relocation
        -- unnecessary. Keep the standard sight mount for either shoulder.
        if self.config.show_3d=='aiming' then self.left_shoulder=false end
        HUD.placement.update(self,pose,projection,latest_raw,log)
        if self.config.debug_logging and projection.camera_distance and self.clock>=(self.next_camera_sample or 0) then
            log(string.format('CAMERA placement distance=%.3f fov=%.3f lateral=%.3f first_person=%s source=%s',projection.camera_distance,projection.camera_fov,projection.camera_lateral,tostring(self.first_person),mode_status))
            self.next_camera_sample=self.clock+1
        end
        self.projection_status=projection.status
        local use_weapon=self.config.anchor_mode=='weapon' and point~=nil and not provider and self.clock>=manual_until
        if use_weapon~=attachment_active then motion.ready=false;attached.ready=false;attachment_active=use_weapon end
        local x,y
        if use_weapon then
            x,y=HUD.motion.attach(attached,{x=(point.x-.5)*w*1080/h,y=(point.y-.5)*1080},dt,self.config)
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
        if self.scene_test_only then world_probe.draw(nil,self.config);view.clear();return end
        if not model or alpha<0.01 then world_display.release();world_probe.draw(nil,self.config);view.clear();return end
        if self.config.anchor_mode=='world' and self.weapon_pose then
            local world_config={};for k,v in pairs(self.config)do world_config[k]=v end
            if self.config.show_3d=='aiming' then
                local aiming=HUD.camera_mode.read_aiming(backend,latest_raw)
                world_config.occlusion_mode=aiming==true and 'gui' or 'gui_depth'
            end
            local world_commands=HUD.layout.compose(model,0,0,2*self.config.scale,alpha*self.config.opacity,world_config,self.clock)
            local f=world_commands[1];local left,bottom=f.x,f.y
            for _,v in ipairs(world_commands) do v.x=v.x-left;v.y=v.y-bottom end
            if world_display.draw(self.weapon_pose,world_config,nil,dt,nil,world_commands) then
                view.clear();self.anchor_status='weapon 3D WorldGUI';return
            end
        end
        world_display.release()
        local s=h/1080
        x=w/2+(x+(use_weapon and self.config.weapon_offset_x or self.config.offset_x))*s;y=h/2+(y+(use_weapon and self.config.weapon_offset_y or self.config.offset_y))*s
        local scale=s*self.config.scale
        local commands=HUD.layout.compose(model,x,y,scale,alpha*self.config.opacity,self.config,self.clock)
        local frame=commands[1];local margin=4*scale
        local dx=math.max(margin,math.min(w-margin-frame.w,frame.x))-frame.x
        local dy=math.max(margin,math.min(h-margin-frame.h,frame.y))-frame.y
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
        view.draw(commands)
        if self.config.debug_logging then world_probe.draw(self.weapon_pose,self.config,nil,dt) else world_probe.release() end
    end
    function self.tick(dt)
        if not retired then
            local ok,err=pcall(self.frame,dt)
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
        retired=true;menu.retire();pcall(world_display.release);pcall(world_probe.release);pcall(view.release)
        if backend.close then pcall(backend.close) end
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

