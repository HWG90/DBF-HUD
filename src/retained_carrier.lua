-- Experimental retained image carriers. The compositor owns the target resource.
-- These carriers never destroy a target or retain temporary native vectors/poses.
local M={}
local EMPTY={}
local AXES={1,2,3,5,6,7,9,10,11}
local ORIGIN={'x','y','z'}
local BOUNDS={'x','y','w','h'}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function need(t,k)assert(t and type(t[k])=='function','missing '..k)end
local function need_constructor(t,k)
    local value=t and t[k]
    local meta=type(value)=='table' and getmetatable(value)
    assert(type(value)=='function' or (type(meta)=='table' and type(meta.__call)=='function'),'missing '..k)
end
local ffi
local function native_handle(value,label)
    local kind=type(value)
    assert(kind~='nil' and not(kind=='boolean' and not value),'missing '..label)
    if kind=='cdata' or kind=='userdata' then
        ffi=ffi or require('ffi')
        local ok,address=pcall(function()return tonumber(ffi.cast('uintptr_t',value))end)
        assert(ok and address and address>65536,'invalid '..label..' pointer')
    else
        -- Offline engine doubles are tables; numeric zero and other scalar
        -- lookalikes must never be accepted as native binding owners.
        assert(kind=='table','invalid '..label..' handle')
    end
    return value
