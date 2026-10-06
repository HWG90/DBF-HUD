HUD={native_font_data={order={},faces={bigblue=true}}}
HUD.config=dofile('src/config.lua');HUD.shader_layers=dofile('src/shader_layers.lua')
local L,C=HUD.shader_layers,HUD.config
local c=C.new();assert(#L.effective(c)==0)
C.apply(c,{theme_shader='carbon',theme_shader_scale=1.35,effect_shader='crt_scan'})
assert(c.shader_layers==nil and c.theme_shader_scale==1.35)
local rows=L.effective(c);assert(#rows==2 and rows[1].shader=='carbon' and rows[2].shader=='crt_scan')
C.apply(c,L.edit(c,'add'));assert(#c.shader_layers==3)
local id=c.shader_layers[3].id;C.apply(c,L.edit(c,'up',id));assert(c.shader_layers[2].id==id)
C.apply(c,L.edit(c,'strength',id,2));C.apply(c,L.edit(c,'blend',id,3))
local a,b=L.words(c.shader_layers,1);assert(a>0 and a<16777216 and b<16777216)
-- Signed depth encoding keeps both words exactly representable in a float
assert(a<16777216)
local restored=assert(loadstring(C.serialize(c)))();local round=C.new();C.apply(round,restored)
assert(round.shader_layers[2].id==id and round.shader_layers[2].strength==2)
local weapon='0123456789abcdef';C.set_panel(c,weapon,{shader_layers={}});assert(#C.effective(c,weapon).shader_layers==0)
C.set_panel(c,weapon,{shader_layers=c.shader_layers});assert(#C.effective(c,weapon).shader_layers==3)
local before=C.serialize(c);assert(not pcall(C.apply,c,{shader_layers={{id=1,shader='bad'}}}));assert(C.serialize(c)==before)
assert(not pcall(L.validate,{[2]={id=1,shader='carbon'}}))
C.apply(c,L.edit(c,'remove',id));assert(not pcall(L.edit,c,'remove',id))
C.apply(c,L.edit(c,'add'));C.apply(c,L.edit(c,'add'));assert(not pcall(L.edit,c,'add'))
print('PASS shader lists, migration, ordering, stable identities, validation, persistence and bounds')

local calls=0;local rows={{id=1,shader='carbon',scale=2,strength=4,blend=1}}
for i=1,10 do assert(L.material('missing',rows,function()calls=calls+1;return false end)=='missing')end
assert(calls==1,'material availability was queried every frame')
for _,e in ipairs(HUD.shader_catalog)do for scale=1,4 do for strength=1,4 do for blend=1,3 do
 local r={};for i=1,4 do r[i]={id=i,shader=e.id,scale=scale,strength=strength,blend=blend}end
 local x,y=L.words(r,1);local off=L.words(r,0);assert(x>0 and x<16777216 and y<16777216 and off==-x)
end end end end
print('PASS all catalog IDs and parameter combinations fit exact float words; material lookup is cached')

assert(L.status({shader_layers={}},function()error('empty list queried native asset')end):find('0 shader layers',1,true))
assert(L.status({shader_layers={{id=1,shader='carbon',enabled=false}}},function()return false end):find('0 enabled',1,true))
print('PASS layer status reflects authoritative enabled settings and missing native material')
