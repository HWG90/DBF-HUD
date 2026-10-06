local ffi=require('ffi')
local M=dofile('src/runtime_texture_native.lua')
local checks=0;local function check(v,s)assert(v,s);checks=checks+1 end
local unit=newproxy();local material=newproxy();local mesh=newproxy()
local boxed=false;local present=true;local calls=0;local refreshes=0;local id_reads=0
local sr={Renderer={},Material={},Mesh={},Unit={},IdString64={to_hex=function(x)return x end},IdString32={to_hex=function(x)return x end},
 Application={worlds=function()return{1}end},World={units=function()return present and {unit}or{}end}}
sr.Renderer.create_resource=function()error('must not allocate in these tests')end
sr.Renderer.update_texture_base64=function()error('must not upload in these tests')end
sr.Material.set_resource=function(h,slot,r)assert(h==material and slot=='emissive_map' and r=='owned');calls=calls+1 end
sr.Mesh.refresh_instance_hash=function(h)assert(h==mesh);refreshes=refreshes+1 end
sr.Unit.resource_name=function()return'be0be6b1875a4a66'end;sr.Unit.num_meshes=function()return 1 end
sr.Unit.mesh=function()return mesh end;sr.Mesh.num_materials=function()return 1 end
sr.Mesh.material_slot_id=function()return'a340edce'end;sr.Mesh.material=function()return material end
sr.Material.id64=function()id_reads=id_reads+1;return'aa43784ff664c0f5'end
local addresses={[sr.Renderer.create_resource]=100000,[sr.Renderer.update_texture_base64]=200000,
 [sr.Material.set_resource]=300000,[sr.Mesh.refresh_instance_hash]=400000}
local code={[100000]='488bd1e9a8fbffffcccccccccccccccc',[200000]='48895c240848896c2410488974241848',
 [300000]='48895c24184889742420574883ec20ba',[400000]='4883ec28ba01000000ff15b9eff60048'}
local old=package.loaded['jit.util'];package.loaded['jit.util']={funcinfo=function(fn)return{addr=addresses[fn]}end}
local function header(size,values)
 local b=ffi.new('uint8_t[?]',size);for offset,value in pairs(values)do ffi.cast('uint32_t*',b+offset)[0]=value end;return ffi.string(b,size)
end
local backend={module=function()return 10000000 end,read=function(a,n)
 if a==10000000 then return header(64,{[60]=128})end
 if a==10000128 then return 'PE\0\0'..string.rep('\0',4)..header(4,{[0]=0x6ab382e4})end
 if code[a]then return(code[a]:gsub('..',function(x)return string.char(tonumber(x,16))end))end
 if a==tonumber(ffi.cast('uintptr_t',material))then return header(64,{[0]=boxed and 0x6f6f4d64 or 0})end
 error('unexpected memory read')
end}
local n=M.new(sr,backend)
local spec={kind='world_mesh',unit=unit,unit_resource='be0be6b1875a4a66',meshes={1},material_slot='a340edce',material_id='aa43784ff664c0f5',texture_slot='emissive_map'}
local t=n.target(spec);check(n.valid(t),'real mesh material recognized')
boxed=true;local previous=id_reads;check(not n.valid(t) and id_reads==previous,'boxed return rejected before Material API');boxed=false
check(not pcall(n.bind,t,'owned') and calls==0,'update phase binding rejected')
n.set_phase(true);n.bind(t,'owned');check(calls==1 and refreshes==1,'world binding refreshes affected mesh')
spec.kind='scope';local scope=n.target(spec);n.bind(scope,'owned');check(calls==2 and refreshes==1,'scope keeps measured direct binding behavior')
present=false;check(not n.valid(t),'retired unit rejected');check(not pcall(n.bind,t,'owned') and calls==2,'stale target cannot bind')
spec.kind='gui';check(not pcall(n.target,spec),'unverified GUI targets rejected')
check(not pcall(n.validate_image,{texture_slot='lens_occlusion_texture'},{rgba=string.char(10,10,10,255)}),'gray expansion rejected for native red mask')
check(pcall(n.validate_image,{texture_slot='lens_occlusion_texture'},{rgba=string.char(10,0,0,255)}),'native red channel preserved')
code[300000]=string.rep('00',16);check(not pcall(M.new,sr,backend),'changed native wrapper rejected')
package.loaded['jit.util']=old
print('native texture contracts: '..checks..' passed')
