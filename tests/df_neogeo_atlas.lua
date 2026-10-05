HUD={native_font_data=dofile('src/native_font_data.lua')}
HUD.font=dofile('src/font.lua')
HUD.config={rgb=function(s)local a,b,c=s:match('#(%x%x)(%x%x)(%x%x)');return {tonumber(a,16),tonumber(b,16),tonumber(c,16)}end}
local M=dofile('src/df_neogeo_atlas.lua')
local function compose(m)return M.compose(m,0,0,1,.8,{panel_opacity=.25,text_opacity=.5,text_color='#ABCDEF',background_color='#102030'})end
local function role(a,r)local t={} for _,v in ipairs(a)do if v.render_role==r then t[#t+1]=v end end return t end
local a=compose({value=2,reserve=40,fire_mode='SEMI'})
local textures=0;for _,v in ipairs(a)do if v.type=='texture'then textures=textures+1;if v.atlas_rect then assert(v.atlas_rect[1]+v.atlas_rect[3]<=1 and v.atlas_rect[2]+v.atlas_rect[4]<=1)end end end;assert(textures==5)
assert(role(a,'backing')[1].a==.2)
for _,v in ipairs(role(a,'state'))do assert(v.c[1]==255 and v.c[2]==255 and v.texture_theme==false)end
for _,v in ipairs(role(a,'rim'))do assert(v.c[1]==16 and v.c[2]==32)end
local labels={};for _,v in ipairs(a)do if v.text=='SEMI' or v.text=='VOLLEY'then labels[#labels+1]=v end end
assert(labels[1].size==labels[2].size and labels[1].readout_zone.cx+labels[2].readout_zone.cx==160)
local fired=role(compose({value=1,df_shell_spent={true,false}}),'state');assert(fired[1].a==.8*.42 and fired[2].a==.8)
local empty=role(compose({value=0,df_ejector_open=true}),'state');assert(empty[1].atlas_rect[1]==2/3 and empty[2].atlas_rect[1]==2/3)
assert(role(compose({}),'state')[1].a==.8*.2)
local title=false;for _,v in ipairs(a)do if v.text=='DOUBLE FREEDOM'then title=true end end;assert(title)
print('PASS hybrid states, separated tint, equal mode scale, symmetric spacing, five texture budget')

for _,v in ipairs(labels)do local l,b,r,t=HUD.font.measure(v.text,v.size,v.font);assert(t-b>=6,'selector stayed microscopic');assert(r-l<=42.001,'selector exceeded cell') end
print('PASS selector actual glyph height and cell width')

local present={}
assert(not M.ready(function(name)return present[name]end))
for _,v in ipairs(a)do if v.texture_resource then present[v.texture_resource]=true end end
assert(M.ready(function(name)return present[name]end))
present['mods/dbf_hud/textures/df_neogeo_rim_neutral']=nil
assert(not M.ready(function(name)return present[name]end))
print('PASS atlas readiness requires every drawn resource')
