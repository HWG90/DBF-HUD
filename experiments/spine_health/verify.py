from pathlib import Path
from lupa.luajit21 import LuaRuntime
import struct

lua = LuaRuntime()
lua.globals().prototype = lua.execute(Path(__file__).with_name('spine_health.lua').read_text())
lua.execute('''
local M=prototype
local bones={spine1={0,0,0},spine2={0,0,.2},chest={0,.05,.4}}
for _,hp in ipairs({0,1,25,50,75,100,125})do
 local s=M.geometry(bones,hp,100);assert(#s==8)
 local sum=0;for _,v in ipairs(s)do sum=sum+v.fill;assert(v.top[3]>v.bottom[3])end
 assert(math.abs(sum-8*math.min(1,hp/100))<1e-9)
end
assert(not pcall(M.geometry,bones,10,0))
assert(not pcall(M.geometry,bones,0/0,100))
assert(not pcall(M.geometry,{spine1={0,0,0},spine2={0,0,0},chest={0,0,.4}},10,100))
local reads,submits,clears=0,0,0
local frame={local_owner=true,third_person=true,identity='a',health=75,max_health=100}
local valid=true
local p=M.new({clear=function()clears=clears+1 end,
 frame=function()reads=reads+1;return frame end,bones=function()return bones end,
 valid=function()return valid end,submit=function(f,s)submits=submits+1;assert(#s==8)end})
p.draw();assert(reads==0)
p.enable(true);p.draw();assert(submits==1)
frame.identity='b';p.draw();assert(submits==2 and clears==3)
frame.third_person=false;p.draw();assert(submits==2)
frame.third_person=true;valid=false;p.draw();assert(submits==2)
local before=reads;p.draw();assert(reads==before) -- failure latches until explicit enable
p.enable(true);valid=true;p.draw();assert(submits==3)
p.release();before=reads;p.draw();assert(reads==before)
''')
print('PASS: geometry, health bounds, invalid data, owner replacement, first person, failure latch, idle disable')

root = Path(__file__).parent
for path in root.glob('*.lua'):
    lua.execute('assert((loadstring or load)(...))', path.read_text())
lua.globals().Renderer = lua.execute((root / 'renderer.lua').read_text())
lua.execute('''
local alive,created,moved,updated,destroyed={},0,0,0,0
local world={};local current=world
local sr={Application={main_world=function()return current end,can_get=function()return false end},
 Vector3=function(...)return{...}end,Vector2=function(...)return{...}end,Color=function(...)return{...}end,
 Matrix4x4={from_axes=function(...)return{...}end},World={},Gui={}}
sr.World.create_world_gui=function(w)assert(w==current);created=created+1;local g={};alive[g]=true;return g end
sr.World.destroy_gui=function(w,g)assert(w==current and alive[g]);alive[g]=nil;destroyed=destroyed+1 end
sr.Gui.bitmap=function(g)assert(alive[g]);return{}end
sr.Gui.update_bitmap=function(g)assert(alive[g]);updated=updated+1 end
sr.Gui.move=function(g)assert(alive[g]);moved=moved+1 end
local r=Renderer.new(sr);local f={world=world,right={1,0,0}}
local bones={spine1={0,0,0},spine2={0,0,.2},chest={0,0,.4}}
r.submit(f,prototype.geometry(bones,100,100));assert(created==8 and updated==8)
for i=1,100 do r.submit(f,prototype.geometry(bones,100,100))end
assert(created==8 and updated==8 and moved==0)
r.submit(f,prototype.geometry(bones,50,100));assert(updated==16 and created==8)
bones.chest={0,.1,.4};r.submit(f,prototype.geometry(bones,50,100));assert(moved>0 and updated==16)
r.clear();assert(destroyed==8)
r.submit(f,prototype.geometry(bones,50,100));assert(created==16)
current={};r.clear();assert(destroyed==8) -- retired world, no stale destruction
''')
print('PASS: retained rendering, unchanged-state idle, health-only ink changes, motion, live/retired-world cleanup')

# Synthetic byte-level fixture for the build-pinned read-only backend.
mem = {}
def put(at, data):
    mem.update((at+i, b) for i,b in enumerate(data))
