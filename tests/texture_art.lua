local M=assert(loadfile('src/texture_art.lua'))()
local spec={w={version=1,layers={{id='receiver',material='art_material',texture='art_texture',command_count=2,aspect=2}}}}
for _,s in ipairs({.05,.25,1,4})do
 local commands={{type='panel',x=0,y=0,w=20*s,h=10*s},
 {type='rect',x=0,y=0,w=10*s,h=10*s,texture_art_layer='receiver',texture_art_static=true,texture_art_opacity=.8},
 {type='text',text='032'},
 {type='rect',x=10*s,y=0,w=10*s,h=10*s,texture_art_layer='receiver',texture_art_static=true,texture_art_opacity=.8},
 {type='rect',charge_meter=true,w=3,h=1}}
 local out=M.prepare(commands,'w',function()return true end,spec)
 assert(#out==4 and out[2].type=='texture' and out[2].w==20*s and out[2].h==10*s and out[2].a==.8)
 assert(out[1]==commands[1] and out[3]==commands[3] and out[4]==commands[5])
 assert(M.prepare(commands,'other',function()return true end,spec)==commands)
 assert(M.prepare(commands,'w',function(k)return k~='texture' end,spec)==commands)
 commands[2].charge_meter=true;assert(M.prepare(commands,'w',function()return true end,spec)==commands);commands[2].charge_meter=nil
 commands[2].x=0/0;assert(M.prepare(commands,'w',function()return true end,spec)==commands);commands[2].x=0
 commands[2].type='text';assert(M.prepare(commands,'w',function()return true end,spec)==commands)
end
print('PASS static texture groups, dynamic retention, scaling, opacity and primitive fallback')
local commands={{type='rect',x=2,y=3,w=4,h=2,texture_art_layer='receiver',texture_art_static=true,texture_art_opacity=.6,texture_art_box={x=0,y=0,w=20,h=10}}}
local variants={w={version=1,layers={{id='receiver',command_count=1,aspect=2}},variants={faithful={receiver={material='faithful_mat',texture='faithful_tex'}},realistic={receiver={material='realistic_mat',texture='realistic_tex'}}}}}
local a=M.prepare(commands,'w',function()return true end,variants,'faithful')
local b=M.prepare(commands,'w',function()return true end,variants,'realistic')
assert(a[1].texture_resource=='faithful_tex' and b[1].texture_resource=='realistic_tex')
assert(a[1].x==b[1].x and a[1].w==b[1].w and a[1].w==20 and a[1].h==10 and a[1].a==.6)
assert(M.prepare(commands,'w',function()return true end,variants,'unknown')==commands)
print('PASS faithful/realistic variants retain identical full-canvas geometry and opacity')
