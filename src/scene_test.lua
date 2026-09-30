-- Experimental scene-mesh carrier; uses only engine-owned handles.
local M={}
function M.new(sr,log)
    local A,W,U,Mesh=sr.Application,sr.World,sr.Unit,sr.Mesh
    local unit,world,bound;local failed=false;local smooth={}
    local self={}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if w==v then return true end end
        return false
    end
    function self.release()
        if unit and live(world) then W.destroy_unit(world,unit) end
        unit,world,bound=nil,nil,nil;smooth={}
    end
    function self.draw(p,c,target,dt)
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
                log('SCENE plane spawn begin')
                unit=assert(W.spawn_unit(world,name))
                assert(U.num_meshes(unit)==1,'unexpected mesh count')
                local mesh=U.mesh(unit,1)
                assert(Mesh.num_materials(mesh)==1,'unexpected material count')
                local material=Mesh.material(mesh,1)
                local ffi=require('ffi')
                assert(tonumber(ffi.cast('uintptr_t',material))>=65536,'invalid scene material')
                assert(tonumber(ffi.cast('uintptr_t',target))>=65536,'invalid panel texture')
                log('SCENE verified material texture bind begin')
                sr.Material.set_resource(material,'color_map',target)
                sr.Material.set_resource(material,'emissive_map',target)
                sr.Material.set_scalar(material,'use_color_map',1)
                sr.Material.set_scalar(material,'use_emissive_map',1)
                sr.Material.set_scalar(material,'emissive_intensity',1)
                sr.Material.set_vector3(material,'base_color',sr.Vector3(1,1,1))
                sr.Material.set_vector3(material,'emissive',sr.Vector3(1,1,1))
                bound=target
                log('SCENE plane texture bound')
            end
            assert(bound==target,'render target changed without scene retirement')
            local m=p.matrix
            local x,y,z=c.mount_x,c.mount_y,c.mount_z+0.2
            local px=p.x+m[1]*x+m[5]*y+m[9]*z
            local py=p.y+m[2]*x+m[6]*y+m[10]*z
            local pz=p.z+m[3]*x+m[7]*y+m[11]*z
            m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
            local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),sr.Vector3(-m[9],-m[10],-m[11]),sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[13],m[14],m[15]))
            U.set_local_pose(unit,1,pose)
            U.set_local_scale(unit,1,sr.Vector3(0.24,0.24,0.12))
        end)
        if not ok then failed=true;log('SCENE stopped '..tostring(err));self.release() end
    end
    return self
end
return M
