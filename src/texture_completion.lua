-- Read-only completion adapter for the measured renderer path.
-- No guessed frame waits, no COM/native function calls.
local M={}
local completion='83b9f000000001760948c7c0ffffffffc3cc488b81e8000000f0830c2400488b00c3'
local function unhex(s)return(s:gsub('..',function(v)return string.char(tonumber(v,16))end))end
function M.new(backend,base)
 local function read(a,n)return assert(backend.read(a,n),'completion metadata unavailable')end
 local function uint(a,n)
  local b=read(a,n);assert(#b==n,'short completion read');local v=0
  for i=n,1,-1 do v=v*256+b:byte(i)end
  assert(v<2^53,'completion integer out of exact range');return v
 end
 local function ptr(a)local p=uint(a,8);assert(p>65535 and p<2^47,'invalid completion pointer');return p end
 local function resolve()
  assert(read(base+0x4184ca,3)==string.char(0x48,0x8b,0x0d),'unsupported context lookup')
  local context=ptr(base+0x2362468)
  local frontend=ptr(context+0x338)
  local factory=ptr(frontend+0x1168)
  local fence=ptr(factory+0x658)
  local query=ptr(ptr(fence)+0x40)
  assert(read(query,34)==unhex(completion),'unverified completion query')
  return factory,fence
 end
 local self={}
 function self.capture()
  local factory,fence=resolve()
  return {factory=factory,fence=fence,serial=uint(factory+0x668,8)}
 end
 function self.done(token)
  local factory,fence=resolve()
  assert(token.factory==factory and token.fence==fence,'completion owner changed')
  -- UINT64_MAX/device removed is failure, never successful completion.
  assert(uint(fence+0xf0,4)<=1,'completion device unavailable')
  local completed=uint(ptr(fence+0xe8),8)
  return completed>token.serial
 end
 return self
end
return M
