HUD={}
for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end end
local cfg=HUD.config.new();cfg.decoration='outline';cfg.texture_art_trial=false
local frame={type='panel',x=0,y=0,w=100,h=80,c={0,0,0},a=0}
local image={type='texture',x=0,y=0,w=100,h=80,c={255,255,255},a=1,texture_resource='artwork'}
local out=HUD.layout.decorate_textures({frame,image,{type='rect',decoration=true,x=0,y=0,w=1,h=1}},1,cfg,1)
local count=0;for _,v in ipairs(out)do if v.decoration then count=count+1 end end
assert(count==4 and out[2]==image and image.a==1 and image.c[1]==255,'decoration altered artwork or doubled perimeter')
cfg.decoration='none';out=HUD.layout.decorate_textures(out,1,cfg,1);assert(#out==2 and out[2]==image)
local plain={frame};assert(HUD.layout.decorate_textures(plain,1,cfg,1)==plain,'primitive housing must keep its existing decoration path')
cfg.hud_presentation='practical';cfg.decoration='outline';cfg.style_3d='hologram'
local simple=HUD.view_presentation.compose({value=2,reserve=31,fire_mode='SEMI'},0,0,1,1,cfg)
for _,v in ipairs(simple)do assert(not v.decoration and v.type~='texture')end
print('PASS texture perimeter selectable/removable without changing sprite pixels, no duplicate primitive decoration, Simple has no decoration/style overlays')
