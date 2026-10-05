-- Display latch for an observed shot; not physical casing occupancy.
local M={}
function M.new() return {} end
function M.step(s,m)
 if not m or m.resource_hex~='9f80d67a12a7e40f' or type(m.value)~='number' then
  s.key=nil;s.count=nil;s.spent=nil;return
 end
 local key=tostring(m.id)..'/'..tostring(m.unit_ref)
 if s.key~=key or m.value>0 then s.spent=false
 elseif s.count and s.count>0 and m.value==0 then s.spent=true end
 m.recoilless_spent=s.spent==true
 s.key=key;s.count=m.value
end
return M
