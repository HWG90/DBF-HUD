HUD={}
for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end end
local M=HUD.df_retro_panel;local cfg=HUD.config.new();local resource=function()return 'ready'end
for _,n in ipairs({0,1,2})do
 local out=M.compose({value=n,reserve=31,fire_mode='SEMI',compass_heading=90},0,0,1,1,cfg,resource)
 local shells,selectors,digits={},{},{}
 for _,v in ipairs(out)do
  assert(v.type~='text','atlas presentation must sample lettering')
  if v.atlas_region=='loaded_shell' or v.atlas_region=='fired_shell' then shells[#shells+1]=v;assert(v.w==128*128/600 and v.h==384*128/600)end
  if v.atlas_region=='selector' then selectors[#selectors+1]=v end
  if v.atlas_region and v.atlas_region:match('^digit_') then digits[#digits+1]=v.atlas_region end
 end
 assert(#shells==2 and #selectors==2 and table.concat(digits,',')=='digit_0,digit_3,digit_1')
 local states=HUD.df_retro_spec.state_contract[tostring(n)];assert(shells[1].atlas_region==states[1] and shells[2].atlas_region==states[2])
 assert(#HUD.screen_scene.expand_texture_layers(out)==#out)
end
local out=M.compose({},0,0,1,1,cfg,resource)
for _,v in ipairs(out)do assert(v.atlas_region~='loaded_shell' and v.atlas_region~='fired_shell' and v.atlas_region~='selector' and not(v.atlas_region and v.atlas_region:match('^digit_')))end
cfg.panel_opacity=0;out=M.compose({value=2,reserve=100000,fire_mode='VOLLEY',compass_heading=359},0,0,1,1,cfg,resource)
assert(out[2].a==0 and out[3].a==1,'backing slider dimmed artwork')
local images=0;for _,v in ipairs(HUD.screen_scene.expand_texture_layers(out))do if v.type=='texture'then images=images+1 end end;assert(images<=HUD.screen_scene.max_texture_images)
cfg.force_all_hud_texture_off=true;assert(M.compose({value=2},0,0,1,1,cfg,resource)==nil)
local raw=M.primitive({value=2,reserve=31,fire_mode='SEMI'},0,0,1,1,cfg)
for _,v in ipairs(raw)do assert(v.type~='texture' and v.x==v.x and v.y==v.y)end
for _,size in ipairs({{224,672},{600,988},{76,108}})do
 local boxes=HUD.screen_scene.feather_boxes(size[1],size[2],6/size[1],6/size[2]);local area=0
 assert(#boxes==17 and boxes[#boxes][5]==1)
 for _,v in ipairs(boxes)do area=area+v[3]*v[4];assert(v[1]>=0 and v[2]>=0 and v[1]+v[3]<=size[1]+1e-9 and v[2]+v[4]<=size[2]+1e-9 and v[5]>0 and v[5]<=1)end
 assert(math.abs(area-size[1]*size[2])<1e-6,'edge bands overlap or leave gaps')
end
print('PASS v2 cell UVs, loaded/fired/unknown bounds, texture digits/selectors, independent backing, force-off primitive fallback, bounded slots and feather geometry')
