local upright=(function()
-- Observed six-slot presentation. Count transitions do not identify physical chambers.
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

end)()
-- Approved count-driven cylinder display; animation duration is presentation only.
local M={supports_speedloader=false,supports_ejection=false}
function M.new() return {} end
local function nextslot(i) return (i-2)%6+1 end
function M.step(s,m,clock)
 s.upright=s.upright or upright.new();upright.step(s.upright,m)
 if not m or m.resource_hex~='8d3d52a3b2f19402' or type(m.value)~='number' or m.value%1~=0 or m.value<0 or m.value>6 then
  s.key=nil;s.count=nil;s.loaded=nil;return
 end
 local previous_turns=s.turns or 0
 local key=tostring(m.id)..'/'..tostring(m.unit_ref)
 if key~=s.key then
  s.loaded={false,false,false,false,false,false};s.bottom=1;s.turns=0;s.render_turns=0;s.animation=nil
  local i=1;for k=1,m.value do s.loaded[i]=true;i=nextslot(i) end
 elseif m.value<s.count then
  for k=1,s.count-m.value do
   -- Advance over unknown empty slots if entering a partial initial state.
   for j=1,6 do if s.loaded[s.bottom] then break end;s.bottom=nextslot(s.bottom);s.turns=s.turns+1 end
   s.loaded[s.bottom]=false;s.bottom=nextslot(s.bottom);s.turns=s.turns+1
  end
 elseif m.value>s.count then
  local needed=m.value-s.count;local i=s.bottom
  for j=1,6 do if not s.loaded[i] and needed>0 then s.loaded[i]=true;needed=needed-1 end;i=nextslot(i) end
 end
 -- Position the next live round at bottom, including partial-load reset cases.
 if m.value>0 then for j=1,6 do if s.loaded[s.bottom] then break end;s.bottom=nextslot(s.bottom);s.turns=s.turns+1 end end
 -- Immediate indexing: no intermediate orientation frames or per-shot raster rebuild sequence.
 s.animation=nil;s.render_turns=s.turns
 m.cylinder_render_angle=-(s.turns%6)*math.pi/3
 m.cylinder_slots={};for i=1,6 do m.cylinder_slots[i]=s.loaded[i] end
 m.cylinder_turns=s.turns;m.cylinder_bottom=s.bottom;m.cylinder_angle=-s.turns*math.pi/3
 s.key=key;s.count=m.value
end
return M
