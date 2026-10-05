-- Retirement requires adapter acknowledgments, never elapsed-frame guesses.
-- Not connected to native destruction until that contract is measured.
local M={}
function M.new(adapter,store)
 assert(type(adapter.upload_done)=='function' and type(adapter.detached)=='function' and type(adapter.draws_done)=='function' and type(adapter.destroy)=='function','retirement acknowledgments required')
 local self={pending={},failed={}}
 function self.retire(record)
  assert(record.resource and record.bytes and not record.destroyed,'owned live resource required')
  if record.retiring then return end
  record.retiring=true;self.pending[#self.pending+1]=record
 end
 function self.step()
  for i=#self.pending,1,-1 do
   local r=self.pending[i]
   if not r.release_failed and adapter.upload_done(r)==true and adapter.detached(r)==true and adapter.draws_done(r)==true then
    local ok,done=pcall(adapter.destroy,r)
    -- An exception may follow partial native destruction: never retry it.
    if not ok or done~=true then r.release_failed=true;self.failed[#self.failed+1]=r
    else
     r.destroyed=true;store.bytes=store.bytes-r.bytes
     -- Caller removes cache/publication entries before retire().
     r.resource=nil;r.source=nil;r.rgba=nil;r.prefix=nil
     table.remove(self.pending,i)
    end
   end
  end
  return #self.pending==0
 end
 return self
end
return M
