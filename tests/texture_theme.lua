HUD={shader_catalog={{id='carbon'}}}
local M=dofile('src/texture_theme.lua')
local seen;local function exists(kind,name)seen=name;return true end
assert(M.material('art','carbon',exists)=='art_texture_theme_carbon')
assert(M.material('art','none',exists)=='art' and M.material('art','auto',exists)=='art')
assert(M.material('missing','carbon',function()return false end)=='missing')
for _,scale in ipairs({.25,1,4})do for _,time in ipairs({0,.125,1023.9375,1024})do for _,animated in ipairs({0,1})do
 local word=M.parameters(1,scale,time,animated)
 assert(word%2==1 and word<16777216)
 assert(math.floor(word/2)%256/32==scale)
 assert(math.floor(word/512)%16384/16==math.floor(time*16)%16384/16)
 assert(math.floor(word/8388608)==animated)
end end end
assert(M.parameters(0,0/0,math.huge,0)==64)
print('PASS texture material selection/fallback and exact depth/scale/time/animation encoding')
