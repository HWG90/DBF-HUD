HUD={mechanical_layouts=dofile('src/mechanical_layouts.lua'),config={rgb=function()return {216,223,201}end},font={measure=function(t,s)return 0,0,#t*s*.5,s*.75 end}}
local art=dofile('src/mechanical_art.lua')
local id='e8d5f49ad7780e54';local projected='mods/dbf_hud/textures/projected_'..id
local function compose(hot,missing,weapon)
 local out,active=art.compose({}, {resource_hex=weapon or id,value=1,reserve=4,reserve_kind='BATTERIES',capacity=3,fraction=1},0,0,1,.7,{panel_opacity=.4},0,nil,function(kind,name)return name~=missing end,hot)
 assert(active)
 for _,v in ipairs(out)do if v.type=='texture'then return v,out end end
 error('No texture')
end
local packed=compose(function()return nil end)
assert(packed.texture_material=='mods/dbf_hud/materials/projected_'..id)
local clean,list=compose(function(t)return t==projected and {}end)
assert(clean.texture_material=='mods/dbf_hud/materials/mechanical_'..id)
assert(clean.texture_resource==projected and math.abs(clean.a-.28)<1e-6)
local fallback=compose(function(t)return t==projected and {}end,'mods/dbf_hud/materials/mechanical_'..id)
assert(fallback.texture_material==packed.texture_material)
local neighbor=compose(function()return {}end,nil,'fb3a19078694708a')
assert(neighbor.texture_material=='mods/dbf_hud/materials/projected_fb3a19078694708a')
local reserve=false
for _,v in ipairs(list)do if v.type=='text'and v.text=='004 BATTERIES'then reserve=true end end
assert(reserve,'Live reserve lost')
local meter=0
for _,v in ipairs(list)do if v.type=='rect'and v.mechanical_live then
 meter=meter+1
 local top=1-(v.y+v.h-clean.y)/clean.h;local bottom=1-(v.y-clean.y)/clean.h
 assert(top>=.30 and bottom<.34,'Ammo meter overlaps label or count')
end end
assert(meter==3,'Ammo segmentation lost')
print('EPOCH: publication-gated material, missing-material fallback, transparency multiplier, live reserve and neighboring weapon preserved')
