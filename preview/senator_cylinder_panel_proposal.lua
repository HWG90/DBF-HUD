-- Uninstalled rear cylinder prototype. Bottom/clockwise is presentation order only.
local M={}
local raster_cache={}
function M.compose(m,x,y,s,opacity,cfg,measure)
 local w,h=148,184
 for _,item in ipairs({{'P-4 SENATOR',11,170},{m.reserve~=nil and string.format('%03d ROUNDS',m.reserve) or '--- ROUNDS',12,13}}) do
  local a,b,e,t=HUD.font.measure(item[1],item[2]*s,cfg.font)
  w=math.max(w,(e-a)/s+16);h=math.max(h,item[3]+t/s+5)
 end
 local steel,silver,gold={24,31,36},{198,210,218},{218,172,78}
 local out={{type='panel',x=x,y=y,w=w*s,h=h*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted}}
 local function rect(dx,dy,rw,rh,c,tag,slot)
  out[#out+1]={type='rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=opacity*.92,senator_part=tag,senator_slot=slot}
 end
 local function text(t,dy,size,c,child)
  local a,b,e,f=HUD.font.measure(t,size*s,cfg.font)
  out[#out+1]={type='text',text=t,x=x+w*s/2-(a+e)/2,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,center_in_frame=true,child=child,weapon_label=not child and t=='P-4 SENATOR' or nil}
 end
 text('P-4 SENATOR',170,11,gold)
 rect(8,163,w-16,.7,gold)
 local metals={{92,65,31},{139,104,55},{196,158,93},{234,201,138},{248,226,175},{216,183,117},{168,132,70},{112,81,37}}

 local cx,cy=w/2,96
 -- Static native rectangles, with scanline runs and quantized metallic shading.
 local function raster(radius,fn,tag,slot)
  local key=radius..'/'..tag..'/'..string.format('%.8f',m.cylinder_preview_angle or m.cylinder_angle or 0)
  local cached=raster_cache[key]
  if cached then for _,run in ipairs(cached) do rect(cx+run.x,cy+run.y,run.w,run.h,run.c,tag,slot) end;return end
  local saved={};local function drawrun(run)
   if cfg.senator_verify_raster then for yy=run.y,run.y+run.h-1 do for xx=run.x,run.x+run.w-1 do
    local c=fn(xx+.5,yy+.5);assert(c and c[1]==run.c[1] and c[2]==run.c[2] and c[3]==run.c[3],'merged raster changed shading')
   end end end
   saved[#saved+1]=run;rect(cx+run.x,cy+run.y,run.w,run.h,run.c,tag,slot) end
  local active={}
  for yy=-radius,radius-1 do
   local start,last,lastcolor;local row={}
   local function emit(xx)
    if last then
     local key=start..'/'..xx..'/'..last
     local run=active[key]
     if run then run.h=run.h+1 else run={x=start,y=yy,w=xx-start,h=1,c=lastcolor};end
     row[key]=run
    end
   end
   for xx=-radius,radius do
    local color=xx<radius and fn(xx+.5,yy+.5) or nil
    local key=color and table.concat(color,',')
    if key~=last then emit(xx);start,last,lastcolor=xx,key,color end
   end
   for key,run in pairs(active) do if not row[key] then drawrun(run) end end
   active=row
  end
  for _,run in pairs(active) do drawrun(run) end
  raster_cache[key]=saved
 end
 local rotation=m.cylinder_preview_angle or m.cylinder_angle or 0
 local ca,sa=math.cos(rotation),math.sin(rotation)
 local brass={{93,69,37},{128,95,49},{158,122,66},{183,145,83},{207,170,107},{225,192,135},{240,211,160},{250,228,185}}
 local function circle(px,py,r,loaded,slot)
  local oldcx,oldcy=cx,cy;cx,cy=px,py
  raster(r+2,function(x,y)
   local d=math.sqrt(x*x+y*y)
   if d>r+1 then return end
   if d>r then return {31,28,24} end
   if not loaded then
    if d>r-1.4 then return y>0 and {112,116,115} or {55,60,62} end
    if d>r-3 then return {33,36,39} end
    return {8,11,14}
   end
   if d>r-1 then return y>0 and {250,226,176} or {109,77,36} end
   if d>r-2 then return {151,111,53} end
   if d<1.6 then return {82,62,37} end
   if d<4 then return y>0 and {226,203,155} or {153,126,82} end
   if d<5 then return {72,57,35} end
   if d<6 then return {243,215,159} end
   if d<7 then return {104,77,38} end
   local q=math.max(1,math.min(8,math.floor(4.5+(-x+y)*.11+math.sin(x*.45+y*.3)*.35)))
   return brass[q]
  end,loaded and 'projectile' or 'chamber',slot)
  cx,cy=oldcx,oldcy
 end
 raster(62,function(x,y)
  local ux,uy=x*ca+y*sa,-x*sa+y*ca
  local ax,ay=math.abs(ux),math.abs(uy)
  if ax>53 or ay>60-ax*.56 then return end
  local edge=math.min(53-ax,(60-ax*.56-ay)*.87)
  if edge<1 then return y>0 and {193,187,174} or {62,58,53} end
  if edge<3 then return {105,100,91} end
  if edge<5 then return {56,54,51} end
  local q=math.floor((uy-ux)/24)
  return {math.max(30,65+q*5),math.max(30,62+q*5),math.max(29,55+q*4)}
 end,'housing')
 -- Slot 1 bottom, then lower-left, upper-left, top, upper-right, lower-right.
 for i=1,6 do
  local angle=-math.pi/2-(i-1)*math.pi/3+rotation
  circle(cx+math.cos(angle)*37,cy+math.sin(angle)*37,15,m.cylinder_slots and m.cylinder_slots[i],i)
 end
 circle(cx,cy,10,false,nil)
 raster(3,function(x,y) local ux,uy=x*ca+y*sa,-x*sa+y*ca;if math.abs(ux)<2 and math.abs(uy)<2 then return {156,151,135} end end,'bolt')
 for i=1,6 do local angle=(i-1)*math.pi/3+rotation
  local ox,oy=cx,cy;cx,cy=ox+math.cos(angle)*18,oy+math.sin(angle)*18
  raster(3,function(x,y) local d=x*x+y*y;if d<6 then return y>0 and {169,153,120} or {86,77,61} end end,'hub');cx,cy=ox,oy
 end
 -- Fixed firing-position cue belongs to the panel, not the rotating cylinder.
 rect(w/2-3,30,6,1,gold,'firing_cue')
 text(m.reserve~=nil and string.format('%03d ROUNDS',m.reserve) or '--- ROUNDS',13,12,silver)
 rect(8,8,w-16,.7,{95,108,117})
 HUD.layout.decorate(out,out[1],s,cfg,opacity)
 local fa,fb,fe,ft=HUD.font.measure(m.fire_mode or '--',11*s,cfg.font)
 local ch=math.max(18,(ft-fb)/s+8)
 local child={type='panel',child=true,x=x,y=y-(2+ch)*s,w=w*s,h=ch*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted}
 out[#out+1]=child;text(m.fire_mode or '--',-2-ch/2-(fb+ft)/(2*s),11,silver,true)
 local group={};HUD.layout.decorate(group,child,s,cfg,opacity)
 for _,v in ipairs(group) do v.child=true;out[#out+1]=v end
 return out
end
return M