end
local function copy_options(c)
    local out={scalars={},vectors={},slots={}}
    local slots=c.retained_texture_slots or {c.retained_texture_slot or 'diffuse_map'}
    assert(type(slots)=='table' and #slots>0,'texture slots required')
    for i,v in ipairs(slots)do assert(type(v)=='string' and v~='','invalid texture slot');out.slots[i]=v end
    for k,v in pairs(c.retained_material_scalars or {})do
        assert(type(k)=='string' and finite(v),'invalid carrier scalar');out.scalars[k]=v
    end
    for k,v in pairs(c.retained_material_vectors or {})do
        assert(type(k)=='string' and type(v)=='table' and #v>=2 and #v<=4,'invalid carrier vector')
        local q={};for i=1,#v do assert(finite(v[i]),'invalid carrier vector value');q[i]=v[i]end;out.vectors[k]=q
    end
    return out
end
local function options_match(a,c)
    local slots=c.retained_texture_slots
    if slots then
        if #a.slots~=#slots then return false end
        for i,v in ipairs(a.slots)do if slots[i]~=v then return false end end
    elseif #a.slots~=1 or a.slots[1]~=(c.retained_texture_slot or 'diffuse_map')then return false end
    local scalars,vectors=c.retained_material_scalars or EMPTY,c.retained_material_vectors or EMPTY
    for k,v in pairs(a.scalars)do if scalars[k]~=v then return false end end
    for k,v in pairs(scalars)do if a.scalars[k]~=v then return false end end
    for k,v in pairs(a.vectors)do
        local q=vectors[k];if type(q)~='table' or #q~=#v then return false end
        for i=1,#v do if q[i]~=v[i]then return false end end
    end
    for k in pairs(vectors)do if not a.vectors[k]then return false end end
    return true
end
function M.new(sr,log,mode)
    assert(mode=='worldgui' or mode=='mesh','unsupported retained carrier mode')
    local A,W,G,U,Mesh,Mat=sr.Application,sr.World,sr.Gui,sr.Unit,sr.Mesh,sr.Material
    log=log or function()end
    local world,gui,unit,material,bitmap,bound,setup,name,alpha_uniform,w,h,last_alpha
    local failed
    local stats={created=0,moved=0,bindings=0,alpha_updates=0,released=0}
    local self={status='not started',mode=mode}
    local function live(candidate)
        if not candidate then return false end
        for _,v in pairs(A.worlds() or {})do if candidate==v then return true end end
        return false
    end
    local function clear()
        world,gui,unit,material,bitmap,bound,setup,name,alpha_uniform,w,h,last_alpha=nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil
    end
    function self.release()
        local ok,err=pcall(function()
            if (gui or unit) and live(world)then
                if gui then W.destroy_gui(world,gui)else W.destroy_unit(world,unit)end
            end
        end)
        if not ok then self.status='carrier cleanup failed: '..tostring(err);return false,self.status end
        if gui or unit then stats.released=stats.released+1 end
        clear();failed=nil;self.status='released';return true
    end
    function self.stats()
        return {created=stats.created,moved=stats.moved,bindings=stats.bindings,
            alpha_updates=stats.alpha_updates,released=stats.released,active=gui~=nil or unit~=nil,mode=mode}
    end
    local function pose(m,at,bounds)
        local x,y=bounds.x+bounds.w/2,bounds.y+bounds.h/2
        local p=sr.Vector3(at.x+(m[1]*x+m[9]*y)/1000,
            at.y+(m[2]*x+m[10]*y)/1000,at.z+(m[3]*x+m[11]*y)/1000)
        local right=sr.Vector3(m[1],m[2],m[3])
        if mode=='mesh' then
            -- plane_primitive's local XY plane spans one unit, centered at zero.
            -- Match archived_mesh's right/up/-forward basis, with exact mm size.
            return sr.Matrix4x4.from_axes(right,sr.Vector3(m[9],m[10],m[11]),sr.Vector3(-m[5],-m[6],-m[7]),p)
        end
        return sr.Matrix4x4.from_axes(right,sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[9],m[10],m[11]),p)
    end
    local function apply_options()
        for _,slot in ipairs(setup.slots)do Mat.set_resource(material,slot,bound);stats.bindings=stats.bindings+1 end
        for k,v in pairs(setup.scalars)do Mat.set_scalar(material,k,v)end
        for k,v in pairs(setup.vectors)do Mat['set_vector'..#v](material,k,sr['Vector'..#v](unpack(v)))end
    end
    local function draw(m,at,bounds,target,c)
        assert(type(m)=='table' and type(at)=='table' and type(bounds)=='table','carrier pose and bounds required')
        for _,i in ipairs(AXES)do assert(finite(m[i]),'invalid carrier axes')end
        for _,k in ipairs(ORIGIN)do assert(finite(at[k]),'invalid carrier origin')end
        for _,k in ipairs(BOUNDS)do assert(finite(bounds[k]),'invalid carrier bounds')end
        assert(bounds.w>0 and bounds.h>0,'invalid carrier extent')
        native_handle(target,'carrier target')
        need(A,'main_world');need(A,'worlds');need(A,'can_get');need_constructor(sr,'Vector3');need(sr.Matrix4x4,'from_axes')
        local alpha=c.retained_alpha==nil and 1 or c.retained_alpha
        assert(finite(alpha) and alpha>=0 and alpha<=1,'invalid carrier alpha')
        local requested=c.retained_material
        if mode=='worldgui' then requested=requested or 'content/ui/shared/material/gui_diffuse_map' end
        assert(type(requested)=='string' and requested~='','explicit mesh material required')
        local main=native_handle(A.main_world(),'main world')
        if not live(main)then error('no live main world')end
        if (gui or unit) and world~=main then assert(self.release())end
        if gui or unit then
            assert(bound==target,'target changed; release carrier first')
            assert(name==requested and alpha_uniform==c.retained_alpha_uniform and options_match(setup,c),'material options changed; release carrier first')
            assert(w==bounds.w and h==bounds.h,'target extent changed; release carrier first')
        else
            assert(A.can_get('material',requested),'carrier material unavailable: '..requested)
            local options=copy_options(c)
            need(Mat,'set_resource')
            if next(options.scalars)or c.retained_alpha_uniform then need(Mat,'set_scalar')end
            for _,v in pairs(options.vectors)do need(Mat,'set_vector'..#v);need_constructor(sr,'Vector'..#v)end
            if mode=='worldgui' then
                need(W,'create_world_gui');need(W,'destroy_gui');need(G,'material');need(G,'bitmap');need(G,'move')
                need_constructor(sr,'Vector2');need_constructor(sr,'Color')
            else
                for _,k in ipairs({'spawn_unit','destroy_unit'})do need(W,k)end
                for _,k in ipairs({'set_material','num_meshes','mesh','set_local_pose','set_local_scale','set_mesh_visibility'})do need(U,k)end
                for _,k in ipairs({'material','num_materials','refresh_instance_hash'})do need(Mesh,k)end
                assert(A.can_get('unit','content/art_shared/meshes/plane_primitive'),'plane unit unavailable')
                assert(alpha==1 or type(c.retained_alpha_uniform)=='string','mesh alpha requires explicit retained_alpha_uniform')
            end
            world,name,bound,setup,w,h,alpha_uniform=main,requested,target,options,bounds.w,bounds.h,c.retained_alpha_uniform
            local tm=pose(m,at,bounds)
            if mode=='worldgui' then
                -- No 'immediate': this single bitmap survives camera movement.
                gui=native_handle(W.create_world_gui(world,tm,1000,1000),'retained world GUI')
                material=native_handle(G.material(gui,name),'carrier GUI material')
                apply_options()
                bitmap=assert(G.bitmap(gui,name,sr.Vector3(-w/2,-h/2,0),sr.Vector2(w,h),sr.Color(math.floor(alpha*255+.5),255,255,255)),'retained bitmap unavailable')
            else
                unit=native_handle(W.spawn_unit(world,'content/art_shared/meshes/plane_primitive'),'carrier unit')
                assert(U.num_meshes(unit)==1,'unexpected carrier mesh count')
                U.set_mesh_visibility(unit,1,false,'shadow_caster')
                U.set_material(unit,'material',name)
                local mesh=native_handle(U.mesh(unit,1),'carrier mesh')
                assert(Mesh.num_materials(mesh)==1,'unexpected carrier material count')
                material=native_handle(Mesh.material(mesh,1),'carrier mesh material')
                apply_options()
                if alpha_uniform then Mat.set_scalar(material,alpha_uniform,alpha)end
                Mesh.refresh_instance_hash(mesh)
                U.set_local_pose(unit,1,tm)
                U.set_local_scale(unit,1,sr.Vector3(w/1000,h/1000,1))
            end
            last_alpha=alpha;stats.created=stats.created+1;stats.moved=stats.moved+1
            self.status=mode..' retained carrier submitted; appearance unverified';return true
        end
        if alpha~=last_alpha then
            if mode=='worldgui' then
                need(G,'update_bitmap')
                G.update_bitmap(gui,bitmap,name,sr.Vector3(-w/2,-h/2,0),sr.Vector2(w,h),sr.Color(math.floor(alpha*255+.5),255,255,255))
            else
                assert(type(alpha_uniform)=='string','mesh alpha requires explicit retained_alpha_uniform')
                Mat.set_scalar(material,alpha_uniform,alpha)
            end
            last_alpha=alpha;stats.alpha_updates=stats.alpha_updates+1
        end
        local tm=pose(m,at,bounds)
        if gui then G.move(gui,tm)
        else
            U.set_local_pose(unit,1,tm)
            -- Setting the complete local pose replaces node scale. Restore the
            -- authored extent after every move, matching the archived carrier.
            U.set_local_scale(unit,1,sr.Vector3(w/1000,h/1000,1))
        end
        stats.moved=stats.moved+1;self.status=mode..' retained carrier submitted; appearance unverified';return true
    end
    function self.draw(m,at,bounds,target,c)
        if failed then return false,failed end
        local ok,result=pcall(draw,m,at,bounds,target,c or EMPTY)
        if ok then return result end
        local reason=tostring(result)
        local released,release_error=self.release()
        failed=reason..(released and '' or ('; '..release_error));self.status=failed
        log('RETAINED_CARRIER '..mode..' stopped: '..failed)
        return false,failed
    end
    return self
end
return M
