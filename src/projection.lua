-- Diagnostic world-to-screen projection. Reads data only; no engine calls.
-- Initial scope: perspective camera with identity local camera offset.
local M={}
local function unhex(s)return (s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
local function validate(m,fov,aspect)
    assert(fov>.05 and fov<3.1 and aspect>.1 and aspect<10,'projection dimensions')
    for i=1,16 do assert(type(m[i])=='number' and m[i]==m[i] and math.abs(m[i])<1e7,'camera matrix finite') end
    for _,k in ipairs({1,5,9}) do
        local n=m[k]^2+m[k+1]^2+m[k+2]^2;assert(math.abs(n-1)<.01,'camera axis scale')
    end
    for _,p in ipairs({{1,5},{1,9},{5,9}}) do
        local a,b=p[1],p[2];assert(math.abs(m[a]*m[b]+m[a+1]*m[b+1]+m[a+2]*m[b+2])<.01,'camera axes')
    end
    assert(math.abs(m[4])+math.abs(m[8])+math.abs(m[12])+math.abs(m[16]-1)<1e-5,'camera affine')
end
local function project_validated(m,x,y,z,fov,aspect,near)
    local dx,dy,dz=x-m[13],y-m[14],z-m[15]
    local right=dx*m[1]+dy*m[2]+dz*m[3]
    local depth=dx*m[5]+dy*m[6]+dz*m[7]
    local up=dx*m[9]+dy*m[10]+dz*m[11]
    if depth<=math.max(near,.0001) then return nil,'behind camera or near plane' end
    local t=math.tan(fov*.5)
    local nx,ny=.5+.5*right/(depth*t*aspect),.5+.5*up/(depth*t)
    if nx~=nx or ny~=ny or nx<0 or nx>1 or ny<0 or ny>1 then return nil,'outside viewport' end
    return {x=nx,y=ny,depth=depth},'projected weapon root'
end
-- Validate this immutable frame snapshot once, rather than once per glyph corner.
function M.project(m,x,y,z,fov,aspect,near)
    validate(m,fov,aspect)
    return project_validated(m,x,y,z,fov,aspect,near)
end
function M.projector(m,fov,aspect,near)
    validate(m,fov,aspect)
    return function(x,y,z)return project_validated(m,x,y,z,fov,aspect,near) end
end
-- Invert the camera projection of a planar panel without clipping its corners.
-- u runs right and v runs down. This also handles partially offscreen panels.
function M.panel_inverse(camera,fov,aspect,x,y,z,ux,uy,uz,vx,vy,vz)
    local t=math.tan(fov*.5)
    local function terms(px,py,pz)
        local r=px*camera[1]+py*camera[2]+pz*camera[3]
        local d=px*camera[5]+py*camera[6]+pz*camera[7]
        local up=px*camera[9]+py*camera[10]+pz*camera[11]
        return .5*d+r/(2*t*aspect),.5*d-up/(2*t),d
    end
    local a,d,g=terms(ux,uy,uz)
    local b,e,h=terms(vx,vy,vz)
    local c,f,i=terms(x-camera[13],y-camera[14],z-camera[15])
    local aa,ab,ac=e*i-f*h,c*h-b*i,b*f-c*e
    local ba,bb,bc=f*g-d*i,a*i-c*g,c*d-a*f
    local ca,cb,cc=d*h-e*g,b*g-a*h,a*e-b*d
    local determinant=a*aa+b*ba+c*ca
    local extent=math.max(math.abs(a),math.abs(b),math.abs(c),math.abs(d),math.abs(e),math.abs(f),math.abs(g),math.abs(h),math.abs(i))
    if extent==0 or math.abs(determinant)<1e-12*extent^3 then return nil end
    local norm=math.max(math.abs(ca),math.abs(cb),math.abs(cc))
    if norm==0 then return nil end
    return aa/norm,ab/norm,ac/norm,ba/norm,bb/norm,bc/norm,ca/norm,cb/norm,cc/norm
end

-- Clip a convex world-space polygon against this snapshot's perspective frustum.
-- UVs are interpolated at intersections before the perspective divide.
function M.clip_polygon(m,vertices,fov,aspect,near,scratch)
    assert(fov>.05 and fov<3.1 and aspect>.1 and aspect<10,'projection dimensions')
    local t=math.tan(fov*.5);local n=math.max(near,.0001)
    local polygon=scratch and scratch.camera or {}
    for i,v in ipairs(vertices) do
        local dx,dy,dz=v.x-m[13],v.y-m[14],v.z-m[15]
        local point=polygon[i] or {};polygon[i]=point
        point.r=dx*m[1]+dy*m[2]+dz*m[3];point.d=dx*m[5]+dy*m[6]+dz*m[7]
        point.u=dx*m[9]+dy*m[10]+dz*m[11];point.s=v.s or 0;point.v=v.v or 0
    end
    for i=#polygon,#vertices+1,-1 do polygon[i]=nil end
    -- Most HUD pieces are fully inside the snapshot frustum. Keep their
    -- vertices unchanged instead of allocating five clipping work lists.
    local fully_inside=true
    for _,p in ipairs(polygon) do
        if p.d<n or p.d*t*aspect+p.r<0 or p.d*t*aspect-p.r<0 or p.d*t+p.u<0 or p.d*t-p.u<0 then fully_inside=false;break end
    end
    if not fully_inside then
    local planes={function(p)return p.d-n end,function(p)return p.d*t*aspect+p.r end,
        function(p)return p.d*t*aspect-p.r end,function(p)return p.d*t+p.u end,function(p)return p.d*t-p.u end}
    for _,distance in ipairs(planes) do
        if #polygon==0 then break end
        local clipped={};local previous=polygon[#polygon];local pd=distance(previous)
        for _,current in ipairs(polygon) do
            local cd=distance(current)
            if (pd>=0)~=(cd>=0) then
                local ratio=pd/(pd-cd);local intersection={}
                for _,key in ipairs({'r','d','u','s','v'}) do intersection[key]=previous[key]+(current[key]-previous[key])*ratio end
                clipped[#clipped+1]=intersection
            end
            if cd>=0 then clipped[#clipped+1]=current end
            previous,pd=current,cd
        end
        polygon=clipped
    end
    end
    local result=scratch and fully_inside and scratch.result or {}
    for i,p in ipairs(polygon) do
        local point=result[i] or {};result[i]=point
        point.x=math.max(0,math.min(1,.5+.5*p.r/(p.d*t*aspect)))
        point.y=math.max(0,math.min(1,.5+.5*p.u/(p.d*t)));point.depth=p.d;point.s=p.s;point.v=p.v
    end
    for i=#result,#polygon+1,-1 do result[i]=nil end
    return result
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
        -- CPU projection still requires identity local offsets. The engine's
        -- validated wrapper handles recoil/dive offsets for native depth reads.
        local local_supported=true
        for _,o in ipairs({0x80,0x84,0x88,0x90,0x94,0x98,0x48,0x4c}) do
            local value=r.f(b,o);assert(value==value and math.abs(value)<1e4,'camera local offset invalid')
            if math.abs(value)>=1e-6 then local_supported=false end
        end
        local rotation_w=r.f(b,0x8c);assert(rotation_w==rotation_w and math.abs(rotation_w)<2,'camera local rotation invalid')
        if math.abs(math.abs(rotation_w)-1)>=1e-6 then local_supported=false end
        local array=r.p(scene+0x28);local data=r.read(array+index*64,64);local matrix={}
        for i=1,16 do matrix[i]=r.f(data,(i-1)*4) end
        assert(r.p(base+0x346d560)==state and r.p(state)==camera and r.p(camera+0x18)==scene
            and r.u(r.read(camera+0x20,4),0)==index and r.p(scene+0x28)==array,'camera changed during read')
        validate(matrix,fov,aspect)
        self.native_camera=camera;self.native_getter=getter
        self.native_near=near
        self.native_fov=fov
        self.native_owner={base=base,state=state,scene=scene,index=index,array=array}
        self.depth_camera_matrix=matrix
        if not local_supported then return nil,'camera local offset unsupported for CPU projection; native projection available'end
        self.camera_matrix=matrix;self.camera_near=near;self.camera_aspect=aspect
        self.camera_distance=math.sqrt((pose.x-matrix[13])^2+(pose.y-matrix[14])^2+(pose.z-matrix[15])^2)
        self.camera_fov=fov
        self.camera_lateral=(pose.x-matrix[13])*matrix[1]+(pose.y-matrix[14])*matrix[2]+(pose.z-matrix[15])*matrix[3]
        return M.project(matrix,pose.x,pose.y,pose.z,fov,aspect,near)
    end
    function self.native_point(x,y,z)
        if not backend.project_camera or not self.native_camera or not self.native_getter then self.native_status='camera descriptor unavailable';return nil end
        local ok,a,b,d=pcall(function()
            local owner=assert(self.native_owner);r.reset()
            assert(r.p(owner.base+0x346d560)==owner.state and r.p(owner.state)==self.native_camera and
                r.p(self.native_camera+0x18)==owner.scene and r.u(r.read(self.native_camera+0x20,4),0)==owner.index and
                r.p(owner.scene+0x28)==owner.array,'camera owner changed before native projection')
            return backend.project_camera(self.native_getter,self.native_camera,x,y,z)
        end)
        if not ok then self.native_status=tostring(a);return nil end
        for _,value in ipairs({a,b,d})do if type(value)~='number'or value~=value or math.abs(value)>=1e7 then self.native_status='nonfinite native projection';return nil end end
        if type(a)~='number'or type(b)~='number'or type(d)~='number'then self.native_status='incomplete native projection';return nil end
        -- Native perspective projection returns forward normalized device depth.
        -- The scene-depth shader samples linear metres, so invert near/z first.
        if not self.native_near or d>=1 then self.native_status='native depth outside perspective range';return nil end
        local depth=self.native_near/(1-d)
        if depth~=depth or depth<=0 or depth>=10000 then self.native_status='invalid native linear depth';return nil end
        self.native_status='projected'
        return {x=a,y=b,depth=depth,native_depth=d}
    end
    function self.poll(base,pose,aspect)
        if not base or not pose then self.status='no weapon pose';return nil end
        self.native_camera=nil;self.native_getter=nil;self.native_owner=nil;self.native_near=nil;self.native_fov=nil;self.depth_camera_matrix=nil
        self.camera_matrix=nil;self.camera_near=nil;self.camera_aspect=nil
        self.camera_distance=nil;self.camera_fov=nil;self.camera_lateral=nil
        local ok,result,status=pcall(self.snapshot,base,pose,aspect)
        self.status=ok and status or tostring(result)
        return ok and result or nil
    end
    return self
end
-- Invert an ordered projected quad: TL, TR, BR, BL; screen UV -> unit panel UV.
-- Rows match screen_scene.atlas_rows: u numerator, v numerator, denominator.
local function valid(v)return type(v)=='number'and v==v and math.abs(v)<=1e7 end
-- The guarded engine wrapper returns output pixels, which can differ from GUI
-- pixels under upscaling. Normalize once; screen_scene scales to GUI pixels.
function M.native_coordinate_map(output_width,output_height)
 if not valid(output_width)or not valid(output_height)or output_width<=0 or output_height<=0 then return nil end
 return {space='output_pixels',sx=1/output_width,sy=1/output_height,bx=0,by=0}
end
function M.normalize_native_point(point,map)
 if not point or not map then return nil end
 point.x=point.x*map.sx+map.bx;point.y=point.y*map.sy+map.by
 return valid(point.x)and valid(point.y)and point or nil
end
function M.native_panel_inverse(points)
 if type(points)~='table'or #points~=4 then return nil end
 local x,y={},{ };local xmin,ymin,xmax,ymax=math.huge,math.huge,-math.huge,-math.huge
 for i=1,4 do
  local p=points[i];if type(p)~='table'then return nil end
  x[i]=p.x~=nil and p.x or p[1];y[i]=p.y~=nil and p.y or p[2]
  if not valid(x[i])or not valid(y[i])then return nil end
  xmin=math.min(xmin,x[i]);xmax=math.max(xmax,x[i]);ymin=math.min(ymin,y[i]);ymax=math.max(ymax,y[i])
 end
 local span=math.max(xmax-xmin,ymax-ymin);if span<=0 then return nil end
 -- A finite visible planar projection must be convex and have distinct corners.
 local sign
 for i=1,4 do
  local j,k=i%4+1,(i+1)%4+1
  local cross=(x[j]-x[i])*(y[k]-y[j])-(y[j]-y[i])*(x[k]-x[j])
  if math.abs(cross)<=1e-12*span^2 or(sign and cross*sign<0)then return nil end
  sign=cross
 end
 local dx1,dx2,dx3=x[2]-x[3],x[4]-x[3],x[1]-x[2]+x[3]-x[4]
 local dy1,dy2,dy3=y[2]-y[3],y[4]-y[3],y[1]-y[2]+y[3]-y[4]
 local g,h=0,0
 if math.abs(dx3)>1e-12*span or math.abs(dy3)>1e-12*span then
  local determinant=dx1*dy2-dx2*dy1;local extent=math.max(math.abs(dx1),math.abs(dx2),math.abs(dy1),math.abs(dy2))
  if math.abs(determinant)<=1e-12*extent^2 then return nil end
  g=(dx3*dy2-dx2*dy3)/determinant;h=(dx1*dy3-dx3*dy1)/determinant
 end
 local a,b,c=x[2]-x[1]+g*x[2],x[4]-x[1]+h*x[4],x[1]
 local d,e,f=y[2]-y[1]+g*y[2],y[4]-y[1]+h*y[4],y[1]
 local rows={e-f*h,c*h-b,b*f-c*e,f*g-d,a-c*g,c*d-a*f,d*h-e*g,b*g-a*h,a*e-b*d}
 local determinant=a*rows[1]+b*rows[4]+c*rows[7]
 local extent=math.max(math.abs(a),math.abs(b),math.abs(c),math.abs(d),math.abs(e),math.abs(f),math.abs(g),math.abs(h),1)
 if not valid(determinant)or math.abs(determinant)<=1e-12*extent^3 then return nil end
 local norm=math.max(math.abs(rows[7]),math.abs(rows[8]),math.abs(rows[9]));if norm<=0 then return nil end
 for i=1,9 do rows[i]=rows[i]/norm;if not valid(rows[i])then return nil end end
 -- Reject numerically unstable inverses instead of sending malformed shader UVs.
 local expected={{0,0},{1,0},{1,1},{0,1}}
 for i=1,4 do
  local denominator=rows[7]*x[i]+rows[8]*y[i]+rows[9]
  if not valid(denominator)or math.abs(denominator)<=1e-12 then return nil end
  local u=(rows[1]*x[i]+rows[2]*y[i]+rows[3])/denominator
  local v=(rows[4]*x[i]+rows[5]*y[i]+rows[6])/denominator
  if not valid(u)or not valid(v)or math.abs(u-expected[i][1])>1e-7 or math.abs(v-expected[i][2])>1e-7 then return nil end
 end
 return rows
end

-- Reuse one guarded corner projection for a complete planar GUI surface.
-- Input corners are TL/TR/BR/BL in D3D screen UVs, with native linear depth.
-- Local geometry remains bottom-left/up; atlas mapping remains top-left/down.
function M.native_panel_snapshot(frame,points,near)
 if not frame or not valid(frame.x)or not valid(frame.y)or not valid(frame.w)or not valid(frame.h)or frame.w<=0 or frame.h<=0 then return nil end
 local rows=M.native_panel_inverse(points);if not rows then return nil end
 for i=1,4 do if not valid(points[i].depth)or points[i].depth<=0 then return nil end end
 local a,b,c,d,e,f,g,h,i=unpack(rows)
 local forward={e*i-f*h,c*h-b*i,b*f-c*e,f*g-d*i,a*i-c*g,c*d-a*f,d*h-e*g,b*g-a*h,a*e-b*d}
 local norm=math.max(math.abs(forward[7]),math.abs(forward[8]),math.abs(forward[9]));if norm<=0 then return nil end
 for k=1,9 do forward[k]=forward[k]/norm;if not valid(forward[k])then return nil end end
 local d0,du,dv=points[1].depth,points[2].depth-points[1].depth,points[4].depth-points[1].depth
 -- Native float projection can round; refuse a nonplanar depth snapshot.
 if math.abs(d0+du+dv-points[3].depth)>.002+math.abs(points[3].depth)*.002 then return nil end
 local threshold=math.max(near or .0001,.0001)
 local snapshot={rows=rows}
 function snapshot.project(x,y)
  local u,v=(x-frame.x)/frame.w,1-(y-frame.y)/frame.h
  local depth=d0+du*u+dv*v;local divisor=forward[7]*u+forward[8]*v+forward[9]
  if not valid(depth)or depth<=threshold or not valid(divisor)or math.abs(divisor)<1e-12 then return nil end
  local nx=(forward[1]*u+forward[2]*v+forward[3])/divisor
  local ny=1-(forward[4]*u+forward[5]*v+forward[6])/divisor
  if not valid(nx)or not valid(ny)then return nil end
  return {x=nx,y=ny,depth=depth}
 end
 function snapshot.image_rows(x,y,w,h)
  if not valid(w)or not valid(h)or w<=0 or h<=0 then return nil end
  local ox,oy=frame.x-x,y+h-frame.y-frame.h
  local cropped={}
  for k=1,3 do
   cropped[k]=(frame.w*rows[k]+ox*rows[k+6])/w
   cropped[k+3]=(frame.h*rows[k+3]+oy*rows[k+6])/h
   cropped[k+6]=rows[k+6]
  end
  return cropped
 end
 return snapshot
end

return M
