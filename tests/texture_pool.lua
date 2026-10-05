local M=dofile('src/texture_pool.lua');local serial,completed,destroys=1,0,0
local store={bytes=0,resources={},cache={},images={}};local attached=false
local adapter={retirement_token=function()assert(not attached);return serial end,retirement_done=function(t)return completed>t end,destroy_retired=function(r,t,detached)assert(detached and not attached and completed>t);destroys=destroys+1;return true end}
local q=M.new(adapter,store);q.register_consumer('gui',function()attached=false;return true end)
local function record(i)local r={bytes=4,ready=true,consumed=true,resource={},rgba=tostring(i),source={}};store.bytes=store.bytes+4;store.resources[#store.resources+1]=r;store.cache[r.rgba]={r=r};store.images.test=r;return r end
q.publish({test=record(0)})
for i=1,1000 do
 attached=true;local r=record(i);q.publish({test=r,alias=r});assert(store.bytes==8 and not attached)
 completed=serial;assert(not q.step() and store.bytes==8)
 completed=serial+1;assert(q.step() and store.bytes==4 and #store.resources==1 and store.active.test==r)
 serial=serial+2
end
q.close();completed=serial+1;assert(q.step() and store.bytes==0 and #store.resources==0 and destroys==1001)
local r=record(1002);local newer=M.new(adapter,store);newer.publish({test=r});attached=true
store.consumers.bad=function()return false end
assert(not pcall(newer.publish,{}) and store.active.test==r and store.bytes==4)
print('PASS 1000 atomic swaps, bounded bytes/resources, shared aliases, completion delay, teardown and refused detach')
