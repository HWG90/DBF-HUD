-- Presentation geometry only: the profiles describe artwork, never ammunition telemetry.
local M={}
local brass={202,157,76};local light={252,222,149};local dark={106,76,37}
local copper={189,113,73};local silver={190,206,217};local steel={66,80,88}
local function canvas()
 local a={w=48,h=18,runs={}}
 local function r(x,y,w,h,c) a.runs[#a.runs+1]={x,y,w,h,c} end
 return a,r
end
local function cartridge(p)
 local a,r=canvas();local case=p.case or 25;local neck=p.neck or 5;local tip=p.tip or 10
 local body=p.body or brass;local projectile=p.projectile or copper
 r(0,2,3,14,dark);r(0,13,3,3,light);r(3,3,2,12,dark) -- rim and extractor groove
 r(5,3,case,12,body);r(6,4,case-2,2,dark);r(6,11,case-2,2,light)
 r(7,7,case-4,3,body);r(case+3,3,2,12,light) -- machined mouth
 r(case+5,4,2,10,body);r(case+7,5,2,8,body)
 r(case+9,6,neck,6,body);r(case+9,6,1,6,dark) -- shoulder and neck seam
 local x=case+9+neck
 r(x,6,tip*.55,6,projectile);r(x+tip*.55,7,tip*.25,4,projectile);r(x+tip*.8,8,tip*.2,2,projectile)
 r(x+1,10,math.max(1,tip*.5-1),1,{245,179,124})
 if p.band then r(x,6,2,6,p.band) end
 if p.soft then r(x+tip*.8,8,tip*.2,2,silver) end
 a.w=x+tip;a.h=18;return a
end
local profiles={
 ['Adjudicator']={case=27,neck=5,tip=12},['Diligence']={case=29,neck=5,tip=13},
 ['Counter Sniper']={case=33,neck=6,tip=15,band=silver},['Constitution']={case=30,neck=4,tip=12},
 ['Amendment']={case=25,neck=5,tip=11},['Dominator']={case=20,neck=3,tip=15,band={211,190,78}},
 ['Suppressor']={case=22,neck=4,tip=14,band={169,192,157}},['Tenderizer']={case=28,neck=4,tip=11},
 ['Liberator']={case=23,neck=5,tip=10},['Penetrator']={case=26,neck=6,tip=15,projectile=silver},
 ['Concussive']={case=22,neck=3,tip=9,projectile={100,192,221}},['Carbine']={case=20,neck=5,tip=10},
 ['Coyote']={case=25,neck=5,tip=11,band={255,133,42}},['Peacemaker']={case=14,neck=2,tip=7},
 ['Verdict']={case=19,neck=2,tip=10},['Redeemer']={case=13,neck=2,tip=7},
 ['Senator']={case=24,neck=2,tip=8,soft=true},['Breacher']={case=20,neck=3,tip=10},
 ['Knight']={case=13,neck=3,tip=8},['Defender']={case=16,neck=2,tip=8},
 ['Pummeler']={case=17,neck=2,tip=8,projectile={100,192,221}},['Gallant']={case=20,neck=4,tip=10},
 ['Stalwart']={case=23,neck=5,tip=10},['Heavy Machine Gun']={case=34,neck=7,tip=16},
 ['Machine Gun']={case=29,neck=5,tip=13},['Maxigun']={case=25,neck=5,tip=12},
 ['Reprimand']={case=20,neck=3,tip=9},['StA-11']={case=18,neck=3,tip=8},
 ['M7S']={case=14,neck=3,tip=9},['M6C']={case=18,neck=2,tip=9,soft=true},
 ['Veto']={case=16,neck=2,tip=8},['Warrant']={case=21,neck=3,tip=10},
 ['Bolt Pistol']={case=20,neck=2,tip=14,band={205,196,156}},
 ['Eruptor']={case=32,neck=4,tip=16,band={223,161,74}},
 ['Arbitrator']={case=26,neck=5,tip=13},['Pacifier']={case=28,neck=3,tip=10,projectile={111,193,218}},
 ['Hyena']={case=27,neck=6,tip=14},['Censor']={case=30,neck=6,tip=12},
 ['Hot-Shot']={case=28,neck=4,tip=13,band={237,126,57}},
 ['StA-52']={case=24,neck=4,tip=12},['Variable']={case=25,neck=7,tip=13},
 ['Bullet Storm']={case=22,neck=5,tip=11},
}
local function stacked(a,count,belt)
 if count==1 then return a end
 local b,r=canvas();b.w=a.w;b.h=count*20-2
 for i=0,count-1 do for _,v in ipairs(a.runs) do r(v[1],v[2]+i*20,v[3],v[4],v[5]) end end
 if belt then for i=0,count-2 do
  r(10,14+i*20,4,14,steel);r(11,15+i*20,1,12,silver)
  r(21,14+i*20,4,14,steel);r(22,15+i*20,1,12,silver)
 end end
 return b
end
local function shell(name)
 local a,r=canvas();a.w=40
 local hull=name:find('Slug') and {115,182,202} or name:find('Incendiary') and {235,118,57} or {65,145,235}
 r(0,2,3,14,brass);r(0,13,3,2,light);r(3,3,7,12,brass);r(4,4,5,2,dark);r(4,11,5,2,light)
 r(10,3,27,12,hull);r(11,4,25,2,{26,65,104});r(11,11,25,2,{163,220,252})
 r(10,3,1,12,dark);r(37,4,3,10,hull)
 for y=5,11,3 do r(36,y,3,1,{183,222,242}) end
 r(15,7,10,2,{210,229,238});r(17,7,6,2,hull) -- hull stamp outline, not a fake gauge
 local bands=name:find('Breaker') and 2 or name:find('Bushwhacker') and 3 or name:find('Halt') and 4 or 1
 for i=0,bands-1 do r(28+i*2,4,1,10,{185,212,224}) end
 if name:find('Slug') then r(38,6,2,6,silver);r(36,7,2,4,{67,83,97}) end
 return a
end
local energy_profiles={
 ['Scythe']={3,1,44},['Sickle']={4,2,44},['Double-Edge']={5,2,46},
 ['Trident']={3,3,44},['Sai']={2,2,38},['Talon']={2,1,35},
 ['Laser Cannon']={6,1,50},['Quasar']={6,1,52},['Scorcher']={3,1,42},
 ['Loyalist']={2,1,35},['Purifier']={5,1,48},['Accelerator']={4,2,50},
 ['Epoch']={5,3,48},['Blitzer']={3,3,40},['Arc Thrower']={5,1,46},
 ['Meltagun']={6,2,46},['Punisher Plasma']={4,1,46},
}
local function energy(name,family)
 local a,r=canvas();a.w=44;a.h=20
 local c=family=='plasma' and {177,129,255} or family=='arc' and {87,189,255} or {77,224,225}
 r(0,5,4,10,steel);r(1,6,2,8,silver);r(4,3,30,14,steel);r(5,4,28,12,{34,48,58})
 local p={3,1,44};local best=0
 for key,v in pairs(energy_profiles) do if name:find(key,1,true) and #key>best then p=v;best=#key end end
 local cores=p[2]
 for i=0,cores-1 do local y=5+i*10/cores;r(7,y,23,7/cores,c);r(8,y+4/cores,20,1,{223,249,255}) end
 local coils=p[1]
 for i=0,coils-1 do local x=8+i*21/coils;r(x,2,2,16,silver);r(x,4,1,12,steel) end
 r(34,4,4,12,silver);r(38,6,4,8,steel);r(42,8,2,4,c)
 r(6,17,25,1,silver);r(6,2,25,1,silver)
 if family=='arc' then r(16,7,8,2,{235,252,255});r(20,5,2,6,{235,252,255}) end
 -- Housing length is an artistic model distinction, not a measured weapon specification.
 local stretch=p[3]/44;for _,v in ipairs(a.runs) do v[1]=v[1]*stretch;v[3]=v[3]*stretch end;a.w=p[3]
 return a
end
local function rocket(name)
 local a,r=canvas();a.w=54;a.h=22
 local fat=name:find('Spear') and 2 or 0;local olive={99,121,77};local ink={36,44,35}
 r(7,6-fat,32,10+fat*2,olive);r(9,7-fat,28,2,ink);r(9,13+fat,26,2,{173,189,135})
 r(13,6-fat,2,10+fat*2,silver);r(33,6-fat,2,10+fat*2,{227,185,74})
 r(39,7-fat,6,8+fat*2,silver);r(45,8,5,6,silver);r(50,9,3,4,silver);r(53,10,1,2,silver)
 r(0,3,12,3,steel);r(2,0,6,3,silver);r(0,16,12,3,steel);r(2,19,6,3,silver)
 r(3,7,4,8,steel);r(4,9,2,4,{242,179,69});r(18,9,10,3,ink);r(20,10,6,1,silver)
 if name:find('Napalm') then r(39,7,6,8,{250,141,48});r(41,11,3,2,{255,216,92}) end
 if name:find('Commando') then r(24,4,6,2,steel);r(24,16,6,2,steel)
 elseif name:find('W.A.S.P.') then r(19,2,9,3,silver);r(19,17,9,3,silver)
 elseif name:find('Leveller') then r(29,6,4,10,{225,153,65})
 elseif name:find('Silo') then r(9,4,3,14,silver);r(20,4,3,14,silver) end
 return a
end
local function ordnance(name)
 local a,r=canvas();a.w=42;a.h=22
 local olive={97,117,71};local amber={239,181,64}
 local tall=name:find('Autocannon') and 4 or name:find('Ultimatum') and -3 or 0
 r(0,2,3,18,brass);r(0,16,3,3,light);r(3,3,20+tall,16,brass)
 r(4,4,18+tall,3,dark);r(4,14,18+tall,3,light);r(21+tall,3,2,16,dark)
 r(23+tall,4,11,14,olive);r(24+tall,5,9,2,{42,55,35});r(24+tall,14,8,2,{181,201,134})
 r(34+tall,6,4,10,olive);r(38+tall,8,2,6,olive)
 r(27+tall,4,2,14,amber);r(28+tall,8,1,6,{255,224,138})
 r(7,8,10,1,{229,189,108});r(35+tall,8,1,6,{190,207,147})
 r(18,3,1,16,{185,131,58})
 if name:find('Ultimatum') then r(29,9,4,4,{224,178,62});r(30,10,2,2,{48,52,33}) end
 a.w=40+tall
 return a
end
local function dart(name)
 local a,r=canvas();a.w=50;a.h=18
 local fins=name:find('Speargun') and 9 or name:find('Crossbow') and 7 or 5
 r(0,0,fins,3,steel);r(0,15,fins,3,steel);r(3,3,2,12,silver)
 r(5,7,32,4,silver);r(7,10,28,1,{243,250,255});r(7,7,28,1,{93,116,127})
 r(36,6,5,6,steel);r(41,7,5,4,silver);r(46,8,4,2,silver)
 r(10,6,2,6,{99,194,166});r(14,8,15,1,{230,244,239})
 r(1,2,fins-2,1,silver);r(1,15,fins-2,1,silver)
 r(32,7,1,4,steel);r(43,10,2,1,{243,250,255})
 if name:find('Crossbow') then r(36,5,5,8,{227,161,67});r(39,6,1,6,{255,215,131}) end
 return a
end
local function tool(name)
 local a,r=canvas();a.w=46;a.h=22;local yellow={231,189,65}
 if name:find('C4') then
  r(3,2,36,18,{79,99,64});r(4,3,34,2,{143,159,113});r(5,6,32,12,{47,66,43})
  for _,x in ipairs({8,31}) do r(x,2,3,18,yellow);r(x+1,4,1,14,{254,225,130}) end
  r(16,7,12,9,steel);r(17,8,10,7,silver);r(18,9,8,5,{59,95,80});r(20,11,4,1,yellow)
  r(22,16,2,5,steel);r(23,20,13,1,silver);r(36,15,1,6,silver)
 elseif name:find('Flag') then
  r(3,0,3,22,steel);r(3,1,1,20,silver);r(1,20,7,2,yellow)
  r(6,9,35,12,yellow);r(7,10,32,2,{254,224,119});r(7,9,32,1,{130,105,41})
  r(16,12,11,6,steel);r(19,11,5,8,steel);r(20,14,3,2,silver)
  r(40,10,3,10,{178,142,51});r(41,11,3,8,{209,171,65})
 elseif name:find('Hatchet') then
  r(15,0,5,18,steel);r(16,1,1,16,silver)
  for y=1,10,3 do r(15,y,5,1,{98,109,111}) end
  r(2,13,35,8,silver);r(2,14,3,6,{240,247,250});r(5,14,22,2,{112,134,146})
  r(28,15,8,4,steel);r(16,17,3,2,yellow);r(17,17,1,1,light)
 else
  local lance=name:find('Lance');local stun=name:find('Stun')
  r(0,7,13,8,steel);r(2,8,10,2,{105,123,133})
  for x=2,11,3 do r(x,7,1,8,{30,38,43}) end
  r(12,4,3,14,yellow);r(13,5,1,12,light)
  r(15,7,23,8,silver);r(16,8,21,2,{103,124,138});r(16,13,21,1,{244,250,253})
  if stun then
   for x=19,34,5 do r(x,6,2,10,{88,186,222});r(x,8,1,6,{226,250,255}) end
   r(38,8,5,6,steel);r(43,9,3,4,{142,230,250})
  else
   r(38,8,4,6,silver);r(42,9,3,4,silver);r(45,10,1,2,silver)
   r(18,10,15,1,{221,234,241})
  end
  if lance then for _,v in ipairs(a.runs) do if v[1]>=15 then v[1]=15+(v[1]-15)*1.25;v[3]=v[3]*1.25 end end;a.w=54 end
 end
 return a
end
local function fuel_vessel(name)
 local a,r=canvas();a.w=56;a.h=28
 local gas=name:lower():find('chem',1,true) or name:find('Sterilizer',1,true)
 local body=gas and {114,147,67} or {181,130,67};local highlight=gas and {196,224,121} or {239,196,117}
 -- Insulated tank, captive retaining straps, regulator spindle and routed pipe.
 r(7,4,31,20,{31,41,45});r(9,5,27,18,body);r(11,6,23,3,highlight);r(11,19,23,2,{65,71,45})
 for _,x in ipairs({12,29}) do r(x,3,4,22,silver);r(x+1,5,1,18,{244,240,213});r(x+3,5,1,18,steel) end
 r(17,11,9,5,{43,56,41});r(20,12,3,3,highlight)
 r(38,10,9,8,steel);r(39,11,7,2,silver);r(40,16,5,1,silver)
 r(42,18,2,5,brass);r(39,23,8,2,brass);r(41,22,4,1,light)
 r(47,12,4,4,brass);r(50,5,2,10,silver);r(45,3,9,2,silver);r(45,4,2,3,steel)
 r(1,4,6,3,steel);r(1,21,6,3,steel);r(3,7,2,14,silver)
 for k=0,2 do r(18+k*3,2,1.5,1,highlight);r(18+k*3,25,1.5,1,highlight) end
 return a
end
local function build_icon(style,m,fallback)
 local f,name=style.family,style.name
 if f=='rifle' or f=='precision' or f=='sidearm' or f=='compact' or f=='belt' then
  local p=profiles.Liberator
  -- Most specific designation wins; aliases retain the family specification.
  local best=0
  for key,v in pairs(profiles) do if name:find(key,1,true) and #key>best then p=v;best=#key end end
  local n=f=='belt' and 3 or (m.fire_mode=='AUTO' or m.fire_mode=='BURST') and 3 or 1
  return stacked(cartridge(p),n,f=='belt')
 elseif f=='shotgun' then
  if m.resource_hex=='72170a55a1f37ff1' then
   local b={w=150,h=110,runs={},loaded={}}
   local function rect(x,y,w,h,color)b.runs[#b.runs+1]={x,y,w,h,color,1}end
   local function disc(cx,cy,r,color)
    for y=-r,r-1,2 do
     local height=math.min(2,r-y);local dy=y+height/2
     local half=math.sqrt(math.max(0,r*r-dy*dy))
     local c=type(color)=='function' and color((dy+r)/(2*r)) or color
     rect(cx-half,cy+y,half*2,height,c)
    end
   end
   -- A steel breech block, chamfered at its corners, carries two circular bores.
   for y=20,95,2 do
    local inset=y<32 and (32-y)*.8+6 or y>83 and (y-83)*.8+6 or 6
    local shade=math.floor(80+(y-20)*.48+3*math.sin(y*1.4))
    rect(inset,y,150-2*inset,2,{shade+3,shade+1,shade})
   end
   rect(18,96,114,.8,{215,211,203});rect(17,94,116,.6,{164,164,161})
   rect(5,33,.8,51,{189,184,177});rect(144,33,.8,51,{169,169,166})
   rect(18,20,114,.7,{46,42,36});rect(3,48,3,16,{67,67,67});rect(144,48,3,16,{67,67,67})
   rect(2,62,4,.7,{184,184,178});rect(144,62,4,.7,{184,184,178})
   rect(42,20,.7,12,{33,31,29});rect(108,20,.7,12,{33,31,29})
   for barrel=1,2 do
    local cx=barrel==1 and 42 or 108
    local loaded=m.fire_mode=='VOLLEY' and m.value>=2 or (m.fire_mode~='VOLLEY' and m.value>=(barrel==1 and 2 or 1))
    b.loaded[barrel]=loaded
    disc(cx,62,32,{34,29,22})
    disc(cx,62,31,function(t)local v=math.floor(108+70*t);return {v+3,v+2,v}end)
    disc(cx,62,29,{35,31,26})
    if loaded then
     disc(cx,62,27,function(t)return {math.floor(165+40*t),math.floor(137+34*t),math.floor(80+23*t)}end)
     disc(cx,62,25,function(t)return {math.floor(151+38*t),math.floor(126+32*t),math.floor(77+22*t)}end)
     disc(cx,62,9,{52,34,14});disc(cx,62,8,{180,139,63})
     disc(cx,62,6,{30,30,30});disc(cx,62,5,function(t)local v=math.floor(121+59*t);return {v-6,v,v+12}end)
     rect(cx-2,65,4,.6,{223,225,224});rect(cx-4,60,.5,4,{205,209,207})
     rect(cx+3.5,59,.6,3,{81,89,98})
    else
     disc(cx,62,27,function(t)local v=math.floor(12+16*(1-t));return {v,v,v+1}end)
     disc(cx,62,24,{7,9,11});disc(cx,62,21,{4,6,8})
    end
   end
   disc(75,28,7,{34,33,31});disc(75,28,5,{145,146,146});disc(75,28,3,{9,11,13})
   assert(#b.runs<=448,'cached detailed breech geometry budget')
   return b
  end
  return stacked(shell(name),m.fire_mode=='VOLLEY' and 3 or 1,false)
 elseif f=='laser' or f=='plasma' or f=='arc' then return energy(name,f)
 elseif f=='rocket' then return rocket(name)
 elseif f=='explosive' then return ordnance(name)
 elseif f=='dart' then return dart(name)
 elseif f=='tool' then return tool(name)
 elseif f=='fuel' then return fuel_vessel(name)
 elseif f=='medical' then
  local a=dart(name);for _,r in ipairs(a.runs) do if r[1]>=5 and r[1]<=35 then r[5]={94,217,163} end end;return a
 end
 -- Already bespoke darts, grenades, tools and fuel symbols keep their real silhouette.
 return fallback
end
local cache={}
function M.icon(style,m,fallback)
 if m.resource_hex=='72170a55a1f37ff1' then
  local key='breech/'..tostring(m.fire_mode)..'/'..tostring(m.value)
  if not cache[key] then cache[key]=build_icon(style,m,fallback) end
  return cache[key]
 end
 local key=style.name..'/'..tostring(m.fire_mode)..'/'..tostring(fallback)
 if not cache[key] then cache[key]=build_icon(style,m,fallback) end
 return cache[key]
end
-- Recolor only the verified Autocannon FLAK projectile; shared source art stays immutable.
local flak_icons={}
local function standard_autocannon_icon(m,icon)
 if not icon or m.resource_hex~='a8cffb316f0b5c5f' or m.ammo_mode~='FLAK' then return icon end
 if flak_icons[icon] then return flak_icons[icon] end
 local copy={};for k,v in pairs(icon) do copy[k]=v end;copy.runs={}
 for _,run in ipairs(icon.runs) do
  local r={};for k,v in pairs(run) do r[k]=v end
  -- Existing grenade-shell silhouette: projectile begins at x14, brass casing ends at x14.
  if r[1]>=14 then
   local c=r[5]
   if r[1]==16 then r[5]={255,183,48}
   elseif c and c[1]<80 then r[5]={132,60,22}
   elseif c and c[1]>160 then r[5]={255,215,126}
   else r[5]={240,128,43} end
  end
  copy.runs[#copy.runs+1]=r
 end
 flak_icons[icon]=copy;return copy
end
-- Approved long Autocannon case; explicit false retains legacy art for comparison.
local long_icons={}
function M.autocannon_icon(m,icon,preview)
 local original=standard_autocannon_icon(m,icon)
 if preview==false or not original or m.resource_hex~='a8cffb316f0b5c5f' then return original end
 if long_icons[original] then return long_icons[original] end
 local copy={w=original.w+20,h=original.h,runs={}}
 for _,run in ipairs(original.runs) do
  local r={};for k,v in pairs(run) do r[k]=v end
  if r[1]>=12 then r[1]=r[1]+20
  elseif r[1]==3 then r[3]=r[3]+20 end
  copy.runs[#copy.runs+1]=r
 end
 long_icons[original]=copy;return copy
end
return M

