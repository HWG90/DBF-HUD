-- Read-only, build-pinned avatar/health adapter. No native gameplay calls/writes.
-- Layout provenance: Photo Mode subject_backend and Temporary Unlocks freezes.
local M={}
local function unhex(s)return(s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
local function normalize(v)
 local n=math.sqrt(v[1]^2+v[2]^2+v[3]^2);assert(n>1e-5,'Spine anatomical axis degenerate')
 return {v[1]/n,v[2]/n,v[3]/n}
end
local function cross(a,b)return{a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function dot(a,b)return a[1]*b[1]+a[2]*b[2]+a[3]*b[3]end
-- Bone-local axes differ across this rig. Build a shared anatomical frame from
-- POSITIONS, then offset every centerline anchor along the SAME rear normal.
function M.anatomy(points,root_forward,offset)
 local a,c,l,r=points.spine1,points.chest,points.l_clavicle,points.r_clavicle
 local up=normalize({c[1]-a[1],c[2]-a[2],c[3]-a[3]})
 local lateral={r[1]-l[1],r[2]-l[2],r[3]-l[3]};local along=dot(lateral,up)
 local right=normalize({lateral[1]-up[1]*along,lateral[2]-up[2]*along,lateral[3]-up[3]*along})
 local forward=cross(up,right)
 if dot(forward,root_forward)<0 then
  for i=1,3 do right[i]=-right[i];forward[i]=-forward[i]end
 end
 local bones={}
 for _,name in ipairs({'spine1','spine2','chest'})do
  local p=points[name];bones[name]={p[1]-forward[1]*offset,p[2]-forward[2]*offset,p[3]-forward[3]*offset}
 end
 return bones,right,forward
end
function M.memory()
 local ffi=require('ffi');local util=require('jit.util')
 pcall(ffi.cdef,[[void *SPH_GetModuleHandleA(const char*) __asm__("GetModuleHandleA");
 void *SPH_GetCurrentProcess(void) __asm__("GetCurrentProcess");
 int SPH_ReadProcessMemory(void*,const void*,void*,size_t,size_t*) __asm__("ReadProcessMemory");
 int SPH_QueryPerformanceCounter(int64_t*) __asm__("QueryPerformanceCounter");
 int SPH_QueryPerformanceFrequency(int64_t*) __asm__("QueryPerformanceFrequency");]])
 local k=ffi.load('kernel32');local process=k.SPH_GetCurrentProcess()
 local buffer,got=ffi.new('uint8_t[4096]'),ffi.new('size_t[1]')
 local m={game=tonumber(ffi.cast('uintptr_t',k.SPH_GetModuleHandleA('game.dll'))),exe=tonumber(ffi.cast('uintptr_t',k.SPH_GetModuleHandleA(nil)))}
 function m.read(at,n)
  assert(k.SPH_ReadProcessMemory(process,ffi.cast('void*',at),buffer,n,got)~=0 and tonumber(got[0])==n,'Spine read unavailable')
  return ffi.string(buffer,n)
 end
 function m.ref(handle)return math.floor(tonumber(ffi.cast('uintptr_t',handle))/4)end
 function m.address(handle)return tonumber(ffi.cast('uintptr_t',handle))end
 function m.function_address(fn)return util.funcinfo(fn).addr end
 local tick,freq=ffi.new('int64_t[1]'),ffi.new('int64_t[1]');assert(k.SPH_QueryPerformanceFrequency(freq)~=0)
 local frequency=tonumber(freq[0])
 function m.clock()k.SPH_QueryPerformanceCounter(tick);return tonumber(tick[0])/frequency end
 return m
end
function M.new(sr,mem)
 mem=mem or M.memory();local game,exe=mem.game,mem.exe
 local function read(at,n)
  assert(type(at)=='number' and at>=65536 and at<2^47 and n>0 and n<=4096,'Spine read bounds')
  local b=mem.read(at,n);assert(type(b)=='string' and #b==n,'Spine read incomplete');return b
 end
 local function u(b,o)local a,c,d,e=b:byte(o+1,o+4);return a+c*256+d*65536+e*16777216 end
 local function word(at)return u(read(at,4),0)end
 local function ptr(at)local b=read(at,8);return u(b,0)+u(b,4)*4294967296 end
 local function pin(base,off,hex)assert(read(base+off,#hex/2)==unhex(hex),'Spine layout fingerprint mismatch '..string.format('%x',off))end
 local function image(base,stamp)
  assert(base and base>=65536,'Spine module unavailable')
  local pe=word(base+60);assert(pe>=64 and pe<1048576 and read(base+pe,4)=='PE\0\0' and word(base+pe+8)==stamp,'Spine unsupported game build')
 end
 image(game,0x6ab3b43f);image(exe,0x6ab382e4)
 pin(exe,0x9d8c0,'48895c24084889742410574883ec20488b351a289701')
 pin(game,9562400,'488bc4488958104889701848897820554154415541564157488d68a14881ecf00000000f2970c8')
 pin(game,0xa42a74,'4c8b0ded398e02');pin(game,0xa42b1f,'4138bc24ec020000');pin(game,0xa42b2a,'41888424ec020000')
 pin(game,0xa4604c,'4c8b15cd0c8e02');pin(game,0xa460da,'4869c138120000');pin(game,0xa460e1,'4a8b841088e8530048c1e82a2401')
 for _,name in ipairs({'has_node','node','num_scene_graph_items','world_pose'})do assert(type(sr.Unit[name])=='function','Spine Unit API missing: '..name)end
 -- This established engine binding is also the subject backend's build anchor.
 assert(mem.function_address(sr.Unit.set_mesh_visibility)==exe+0x4128e0,'Spine Unit binding changed')
 local function lookup(at,key,limit)
  local b=read(at,20);local data=u(b,0)+u(b,4)*4294967296;local cap,empty,seed=u(b,8),u(b,12),u(b,16)
  assert(cap>0 and cap<=4194304,'Spine map bounds')
  local low=key%65536;local hash=(low*seed+(((key-low)/65536*seed)%65536)*65536)%4294967296
  for i=0,math.min(cap,64)-1 do local row=read(data+((hash+i)%cap)*8,8);local found=u(row,0)
   if found==key then local index=u(row,4);assert(index<limit,'Spine map index');return index end
   if found==empty then return end
  end
 end
 local function owner()
  local players=ptr(game+0x3326468);if players==0 then return end
  local count=word(players+132);assert(count<=8,'Spine player count');if count==0 then return end
  local player
  for i=0,count-1 do local b=read(ptr(players+232+i*8),24)
   if u(b,20)%2==1 then assert(not player,'Spine local ownership ambiguous');player=u(b,8)end
  end
  if not player then return end
  local pi=lookup(players+208,player,8);if not pi then return end
  local goid=word(players+936+pi*32);if goid==0x7fff or goid==0xffffffff then return end
  local entities=ptr(game+0x346bf98);local ei=lookup(entities+0xf22ec8,goid,4194304);if not ei then return end
  local at=entities+0xf32f18+ei*24;local b=read(at,24)
  if u(b,0)~=0x294dfa97 or u(b,4)~=0x4d1c334d or u(b,20)%2~=1 then return end
  assert(u(b,16)==goid,'Spine avatar identity changed')
  return {players=players,player=player,goid=goid,avatar=u(b,8),ref=u(b,12),record=at}
 end
 local function key(o)return table.concat({o.players,o.player,o.goid,o.avatar,o.ref},':')end
 local function native(ref)
  local registry=ptr(exe+0x1a100f0);local index=ref%4194304;local generation=math.floor(ref/4194304)
  assert(index<word(registry+0x98) and read(ptr(registry+0xa0)+index,1):byte()==generation,'Spine Unit generation retired')
  local unit=ptr(ptr(registry+0x88)+index*8);local vt=ptr(unit)
  assert(ptr(vt+0xf8)==exe+0x2bd890 and ptr(vt+0xc8)==exe+0x2c3990 and word(unit+8)==ref,'Spine Unit identity changed')
  return unit
 end
 local cache;local self={stats={enumerations=0,frames=0},clock=mem.clock or os.clock}
 function self.valid(frame)
  local o=owner()
  return o~=nil and key(o)==frame.owner_key and sr.Application.main_world()==frame.world
   and native(o.ref)==frame.native and ptr(frame.native+0x18)==frame.world_native
 end
 function self.invalidate()cache=nil end
 function self.frame()
  local o=owner();if not o then cache=nil;return nil end
  local world=sr.Application.main_world();if not world then cache=nil;return nil end
  local world_native=ptr(mem.address(world));local unit=native(o.ref)
  if ptr(unit+0x18)~=world_native then cache=nil;return nil end
  local owner_key=key(o);local identity=owner_key..':'..world_native
  local fp=read(o.players+0x2ec,1):byte();assert(fp==0 or fp==1,'Spine first-person flag invalid')
  if fp==1 then
   local character=ptr(game+0x3326d20);local ci=lookup(character+0xf8,o.avatar,16)
   if not ci then return nil end
   assert(ptr(character+0x110+ci*8)==o.record,'Spine camera avatar changed')
   local flags=read(character+0x53e880+ci*0x1238,16)
   local aiming=math.floor(flags:byte(11)/4)%2==1
   assert(aiming==(math.floor(flags:byte(16)/32)%2==1),'Spine aiming flags disagree')
   if aiming then return nil end
  end
  local health=ptr(game+0x3326688);if health==0 then return nil end
  local capacity,live=word(health+0x1010),word(health+0x1020)
  assert(capacity<=4096 and live<=capacity,'Spine health bounds')
  local index=lookup(health+0x1030,o.avatar,4096);if not index or index>=live then return nil end
  local descriptors,records,extended=ptr(health+0x1048),ptr(health+0x1058),ptr(health+0x1060)
  local descriptor=ptr(descriptors+index*8);local d=read(descriptor,24)
  assert(u(d,8)==o.avatar and u(d,16)==o.goid,'Spine health owner changed')
  local row=records+index*440;local current=word(row+20);local maximum=word(extended+index*28+20)
  if word(row+412)~=0 or current==0 then return nil end
  assert(maximum>0 and maximum<=100000 and current<=maximum,'Spine health invalid')
  local frame={local_owner=true,third_person=true,identity=identity,owner_key=owner_key,world=world,
   world_native=world_native,native=unit,ref=o.ref,health=current,max_health=maximum}
  assert(self.valid(frame),'Spine owner changed before bone lookup')
  if not cache or cache.identity~=identity or cache.native~=unit then
   local handle;local units=sr.World.units(world);assert(type(units)=='table' and #units<=131072,'Spine Unit enumeration bounds')
   self.stats.enumerations=self.stats.enumerations+1
   for _,candidate in ipairs(units)do
    if mem.ref(candidate)==o.ref then assert(not handle,'Spine render handle ambiguous');handle=candidate end
   end
   assert(handle,'Spine render handle unavailable')
   assert(self.valid(frame),'Spine owner changed during enumeration')
   local n=sr.Unit.num_scene_graph_items(handle);assert(n==107,'Spine unsupported skeleton')
   local nodes={}
   for _,name in ipairs({'spine1','spine2','chest','l_clavicle','r_clavicle'})do
    assert(sr.Unit.has_node(handle,name),'Spine bone missing: '..name)
    local node=sr.Unit.node(handle,name);assert(type(node)=='number' and node%1==0 and node>=1 and node<=n,'Spine node invalid');nodes[name]=node
   end
   cache={identity=identity,native=unit,handle=handle,nodes=nodes}
  end
  frame.handle,frame.nodes=cache.handle,cache.nodes;self.stats.frames=self.stats.frames+1
  return frame
 end
 function self.bones(frame,offset)
  assert(self.valid(frame),'Spine owner retired before transform read')
  local X,V=sr.Matrix4x4,sr.Vector3;local points={}
  for _,name in ipairs({'spine1','spine2','chest','l_clavicle','r_clavicle'})do
   local pose=sr.Unit.world_pose(frame.handle,frame.nodes[name])
   local p=X.translation(pose);points[name]={V.x(p),V.y(p),V.z(p)}
  end
  local root=X.forward(sr.Unit.world_pose(frame.handle,1))
  local bones,right,forward=M.anatomy(points,{V.x(root),V.y(root),V.z(root)},offset)
  frame.right=right
  return bones
 end
 return self
end
return M
