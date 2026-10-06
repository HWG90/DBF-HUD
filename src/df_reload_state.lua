-- Weapon reload events only. Ammo zero and key presses are not reload events.
local M={}
function M.new()return {}end
function M.step(s,m,event)
 if not m or m.resource_hex~='72170a55a1f37ff1' then s.key=nil;s.open=false;s.count=nil;return end
 local key=tostring(m.id)..'/'..tostring(m.unit_ref)
 if s.key~=key then s.key=key;s.open=false;s.count=nil end
 if event and event.verified==true and event.weapon_id==m.id and event.unit_ref==m.unit_ref then
  if event.phase=='start' then s.open=true
  elseif event.phase=='complete'or event.phase=='cancel' then s.open=false end
 end
 -- Confirmed ammunition arrival closes the visual even if a completion event is missed.
 if type(m.value)=='number' and type(s.count)=='number' and m.value>s.count then s.open=false end
 s.count=m.value;m.df_ejector_open=s.open==true
end
return M
