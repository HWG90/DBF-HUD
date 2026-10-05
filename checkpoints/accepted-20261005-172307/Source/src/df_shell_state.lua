-- Observed firing status, never a claim about physical hull occupancy/ejection.
local M={}
local function loaded(n,mode,side) return mode=='VOLLEY' and n>=2 or mode~='VOLLEY' and n>=(3-side) end
function M.new() return {} end
function M.step(s,m)
 if not m or m.resource_hex~='72170a55a1f37ff1' or type(m.value)~='number' then
  s.key=nil;s.count=nil;s.spent=nil;return
 end
 local key=tostring(m.id)..'/'..tostring(m.unit_ref)
 if s.key~=key or not s.spent or m.value>s.count then s.spent={false,false} end
 if s.key==key and s.count and m.value<s.count then
  for side=1,2 do
   if loaded(s.count,s.mode,side) and not loaded(m.value,m.fire_mode,side) then s.spent[side]=true end
  end
 end
 for side=1,2 do if loaded(m.value,m.fire_mode,side) then s.spent[side]=false end end
 m.df_shell_spent={s.spent[1],s.spent[2]}
 s.key=key;s.count=m.value;s.mode=m.fire_mode
end
return M
