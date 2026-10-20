-- Candidate for the captured texture-kind0 pointer-snapshot queue contract.
-- Keep every prepared record alive until process exit, including failed submits.
local ffi=require('ffi')
local M={}
-- The game's Lua allocator occupies a constrained low-address arena. Bulk
-- upload bytes do not need GC addresses: retain a small owner in Lua instead.
if not pcall(ffi.typeof,'dbf_hud_upload_allocation_v1')then ffi.cdef[[
 typedef struct {uint8_t *data;size_t bytes;} dbf_hud_upload_allocation_v1;
 void *dbf_hud_upload_VirtualAlloc(void*,size_t,uint32_t,uint32_t) __asm__("VirtualAlloc");
 int dbf_hud_upload_VirtualFree(void*,size_t,uint32_t) __asm__("VirtualFree");
 int dbf_hud_upload_memcmp(const void*,const void*,size_t) __asm__("memcmp");
]]end
local kernel,crt=ffi.load('kernel32'),ffi.load('msvcrt')
local function release(allocation)
 if allocation.data~=nil then
  kernel.dbf_hud_upload_VirtualFree(allocation.data,0,0x8000)
  allocation.data=nil
 end
end
local function allocate(count)
 local owner=ffi.gc(ffi.new('dbf_hud_upload_allocation_v1'),release)
 local pointer=kernel.dbf_hud_upload_VirtualAlloc(nil,count,0x3000,4)
 assert(pointer~=nil,'HUD upload allocation failed')
 if tonumber(ffi.cast('uintptr_t',pointer))<4294967296 then
  kernel.dbf_hud_upload_VirtualFree(pointer,0,0x8000)
  error('HUD upload allocation must stay outside Lua address space',0)
 end
 owner.data=ffi.cast('uint8_t*',pointer);owner.bytes=count
 return owner
end
local function owned(record)
 if record.allocation then
  return ffi.istype('dbf_hud_upload_allocation_v1',record.allocation)
   and record.allocation.data==record.pixels and tonumber(record.allocation.bytes)==record.capacity
   and record.pointer==tonumber(ffi.cast('uintptr_t',record.pixels))
 end
 -- A hot reload can finish an already prepared legacy upload without moving
 -- a buffer that a renderer command may still reference.
 return ffi.sizeof(record.pixels)==record.capacity
end
function M.prepare(bytes,width,height)
 assert(type(width)=='number' and type(height)=='number' and width%1==0 and height%1==0 and width>=1 and height>=1 and width<=2048 and height<=2048,'invalid dimensions')
 local count=width*height*4
 assert(type(bytes)=='string' and #bytes==count,'invalid RGBA8 byte count')
 local allocation=allocate(count)
 local pixels=allocation.data
 ffi.copy(pixels,bytes,count)
 assert(crt.dbf_hud_upload_memcmp(pixels,bytes,count)==0,'owned source copy failed')
 return {pixels=pixels,allocation=allocation,capacity=count,width=width,height=height,
  pointer=tonumber(ffi.cast('uintptr_t',pixels)),state='prepared'}
end
-- A completed upload can change its CPU owner without touching the texture.
-- The caller must prove the renderer fence completed before dropping the old
-- source; queue-consumed alone is not that proof.
function M.promote(record,bytes,completed)
 assert(completed==true,'GPU completion required before source migration')
 assert(record.state=='submitted' and record.pixels and owned(record),'owned submitted source required')
 assert(type(bytes)=='string' and #bytes==record.capacity,'migration byte count changed')
 assert(crt.dbf_hud_upload_memcmp(record.pixels,bytes,record.capacity)==0,'migration source differs')
 if record.allocation then return record,false end
 local next_record=M.prepare(bytes,record.width,record.height)
 next_record.state=record.state
 return next_record,true
end
function M.submit(resource,record,inspect,queue)
 assert(record.state=='prepared' and record.pixels and owned(record),'fresh owned buffer required')
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
