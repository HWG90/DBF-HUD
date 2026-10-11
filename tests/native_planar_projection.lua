-- Compare the shared plane snapshot with independent tilted pinhole projection.
-- No game calls, native pointers or GUI objects are involved.
local P=dofile('src/projection.lua')
local Scene=dofile('src/screen_scene.lua')
local function close(a,b)
 assert(math.abs(a-b)<1e-8*math.max(1,math.abs(a),math.abs(b)),tostring(a)..' ~= '..tostring(b))
end
local function uv(rows,x,y)
 local d=rows[7]*x+rows[8]*y+rows[9]
 return (rows[1]*x+rows[2]*y+rows[3])/d,(rows[4]*x+rows[5]*y+rows[6])/d
end
local function corners(frame,project)
 local out={}
 for i,p in ipairs({{frame.x,frame.y+frame.h},{frame.x+frame.w,frame.y+frame.h},{frame.x+frame.w,frame.y},{frame.x,frame.y}})do
  local q=project(p[1],p[2]);out[i]={x=q.x,y=1-q.y,depth=q.depth}
 end
 return out
end
local function camera(x,y,sx,sy)
 local wx=.18+(.82*x-.12*y)/1000
 local wy=1.13+(.15*x+.21*y)/1000
 local wz=.10+(.08*x+.96*y)/1000
 local d=wy+.08*wx+.03*wz
 return {x=.5+.34*wx/d+sx,y=.41+.40*wz/d+sy,depth=d}
end
math.randomseed(20261010)
local cases,points,boxes=0,0,0
for _,frame in ipairs({{x=-87,y=-152,w=174,h=304},{x=-73,y=-24,w=348,h=608},{x=42,y=-61,w=61,h=117}})do
 for _,shift in ipairs({{0,0},{.06,-.04},{1.2,.3}})do
  local function direct(x,y)return camera(x,y,shift[1],shift[2])end
  local snapshot=assert(P.native_panel_snapshot(frame,corners(frame,direct),.005))
  cases=cases+1
  for i=1,80 do
   -- Include points outside the frame: decoration and glyph overhang use them.
   local x=frame.x+(-.75+2.5*math.random())*frame.w
   local y=frame.y+(-.75+2.5*math.random())*frame.h
   local a,b=assert(snapshot.project(x,y)),direct(x,y)
   close(a.x,b.x);close(a.y,b.y);close(a.depth,b.depth);points=points+1
  end
  for i=1,24 do
   local image={x=frame.x+(-.2+1.2*math.random())*frame.w,y=frame.y+(-.2+1.2*math.random())*frame.h,
    w=(.05+.7*math.random())*frame.w,h=(.05+.7*math.random())*frame.h}
   local rows=assert(snapshot.image_rows(image.x,image.y,image.w,image.h))
   local crop={.125,.0625,.4375,.23046875};local atlas=Scene.atlas_rows(rows,crop)
   for _,p in ipairs({{0,0},{1,0},{1,1},{0,1},{.23,.67}})do
    local x=image.x+p[1]*image.w;local y=image.y+(1-p[2])*image.h
    local projected=direct(x,y);local u,v=uv(rows,projected.x,1-projected.y)
    close(u,p[1]);close(v,p[2])
    u,v=uv(atlas,projected.x,1-projected.y)
    close(u,crop[1]+crop[3]*p[1]);close(v,crop[2]+crop[4]*p[2])
   end
   boxes=boxes+1
  end
  assert(snapshot.image_rows(0,0,0,1)==nil and snapshot.image_rows(0,0,1,-1)==nil)
 end
end
local frame={x=0,y=0,w=100,h=100}
local function near_camera(x,y)
 local depth=.02+.001*x+.0002*y
 return {x=.5+.0002*x/depth,y=.5+.0002*y/depth,depth=depth}
end
local native=corners(frame,near_camera)
local near_snapshot=assert(P.native_panel_snapshot(frame,native,.05))
assert(near_snapshot.project(0,0)==nil,'Point below near plane accepted')
assert(near_snapshot.project(30,0)==nil,'Point exactly at near plane accepted')
assert(near_snapshot.project(-100,0)==nil,'Point behind camera accepted')
local visible=assert(near_snapshot.project(100,100));close(visible.depth,.14)
native[3].depth=native[3].depth+.05
assert(P.native_panel_snapshot(frame,native,.05)==nil,'Nonplanar depth snapshot accepted')
for _,bad in ipairs({0,-1,math.huge,0/0})do
 native=corners(frame,near_camera);native[2].depth=bad
 assert(P.native_panel_snapshot(frame,native,.05)==nil,'Invalid native depth accepted')
end
assert(P.native_panel_snapshot({x=0,y=0,w=0,h=100},corners(frame,near_camera),.05)==nil)
assert(P.native_panel_snapshot(frame,{{x=0,y=0,depth=1},{x=1,y=0,depth=1},{x=2,y=0,depth=1},{x=3,y=0,depth=1}},.05)==nil)
print(string.format('PASS native planar projection: %d tilted/resized/shaken cases, %d interior/exterior points, %d image/atlas crops, GUI/D3D Y agreement, near/behind refusal, invalid/nonplanar depth rejection',cases,points,boxes))
