-- Ammo-observed, once-per-burst cosmetic state. No input or memory writes.
local M={}
function M.new() return {cooldown=0} end
function M.step(s,m,now,enabled,random)
 local id=m and (m.unit_ref or m.id or m.resource_hex)
 if enabled==false or not m or m.resource_hex~='11c27d3babb38956' then
  s.id=nil;s.value=nil;s.last=nil;s.start=nil;s.rolled=nil;s.until_at=nil;return false
 end
 if s.id~=id or (s.time and now<s.time) then
  s.id=id;s.value=nil;s.last=nil;s.start=nil;s.rolled=nil;s.until_at=nil
 end
 s.time=now
 local value=m.value
 if s.value and (value>s.value or value==0 or (s.last and now-s.last>.35)) then
  s.last=nil;s.start=nil;s.rolled=nil;s.until_at=nil
 end
 if s.value and value<s.value and value>0 then
  if not s.last then s.start=now end
  s.last=now
  if not s.rolled and now-s.start>=4 then
   s.rolled=true
   if now>=s.cooldown and (random or math.random)()<.15 then
    s.until_at=now+1.1;s.cooldown=now+45
   end
  end
 end
 s.value=value
 return s.until_at~=nil and now<s.until_at
end
return M
