-- Every native corner must recheck ownership immediately before calling the
-- engine wrapper, even when the camera changed since the frame snapshot.
local ffi=require('ffi')
HUD={memory=dofile('src/memory.lua')}
local Projection=dofile('src/projection.lua')
local bytes={};local reads,calls=0,0
local function put(a,s)for i=1,#s do bytes[a+i-1]=s:byte(i)end end
local function u32(n)return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)end
local function U(a,n)put(a,u32(n))end
local function P(a,n)put(a,u32(n%2^32)..u32(math.floor(n/2^32)))end
local function F(a,n)local f=ffi.new('float[1]',n);put(a,ffi.string(f,4))end
local function hex(s)return(s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
local function read(a,n)
 reads=reads+1;local s={}
 for i=0,n-1 do if bytes[a+i]==nil then return nil end;s[#s+1]=string.char(bytes[a+i])end
 return table.concat(s)
end
local base,api,cap,getter,impl,state,cam,scene,mat=0x50000000,0x60000000,0x60001000,0x60002000,0x60003000,0x60004000,0x60005000,0x60006000,0x60007000
P(base+0x3326308,api);P(api+0x20,cap);P(cap+0xf8,getter)
put(getter,string.rep('\0',0x137));put(impl,string.rep('\0',0x76))
put(getter,hex('48895c2408574883ec60'))
put(getter+0x132,hex('e8')..u32((impl-getter-0x137)%2^32))
put(impl,hex('488bc448895808488968104889701857'))
put(impl+0x62,hex('488b471848c1e206418be948035028e80a951500'))
P(base+0x346d560,state);P(state,cam);put(cam,string.rep('\0',160))
P(cam+0x18,scene);U(cam+0x20,0);U(cam+0x30,1)
F(cam+0x28,.05);F(cam+0x34,math.pi/2);F(cam+0x8c,1);P(scene+0x28,mat)
for i,v in ipairs({1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1})do F(mat+(i-1)*4,v)end
local backend={read=read,project_camera=function(fn,owner,x,y,z)
 assert(fn==getter and owner==cam);calls=calls+1;return .2,.3,.995
end}
local reader=Projection.new(backend);local pose={x=0,y=10,z=0}
assert(reader.poll(base,pose,2),reader.status)
reads=0
for i=1,16 do local p=assert(reader.native_point(i,2,3));assert(math.abs(p.depth-10)<1e-5)end
assert(reads==64 and calls==16,'Each corner must freshly read all four ownership fields')
for _,change in ipairs({{base+0x346d560,state},{state,cam},{cam+0x18,scene},{scene+0x28,mat}})do
 P(change[1],change[2]+0x1000)
 assert(not reader.native_point(1,2,3)and calls==16,'Changed pointer reached native engine call')
 P(change[1],change[2])
end
U(cam+0x20,1);assert(not reader.native_point(1,2,3)and calls==16,'Changed node reached native engine call');U(cam+0x20,0)
local saved=bytes[scene+0x28];bytes[scene+0x28]=nil
assert(not reader.native_point(1,2,3)and calls==16,'Unreadable owner reached native engine call');bytes[scene+0x28]=saved
assert(reader.native_point(1,2,3)and calls==17,'Restored owner did not recover')
local tearing={read=function(a,n)local s=read(a,n);if a==mat then U(cam+0x20,1)end;return s end}
assert(not Projection.new(tearing).poll(base,pose,2),'Torn snapshot accepted');U(cam+0x20,0)
assert(reader.poll(base,pose,2))
-- Pure plane projection retains the exact near-plane decision around adjacent
-- floating values; this catches arithmetic reordering at its rejection boundary.
local frame={x=0,y=0,w=100,h=100}
local function direct(x,y)
 local depth=.02+.001*x+.0002*y
 return{x=.5+.0002*x/depth,y=.5+.0002*y/depth,depth=depth}
end
local points={}
for i,p in ipairs({{0,100},{100,100},{100,0},{0,0}})do local q=direct(p[1],p[2]);points[i]={x=q.x,y=1-q.y,depth=q.depth}end
local plane=assert(Projection.native_panel_snapshot(frame,points,.05))
assert(not plane.project(30,0)and not plane.project(30-1e-10,0)and plane.project(30+1e-10,0),'Near-plane rejection changed')
print('PASS native projection: 64 fresh reads for 16 native points; state/camera/scene/node/array/unreadable/torn ownership refusal; exact near-plane boundary')
