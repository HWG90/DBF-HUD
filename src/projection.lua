-- Diagnostic world-to-screen projection. Reads data only; no engine calls.
-- Initial scope: perspective camera with identity local camera offset.
local M={}
local function unhex(s)return (s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
function M.project(m,x,y,z,fov,aspect,near)
    assert(fov>.05 and fov<3.1 and aspect>.1 and aspect<10,'projection dimensions')
    for i=1,16 do assert(type(m[i])=='number' and m[i]==m[i] and math.abs(m[i])<1e7,'camera matrix finite') end
    for _,k in ipairs({1,5,9}) do
        local n=m[k]^2+m[k+1]^2+m[k+2]^2;assert(math.abs(n-1)<.01,'camera axis scale')
    end
    for _,p in ipairs({{1,5},{1,9},{5,9}}) do
        local a,b=p[1],p[2];assert(math.abs(m[a]*m[b]+m[a+1]*m[b+1]+m[a+2]*m[b+2])<.01,'camera axes')
    end
    assert(math.abs(m[4])+math.abs(m[8])+math.abs(m[12])+math.abs(m[16]-1)<1e-5,'camera affine')
    local dx,dy,dz=x-m[13],y-m[14],z-m[15]
    local right=dx*m[1]+dy*m[2]+dz*m[3]
    local depth=dx*m[5]+dy*m[6]+dz*m[7]
    local up=dx*m[9]+dy*m[10]+dz*m[11]
    if depth<=math.max(near,.05) then return nil,'behind camera or near plane' end
    local t=math.tan(fov*.5)
    local nx,ny=.5+.5*right/(depth*t*aspect),.5+.5*up/(depth*t)
    if nx~=nx or ny~=ny or nx<0 or nx>1 or ny<0 or ny>1 then return nil,'outside viewport' end
    return {x=nx,y=ny,depth=depth},'projected weapon root'
end
-- Screen-relative seed only; this does not establish model clearance.
function M.auto_mount(camera,p,fov,aspect,near)
    local dx,dy,dz=p.x-camera[13],p.y-camera[14],p.z-camera[15]
    local depth=dx*camera[5]+dy*camera[6]+dz*camera[7]
    depth=math.max(near+.15,math.max(.55,depth))
    local nx=(p.first_person or p.left_shoulder) and .42 or .58
    local right=(nx-.5)*2*depth*math.tan(fov*.5)*aspect
    local up=-.04*depth*math.tan(fov*.5)
    local x=camera[13]+camera[5]*depth+camera[1]*right+camera[9]*up-p.x
    local y=camera[14]+camera[6]*depth+camera[2]*right+camera[10]*up-p.y
    local z=camera[15]+camera[7]*depth+camera[3]*right+camera[11]*up-p.z
    local m=p.matrix
    return {x=x*m[1]+y*m[2]+z*m[3],y=x*m[5]+y*m[6]+z*m[7],z=x*m[9]+y*m[10]+z*m[11]}
end
function M.left_shoulder(previous,lateral,first_person)
    if first_person or not lateral then return false end
    return lateral>(previous and 0.4 or 0.7)
end
function M.first_person(previous,distance,fov)
    if not distance or not fov then return false end
    if previous then return distance<0.95 and fov<1.45 end
    return distance<0.75 and fov<1.3
end
function M.new(backend)
    local r=HUD.memory.new(backend);local self={status='not sampled'}
    function self.snapshot(base,pose,aspect)
        r.reset()
        local api=r.p(base+0x3326308);local camera_api=r.p(api+0x20)
        local getter=r.p(camera_api+0xf8)
        assert(r.read(getter,10)==unhex('48895c2408574883ec60'),'unknown projection wrapper')
        local call=r.read(getter+0x132,5);assert(call:byte()==0xe8,'unknown projection call')
        local impl=getter+0x137+r.i(call,1)
        assert(r.read(impl,16)==unhex('488bc448895808488968104889701857'),'unknown projection implementation')
        assert(r.read(impl+0x62,20)==unhex('488b471848c1e206418be948035028e80a951500'),'unknown camera scene layout')
        local state=r.p(base+0x346d560);local camera=r.p(state);local b=r.read(camera,160)
        local scene=r.p(camera+0x18);local index=r.u(b,0x20)
        assert(index<4096,'camera node index')
        assert(r.u(b,0x30)==1 and r.u(b,0x50)==0,'unsupported camera projection mode')
        local near,fov=r.f(b,0x28),r.f(b,0x34)
        assert(near>0 and near<10,'camera near plane')
        -- Nonidentity local offsets require a separately verified inverse transform.
        for _,o in ipairs({0x80,0x84,0x88,0x90,0x94,0x98,0x48,0x4c}) do
            assert(math.abs(r.f(b,o))<1e-6,'camera local offset unsupported')
        end
        assert(math.abs(math.abs(r.f(b,0x8c))-1)<1e-6,'camera local rotation unsupported')
        local array=r.p(scene+0x28);local data=r.read(array+index*64,64);local matrix={}
        for i=1,16 do matrix[i]=r.f(data,(i-1)*4) end
        assert(r.p(base+0x346d560)==state and r.p(state)==camera and r.p(camera+0x18)==scene
            and r.u(r.read(camera+0x20,4),0)==index and r.p(scene+0x28)==array,'camera changed during read')
        self.camera_matrix=matrix;self.camera_near=near;self.camera_aspect=aspect
        self.camera_distance=math.sqrt((pose.x-matrix[13])^2+(pose.y-matrix[14])^2+(pose.z-matrix[15])^2)
        self.camera_fov=fov
        self.camera_lateral=(pose.x-matrix[13])*matrix[1]+(pose.y-matrix[14])*matrix[2]+(pose.z-matrix[15])*matrix[3]
        return M.project(matrix,pose.x,pose.y,pose.z,fov,aspect,near)
    end
    function self.poll(base,pose,aspect)
        if not base or not pose then self.status='no weapon pose';return nil end
        self.camera_matrix=nil;self.camera_near=nil;self.camera_aspect=nil
        self.camera_distance=nil;self.camera_fov=nil;self.camera_lateral=nil
        local ok,result,status=pcall(self.snapshot,base,pose,aspect)
        self.status=ok and status or tostring(result)
        return ok and result or nil
    end
    return self
end
return M
