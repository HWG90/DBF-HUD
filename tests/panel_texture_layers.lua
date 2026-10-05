local layers=dofile('src/panel_texture_layers.lua')
local scene=dofile('src/screen_scene.lua')
local definitions=layers.double_freedom({texture='blue-shell',material='shell-material'},
 {{.2,.3,.2,.5},{.6,.3,.2,.5}})
local function available()return true end
local base={type='texture',texture_resource='empty-housing',texture_material='panel-material',x=0,y=0,w=100,h=100,a=1}
for _,mode in ipairs({'SEMI','VOLLEY'})do
 for _,n in ipairs({2,1,0,2,0,1,2})do
  base.texture_layers=layers.prepare(definitions,{value=n,fire_mode=mode},available)
  local commands=scene.expand_texture_layers({base})
  assert(#commands==1+n,'loaded shell image count differs from ammunition')
  assert(commands[1].texture_resource=='empty-housing')
  if n==1 then assert(commands[2].x==60,'wrong remaining barrel')end
 end
end
for _,n in ipairs({-1,.5,'2',0/0})do
 base.texture_layers=layers.prepare(definitions,{value=n},available)
 assert(#scene.expand_texture_layers({base})==1,'unknown count invented loaded shells')
end
assert(not layers.prepare(definitions,{value=0},function(_,name)return name~='blue-shell'end),'missing hidden image did not fall back')
assert(definitions[1].visible==nil and definitions[1].state.threshold==2,'shared definitions mutated')
local rows={2,3,4,5,6,7,.1,.2,1}
local mapped=scene.atlas_rows(rows,{.25,.5,.125,.25})
for _,point in ipairs({{0,0},{.2,.8},{1,1}})do
 local x,y=point[1],point[2];local denominator=rows[7]*x+rows[8]*y+rows[9]
 local u=(rows[1]*x+rows[2]*y+rows[3])/denominator
 local v=(rows[4]*x+rows[5]*y+rows[6])/denominator
 assert(math.abs((mapped[1]*x+mapped[2]*y+mapped[3])/denominator-(.25+.125*u))<1e-9)
 assert(math.abs((mapped[4]*x+mapped[5]*y+mapped[6])/denominator-(.5+.25*v))<1e-9)
end
assert(rows[1]==2 and mapped[7]==rows[7],'atlas mapping mutated shared projection')
assert(not pcall(scene.atlas_rows,rows,{.9,0,.2,1}),'out-of-bounds atlas region accepted')
print('panel image state: semi/volley firing, partial/full reload, unknown count and missing-asset fallback passed')
print('atlas mapping: perspective-preserving regions and bounds passed')
