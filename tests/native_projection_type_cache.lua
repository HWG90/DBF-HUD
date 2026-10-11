-- Exercise the maintained native backend with real LuaJIT types and buffers.
-- The function-pointer cast returns a Lua callback; dummy addresses are never called.
local real_ffi=require('ffi')
local signature='float* (*)(float*, const void*, const float*)'
local parses,casts,calls=0,0,0
local project_type
local ffi={}
for key,value in pairs(real_ffi)do ffi[key]=value end
function ffi.load(name)
 assert(name=='kernel32'or name=='user32')
 return {dbf_hud_process=function()return real_ffi.cast('void*',65536)end}
end
function ffi.typeof(value)
 if value==signature then
  parses=parses+1
  project_type=real_ffi.typeof(value)
  return project_type
 end
 return real_ffi.typeof(value)
end
function ffi.cast(kind,value)
 -- Catch the original leak before it can allocate thousands of anonymous types.
 assert(kind~=signature,'Anonymous projection signature reparsed for each point')
 if kind==project_type then
  assert(value==123456 or value==234567,'Unexpected projection wrapper address')
  casts=casts+1
  local offset=value==123456 and 1000 or 2000
  return function(out,camera,input)
   assert(tonumber(real_ffi.cast('uintptr_t',camera))==345678)
   assert(tonumber(real_ffi.cast('uintptr_t',out))%16==0)
   assert(tonumber(real_ffi.cast('uintptr_t',input))%16==0)
   calls=calls+1
   out[0],out[1],out[2]=input[0]+offset,input[1]+offset,.5
   return out
  end
 end
 return real_ffi.cast(kind,value)
end
local original_require=require
require=function(name)if name=='ffi'then return ffi end;return original_require(name)end
local ok,backend=pcall(function()return dofile('src/memory.lua').native()end)
require=original_require
assert(ok,backend)
assert(parses==0 and casts==0,'Projection type must initialize lazily')
assert(#backend.projection_buffers==2,'Aligned buffers lost their storage owners')
for i=1,50000 do
 local x,y,z=backend.project_camera(123456,345678,i,-i,i%17)
 assert(x==i+1000 and y==-i+1000 and z==.5,'Projection callback output changed')
end
assert(parses==1 and casts==1 and calls==50000,'Per-point CType or function cast regression')
for i=1,10000 do
 local x,y,z=backend.project_camera(234567,345678,i,-i,i%17)
 assert(x==i+2000 and y==-i+2000 and z==.5,'Changed wrapper output not used')
end
assert(parses==1 and casts==2 and calls==60000,'Changed wrapper did not reuse the function CType')
backend.close()
print('PASS native projection type cache: 60000 real-buffer calls, one anonymous CType parse, one callable cast per stable wrapper address, changed wrapper refreshed, aligned storage retained, no dummy native calls')
