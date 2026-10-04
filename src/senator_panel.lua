-- Approved rear cylinder; bottom/clockwise is a count-driven presentation model.
local M={}
local art_cache,cache_order={},{}
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
 local bits={};for i=1,6 do bits[i]=m.cylinder_slots and m.cylinder_slots[i] and '1' or '0' end
 local key=table.concat({w,x,y,s,string.format('%.8f',(m.cylinder_render_angle or m.cylinder_angle or 0)%(2*math.pi)),table.concat(bits)},'/')
 local cached=art_cache[key]
 if cached then
  for _,v in ipairs(cached) do v.a=opacity*.92;out[#out+1]=v end
 else
  local first_art=#out+1
 local cx,cy=w/2,96
 local rotation=m.cylinder_render_angle or m.cylinder_angle or 0
 local function polygon(points,color,tag,slot)
  -- Convex fan grouped into native quads; renderer uses its existing triangle path.
  for i=2,#points-1,2 do
   local q={points[1],points[i],points[i+1],points[math.min(i+2,#points)]}
   local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
   local world={}
   for j,v in ipairs(q) do
    left=math.min(left,v[1]);right=math.max(right,v[1]);bottom=math.min(bottom,v[2]);top=math.max(top,v[2])
    world[j]={x+v[1]*s,y+v[2]*s}
   end
   out[#out+1]={type='rect',quad=world,x=x+left*s,y=y+bottom*s,w=(right-left)*s,h=(top-bottom)*s,c=color,a=opacity*.92,senator_part=tag,senator_slot=slot}
  end
 end
 local function disk(px,py,r,n,color,tag,slot,angle)
  local points={};for j=1,n do local t=(j-1)*2*math.pi/n+(angle or math.pi/12);points[j]={px+math.cos(t)*r,py+math.sin(t)*r} end
  polygon(points,color,tag,slot)
 end
 local function hex(r,color)
  disk(cx,cy,r,6,color,'housing',nil,math.pi/2+rotation)
 end
 hex(60,{157,153,139});hex(58.8,{52,52,49});hex(56.7,{99,95,84});hex(53.7,{60,59,53})
 -- Broad face planes and restrained highlights replace pixel-by-pixel surface runs.
 local function rotate(dx,dy) return {cx+dx*math.cos(rotation)-dy*math.sin(rotation),cy+dx*math.sin(rotation)+dy*math.cos(rotation)} end
 polygon({rotate(0,53),rotate(-46.5,26.8),rotate(-46.5,-26.8),rotate(0,-53)},{75,72,63},'housing')
 polygon({rotate(0,53),rotate(46.5,26.8),rotate(46.5,-26.8),rotate(0,-53)},{53,52,48},'housing')
 for i=1,6 do
  local angle=-math.pi/2-(i-1)*math.pi/3+rotation
  local px,py=cx+math.cos(angle)*37,cy+math.sin(angle)*37
  local loaded=m.cylinder_slots and m.cylinder_slots[i]
  local tag=loaded and 'projectile' or 'chamber'
  disk(px,py,16,8,{27,27,25},tag,i)
  if loaded then
   disk(px,py,15,12,{139,103,52},tag,i)
   disk(px,py,13.6,8,{210,174,111},tag,i)
   polygon({{px-5,py+12.5},{px+5,py+12.5},{px+10,py+8},{px-10,py+8}},{243,216,167},tag,i)
   polygon({{px+9,py+8},{px+13,py+4},{px+13,py-4},{px+9,py-8}},{173,135,75},tag,i)
   disk(px,py,7,8,{106,77,39},tag,i)
   disk(px,py,5.5,8,{225,195,141},tag,i)
   rect(px-1,py-1,2,2,{83,64,39},tag,i)
  else
   disk(px,py,14.8,8,{84,87,85},tag,i)
   disk(px,py,13,8,{32,36,38},tag,i)
   disk(px,py,11.6,8,{8,11,14},tag,i)
  end
 end
 disk(cx,cy,11,6,{90,91,84},'hub')
 disk(cx,cy,9,6,{24,28,29},'hub')
 polygon({rotate(-2,-2),rotate(2,-2),rotate(2,2),rotate(-2,2)},{156,151,135},'hub')
 for i=1,6 do local angle=(i-1)*math.pi/3+rotation
  rect(cx+math.cos(angle)*18-1.5,cy+math.sin(angle)*18-1.5,3,3,{156,143,115},'hub')
 end
 rect(w/2-3,30,6,1,gold,'firing_cue')
  cached={};for i=first_art,#out do cached[#cached+1]=out[i] end
  art_cache[key]=cached;cache_order[#cache_order+1]=key
  if #cache_order>16 then art_cache[table.remove(cache_order,1)]=nil end
 end
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
M.upright=(function()
-- Approved Senator upper-round close-up, based on the supplied six-cartridge reference.
local M={}
function M.compose(m,x,y,s,opacity,cfg,measure)
 local w,h=132,104
 for _,item in ipairs({{'P-4 SENATOR',11,90},{m.reserve~=nil and string.format('%03d ROUNDS',m.reserve) or '--- ROUNDS',12,13}}) do
  local a,b,e,t=HUD.font.measure(item[1],item[2]*s,cfg.font)
  w=math.max(w,(e-a)/s+16);h=math.max(h,item[3]+t/s+5)
 end
 local steel,silver,gold={24,31,36},{198,210,218},{218,172,78}
 local out={{type='panel',x=x,y=y,w=w*s,h=h*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted}}
 local function rect(dx,dy,rw,rh,c,tag,slot)
  if slot then
   local center=w/2+(slot-3.5)*18
   if tag=='case' or tag=='projectile' then
    local old=(w-90)/2+(slot-1)*16+5
    dx,dy=center+(dx-old)*1.6,80+(dy-76)*1.6
    rw,rh=rw*1.6,rh*1.6
    local top=math.min(80,dy+rh);dy=math.max(32,dy);rh=top-dy
    if rh<=0 then return end
   elseif tag=='slot' then dx,rw=center-7,14 end
  end
  out[#out+1]={type='rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=opacity*.92,senator_part=tag,senator_slot=slot}
 end
 local function text(t,dy,size,c,child)
  local a,b,e,f=HUD.font.measure(t,size*s,cfg.font)
  out[#out+1]={type='text',text=t,x=x+w*s/2-(a+e)/2,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,center_in_frame=true,child=child,weapon_label=not child and t=='P-4 SENATOR' or nil}
 end
 text('P-4 SENATOR',90,11,gold)
 rect(8,83,w-16,.7,gold)
 local metals={{92,65,31},{139,104,55},{196,158,93},{234,201,138},{248,226,175},{216,183,117},{168,132,70},{112,81,37}}
 for i=1,6 do
  local state=m.senator_slots and m.senator_slots[i]
  local xx=(w-90)/2+(i-1)*16
  rect(xx-1,28,12,1,{100,112,119},'slot',i)
  if state and state.case then
   -- Long straight case, subtle cylindrical sheen and a small base rim.
   for k,c in ipairs(metals) do rect(xx+k,34,1,33,c,'case',i) end
   rect(xx,32,10,.8,{96,71,36},'case',i)
   rect(xx,32.8,10,1,{219,188,123},'case',i)
   rect(xx+1,33.8,8,.4,{128,96,47},'case',i)
   rect(xx+2,32.9,5,.3,{248,229,188},'case',i)
   if state.projectile then
    -- Rounded projectile above the reference seam; same brass material.
    rect(xx+1,67,8,.6,{112,84,44},'projectile',i)
    for k,c in ipairs(metals) do
     local hh=(k==1 or k==8) and 4 or (k==2 or k==7) and 6 or 8
     rect(xx+k,68,1,hh,c,'projectile',i)
    end
    rect(xx+3,75.5,4,.5,{232,201,145},'projectile',i)
   else
    -- Simple case edge at the known seam; no invented hidden mouth structures.
    rect(xx+1,67,8,.6,{68,51,30},'case',i)
    rect(xx+2,67.4,6,.3,{188,153,95},'case',i)
   end
  end
 end
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

end)()
return M
