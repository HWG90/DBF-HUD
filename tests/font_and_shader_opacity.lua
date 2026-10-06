HUD={};for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=dofile('src/'..name..'.lua')end end
local cfg=HUD.config.new();local text={type='text',text='025',x=20,y=30,size=12,font='bigblue',c={255,255,255},a=1}
local art={type='texture',x=0,y=0,w=100,h=80,a=1}
local commands={art,text}
assert(HUD.font_scale.apply(commands,cfg)==commands)
cfg.font_scale=1.5;local out=HUD.font_scale.apply(commands,cfg)
local l,b,r,t=HUD.font.measure(text.text,text.size,text.font,true)
local nl,nb,nr,nt=HUD.font.measure(out[2].text,out[2].size,out[2].font,true)
assert(out[1]==art and out[2].size==18 and text.size==12)
assert(math.abs(text.x+(l+r)/2-out[2].x-(nl+nr)/2)<1e-9)
assert(math.abs(text.y+(b+t)/2-out[2].y-(nb+nt)/2)<1e-9)
local legacy={shader_layers={{id=1,shader='crt_scan',strength=2,scale=2}},panel_opacity=.8}
assert(HUD.shader_layers.effective(legacy)[1].opacity==.4,'legacy alpha changed')
for _,alpha in ipairs({.01,1})do
 local rows=HUD.shader_layers.validate({{id=1,shader='crt_scan',opacity=alpha}})
 local expanded=HUD.screen_scene.expand_shader_layers({{type='panel',x=0,y=0,w=100,h=80}}, {shader_layers=rows,panel_opacity=.1})
 assert(expanded[2].a==alpha,'shader opacity coupled to backing')
end
assert(not pcall(HUD.shader_layers.validate,{{id=1,shader='crt_scan',opacity=0}}))
assert(not pcall(HUD.shader_layers.validate,{{id=1,shader='crt_scan',opacity=1.01}}))
print('PASS font sizing preserves measured center/artwork; legacy shader alpha retained;0.01/1 alpha endpoints independent of backing; invalid endpoints rejected')
