-- Isolated feasibility prototype. Not included in maintained HUD bundles.
-- Adapter owns validated local-player identity, health and rendering lifecycle.
local M={}
local function finite(x)return type(x)=='number' and x==x and math.abs(x)<math.huge end
local function point(p)
 assert(type(p)=='table' and finite(p[1]) and finite(p[2]) and finite(p[3]),'invalid bone point')
 return p
end
local function mix(a,b,t)return {a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t}end
-- Three bone positions, offset along one shared anatomical back normal.
-- No guessed indices, native pointers, gameplay writes or animation overrides.
function M.geometry(bones,current,maximum)
 assert(finite(current) and finite(maximum) and maximum>0,'health unavailable')
 local a,b,c=point(bones.spine1),point(bones.spine2),point(bones.chest)
 local function length(x,y)return math.sqrt((x[1]-y[1])^2+(x[2]-y[2])^2+(x[3]-y[3])^2)end
 local ab,bc=length(a,b),length(b,c)
 assert(ab>.001 and bc>.001 and ab+bc<1.2,'unsupported spine geometry')
 local fraction=math.max(0,math.min(1,current/maximum))
 local color=fraction<=.25 and {255,55,35} or fraction<=.5 and {255,180,40} or {55,235,255}
 local split=ab/(ab+bc)
 local function along(t)
  -- Keep the lumbar anchor; extend the upper run toward the shoulders.
  t=t*1.5
  if t<=split then return mix(a,b,t/split)end
  return mix(b,c,(t-split)/(1-split))
 end
 local segments={}
 for i=1,8 do
  segments[i]={bottom=along((i-1+.12)/8),top=along((i-.12)/8),
   fill=math.max(0,math.min(1,fraction*8-(i-1))),color=color,width=.048}
 end
 return segments
end
function M.new(adapter)
 local owner,enabled,failed=nil,false,false
 local self={status='disabled'}
 local function clear()adapter.clear();owner=nil end
 function self.enable(value)
  clear();enabled=value==true;failed=false;self.status=enabled and 'ready' or 'disabled'
 end
 -- Call from existing owning render callback only. Disabled path is idle.
 -- frame() must return a generation-validated local avatar and same-owner health.
 -- bones() copies ONLY spine1/spine2/chest positions, with a local rear offset.
 function self.draw()
  if not enabled or failed then return end
  local ok,why=pcall(function()
   local frame=adapter.frame()
   if not frame or not frame.local_owner or not frame.third_person then clear();self.status='hidden';return end
   assert(frame.identity~=nil,'owner identity unavailable')
   if owner~=frame.identity then clear();owner=frame.identity end
   local geometry=M.geometry(adapter.bones(frame),frame.health,frame.max_health)
   assert(adapter.valid(frame)==true,'owner changed during read')
   adapter.submit(frame,geometry);self.status='submitted; visual acceptance pending'
  end)
  if not ok then failed=true;pcall(clear);self.status=tostring(why)end
 end
 function self.invalidate()clear();self.status='invalidated'end
 function self.release()enabled=false;clear();self.status='released'end
 return self
end
return M
