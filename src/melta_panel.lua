-- Meltagun receiver instrument: physical thermal chamber art, actual shot telemetry.
local M={}
function M.step(state,m,now)
 if not m or m.resource_hex~='6cfcc7f8801a0266' then
  state.id=nil;state.value=nil;state.pulse=nil;state.visual_start=nil;state.visual_level=nil;state.last_time=nil;return
 end
 local id=m.unit_ref or m.id or m.resource_hex
 if id~=state.id then state.id=id;state.value=nil;state.pulse=nil;state.visual_start=nil;state.visual_level=nil;state.last_time=nil end
 if state.value and type(m.value)=='number' and m.value<state.value then state.pulse=now+.14;state.visual_start=now end
 state.value=m.value
 m.melta_discharge=state.pulse and math.max(0,(state.pulse-now)/.14) or 0
 -- Cosmetic envelope only: observed count drop starts a sustained lance then cooling.
 local age=state.visual_start and math.max(0,now-state.visual_start) or nil
 local jet=age and age<2.1 and math.min(1,(2.1-age)/.18) or 0
 local cool=age and age>=2.1 and math.max(0,1-(age-2.1)/2.6) or 0
 if age and age>=4.7 then state.visual_start=nil end
 local target=math.min(1,math.max(0,(m.melta_charge_level or 0)/.65))
 local dt=state.last_time and math.max(0,math.min(.1,now-state.last_time)) or 0
 local level=state.visual_level or target
 level=target>=level and target or math.max(target,level-dt/.22)
 state.visual_level=level;state.last_time=now
 m.melta_visual_glow=math.max(level,jet)
 m.melta_visual_jet=jet;m.melta_visual_cooling=cool
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
 local glow=m.melta_visual_glow or M.glow(m)
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
 -- Engraved angular crest, riveted armor brow and low-key hazard stripes.
 r(65,91,14,2,copper,.6);r(68,93,8,1,rim,.5);r(71,95,2,2,copper,.65)
 for _,dx in ipairs({8,120}) do
  r(dx,96,16,3,shadow)
  for k=0,3 do r(dx+k*4,96,2,2,{220,160,62},.7) end
 end
 r(8,94,128,1,copper,.65)
 text('40-K MELTA',101,10,copper)
 -- Melta discharge nozzle: heavy stepped heat shield around a narrow white-hot bore.
 -- Charge warms the mouth; only the existing discharge pulse produces the jet.
 -- Cosmetic firing/cooling envelope; native discharge pulse remains unchanged.
 local discharge=math.min(1,math.max(0,m.melta_discharge or 0))
 local cooling=m.melta_visual_cooling or (discharge>0 and discharge<=.4 and discharge/.4 or 0)
 local burn={math.floor(104+151*glow),math.floor(35+90*glow),math.floor(25+40*glow)}
 if cooling>0 then burn={math.floor(104+135*cooling),math.floor(35+22*cooling),math.floor(25+6*cooling)} end
 r(18,63,106,27,shadow,.8)
 -- Small receiver accent; the perforated muzzle is the main artwork.
 r(21,68,16,16,{43,49,50});r(22,70,3,12,rim,.7)
 r(27,71,9,10,{71,64,53});r(29,73,2,6,copper,.75)
 -- Broad cylindrical muzzle sleeve with curved stepped end caps and metal shading.
 r(36,67,5,18,{84,47,31});r(41,64,9,24,burn)
 r(50,62,26,28,burn);r(76,64,9,24,burn);r(85,67,5,18,burn)
 r(42,65,35,2,hot({193,82,37}),.9)
 r(50,63,25,1,hot({228,108,46}),.85)
 r(44,85,35,2,{75,32,22},.85);r(50,88,25,1,{62,29,22},.8)
 r(42,68,2,15,hot({235,112,54}),.75)
 -- Two staggered rows of cooling ports, dark recesses and glowing inner edges.
 for k=0,3 do local dx=48+k*9
  for _,dy in ipairs({69,80}) do
   r(dx,dy,5,3,{65,29,23},.95)
   r(dx+1,dy+1,4,1,hot({219,158,80}),.85)
  end
 end
 r(79,67,2,18,hot({211,82,36}),.85)
 -- Heavy muzzle rim and narrow bore with cold-white core.
 r(84,69,5,14,{64,28,21});r(86,71,4,10,hot({210,103,48}))
 if cooling>0 then
  r(88,75,3,2,{math.floor(145+96*cooling),math.floor(46+27*cooling),30})
  r(50,62,26,28,{221,39,20},cooling*.15)
 else
  r(88,75,3,2,{math.floor(135+109*glow),math.floor(177+73*glow),math.floor(198+57*glow)})
 end
 -- Directional, stepped searing lance; no timer or invented retained-temperature signal.
 local jet=m.melta_visual_jet or (discharge>.4 and (discharge-.4)/.6 or 0)
 if jet>0 then
  r(90,70,10,12,{204,47,18},jet*.45)
  r(91,72,17,8,{255,96,22},jet*.8)
  r(91,74,24,4,{255,178,59},jet)
  r(90,75,32,2,{235,250,255},jet)
  r(94,73,7,1,{255,145,35},jet*.9)
  r(102,74,8,1,{202,236,255},jet)
  r(110,76,9,1,{181,223,255},jet*.9)
  r(97,78,6,1,{212,65,20},jet*.7)
  r(118,74,4,1,{255,171,57},jet*.8)
 else
  r(95,75,24,2,{53,47,36},.55)
 end
 text('SHOTS',53,8,rim)
 local number=type(m.value)=='number' and string.format('%03d',m.value) or tostring(m.value or '--')
 text(number,24,32,m.warning and HUD.config.rgb(cfg.heat_red) or ice)
 local fraction=math.max(0,math.min(1,m.fraction or 0))
 for k=0,19 do r(12+k*6,19,4,2,k<math.ceil(fraction*20) and orange or rim,k<math.ceil(fraction*20) and 1 or .18) end
 r(9,15,126,.5,rim,.25)
 text(m.reserve and string.format('%03d CNSTRS',m.reserve) or '-- CNSTRS',5,9,rim)
 -- Additive gothic reliquary details: winged death crest, riveted brass brow,
 -- bone parchment purity tabs and red wax seals. Existing telemetry remains untouched.
 local bone,gold,red={222,211,169},{185,143,63},{130,37,29}
 -- Winged skull occupies the existing small crest space below the thermal chamber.
 r(68,92,8,5,bone);r(69,97,6,1,gold)
 r(69,94,2,1,shadow);r(73,94,2,1,shadow);r(71,92,2,2,shadow)
 for k=0,3 do
  r(53+k*3,95-k,13-k*3,1,gold,.85)
  r(78,95-k,13-k*3,1,gold,.85)
 end
 -- Heavy segmented brow, restrained diagonal engraving and captive studs.
 for _,dx in ipairs({19,111}) do
  r(dx,108,14,4,{63,58,44},.95);r(dx,111,14,1,gold,.8)
  for k=0,2 do r(dx+2+k*4,109,1,1,bone,.7) end
 end
 -- Paired parchment tabs and wax seals on the lower side plates.
 for _,dx in ipairs({5,135}) do
  r(dx,42,4,13,bone,.9);r(dx+1,44,1,8,{111,99,72},.7)
  r(dx-1,54,6,5,red);r(dx,55,4,3,{192,61,40},.8)
  r(dx+1,56,2,1,gold,.7)
 end
 return out
end
return M
