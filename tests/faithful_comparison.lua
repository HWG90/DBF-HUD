HUD={}
for _,name in ipairs({'native_font_data','native_font_uv','native_font','config','font','motion','ammo_types','model','fire_icons','munition_art','mg_easter','df_shell_state','recoilless_state','senator_state','melta_panel','speargun_panel','recoilless_panel','catalog_housing','sta11_panel','weapon_styles','layout','faithful_fragment_assets','faithful_fragments'})do HUD[name]=assert(loadfile('src/'..name..'.lua'))()end
local cfg=HUD.config.new();cfg.panel_opacity=1
local measure=function(t,size,font)return HUD.font.measure(t,size,font or cfg.font,true)end
local asset=HUD.faithful_fragment_assets['4ba41b6f9f405cc2']
local textured=0
for _,scale in ipairs({.25,1,2})do
 for _,rounds in ipairs({0,32,48,49})do
  local model={resource_hex='4ba41b6f9f405cc2',value=rounds,capacity=48,reserve=3,kind='magazine',label='ROUNDS',fire_mode='AUTO'}
  local original=HUD.layout.compose(model,12,15,scale,1,cfg,0,measure)
  local out=HUD.faithful_fragments.prepare(original,asset.spec,asset.assets,12,15,scale,1,cfg,function()return true end)
  assert(out~=original,'faithful match failed')
  local count=0;local retained={};for _,v in ipairs(out)do if v.faithful_fragment then count=count+1 else retained[v]=true end end
  assert(count==4)
  for _,v in ipairs(original)do if v.type~='rect' then assert(retained[v],'live command replaced')end end
  assert(HUD.faithful_fragments.prepare(original,asset.spec,asset.assets,12,15,scale,1,cfg,function()return false end)==original)
  cfg.panel_opacity=.8;assert(HUD.faithful_fragments.prepare(original,asset.spec,asset.assets,12,15,scale,1,cfg,function()return true end)==original);cfg.panel_opacity=1
  textured=textured+1
 end
end
print('PASS '..textured..' current STA11 state/scale layouts; four ordered fragments, unchanged live objects, resource/opacity fallback')
