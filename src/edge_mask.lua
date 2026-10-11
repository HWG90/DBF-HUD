-- One cached full-UV alpha image, regenerated only after appearance edits.
local M={width=128,height=256,resource='mods/dbf_hud/textures/primary_edge_mask_dynamic_v2'}
local function number(v,default,low,high,step)
 if type(v)~='number'or v~=v or math.abs(v)==math.huge then v=default end
 return math.floor(math.max(low,math.min(high,v))/step+.5)*step
end
function M.settings(c)
 c=c or {}
 return {width=number(c.panel_edge_softness,4,0,24,1),curve=number(c.panel_edge_curve,1,.5,3,.1),
  dither=number(c.panel_edge_dither,35,0,100,5),grain=number(c.panel_edge_grain,1,1,4,1)}
end
function M.signature(s)return string.format('%d:%.1f:%d:%d',s.width,s.curve,s.dither,s.grain)end
-- Stratified thresholds avoid banding along each edge. Opposite edges mirror.
local tile={}
local order={0,9,4,13,2,11,6,15,8,1,12,5,10,3,14,7}
for y=0,15 do for x=0,15 do
 tile[y*16+x+1]=((order[y+1]+order[x+1])%16+.5)/16
end end
function M.image(s)
 local width,height=M.width,M.height;local rows={};local cell=s.grain*2
 local fade=width*s.width/100;local amount=s.dither/100
 for y=0,height-1 do
  local row={};local dy=math.min(y,height-1-y)
  for x=0,width-1 do
   local dx=math.min(x,width-1-x);local t=fade>0 and math.min(1,math.min(dx,dy)/fade)or 1
   local alpha=(t*t*(3-2*t))^s.curve
   if amount>0 and alpha>0 and alpha<1 then
    local threshold=tile[(math.floor(dy/cell)%16)*16+math.floor(dx/cell)%16+1]
    alpha=alpha*(1-amount)+(alpha>threshold and 1 or 0)*amount
   end
   row[x+1]=string.char(255,255,255,math.floor(alpha*255+.5))
  end
  rows[y+1]=table.concat(row)
 end
 return {format='RGBA8',width=width,height=height,row_pitch=width*4,rgba=table.concat(rows)}
end
-- Split uses the study's soft bounds and ordered pattern in authored units.
-- All three images publish together through the existing generated-image job.
function M.split_images(s,hard,face)
 assert(hard and face and hard.width==640 and hard.height==322 and face.width==640 and face.height==322,'Split mask sources unavailable')
 local bayer={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}
 local rows={coverage={},face={},soft={}};local fade=121*s.width/100;local mix=s.dither/100
 for y=0,321 do
  local a,b,c={},{},{}
  for x=0,639 do
   local lx,ly=(x+.5)/2-72,(y+.5)/2-19
   local distance=math.min(lx,ly,163-lx,120-ly)
   local t=fade>0 and math.max(0,math.min(1,distance/fade))or(distance>=0 and 1 or 0)
   local alpha=(t*t*(3-2*t))^s.curve
   if mix>0 and alpha>0 and alpha<1 then
    local threshold=(bayer[(math.floor(ly/s.grain)%4)*4+math.floor(lx/s.grain)%4+1]+.5)/16
    alpha=alpha*(1-mix)+(alpha>threshold and 1 or 0)*mix
   end
   local i=(y*640+x)*4+4
   a[x+1]=string.char(255,255,255,math.floor(hard.rgba:byte(i)*alpha+.5))
   b[x+1]=string.char(255,255,255,math.floor(face.rgba:byte(i)*alpha+.5))
   c[x+1]=string.char(255,255,255,math.floor(255*alpha+.5))
  end
  rows.coverage[y+1]=table.concat(a);rows.face[y+1]=table.concat(b);rows.soft[y+1]=table.concat(c)
 end
 local names={coverage='split_hud_dynamic_coverage_v1',face='split_hud_dynamic_face_v1',soft='split_hud_dynamic_soft_v1'}
 local images={};for key,name in pairs(names)do images[name]={format='RGBA8',width=640,height=322,row_pitch=2560,rgba=table.concat(rows[key])}end
 return {images=images}
end
return M
