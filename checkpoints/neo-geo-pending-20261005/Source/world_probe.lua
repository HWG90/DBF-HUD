-- Minimal world-space GUI experiment; only engine-returned world/GUI handles.
local M={}
function M.new(sr,log,direct)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local folded;local smooth={};local depth_fill;local blur;local gui,world;local failed=false;local first=true
    local self={status='not started'}
    local function identity(handle)
        -- LuaJIT %p bypasses the engine's generic '[Material]' __tostring.
        -- This identifies Lua userdata storage, not necessarily its native object.
        local ok,address=pcall(string.format,'%p',handle)
        local native_ok,native=pcall(function()return string.format('0x%X',tonumber(require('ffi').cast('uintptr_t',handle)))end)
        return tostring(handle)..(ok and (' lua_address='..address) or '')..(native_ok and (' native_address='..native) or '')
    end
    local function live(w)
        if not w then return false end
        for _,v in pairs(A.worlds() or {})do if v==w then return true end end
        return false
    end
    function self.release()
        if folded then folded.release();folded=nil end
        if gui and live(world) then
            log('WORLD_GUI destroy begin');W.destroy_gui(world,gui);log('WORLD_GUI destroy complete')
        end
        gui,world=nil,nil;blur=nil;depth_fill=nil;smooth={}
    end
    local function draw(p,c,commands,dt)
        if (not c.world_probe and not commands) or not p then self.release();return end
        if not W.create_world_gui or not G.move or not sr.Matrix4x4 or not sr.Matrix4x4.from_axes then
            self.status='world GUI functions missing';return
        end
        if gui and not live(world) then gui,world=nil,nil;smooth={} end
        local main=A.main_world()
        if not live(main) then self.status='no live main world';return end
        if gui and main~=world then self.release() end
        local fold_commands
        if folded then folded.release();folded=nil end
        local m=p.matrix
        local x,y,z=HUD.scene_test.mount(p,c)
        local px=p.x+m[1]*x+m[5]*y+m[9]*z
        local py=p.y+m[2]*x+m[6]*y+m[10]*z
        local pz=p.z+m[3]*x+m[7]*y+m[11]*z
        if p.gui_pose then px,py,pz=p.x,p.y,p.z end
        if c.keep_hud_upright and not p.gui_pose then m=HUD.pose_motion.upright(m) end
        m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(c.placement_mode)..':'..tostring(p.id)..':'..tostring(p.candidate),dt,c)
        px,py,pz=m[13],m[14],m[15]
        if first then log('WORLD_GUI matrix begin') end
        local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),
            sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(px,py,pz))
        if not gui then
            world=main;log('WORLD_GUI create begin')
            gui=assert(W.create_world_gui(world,pose,1000,1000,'immediate'),'world GUI returned nil')
            log('WORLD_GUI create complete')
            local name='mods/dbf_hud/materials/depth_fill'
            local control='mods/dbf_hud/materials/depth_state_test_loader_control'
            if not direct and A.can_get and A.can_get('material',control) then depth_fill=control
            elseif not direct and A.can_get and A.can_get('material',name) then depth_fill=name
            elseif not direct and A.can_get and A.can_get('material','mods/astra_ammo/materials/depth_fill') then
                depth_fill='mods/astra_ammo/materials/depth_fill' -- Previously deployed optional material.
            end
            log('WORLD_GUI depth material '..(direct and 'not requested' or (depth_fill and 'available' or 'missing; install depth material addon')))
            -- One-time observation only: resolve the same material used by bitmap.
            -- Keep no native material handles across frames or GUI destruction.
            if c.debug_logging then
            log('WORLD_GUI instance '..identity(gui)..' world '..identity(world))
            if type(G.material)=='function' and A.can_get then
                for _,material_name in ipairs({'content/ui/shared/material/gui_fill',
                    depth_fill or 'mods/dbf_hud/materials/depth_fill','mods/dbf_hud/materials/depth_blur'}) do
                    if A.can_get('material',material_name) then
                        local ok,handle=pcall(G.material,gui,material_name)
                        log('WORLD_GUI material instance '..material_name..' '..(ok and identity(handle) or 'lookup failed'))
                    end
                end
            else log('WORLD_GUI material inspection unavailable') end
            end
        else
            if first then log('WORLD_GUI move begin') end
            G.move(gui,pose)
        end
        if commands then
            -- Native screen frost renders white on the verified world-GUI path.
            -- Keep the user's frost preference for screen modes; omit it here.
            -- Bitmap takes the material as a required argument. This avoids relying
            -- on the game's optional rect material overload matching upstream.
            local function solid(x,y,w,h,layer,color)
                if depth_fill then
                    G.bitmap(gui,depth_fill,sr.Vector3(x,y,layer),sr.Vector2(w,h),color)
                else G.rect(gui,sr.Vector3(x,y,layer),sr.Vector2(w,h),color) end
            end
            for _,v in ipairs(commands) do
                local color=sr.Color(math.floor(v.a*255+.5),v.c[1],v.c[2],v.c[3])
                if v.type=='panel' then
                    -- Match the known-working hybrid background; leave experimental
                    -- depth fill on foreground primitives only during this comparison.
                    solid(v.x,v.y,v.w,v.h,1,color)
                elseif v.type=='rect' then
                    solid(v.x,v.y,v.w,v.h,v.scanline_layer and 2.5 or (v.fuel_marker_piece and 3 or 2),color)
                else
                    local resource,material=HUD.native_font.resolve(sr,v.font,c.occlusion_mode~='gui')
                    if resource and not v.fuel_endpoint then
                        for _,part in ipairs(HUD.font.numeric_parts(v)) do
                            local ink=part.c or v.c
                        local part_color=sr.Color(math.floor(v.a*part.alpha*255+.5),ink[1],ink[2],ink[3])
                            G.text(gui,part.text,resource,v.size,material,sr.Vector3(v.x+part.dx,v.y,3),part_color)
                        end
                    end

                end
            end
            if fold_commands and #fold_commands>0 then
                folded=folded or M.new(sr,log,direct)
                local child_panel=fold_commands[1];local edge=child_panel.y+child_panel.h
                local child={}
                for _,v in ipairs(fold_commands) do
                    local copy={};for k,value in pairs(v) do copy[k]=value end
                    copy.y=v.y-edge
                    if copy.type=='text' then
                        local a,b,e,f=HUD.font.measure(copy.text,copy.size,copy.font,true)
                        copy.x=child_panel.x+child_panel.w/2-(a+e)/2
                        copy.y=-child_panel.h/2-(b+f)/2
                    end
                    child[#child+1]=copy
                end
                local hinge=commands[1].y-2
                local upright=HUD.pose_motion.forward_tilt(m,-math.pi/2)
                local child_pose={matrix=upright,x=px+m[9]*hinge/1000,y=py+m[10]*hinge/1000,z=pz+m[11]*hinge/1000,id=p.id,candidate='folded reserve',gui_pose=true}
                folded.draw(child_pose,c,child,dt)
            end
            if first then log('WORLD_GUI panel submitted: '..(depth_fill and 'explicit material bitmap path' or 'default rectangle path'));first=false end
            self.status='world panel; frost unavailable on this rendering path';return true
        end
        if first then log('WORLD_GUI rect begin') end
        G.rect(gui,sr.Vector3(0,0,0),sr.Vector2(240,140),sr.Color(255,45,52,55))
        G.rect(gui,sr.Vector3(0,0,1),sr.Vector2(12,140),sr.Color(255,231,200,92))
        if first then log('WORLD_GUI rect complete');first=false end
        self.status='world rectangle submitted'
    end
    function self.draw(p,c,commands,dt)
        if failed then return end
        local ok,err=pcall(draw,p,c,commands,dt)
        if not ok then
            failed=true;self.status=tostring(err);log('WORLD_GUI Lua failure: '..self.status)
            pcall(self.release)
        end
        return ok and err==true
    end
    return self
end
return M

