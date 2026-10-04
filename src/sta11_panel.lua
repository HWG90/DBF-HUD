-- StA-11 / Killzone helical-feed receiver study. Offline only, no native calibration changes.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=180,126
 local steel,edge,shadow,ice,orange={67,77,82},{147,166,171},{13,18,21},{229,236,235},{232,102,40}
 local function r(dx,dy,rw,rh,c,a,tag)
  if rw>0 and rh>0 then out[#out+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,sta11_study=true,frosted=tag=='panel' and cfg.frosted or nil}end
 end
 local function t(q,dx,dy,z,c,maxwidth,numeric)
  local a,b,e,f=measure(q,z*s);if e-a>maxwidth*s then z=z*maxwidth*s/(e-a);a,b,e,f=measure(q,z*s)end
  out[#out+1]={type='text',text=q,x=x+dx*s-(a+e)/2,y=y+dy*s,size=z*s,font=cfg.font,c=c,a=opacity,numeric_display=numeric,sta11_study=true}
 end
 -- Stepped receiver footprint: compact left readout body with an open right feed bridge.
 r(2,45,108,78,{29,34,36},cfg.panel_opacity,'panel')
 r(3,122,107,2,steel);r(2,45,108,3,steel);r(2,48,2,74,steel);r(108,48,2,74,steel)
 r(4,123,103,.6,edge,.65);r(5,46,102,.5,shadow)
 r(111,111,67,12,{44,49,51},.9);r(111,122,67,1,edge,.6)
 r(111,111,67,1,orange,.65)
 t('StA-11',53,110,12,ice,90)
 t('STAHL',144,115,7,edge,59)
 -- Primary ammunition count is embedded in the receiver, not opposite a fixed icon bay.
 r(9,65,95,38,shadow,.55)
 local valid=type(m.value)=='number' and m.value>=0 and m.value%1==0
 local color=valid and m.value==0 and {236,105,67} or ice
 t(valid and string.format('%03d',m.value) or '---',56,71,34,color,89,true)
 t('ROUNDS',34,54,7,edge,53)
 t(type(m.capacity)=='number' and '/ '..tostring(m.capacity) or '/ --',85,54,7,edge,36)
 -- Armored feed throat on the right, with a horizontal cartridge along the feed axis.
 for _,dy in ipairs({57,89})do r(114,dy,61,3,steel);r(115,dy+2,59,.6,edge,.65)end
 r(173,60,3,29,steel);r(174,61,.7,27,edge,.6)
 -- Long shaded brass case, extractor rim and dark steel connector links.
 for k=0,9 do local q=k/9;local lum=.55+.45*math.sin(q*math.pi)
  r(120,65+k,29,1,{205*lum,166*lum,88*lum})end
 r(117,64,3,12,{174,140,76});r(117,74,3,.7,{245,213,139})
 r(121,66,1,8,{92,75,43});r(148,67,4,6,{184,142,75});r(152,68,4,4,{194,149,80})
 for k=0,11 do local half=2*(1-k/12);r(156+k,70-half,1,half*2,{188,119,69});r(156+k,70+half-.4,1,.4,{237,181,118},.7)end
 r(127,63,3,14,{79,84,83});r(128,64,.6,12,edge,.75)
 r(142,63,3,14,{79,84,83});r(143,64,.6,12,edge,.75)
 -- Helghast optical cues inhabit the feed bridge, separate from the projectile itself.
 for _,dx in ipairs({120,155})do
  r(dx,96,17,11,{37,43,45});r(dx+1,97,15,9,steel);r(dx+3,100,11,3,orange,.9)
  r(dx+4,101,9,.7,{255,188,85});r(dx+2,98,13,.6,shadow)
 end
 -- Underslung helical magazine: long curved housing, keyed endcaps and diagonal grooves.
 -- This is authored mechanical artwork, not a visualization of individual live round positions.
 for yy=0,31 do
  local q=(yy+.5)/32;local inset=(1-math.sin(q*math.pi))*4
  local lum=.5+.5*math.sin(q*math.pi)
  r(10+inset,12+yy,155-inset*2,1,{87*lum,104*lum,112*lum})
 end
 r(18,39,137,.7,{173,193,199},.7);r(17,16,140,.7,{17,27,33},.85)
 for coil=0,10 do
  local start=20+coil*12
  for step=0,9 do
   local px=start+step*.6;local py=18+step*2
   r(px,py,1.1,2,{23,36,44},.8);r(px+1.2,py,.5,2,{153,176,184},.5)
  end
 end
 -- Mounting straps and turn-lock end rings echo the real front-heavy feed assembly.
 for _,dx in ipairs({12,158})do
  r(dx,14,7,28,{48,61,69});r(dx+1,15,1,26,edge,.7);r(dx+5,15,1,26,shadow)
  r(dx-1,20,9,16,{74,89,98});r(dx,35,7,.7,edge,.8)
 end
 for _,dx in ipairs({31,131})do r(dx,12,5,34,{42,53,60});r(dx+1,13,.7,32,edge,.7);r(dx-2,43,9,5,steel)end
 r(166,19,10,19,steel);r(175,23,3,11,{101,118,127});r(167,35,8,.7,edge,.8)
 -- A single orange key differentiates the feed release from decorative optics.
 r(15,45,17,5,{43,49,49});r(16,46,15,2,orange,.75)
 for _,dx in ipairs({6,101})do r(dx,116,4,4,shadow);r(dx+1,117.7,2,.5,edge,.65)end
 -- Native reserves form the bottom issue plate, independent of the helical artwork.
 r(8,1,166,8,{28,36,41},cfg.panel_opacity,'panel');r(8,8,166,.6,steel,.5)
 local reserve=type(m.reserve)=='number' and string.format('%02d',m.reserve) or '--'
 t('RESERVE',35,2,6,edge,48)
 t(reserve..' '..(m.reserve_kind or 'MAGS'),132,2,7,ice,71,true)
 return out
end