def u32(at, n): put(at, struct.pack('<I', n))
def ptr(at, n): put(at, struct.pack('<Q', n))
def read(at, n):
    at, n = int(at), int(n)
    try: return bytes(mem[at+i] for i in range(n))
    except KeyError: raise RuntimeError(f'unmapped fixture read {at:x}+{n}')
game, exe = 0x10000000, 0x20000000
for base, stamp in [(game, 0x6ab3b43f), (exe, 0x6ab382e4)]:
    u32(base+60, 128);put(base+128,b'PE\0\0');u32(base+136,stamp)
pins=[(exe,0x9d8c0,'48895c24084889742410574883ec20488b351a289701'),
 (game,9562400,'488bc4488958104889701848897820554154415541564157488d68a14881ecf00000000f2970c8'),
 (game,0xa42a74,'4c8b0ded398e02'),(game,0xa42b1f,'4138bc24ec020000'),(game,0xa42b2a,'41888424ec020000'),
 (game,0xa4604c,'4c8b15cd0c8e02'),(game,0xa460da,'4869c138120000'),(game,0xa460e1,'4a8b841088e8530048c1e82a2401')]
for base, off, code in pins: put(base+off,bytes.fromhex(code))
players,entities,health,registry=0x30000000,0x40000000,0x50000000,0x60000000
unit,vt,world_pointer,world_native=0x70000000,0x71000000,0x72000000,0x73000000
put(0x74000000,bytes(24));u32(0x74000000+8,42);u32(0x74000000+20,1)
ptr(game+0x3326468,players);u32(players+132,1);ptr(players+232,0x74000000)
u32(players+936,77);put(players+0x2ec,b'\0')
def hashmap(at,key,array):
    put(at,struct.pack('<QIII',array,1,0xffffffff,1));put(array,struct.pack('<II',key,0))
