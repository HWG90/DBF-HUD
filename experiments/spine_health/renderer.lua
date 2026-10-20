-- Retained world GUI segments: create once; recolor only on health changes.
local M={}
local function cross(a,b)return{a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]}end
local function unit(a)
 local n=math.sqrt(a[1]^2+a[2]^2+a[3]^2);assert(n>1e-6,'Spine degenerate segment basis')
 return {a[1]/n,a[2]/n,a[3]/n},n
end
local function same(a,b)
 if not a then return false end
 for i=1,#b do if math.abs(a[i]-b[i])>1e-6 then return false end end
 return true
end
function M.new(sr)
 local A,W,G,V,X=sr.Application,sr.World,sr.Gui,sr.Vector3,sr.Matrix4x4
 for _,name in ipairs({'bitmap','update_bitmap','move'})do assert(type(G[name])=='function','Spine GUI API missing: '..name)end
 local world,slots,material=nil,{},nil
 local self={stats={created=0,moved=0,updated=0,released=0},material='not selected'}
 function self.clear()
  -- The world destroys its GUI objects when retired. Never call stale handles.
  if world and world==A.main_world() then
   for _,s in ipairs(slots)do if s.gui then W.destroy_gui(world,s.gui);self.stats.released=self.stats.released+1 end end
  end
  slots={};world=nil
 end
 local function color(rgb,alpha)return sr.Color(alpha,rgb[1],rgb[2],rgb[3])end
 local function position()return V(-280,90,3)end
 function self.submit(frame,segments)
  assert(frame.world==A.main_world(),'Spine render world retired')
  if world~=frame.world then self.clear();world=frame.world end
  if not material then
   -- Prefer an already-loaded depth material; no archive reload is attempted.
   local depth='mods/dbf_hud/materials/depth_fill'
   material=A.can_get and A.can_get('material',depth) and depth or 'content/ui/shared/material/gui_fill'
   self.material=material
  end
  for i,g in ipairs(segments)do
   local up,length=unit({g.top[1]-g.bottom[1],g.top[2]-g.bottom[2],g.top[3]-g.bottom[3]})
   local dot=frame.right[1]*up[1]+frame.right[2]*up[2]+frame.right[3]*up[3]
   local right=unit({frame.right[1]-up[1]*dot,frame.right[2]-up[2]*dot,frame.right[3]-up[3]*dot})
   local forward=cross(up,right)
   local pose={right[1]*g.width,right[2]*g.width,right[3]*g.width,forward[1],forward[2],forward[3],
    up[1]*length,up[2]*length,up[3]*length,g.bottom[1],g.bottom[2],g.bottom[3]}
   local s=slots[i]
   if not s then
    s={};slots[i]=s
    local tm=X.from_axes(V(pose[1],pose[2],pose[3]),V(pose[4],pose[5],pose[6]),V(pose[7],pose[8],pose[9]),V(pose[10],pose[11],pose[12]))
    s.gui=assert(W.create_world_gui(world,tm,1000,1000),'Spine world GUI unavailable')
    s.pose=pose;self.stats.created=self.stats.created+1
    local function plate(x,y,w,h,z,r,g,b)
     G.bitmap(s.gui,material,V(x,y,z),sr.Vector2(w,h),sr.Color(255,r,g,b))
    end
    -- Broad metal vertebrae around a narrow recessed luminous channel. The
    -- overlapping rear rail links the housings instead of loose cyan tiles.
    plate(-210,-190,420,1380,0,22,28,31)
    plate(-550,-35,1100,1070,1,39,46,49)
    plate(-640,150,140,700,2,71,79,82);plate(500,150,140,700,2,71,79,82)
    plate(-500,0,160,1000,2,94,103,105);plate(340,0,160,1000,2,94,103,105)
    plate(-340,0,680,1000,2,11,25,28)
    plate(-500,0,1000,70,3,135,145,145)
    plate(-500,930,1000,70,3,135,145,145)
    s.fill=assert(G.bitmap(s.gui,material,position(),sr.Vector2(560,820),color(g.color,255)),'Spine retained bitmap unavailable')
   elseif not same(s.pose,pose)then
    local tm=X.from_axes(V(pose[1],pose[2],pose[3]),V(pose[4],pose[5],pose[6]),V(pose[7],pose[8],pose[9]),V(pose[10],pose[11],pose[12]))
    G.move(s.gui,tm);s.pose=pose;self.stats.moved=self.stats.moved+1
   end
   local ink={g.fill,g.color[1],g.color[2],g.color[3]}
   if not same(s.ink,ink)then
    G.update_bitmap(s.gui,s.fill,material,position(),sr.Vector2(560,math.max(.001,g.fill*820)),color(g.color,g.fill>0 and 255 or 0))
    s.ink=ink;self.stats.updated=self.stats.updated+1
   end
  end
 end
 return self
end
return M
