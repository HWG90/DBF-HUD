-- Geometry and lifecycle contracts; native appearance still needs live proof.
local Carrier=dofile('src/retained_carrier.lua')
local Scene=dofile('src/screen_scene.lua')
local function close(a,b)assert(math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b))end
local function fixture()
    local state={main={},worlds={},created=0,spawned=0,destroyed=0,moved=0,bitmaps=0,updated=0,bindings=0,scales=0,refreshes=0,materials={},targets={}}
    state.worlds[1]=state.main
    local function vector(...)return {...}end
    local function alive(w)for _,v in ipairs(state.worlds)do if v==w then return true end end end
    local sr={Vector2=vector,Vector3=vector,Vector4=vector,Color=vector,
        Matrix4x4={from_axes=function(r,f,u,p)return {right=r,forward=f,up=u,at=p}end},
        Application={main_world=function()return state.main end,worlds=function()return state.worlds end,
            can_get=function(kind,name)return state.unavailable~=name end},
        World={create_world_gui=function(w,tm,x,y,...)
                assert(alive(w)and x==1000 and y==1000 and select('#',...)==0,'GUI must be retained and authored in millimeters')
                state.created=state.created+1;local g={pose=tm,world=w};state.gui=g;return g
            end,destroy_gui=function(w,g)assert(alive(w)and not g.dead);g.dead=true;state.destroyed=state.destroyed+1 end,
            spawn_unit=function(w,name)assert(alive(w)and name=='content/art_shared/meshes/plane_primitive');state.spawned=state.spawned+1;local u={world=w,mesh={}};state.unit=u;return u end,
            destroy_unit=function(w,u)assert(alive(w)and not u.dead);u.dead=true;state.destroyed=state.destroyed+1 end},
        Gui={material=function(g,name)assert(not g.dead);local mat={owner=g,name=name};state.materials[#state.materials+1]=mat;return mat end,
            bitmap=function(g,name,pos,size,ink)assert(not g.dead);state.bitmaps=state.bitmaps+1;g.bitmap={name=name,pos=pos,size=size,ink=ink};return state.bitmaps end,
            update_bitmap=function(g,id,name,pos,size,ink)assert(not g.dead);state.updated=state.updated+1;g.bitmap={name=name,pos=pos,size=size,ink=ink}end,
            move=function(g,tm)assert(not g.dead);g.pose=tm;state.moved=state.moved+1 end},
        Unit={num_meshes=function()return 1 end,mesh=function(u,i)assert(i==1);return u.mesh end,
            set_material=function(u,slot,name)assert(slot=='material');u.mesh.material={owner=u,name=name};state.materials[#state.materials+1]=u.mesh.material;return 'not the material handle' end,
            set_local_pose=function(u,i,tm)assert(i==1 and not u.dead);u.pose=tm;u.scale={1,1,1};state.moved=state.moved+1 end,
            set_local_scale=function(u,i,v)assert(i==1 and not u.dead);u.scale=v;state.scales=state.scales+1 end,
            set_mesh_visibility=function(u,i,value,filter)assert(i==1 and value==false and filter=='shadow_caster');u.no_shadow=true end},
        Mesh={num_materials=function()return 1 end,material=function(mesh,i)assert(i==1);return mesh.material end,
            refresh_instance_hash=function(mesh)assert(mesh.material);state.refreshes=state.refreshes+1 end},
        Material={set_resource=function(mat,k,v)assert(type(mat)=='table');state.bindings=state.bindings+1;state.targets[v]=true;mat[k]=v end,
            set_scalar=function(mat,k,v)mat[k]=v end,set_vector2=function(mat,k,v)mat[k]=v end,
            set_vector3=function(mat,k,v)mat[k]=v end,set_vector4=function(mat,k,v)mat[k]=v end},
        Renderer={destroy_resource=function()error('carrier must not destroy targets')end}}
    return sr,state
end
local m={.6,.8,0,0,-.8,.6,0,0,0,0,1,0,0,0,0,1}
local origin=Scene.spatial_origin(m,{x=1.5,y=2.4,z=-.8},17)
local b={x=-83,y=-174,w=244,h=91}
local function verify_corners(state,mode,bounds,at)
    local obj=mode=='worldgui'and state.gui or state.unit
    local tm=obj.pose
    for _,p in ipairs({{0,0},{1,0},{0,1},{1,1}})do
        local x,y
        if mode=='worldgui' then
            x=(obj.bitmap.pos[1]+p[1]*obj.bitmap.size[1])/1000
            y=(obj.bitmap.pos[2]+p[2]*obj.bitmap.size[2])/1000
        else x=(p[1]-.5)*obj.scale[1];y=(p[2]-.5)*obj.scale[2]end
        local expected={Scene.point(m,at,bounds.x+bounds.w*p[1],bounds.y+bounds.h*p[2])}
        local up=mode=='worldgui'and tm.up or tm.forward
        for i=1,3 do close(tm.at[i]+tm.right[i]*x+up[i]*y,expected[i])end
    end
end
for _,mode in ipairs({'worldgui','mesh'})do
    local sr,s=fixture();local target={};local c={retained_material=mode=='mesh'and 'test/mesh_rgba' or nil}
    if mode=='mesh' then
        c.retained_texture_slots={'color_map','emissive_map'}
        c.retained_material_scalars={use_color_map=1,opacity=1}
        c.retained_material_vectors={base_color={0,0,0},emissive={1,1,1}}
    end
    local renderer=Carrier.new(sr,nil,mode)
    assert(renderer.draw(m,origin,b,target,c),renderer.status)
    local bindings=s.bindings
    verify_corners(s,mode,b,origin)
    for frame=1,120 do
        local at={x=origin.x+frame*.01,y=origin.y-frame*.004,z=origin.z+frame*.003}
        assert(renderer.draw(m,at,b,target,c),renderer.status)
        verify_corners(s,mode,b,at)
    end
    assert(s.bindings==bindings and s.destroyed==0,'movement rebound resources or destroyed geometry')
    local stats=renderer.stats();assert(stats.created==1 and stats.moved==121 and stats.active)
    if mode=='worldgui' then assert(s.created==1 and s.bitmaps==1 and s.moved==120 and s.updated==0)
    else assert(s.spawned==1 and s.scales==121 and s.refreshes==1 and s.moved==121 and s.unit.no_shadow)end
    -- Changing the authored origin inside the same surface moves the whole image.
    local shifted={x=b.x+6,y=b.y-9,w=b.w,h=b.h}
    assert(renderer.draw(m,origin,shifted,target,c));verify_corners(s,mode,shifted,origin)
    local ok,err=renderer.draw(m,origin,b,{},c)
    assert(not ok and err:find('target changed',1,true),'different target was silently rebound')
    assert(s.bindings==bindings and s.destroyed==1 and s.targets[target])
    assert(not renderer.draw(m,origin,b,target,c),'failed carrier silently retried')
    assert(renderer.release());assert(renderer.draw(m,origin,b,target,c));assert(renderer.release());assert(renderer.release())
    assert(s.destroyed==2,'release was not idempotent')
end
do
    local sr,s=fixture();local target={};local c={};local renderer=Carrier.new(sr,nil,'worldgui')
    assert(renderer.draw(m,origin,b,target,c));c.retained_alpha=.25
    assert(renderer.draw(m,origin,b,target,c));assert(s.updated==1 and s.gui.bitmap.ink[1]==64 and s.bitmaps==1 and s.bindings==1)
    assert(renderer.draw(m,origin,b,target,c));assert(s.updated==1,'unchanged alpha updated the primitive')
    local old=s.gui;local replacement={};s.worlds={replacement};s.main=replacement
    assert(renderer.draw(m,origin,b,target,c));assert(s.created==2 and s.destroyed==0 and not old.dead,'dead-world GUI was destroyed through invalid world')
    assert(renderer.release());assert(s.destroyed==1)
end
do
    local sr,s=fixture();local c={retained_material='test/mesh_rgba',retained_alpha=.4,retained_alpha_uniform='opacity'}
    local renderer=Carrier.new(sr,nil,'mesh');local target={}
    assert(renderer.draw(m,origin,b,target,c));assert(s.unit.mesh.material.opacity==.4)
    c.retained_alpha=.7;assert(renderer.draw(m,origin,b,target,c));assert(s.unit.mesh.material.opacity==.7 and s.bindings==1)
    assert(renderer.release());c.retained_alpha_uniform=nil
    local ok,err=renderer.draw(m,origin,b,target,c);assert(not ok and err:find('mesh alpha requires',1,true)and s.spawned==1)
end
do
    local sr,s=fixture();local renderer=Carrier.new(sr,nil,'mesh')
    local ok,err=renderer.draw(m,origin,b,{},{});assert(not ok and err:find('explicit mesh material',1,true)and s.spawned==0)
    renderer.release();s.unavailable='test/mesh_rgba'
    ok,err=renderer.draw(m,origin,b,{},{retained_material=s.unavailable});assert(not ok and err:find('material unavailable',1,true)and s.spawned==0)
    renderer.release();s.unavailable=nil;sr.Mesh.refresh_instance_hash=nil
    ok,err=renderer.draw(m,origin,b,{},{retained_material='test/mesh_rgba'});assert(not ok and err:find('missing refresh_instance_hash',1,true)and s.spawned==0)
end
do
    local sr,s=fixture();local target={};local renderer=Carrier.new(sr,nil,'worldgui')
    local c={retained_material_scalars={opacity=1}}
    assert(renderer.draw(m,origin,b,target,c));c.retained_material_scalars.opacity=.3
    local ok,err=renderer.draw(m,origin,b,target,c)
    assert(not ok and err:find('material options changed',1,true)and s.destroyed==1)
    renderer.release();sr.Material.set_resource=function()error('native bind failed')end
    ok,err=renderer.draw(m,origin,b,target,{})
    assert(not ok and err:find('native bind failed',1,true)and s.destroyed==2,'partial creation leaked GUI')
end
do
    local sr,s=fixture();local renderer=Carrier.new(sr,nil,'worldgui');local target={}
    assert(renderer.draw(m,origin,b,target,{}))
    local destroy=sr.World.destroy_gui;sr.World.destroy_gui=function()error('native cleanup blocked')end
    local ok,err=renderer.release();assert(not ok and err:find('cleanup blocked',1,true)and renderer.stats().active,'failed cleanup lost ownership')
    sr.World.destroy_gui=destroy;assert(renderer.release());assert(s.destroyed==1)
    local invalid={x=0/0,y=0,w=100,h=100};ok,err=renderer.draw(m,origin,invalid,target,{})
    assert(not ok and err:find('invalid carrier bounds',1,true)and s.created==1)
end
do
    -- The live engine exposes vector/color namespaces as callable tables.
    local function callable(fn)return setmetatable({},{__call=function(_,...)return fn(...)end})end
    for _,mode in ipairs({'worldgui','mesh'})do
        local sr,s=fixture()
        for _,name in ipairs({'Vector2','Vector3','Vector4','Color'})do sr[name]=callable(sr[name])end
        local c={retained_material=mode=='mesh'and'test/mesh_rgba'or nil,
            retained_material_vectors={pair={.1,.2},triple={.3,.4,.5},quad={.6,.7,.8,.9}}}
        local target={};local renderer=Carrier.new(sr,nil,mode)
        assert(renderer.draw(m,origin,b,target,c),renderer.status)
        assert(renderer.draw(m,origin,b,target,c),renderer.status)
        verify_corners(s,mode,b,origin)
        local mat=s.materials[1]
        close(mat.pair[2],.2);close(mat.triple[3],.5);close(mat.quad[4],.9)
        assert(renderer.release())
    end
    for _,name in ipairs({'Vector2','Vector3','Vector4','Color'})do
        local sr,s=fixture();sr[name]={}
        local renderer=Carrier.new(sr,nil,'worldgui')
        local ok,err=renderer.draw(m,origin,b,{},{retained_material_vectors={quad={1,1,1,1}}})
        assert(not ok and err:find('missing '..name,1,true)and s.created==0,'non-callable constructor accepted')
    end
    local sr,s=fixture();sr.Application.main_world=callable(sr.Application.main_world)
    local renderer=Carrier.new(sr,nil,'worldgui');local ok,err=renderer.draw(m,origin,b,{},{})
    assert(not ok and err:find('missing main_world',1,true)and s.created==0,'ordinary API preflight accepted callable table')
end
do
    local ffi=require('ffi')
    local null=ffi.cast('void*',0)
    for _,address in ipairs({0,1,65536})do
        local sr,s=fixture();local renderer=Carrier.new(sr,nil,'worldgui')
        local ok,err=renderer.draw(m,origin,b,ffi.cast('void*',address),{})
        assert(not ok and err:find('invalid carrier target pointer',1,true)and s.bindings==0 and s.created==0,'invalid native target reached binding: '..address..' '..tostring(err))
    end
    local sr,s=fixture();local renderer=Carrier.new(sr,nil,'worldgui');local target=ffi.cast('void*',65537)
    assert(renderer.draw(m,origin,b,target,{}),renderer.status);assert(s.bindings==1);renderer.release()
    for _,mode in ipairs({'worldgui','mesh'})do
        sr,s=fixture();renderer=Carrier.new(sr,nil,mode)
        local c={retained_material=mode=='mesh'and'test/mesh_rgba'or nil}
        if mode=='worldgui' then sr.Gui.material=function()return null end
        else sr.Mesh.material=function()return null end end
        local ok,err=renderer.draw(m,origin,b,{},c)
        assert(not ok and err:find('material pointer',1,true)and s.bindings==0 and s.destroyed==1,'null material was bound or leaked owner')
    end
    sr,s=fixture();sr.World.spawn_unit=function()return null end;renderer=Carrier.new(sr,nil,'mesh')
    local mesh_calls=0;sr.Unit.set_material=function()mesh_calls=mesh_calls+1 end
    local ok,err=renderer.draw(m,origin,b,{},{retained_material='test/mesh_rgba'})
    assert(not ok and err:find('invalid carrier unit pointer',1,true)and mesh_calls==0 and s.bindings==0 and s.destroyed==0)
    sr,s=fixture();sr.Unit.mesh=function()return null end;renderer=Carrier.new(sr,nil,'mesh')
    ok,err=renderer.draw(m,origin,b,{},{retained_material='test/mesh_rgba'})
    assert(not ok and err:find('invalid carrier mesh pointer',1,true)and s.bindings==0 and s.destroyed==1)
    sr,s=fixture();sr.World.create_world_gui=function()return null end;renderer=Carrier.new(sr,nil,'worldgui')
    ok,err=renderer.draw(m,origin,b,{},{})
    assert(not ok and err:find('invalid retained world GUI pointer',1,true)and s.bindings==0 and s.destroyed==0)
    sr,s=fixture();sr.Application.main_world=function()return null end;renderer=Carrier.new(sr,nil,'worldgui')
    ok,err=renderer.draw(m,origin,b,{},{})
    assert(not ok and err:find('invalid main world pointer',1,true)and s.created==0)
end
print('PASS retained carriers: geometry, retention, alpha, callable constructors, native handle guards and owned lifecycle')
