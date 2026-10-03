-- GR-8 ammunition cradle, driven only by native loaded count and mode.
local M={}
function M.compose(frame,m,s,cfg,opacity,measure)
 local x,y=frame.x,frame.y;local w,h=132,124;local out={}
 local dark={13,18,21};local steel={34,42,47};local silver={212,226,230};local rim={119,143,153};local brass={204,159,80}
 local loaded=type(m.value)=='number' and m.value>0
 local mode=m.ammo_mode=='HEAT' and 'HEAT' or (m.ammo_mode=='HE' and 'HE' or 'AMMO')
 local band=mode=='HE' and {235,144,57} or {226,200,102}
 out[1]={type='panel',x=x,y=y,w=w*s,h=h*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='rocket',recoilless_panel=true}
 local function r(dx,dy,rw,rh,c,a,round)
  out[#out+1]={type='rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,recoilless_detail=true,recoilless_round=round}
 end
 local function t(value,dy,size,c)
  local a,b,e,f=0,-size*.2,#value*size*.6,size*.8
  if measure then a,b,e,f=measure(value,size*s);a,b,e,f=a/s,b/s,e/s,f/s end
  out[#out+1]={type='text',text=value,x=x+(w-a-e)*s/2,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity}
 end
 -- Bolted instrument surround and recessed launch-cell housing.
 r(0,0,w,1,rim,.8);r(0,h-1,w,1,rim,.8);r(0,0,1,h,rim,.8);r(w-1,0,1,h,rim,.8)
 r(8,28,116,66,dark);r(10,29,2,64,rim,.4);r(120,29,2,64,rim,.4)
 for _,dx in ipairs({4,125}) do for _,dy in ipairs({4,117}) do r(dx,dy,3,3,dark);r(dx+.5,dy+1,2,.5,silver,.6) end end
 for _,dx in ipairs({14,109}) do
  r(dx,35,9,50,{47,61,68});r(dx,35,9,1,rim)
  for k=0,5 do r(dx+2,39+k*7,5,2,dark);r(dx+2,40+k*7,5,.5,rim,.4) end
 end
 -- Stencilled identifier and verified programmable ammunition selection.
 t('GR-8',109,11,silver);t(mode,95,10,band)
 local closeup=cfg.recoilless_topthird_preview~=false
 local spent=closeup and not loaded and m.recoilless_spent==true
 if (loaded or spent) and cfg.recoilless_detail_preview~=false then
  local part='case'
  local function p(dx,dy,rw,rh,c)
   -- Rotate the detailed reference geometry upright and fit uniformly in the bay.
   -- Rear rim rests at y=33; projectile points up, with unchanged aspect ratio.
   local fit=.56
   local px,py,pw,ph=66-(dy+rh-61)*fit,33+(dx-16)*fit,rh*fit,rw*fit
   if closeup then
    -- Uniform magnification, cropped to the existing bay; no silhouette distortion.
    px,py=66+(px-66)*1.9,90+(py-90)*1.9;pw,ph=pw*1.9,ph*1.9
    local right,top=math.min(108,px+pw),math.min(90,py+ph)
    px,py=math.max(24,px),math.max(33,py)
    pw,ph=right-px,top-py
    if pw<=0 or ph<=0 then return end
   end
   r(px,py,pw,ph,c,1,true)
   out[#out].recoilless_part=part
  end
  -- User backpack reference: approximately 5:1 overall, long dark case and short ogive.
  -- Backpack retaining brackets are not part of the cartridge.
  p(18,51,68,20,{49,35,29});p(20,53,64,16,{77,53,39})
  p(20,55,64,10,{104,72,49});p(21,59,62,4,{119,84,59})
  p(21,62,61,1,{133,99,71})
  p(20,52,64,1,{36,28,25});p(20,69,64,1,{39,30,26})
  -- Heavy rear rim, recessed extractor groove and head reflections.
  p(16,50,3,22,{103,76,48});p(16,51,1,20,{185,143,88})
  p(17,51,1,20,{63,46,33});p(19,52,1,18,{30,25,22})
  p(16,60,1,4,{220,180,113});p(18,68,2,1,{153,115,72})
  -- Case neck ends below the projectile's colored band.
  p(84,52,3,18,{104,72,49});p(84,56,1,10,{131,92,63})
  if loaded then
  part='projectile'
  p(87,52,3,18,band);p(87,60,3,3,{243,218,153})
  p(90,53,2,16,{87,61,42});p(90,59,2,4,{168,121,78})
  -- Terraced ogive retains the brown material and a central reflection.
  for k=0,8 do
   local hh=16-k*1.6;local xx=92+k*2.7;local yy=61-hh/2
   p(xx,yy,2.8,hh,{104-k*3,70-k*2,43-k})
   p(xx,61,2.8,math.max(.7,hh*.18),{155-k*5,111-k*4,67-k*2})
   p(xx,yy,2.8,.6,{53,39,29})
  end
  p(116,60.4,1.5,1.2,{156,119,76})
  else
   -- Open case mouth remains at its original shoulder; projectile runs are absent.
   p(86,53,1,16,{34,26,22});p(86,54,.6,14,{124,91,63})
  end
 elseif loaded then
  local function p(dx,dy,rw,rh,c) r(dx,dy,rw,rh,c,1,true) end
  -- Broad brass case, heavy rim, extractor recess and tapered olive warhead.
  p(53,34,26,24,{147,109,52});p(56,35,20,22,brass);p(58,35,3,22,{247,220,155});p(74,35,3,22,{113,82,40})
  p(49,32,34,4,brass);p(51,32,30,1,{249,224,169});p(57,36,18,1,{116,88,46})
  p(51,58,30,22,{93,108,70});p(54,59,23,20,{133,151,91});p(55,61,3,17,{184,199,132});p(74,61,4,17,{65,81,51})
  p(51,59,30,3,band);p(52,61,27,1,{249,228,171})
  -- Curved ogive approximated with narrow terraces, pointed fuse and seams.
  for k=0,9 do local width=28-k*2.5;p(66-width/2,80+k*1.1,width,1.2,k<7 and {151,165,115} or silver) end
  p(64.5,90,3,2,silver);p(59,68,14,1,{68,83,48});p(62,71,8,1,{207,213,159})
  p(62,38,8,2,{108,80,37});p(63,39,6,.5,{245,223,167})
 else
  -- Empty cradle: no projectile art or made-up loaded count.
  r(49,33,34,2,rim,.3);r(49,33,2,57,rim,.3);r(81,33,2,57,rim,.3);r(49,89,34,2,rim,.3)
  r(58,56,16,1,rim,.2)
 end
 t(loaded and 'LOADED' or 'EMPTY',21,8,loaded and brass or {237,111,87})
 r(9,17,114,.5,rim,.4)
 t(m.reserve and string.format('%03d RCKTS',m.reserve) or '-- RCKTS',5,10,silver)
 for k=0,3 do r(13+k*4,101,2,2,brass,.7);r(105+k*4,101,2,2,brass,.7) end
 return out
end
return M
