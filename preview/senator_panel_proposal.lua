-- Review-only Senator presentation, based on the supplied six-cartridge reference.
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
