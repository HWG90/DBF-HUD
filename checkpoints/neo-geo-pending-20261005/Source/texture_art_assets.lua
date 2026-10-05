-- Optional isolated native trial assets. Missing resources preserve primitive art.
local layers={};local variants={faithful={},realistic={}}
for i,name in ipairs({'underlay','recesses','details'})do
 local id='liberator.'..name
 layers[i]={id=id,command_count=({50,2,53})[i],aspect=124/110}
 for _,variant in ipairs({'faithful','realistic'})do
  variants[variant][id]={material='mods/dbf_hud/materials/texture_liberator_'..variant..'_'..name,texture='mods/dbf_hud/textures/liberator_'..variant..'_'..name}
 end
end
return {['968211c0033dce64']={version=1,layers=layers,variants=variants}}

