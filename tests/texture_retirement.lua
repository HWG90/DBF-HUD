local M=dofile('src/texture_retirement.lua')
local store={bytes=0};local calls=0
local adapter={upload_done=function(r)return r.upload end,detached=function(r)return r.unbound end,draws_done=function(r)return r.fence end,destroy=function(r)calls=calls+1;return true end}
local q=M.new(adapter,store)
for i=1,1000 do
 local r={resource={},source={},rgba='pixels',bytes=4096};store.bytes=store.bytes+4096
 q.retire(r);q.retire(r);assert(not q.step() and calls==i-1)
 r.upload=true;assert(not q.step() and calls==i-1)
 r.unbound=true;assert(not q.step() and calls==i-1)
 r.fence=true;assert(q.step() and calls==i and store.bytes==0 and not r.resource and not r.source)
end
local r={resource={},bytes=8,upload=true,unbound=true,fence=true};store.bytes=8
adapter.destroy=function()calls=calls+1;error('partial native failure')end
q.retire(r);assert(not q.step());local n=calls;assert(not q.step() and calls==n and store.bytes==8)
print('PASS 1000 retirements bounded memory, three acknowledgment gates, duplicate retirement, partial failure quarantine')
