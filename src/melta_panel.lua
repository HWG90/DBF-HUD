-- Meltagun receiver instrument: physical thermal chamber art, actual shot telemetry.
local M={}
function M.step(state,m,now)
 if not m or m.resource_hex~='6cfcc7f8801a0266' then state.id=nil;state.value=nil;state.pulse=nil;return end
 local id=m.unit_ref or m.id or m.resource_hex
 if id~=state.id then state.id=id;state.value=nil;state.pulse=nil end
 if state.value and type(m.value)=='number' and m.value<state.value then state.pulse=now+.14 end
 state.value=m.value
 m.melta_discharge=state.pulse and math.max(0,(state.pulse-now)/.14) or 0
end
function M.glow(m)
 -- Artistic intensity mapping of observed native ramp; not a claimed percentage or firing threshold.
 local charge=math.min(1,math.max(0,(m.melta_charge_level or 0)/.65))
 return math.max(charge,math.min(1,math.max(0,m.melta_discharge or 0)))
end
function M.compose(frame,m,s,cfg,opacity,measure)
 local x,y=frame.x,frame.y;local out={}
 local steel={24,29,33};local rim={148,159,165};local ice={225,234,235}
 local copper={205,124,59};local orange={247,151,54};local shadow={9,15,18}
 local glow=M.glow(m)
 local function hot(base)
  return {math.floor(base[1]+(255-base[1])*glow),math.floor(base[2]+(244-base[2])*glow),math.floor(base[3]+(210-base[3])*glow)}
 end
 local w,h=144,116
 out[1]={type='panel',x=x,y=y,w=w*s,h=h*s,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='plasma',melta_panel=true}
 local function r(dx,dy,rw,rh,c,a)
  out[#out+1]={type='rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,melta_detail=true}
 end
 local function text(value,dy,size,c)
  local a,b,e,f=0,-size*.2,#value*size*.6,size*.8
  if measure then a,b,e,f=measure(value,size*s);a,b,e,f=a/s,b/s,e/s,f/s end
  out[#out+1]={type='text',text=value,x=x+(w-(a+e))/2*s,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,numeric_display=value:match('^%d+$')~=nil,melta_text=true}
 end
 -- Machined perimeter, recessed edge and four captive screws.
 r(0,0,w,1,rim,.65);r(0,h-1,w,1,rim,.65);r(0,0,1,h,rim,.65);r(w-1,0,1,h,rim,.65)
 for _,dx in ipairs({4,w-7}) do for _,dy in ipairs({4,h-7}) do
  r(dx,dy,3,3,shadow);r(dx+.5,dy+1.2,2,.5,rim)
 end end
 -- Layered armored plates and cog-like collars around the furnace housing.
 for _,dx in ipairs({4,128}) do
  r(dx,61,12,31,{44,53,59});r(dx+1,62,2,29,rim,.45)
  for k=0,4 do r(dx+3,64+k*5,7,2,shadow);r(dx+3,65+k*5,5,.5,copper,.5) end
 end
 for _,cx in ipairs({30,114}) do
  r(cx-5,63,10,28,{76,89,97});r(cx-3,65,6,24,{29,38,44})
  for k=0,4 do r(cx-6,64+k*5,12,2,{131,145,151},.8) end
 end
 -- Engraved angular crest, riveted armor brow and low-key hazard stripes.
 r(65,91,14,2,copper,.6);r(68,93,8,1,rim,.5);r(71,95,2,2,copper,.65)
 for _,dx in ipairs({8,120}) do
  r(dx,96,16,3,shadow)
  for k=0,3 do r(dx+k*4,96,2,2,{220,160,62},.7) end
 end
 r(8,94,128,1,copper,.65)
 text('40-K MELTA',101,10,copper)
 -- Horizontal thermal chamber: stepped steel end caps, insulated barrel and coil windings.
 r(28,65,88,23,shadow);r(30,66,84,21,{57,67,73});r(35,69,74,15,{87,54,33})
 r(34,67,76,19,{255,171,61},.07+.17*glow)
 r(37,72,70,8,hot({142,74,30}));r(40,74,64,4,hot(orange));r(43,75,58,1,hot({255,225,157}))
 for k=0,7 do local dx=38+k*9
  r(dx,68,3,17,copper);r(dx,82,3,2,hot({247,189,113}));r(dx+2,69,1,12,{96,58,30})
 end
 for _,dx in ipairs({26,111}) do
  r(dx,66,7,21,{114,129,136});r(dx+1,68,2,17,ice,.65);r(dx+5,69,1,14,shadow)
 end
 for _,dx in ipairs({10,123}) do for k=0,3 do
  r(dx,66+k*6,11,2,shadow);r(dx,67+k*6,9,.6,rim,.45)
 end end
 -- Two safety tabs, rather than invented temperature or charge readings.
 for _,dx in ipairs({22,119}) do r(dx,61,3,3,orange,.8) end
 text('SHOTS',53,8,rim)
 local number=type(m.value)=='number' and string.format('%03d',m.value) or tostring(m.value or '--')
 text(number,24,32,m.warning and HUD.config.rgb(cfg.heat_red) or ice)
 local fraction=math.max(0,math.min(1,m.fraction or 0))
 for k=0,19 do r(12+k*6,19,4,2,k<math.ceil(fraction*20) and orange or rim,k<math.ceil(fraction*20) and 1 or .18) end
 r(9,15,126,.5,rim,.25)
 text(m.reserve and string.format('%03d CNSTRS',m.reserve) or '-- CNSTRS',5,9,rim)
 return out
end
return M
