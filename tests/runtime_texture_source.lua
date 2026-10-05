local ffi=require('ffi')
local M=dofile('src/runtime_texture_source.lua')
local checks=0
local function check(v)assert(v);checks=checks+1 end
local engine=ffi.new('uint8_t[256]');ffi.fill(engine,256,0x33)
local array=ffi.new('uintptr_t[1]',ffi.cast('uintptr_t',engine))
local function inspect()
 return {kind=0,format=0,count=1,width=8,height=8,array=tonumber(ffi.cast('uintptr_t',array)),backing=tonumber(array[0])}
end
local original=tonumber(array[0]);local resource={}
local bytes=string.rep(string.char(1,2,3,255),64)
local record=M.prepare(bytes,8,8);local captured
M.submit(resource,record,inspect,function(r,c)
 check(r==resource and tonumber(array[0])==c.pointer)
 captured=tonumber(array[0]);check(ffi.string(ffi.cast('void*',captured),256)==bytes)
end)
check(record.state=='submitted' and tonumber(array[0])==original)
check(ffi.string(engine,256)==string.rep(string.char(0x33),256))
collectgarbage('collect');check(ffi.string(ffi.cast('void*',captured),256)==bytes)
local failed=M.prepare(bytes,8,8)
check(not pcall(M.submit,resource,failed,inspect,function()error('queue rejected')end))
check(tonumber(array[0])==original and failed.state=='failed' and failed.pixels~=nil)
check(not pcall(M.submit,resource,record,inspect,function()error('duplicate submit')end))
check(not pcall(M.prepare,bytes:sub(2),8,8))
local mismatch=M.prepare(bytes,8,8)
local function wrong()local h=inspect();h.width=9;return h end
check(not pcall(M.submit,resource,mismatch,wrong,function()error('must not submit')end))
check(tonumber(array[0])==original and mismatch.state=='prepared')
local large=M.prepare(string.rep(string.char(9,8,7,255),520*640),520,640)
check(ffi.sizeof(large.pixels)==520*640*4 and large.capacity==520*640*4)
print('owned texture source: '..checks..' checks passed; no game APIs called')

local full=M.prepare(string.rep(string.char(10,20,30,255),1448*1086),1448,1086)
assert(full.capacity==1448*1086*4 and ffi.sizeof(full.pixels)==full.capacity)
assert(ffi.string(full.pixels+full.capacity-4,4)==string.char(10,20,30,255))
assert(not pcall(M.prepare,'',2049,1))
print('PASS current artwork dimensions and upper size bound')
