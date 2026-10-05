-- S-11 single-shot display. Gas hardware is artwork, not pressure telemetry.
local M={}
function M.compose(frame,m,s,cfg,opacity,measure)
 local x,y=frame.x,frame.y;local w,h=132,108;local out={}
 local steel={26,36,32};local rim={150,175,162};local green={172,220,70};local silver={223,235,228};local dark={10,19,15}
 local loaded=type(m.value)=='number' and m.value>0
 out[1]={type='panel',x=x,y=y,w=w*s,h=h*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='dart',speargun_panel=true}
 local function r(dx,dy,rw,rh,c,a,projectile)
  out[#out+1]={type='rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,speargun_detail=true,spear_projectile=projectile}
 end
 local function t(value,dy,size,c)
  local a,b,e,f=0,-size*.2,#value*size*.6,size*.8
  if measure then a,b,e,f=measure(value,size*s);a,b,e,f=a/s,b/s,e/s,f/s end
  out[#out+1]={type='text',text=value,x=x+(w-a-e)*s/2,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity}
 end
 r(0,0,w,1,rim,.7);r(0,h-1,w,1,rim,.7);r(0,0,1,h,rim,.7);r(w-1,0,1,h,rim,.7)
 for _,dx in ipairs({4,125}) do for _,dy in ipairs({4,101}) do r(dx,dy,3,3,dark);r(dx+.5,dy+1,2,.5,rim) end end
 t('S-11',94,10,rim)
 -- Recessed launcher socket, restrained chemical haze and piping.
 r(14,42,2,32,rim,.45);r(16,42,10,2,rim,.45);r(116,43,2,31,rim,.45)
 r(108,41,10,2,rim,.45);r(106,29,2,14,rim,.6)
 -- Chemical vessel, steel straps, valve spindle and vent louvres.
 r(28,24,72,14,dark);r(30,25,68,12,{67,91,56});r(34,27,60,7,{115,147,65})
 r(36,34,56,1,{188,208,123},.8)
 for _,dx in ipairs({32,88}) do r(dx,24,6,14,rim);r(dx+1,25,1,12,silver,.7) end
 r(98,28,9,5,rim);r(105,27,3,7,green);r(104,33,5,2,green)
 for k=0,3 do r(12,26+k*3,10,1,rim,.45);r(112,26+k*3,8,1,rim,.45) end
 for k=0,4 do r(28+k*4,19,2,2,green,.8);r(86+k*4,19,2,2,green,.8) end
 -- Loaded spear: segmented shaft, sharp barbed head and rear stabilisers.
 if loaded then
  local function p(dx,dy,rw,rh,c) r(dx,dy,rw,rh,c,1,true) end
  p(24,58,71,5,silver);p(28,59,64,1,{255,255,233});p(30,57,4,7,rim)
  p(47,57,2,7,rim);p(71,57,2,7,rim);p(89,57,3,7,green)
  p(20,55,9,3,rim);p(20,63,9,3,rim);p(23,53,3,15,silver)
  for k=0,7 do p(94+k*2,55+k*.65,2,11-k*1.3,k<3 and green or silver) end
  p(94,53,3,4,green);p(94,64,3,4,green)
 else
  -- Vacant cradle keeps its silhouette without implying a loaded projectile.
  r(23,54,3,14,rim,.25);r(93,54,3,14,rim,.25);r(26,54,67,1,rim,.2);r(26,67,67,1,rim,.2)
 end
 t(loaded and 'SPEAR READY' or 'EMPTY',79,8,loaded and green or {237,110,86})
 r(10,16,112,.5,rim,.3)
 t(m.reserve and string.format('%03d SPEARS',m.reserve) or '-- SPEARS',5,10,silver)
 return out
end
return M