hashmap(players+208,42,0x75000000)
ptr(game+0x346bf98,entities);hashmap(entities+0xf22ec8,77,0x76000000)
put(entities+0xf32f18,struct.pack('<IIIIII',0x294dfa97,0x4d1c334d,88,1,77,1))
ptr(exe+0x1a100f0,registry);u32(registry+0x98,2);ptr(registry+0xa0,0x77000000)
put(0x77000000+1,b'\0');ptr(registry+0x88,0x78000000);ptr(0x78000000+8,unit)
ptr(unit,vt);u32(unit+8,1);ptr(vt+0xf8,exe+0x2bd890);ptr(vt+0xc8,exe+0x2c3990)
ptr(unit+0x18,world_native);ptr(world_pointer,world_native)
ptr(game+0x3326688,health);u32(health+0x1010,1);u32(health+0x1020,1)
hashmap(health+0x1030,88,0x79000000)
ptr(health+0x1048,0x7a000000);ptr(0x7a000000,0x7b000000)
ptr(health+0x1058,0x7c000000);ptr(health+0x1060,0x7d000000)
put(0x7b000000,struct.pack('<IIIIII',0,0,88,0,77,0));u32(0x7c000000+412,0)
u32(0x7c000000+20,75);u32(0x7d000000+20,100)
lua.globals().Backend=lua.execute((root/'backend.lua').read_text())
lua.globals().fixture_read=read
lua.execute('''
world={};handle={}
fixture_sr={Application={main_world=function()return world end},
 World={units=function()return{handle}end},Unit={
 set_mesh_visibility=function()end,has_node=function()return true end,
 node=function(_,name)return ({spine1=22,spine2=27,chest=29,l_clavicle=43,r_clavicle=66})[name]end,
 num_scene_graph_items=function()return 107 end,world_pose=function()return{}end}}
fixture_backend=Backend.new(fixture_sr,{game=0x10000000,exe=0x20000000,read=fixture_read,
 ref=function()return 1 end,address=function()return 0x72000000 end,
 function_address=function()return 0x204128e0 end})
local a=fixture_backend.frame();assert(a.health==75 and a.max_health==100 and a.nodes.chest==29)
assert(fixture_backend.valid(a))
for i=1,20 do assert(fixture_backend.frame())end
assert(fixture_backend.stats.enumerations==1)
''')
character=0x7e000000
ptr(game+0x3326d20,character);hashmap(character+0xf8,88,0x7f000000)
ptr(character+0x110,entities+0xf32f18)
put(character+0x53e880,bytes(16));put(players+0x2ec,b'\1')
assert lua.eval('fixture_backend.frame()') is not None  # toggle alone is not FP
put(character+0x53e880+10,b'\4');put(character+0x53e880+15,b'\x20')
assert lua.eval('fixture_backend.frame()') is None
put(players+0x2ec,b'\0');u32(0x7b000000+16,999)
assert not lua.eval('pcall(fixture_backend.frame)')[0]
u32(0x7b000000+16,77);u32(0x7c000000+20,0)
assert lua.eval('fixture_backend.frame()') is None
print('PASS: pinned backend, local avatar, same-owner health, cached enumeration, first person, recycled health identity, death')
lua.execute('''
local p={spine1={0,0,0},spine2={0,0,.2},chest={0,0,.4},l_clavicle={-.2,0,.4},r_clavicle={.2,0,.4}}
local b,r,f=Backend.anatomy(p,{0,1,0},.16)
for _,name in ipairs({'spine1','spine2','chest'})do
 assert(math.abs(b[name][1])<1e-9 and math.abs(b[name][2]+.16)<1e-9)
 assert(b[name][3]==p[name][3])
end
assert(r[1]==1 and f[2]==1)
-- Turning rotates the entire centerline/normal together, with no lateral drift.
local q={};for k,v in pairs(p)do q[k]={-v[2],v[1],v[3]}end
local c=Backend.anatomy(q,{-1,0,0},.16)
assert(math.abs(c.spine1[1]-.16)<1e-9 and math.abs(c.spine1[2])<1e-9)
-- Prone: torso up is horizontal. Back offset remains above the body.
local prone={spine1={0,0,0},spine2={0,.2,0},chest={0,.4,0},l_clavicle={-.2,.4,0},r_clavicle={.2,.4,0}}
local d=Backend.anatomy(prone,{0,1,0},.16)
assert(math.abs(d.chest[3]-.16)<1e-9)
''')
print('PASS: common anatomical rear offset, midline placement, turning, prone orientation')
lua.globals().main_source=(root/'main.lua').read_text()
lua.execute('''
local imports,frames,unregistered=0,0,0
local values={spine_enabled=false,rear_offset=.16}
local spec
local environment=setmetatable({mod={log=function()end,require=function(name)
 if name=='spine_health.lua' then return prototype end
 imports=imports+1
 if name=='backend.lua' then return {new=function()return {
  frame=function()frames=frames+1;return nil end,clock=function()return 0 end,
  stats={enumerations=0},valid=function()return true end}end}end
 if name=='renderer.lua' then return {new=function()return {clear=function()end,submit=function()end,
 stats={created=0,moved=0,updated=0},material='fixture'}end}end
 error('Unexpected dependency: '..name)
end},stingray={},DBFMCM={register=function(s)
 spec=s
 return {get=function(k)return values[k]end,unregister=function()unregistered=unregistered+1 end}
end}},{__index=_G})
environment._G=environment
local chunk=assert(loadstring(main_source));setfenv(chunk,environment);local main=chunk()
main.on_enable()
assert(spec.parent_name=="Diver's Best Friend" and spec.pages[1].name=='Experiments')
local toggle
for _,c in ipairs(spec.pages[1].controls)do
 if c.id=='spine_enabled' then toggle=c;assert(c.default==false)end
end
assert(toggle and imports==0)
for i=1,10000 do main.on_update(.016)end
assert(imports==0 and frames==0,'Off must not initialize or sample native adapters')
values.spine_enabled=true;toggle.on_change();main.on_update(.016)
assert(imports==2 and frames==1,'Opt-in initializes only the two local adapters')
values.spine_enabled=false;toggle.on_change();main.on_update(.016)
for i=1,10000 do main.on_update(.016)end
assert(frames==1,'Disabled bar has zero health/bone work')
assert(main.on_disable()==true and unregistered==1,'Removal unregisters the optional tab')
''')
print('PASS: optional Experiments tab, default Off, lazy adapters, 10000 idle updates, clean removal')
