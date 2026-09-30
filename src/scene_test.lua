-- Experimental scene-mesh carrier; uses only engine-owned handles.
local M={}
function M.mount(p,c)
    if p.first_person then return c.fp_mount_x,c.fp_mount_y,c.fp_mount_z+.2 end
    if p.left_shoulder then return c.left_mount_x,c.left_mount_y,c.left_mount_z+.2 end
    return c.mount_x,c.mount_y,c.mount_z+.2
end
function M.new(sr,log,side)
    if not side then
        local front,back=M.new(sr,log,1),M.new(sr,log,-1)
        local overlay=HUD.world_probe.new(sr,log,true)
        local depth_overlay=HUD.world_probe.new(sr,log,false)
        local active_mode
        return {
            draw=function(p,c,target,dt,aspect,commands)
                local mode=c.occlusion_mode or (c.hud_occlusion~=false and 'mesh' or 'gui')
                local occluded=mode=='mesh'
                if active_mode~=mode then
                    front.release();back.release();overlay.release();depth_overlay.release()
                    active_mode=mode
                    log('HUD occlusion mode '..mode)
                end
                if occluded then front.draw(p,c,target,dt,aspect);back.draw(p,c,target,dt,aspect)
                else
                    if not commands then overlay.release();depth_overlay.release();return end
                    local f=commands[1];local scale=240/f.w;local centered={}
                    for _,command in ipairs(commands) do
                        local v={};for k,value in pairs(command) do v[k]=value end
                        v.x=(v.x-f.x-f.w/2)*scale;v.y=(v.y-f.y-f.h/2)*scale
                        if v.w then v.w=v.w*scale end
                        if v.h then v.h=v.h*scale end
                        if v.size then v.size=v.size*scale end
                        centered[#centered+1]=v
                    end
                    if mode=='gui_depth' then depth_overlay.draw(p,c,centered,dt) else overlay.draw(p,c,centered,dt) end
                end
            end,
            release=function() overlay.release();depth_overlay.release();front.release();back.release();active_mode=nil end
        }
    end
    local A,W,U,Mesh=sr.Application,sr.World,sr.Unit,sr.Mesh
    local unit,world,bound,scene_material,last_emission;local failed=false;local smooth={}
    local self={}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if w==v then return true end end
        return false
    end
    function self.release()
        if unit and live(world) then W.destroy_unit(world,unit) end
        unit,world,bound,scene_material,last_emission=nil,nil,nil,nil,nil;smooth={}
    end
    function self.draw(p,c,target,dt,aspect)
        if failed then return end
        if not p or not target then if unit then self.release() end;return end
        local ok,err=pcall(function()
            local main=A.main_world()
            if not live(main) then return end
            if unit and (world~=main or not live(world)) then self.release() end
            if not unit then
                local name='content/art_shared/meshes/plane_primitive'
                assert(A.can_get('unit',name),'plane unit unavailable')
                for _,fn in ipairs({'set_local_pose','set_local_scale','num_meshes','mesh'}) do assert(type(U[fn])=='function','missing Unit.'..fn) end
                assert(Mesh and type(Mesh.num_materials)=='function' and type(Mesh.material)=='function','mesh material API unavailable')
                world=main
                for _,candidate in ipairs({'mods/dbf_hud/materials/fullbright_depth_image','core/appkit/materials/loading_screen','content/effects/base_shaders/mesh_particle_simple','content/env_ship/hangar/props/materials/store_screen_large','content/fac_helldivers/equipment/primary_weapons/assault_rifle_nacho/materials/weapon_screen'}) do
                    log('SCENE fullbright candidate '..candidate..' loaded='..tostring(A.can_get('material',candidate)))
                end
                log('SCENE plane spawn begin')
                unit=assert(W.spawn_unit(world,name))
                assert(U.num_meshes(unit)==1,'unexpected mesh count')
                if type(U.set_mesh_visibility)=='function' then
                    log('SCENE shadow-only visibility begin side='..side)
                    U.set_mesh_visibility(unit,1,false,'shadow_caster')
                    log('SCENE shadow-only visibility returned side='..side)
                end
                local mesh=U.mesh(unit,1)
                assert(Mesh.num_materials(mesh)==1,'unexpected material count')
                local transparent='content/art_shared/materials/placeholder_red_transparent'
                local alpha=type(U.set_material)=='function' and A.can_get('material',transparent)
                if alpha then
                    -- Unit asset declares the named slot 'material' (thin hash eac0b497).
                    log('SCENE transparent material assignment begin')
                    U.set_material(unit,'material',transparent)
                end
                local material=Mesh.material(mesh,1)
                local ffi=require('ffi')
                assert(tonumber(ffi.cast('uintptr_t',material))>=65536,'invalid scene material')
                assert(tonumber(ffi.cast('uintptr_t',target))>=65536,'invalid panel texture')
                log('SCENE verified material texture bind begin')
                sr.Material.set_resource(material,'color_map',target)
                sr.Material.set_resource(material,'emissive_map',target)
                sr.Material.set_scalar(material,'use_color_map',1)
                sr.Material.set_scalar(material,'use_emissive_map',1)
                if side==-1 then
                    sr.Material.set_vector2(material,'uv_scale',sr.Vector2(-1,1))
                    sr.Material.set_vector2(material,'uv_offset',sr.Vector2(1,0))
                end
                scene_material=material
                sr.Material.set_vector3(material,'base_color',sr.Vector3(0,0,0))
                -- Diagnostic: black metallic base removes the dielectric reflection term.
                sr.Material.set_scalar(material,'use_metallic_map',0)
                sr.Material.set_scalar(material,'metallic',1)
                sr.Material.set_scalar(material,'use_roughness_map',0)
                sr.Material.set_scalar(material,'roughness',1)
                sr.Material.set_vector3(material,'emissive',sr.Vector3(1,1,1))
                if alpha then
                    sr.Material.set_scalar(material,'opacity',1)
                    sr.Material.set_scalar(material,'use_opacity_map',1)
                    log('SCENE transparent material bound; alpha pixels unverified')
                end
                bound=target
                log('SCENE plane texture bound')
            end
            assert(bound==target,'render target changed without scene retirement')
            if last_emission~=c.emissive_intensity then
                sr.Material.set_scalar(scene_material,'emissive_intensity',c.emissive_intensity)
                last_emission=c.emissive_intensity
            end
            local m=p.matrix
            local x,y,z=M.mount(p,c)
            local px=p.x+m[1]*x+m[5]*y+m[9]*z
            local py=p.y+m[2]*x+m[6]*y+m[10]*z
            local pz=p.z+m[3]*x+m[7]*y+m[11]*z
            m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
            local pose=sr.Matrix4x4.from_axes(sr.Vector3(side*m[1],side*m[2],side*m[3]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(-side*m[5],-side*m[6],-side*m[7]),sr.Vector3(m[13],m[14],m[15]))
            U.set_local_pose(unit,1,pose)
            U.set_local_scale(unit,1,sr.Vector3(0.24,0.24/math.max(0.25,math.min(8,aspect or 2)),0.24))
        end)
        if not ok then failed=true;log('SCENE stopped '..tostring(err));self.release() end
    end
    return self
end
function M.fullbright(sr,log)
    local gui,world,bound;local stopped=false;local smooth={}
    local A,W,G=sr.Application,sr.World,sr.Gui
    local self={}
    function self.release()
        if gui then
            for _,w in pairs(A.worlds() or {}) do if w==world then W.destroy_gui(world,gui);break end end
        end
        gui,world,bound=nil,nil,nil;smooth={}
    end
    function self.draw(p,c,target,dt,aspect)
        if stopped or not G or not W.create_world_gui then return end
        if not p or not target then self.release();return end
        local ok,err=pcall(function()
            local main=A.main_world()
            if gui and world~=main then self.release() end
            local name='mods/dbf_hud/materials/fullbright_depth_image'
            if not A.can_get('material',name) then return end
            local x,y,z=M.mount(p,c)
            local m=p.matrix
            local px=p.x+m[1]*x+m[5]*y+m[9]*z
            local py=p.y+m[2]*x+m[6]*y+m[10]*z
            local pz=p.z+m[3]*x+m[7]*y+m[11]*z
            m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
            local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(m[13],m[14],m[15]))
            if not gui then
                world=main
                log('FULLBRIGHT main-world GUI create begin')
                gui=assert(W.create_world_gui(world,pose,1000,1000,'immediate'))
                local material=G.material(gui,name)
                local ffi=require('ffi')
                assert(tonumber(ffi.cast('uintptr_t',material))>=65536,'null fullbright material')
                assert(tonumber(ffi.cast('uintptr_t',target))>=65536,'null fullbright target')
                sr.Material.set_resource(material,'diffuse_map',target)
                bound=target
                log('FULLBRIGHT image material bound')
            else G.move(gui,pose) end
            assert(bound==target,'fullbright target changed without cleanup')
            G.bitmap(gui,name,sr.Vector3(-120,-120/(aspect or 2),0),sr.Vector2(240,240/(aspect or 2)),sr.Color(255,255,255,255))
        end)
        if not ok then stopped=true;log('FULLBRIGHT stopped '..tostring(err));pcall(self.release) end
    end
    return self
end
return M
