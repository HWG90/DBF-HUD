-- Batch publication and reclamation. Native adapter owns completion/release.
local M={}
function M.new(adapter,store)
 store.consumers=store.consumers or {};store.retirements=store.retirements or {};store.active=store.active or {}
 local self={closing=false}
 function self.register_consumer(id,detach)
  assert(not store.consumers[id] and type(detach)=='function','unique material owner required')
  store.consumers[id]=detach
  return function()assert(detach()==true,'material owner did not detach');store.consumers[id]=nil end
 end
 local function evict(record)
  for size,bucket in pairs(store.cache or {})do for pixels,r in pairs(bucket)do if r==record then bucket[pixels]=nil end end;if next(bucket)==nil then store.cache[size]=nil end end
  for name,r in pairs(store.images or {})do if r==record then store.images[name]=nil end end
 end
 function self.discard(record)
  assert(record.ready and record.consumed and record.resource,'unready unpublished resource')
  for _,r in pairs(store.active)do assert(r~=record,'cannot discard active artwork')end
  if not record.retiring then
   record.retiring=true;record.retirement_token=adapter.retirement_token(record)
   store.retirements[#store.retirements+1]=record;evict(record)
  end
 end
 function self.publish(prepared)
  assert(not self.closing,'texture pool retiring')
  local keep={};for _,r in pairs(prepared)do assert(r.ready and r.consumed and r.resource,'batch contains unready resource');keep[r]=true end
  -- Destroy GUI/material owners before exposing replacements. A failure leaves
  -- old publication and resources retained; never frees through uncertain refs.
  for _,detach in pairs(store.consumers)do assert(detach()==true,'material detachment not acknowledged')end
  local retiring={}
  for _,r in ipairs(store.resources)do if r.ready and r.consumed and r.resource and not keep[r] and not retiring[r] and not r.retiring then
   retiring[r]=true;r.retiring=true;r.retirement_token=adapter.retirement_token(r)
   store.retirements[#store.retirements+1]=r;evict(r)
  end end
  store.active=prepared
 end
 function self.step()
  for i=#store.retirements,1,-1 do
   local r=store.retirements[i]
   if not r.release_failed and adapter.retirement_done(r.retirement_token)==true then
    local ok,done=pcall(adapter.destroy_retired,r,r.retirement_token,true)
    if not ok or done~=true then r.release_failed=true;store.failure=tostring(done)
    else
     store.bytes=store.bytes-r.bytes;r.destroyed=true;r.resource=nil;r.rgba=nil;r.source=nil;r.prefix=nil
     for j=#store.resources,1,-1 do if store.resources[j]==r then table.remove(store.resources,j)end end
     table.remove(store.retirements,i)
    end
   end
  end
  return #store.retirements==0
 end
 function self.close()if not self.closing then self.publish({});self.closing=true end end
 return self
end
return M
