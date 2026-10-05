-- Candidate for the captured texture-kind0 pointer-snapshot queue contract.
-- Keep every prepared record alive until process exit, including failed submits.
local ffi=require('ffi')
local M={}
function M.prepare(bytes,width,height)
 assert(type(width)=='number' and type(height)=='number' and width%1==0 and height%1==0 and width>=1 and height>=1 and width<=2048 and height<=2048,'invalid dimensions')
 local count=width*height*4
 assert(type(bytes)=='string' and #bytes==count,'invalid RGBA8 byte count')
 local pixels=ffi.new('uint8_t[?]',count)
 ffi.copy(pixels,bytes,count)
 for offset=0,count-1,4096 do
  local n=math.min(4096,count-offset)
  assert(ffi.string(pixels+offset,n)==bytes:sub(offset+1,offset+n),'owned source copy failed')
 end
 return {pixels=pixels,capacity=count,width=width,height=height,
  pointer=tonumber(ffi.cast('uintptr_t',pixels)),state='prepared'}
end
function M.submit(resource,record,inspect,queue)
 assert(record.state=='prepared' and record.pixels and ffi.sizeof(record.pixels)==record.capacity,'fresh owned buffer required')
 local before=inspect(resource)
 assert(before.kind==0 and before.format==0 and before.count==1 and before.width==record.width and before.height==record.height,'unsupported texture descriptor')
 assert(before.array>65535 and before.array<2^47 and before.array%8==0 and before.backing>65535 and before.backing<2^47,'invalid backing array')
 assert(before.backing~=record.pointer,'source aliases engine allocation')
 local slot=ffi.cast('uintptr_t*',before.array)
 assert(tonumber(slot[0])==before.backing,'backing changed before submission')
 -- The measured producer copies the pointer value into its command, not pixels.
 -- Only redirect that value during the synchronous API call. Never write the
 -- full image into the engine's allocation, or leave our buffer owned by it.
 slot[0]=record.pointer
 record.state='submitting'
 local ok,why=pcall(queue,resource,record)
 slot[0]=before.backing
 local after=inspect(resource)
 assert(after.array==before.array and after.backing==before.backing,'engine backing restoration failed')
 record.state=ok and 'submitted' or 'failed'
 if not ok then error(why,0) end
 return true -- Submission only; the caller must establish consumption separately.
end
return M
