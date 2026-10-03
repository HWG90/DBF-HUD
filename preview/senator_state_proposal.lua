-- Preview-only six-slot presentation. Count transitions do not identify physical chambers.
local M={supports_speedloader=false,supports_ejection=false}
function M.new() return {} end
function M.step(s,m)
 if not m or m.resource_hex~='8d3d52a3b2f19402' or type(m.value)~='number' or m.value<0 or m.value>6 or m.value%1~=0 then
  s.key=nil;s.count=nil;s.spent=nil;return
 end
 local key=tostring(m.id)..'/'..tostring(m.unit_ref)
 if s.key~=key then s.spent={false,false,false,false,false,false} end
 local transition
 if s.key==key and s.count then
  if m.value<s.count then
   transition='decrease'
   for i=7-s.count,6-m.value do s.spent[i]=true end
  elseif m.value>s.count then transition='increase' end
 end
 local slots={}
 for i=1,6 do
  local loaded=i>6-m.value
  if loaded then s.spent[i]=false end
  slots[i]={loaded=loaded,projectile=loaded,case=loaded or s.spent[i],observed_spent=s.spent[i]}
 end
 m.senator_slots=slots;m.senator_count_transition=transition
 s.key=key;s.count=m.value
end
return M
