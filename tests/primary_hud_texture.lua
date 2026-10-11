-- Approved primary art plugs into the established HUD Texture composer only.
HUD={native_font_data=dofile('src/native_font_data.lua'),segmented_primary_specs=dofile('src/segmented_primary_specs.lua'),ballistic_family_specs=dofile('src/ballistic_family_specs.lua')}
HUD.config=dofile('src/config.lua');HUD.font=dofile('src/font.lua');HUD.compass=dofile('src/compass.lua')
HUD.layout=dofile('src/layout.lua');HUD.edge_mask=dofile('src/edge_mask.lua')
HUD.segmented_fancy=dofile('src/segmented_fancy.lua')
HUD.shader_layers=dofile('src/shader_layers.lua');HUD.texture_theme=dofile('src/texture_theme.lua')
local Family=dofile('src/ballistic_family.lua');local Art=HUD.segmented_fancy;local Scene=dofile('src/screen_scene.lua')
local resources={[Art.face]=true,[Art.atlas]=true}
local function resource(name)return resources[name]end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function copy(t)local q={};for k,v in pairs(t)do q[k]=v end;return q end
local cfg=HUD.config.new();cfg.segmented_fancy=false;cfg.texture_art_trial=true;cfg.texture_art_variant='faithful';cfg.style_clock=.25
cfg.text_color='#FFFFFF';cfg.decoration_color='#E9C45D';cfg.background_color='#091B35';cfg.panel_opacity=.3
local model={resource_hex='968211c0033dce64',kind='magazine',value=0,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',fraction=.6,state='EMPTY'}
local n=0
for id in pairs(Art.specs)do
 local m=copy(model);m.resource_hex=id;local before=copy(cfg)
 local out=assert(Family.compose(m,10,20,1,.8,cfg,resource),'Primary HUD Texture unavailable: '..id)
 assert(out[1].hud_texture_primary and out[1].atlas_frame and out[1].a==0 and out[2].coverage_mask)
 assert(Family.ready(id,resource));assert(equal(cfg,before),'Composer mutated saved appearance')
 local images=0;for _,v in ipairs(out)do
  assert(not v.segmented_fancy,'Special renderer flag escaped into HUD Texture commands')
  if v.type=='texture'then images=images+1;assert(v.texture_theme~=false and resources[v.texture_resource])end
  if v.type=='text'then assert(v.texture_readout and v.readout_zone and v.render_role=='readout')end
 end
 assert(images==20);n=n+1
end
assert(n==54)
for _,variant in ipairs({'original','realistic','study'})do local q=copy(cfg);q.texture_art_variant=variant;assert(not Family.compose(model,0,0,1,1,q,resource),'Alternative artwork selection overridden')end
local q=copy(cfg);q.texture_art_trial=false;assert(not Family.compose(model,0,0,1,1,q,resource))
q=copy(cfg);q.force_all_hud_texture_off=true;assert(not Family.compose(model,0,0,1,1,q,resource))
for _,key in ipairs({'presentation_view','hud_presentation'})do q=copy(cfg);q[key]=key=='presentation_view'and'third'or'practical';assert(not Family.compose(model,0,0,1,1,q,resource),'Simple composed primary texture art')end
for _,id in ipairs({'e8d5f49ad7780e54','416d053372c4e433','4e4a613eb9bf5c24'})do local m=copy(model);m.resource_hex=id;local out=Family.compose(m,0,0,1,1,cfg,resource);assert(not out or not out[1].hud_texture_primary,'Unsupported primary identity adopted')end
resources[Art.face]=nil;assert(not Family.compose(model,0,0,1,1,cfg,resource),'Missing cached face prevented normal fallback')
resources[Family.mask]=true;resources['mods/dbf_hud/textures/ballistic_family_'..model.resource_hex]=true
local legacy=assert(Family.compose(model,0,0,1,1,cfg,resource));assert(legacy[1].ballistic_family and not legacy[1].hud_texture_primary and legacy[1].w==148,'Existing ballistic art fallback changed')
resources[Art.face]=true
-- Policy decisions belong to config; use the shared selector unchanged to prove decoration dispatch.
local policy=HUD.config.texture_policy;HUD.config.texture_policy=function(c)return c end
cfg.decoration='outline';cfg.theme_shader='crt_scan';cfg.style_3d='hologram';local before=copy(cfg)
local out=assert(Family.compose(model,0,0,1,1,cfg,resource));local decoration=0
for _,v in ipairs(out)do if v.decoration then decoration=decoration+1;assert(v.type=='rect'and v.c[1]==233 and v.c[2]==196 and v.c[3]==93)end end
assert(decoration==4 and equal(cfg,before),'Shared perimeter selector or saved appearance changed')
assert(HUD.texture_theme.material(out[2].texture_material,cfg.theme_shader,function()return true end):find('_texture_theme_crt_scan',1,true),'Existing theme material cannot target primary art')
cfg.shader_layers={};for i=1,4 do cfg.shader_layers[i]={id=i,shader='crt_scan',opacity=.2,scale=2,enabled=true}end
local expanded=Scene.expand_shader_layers(Scene.expand_texture_layers(out),cfg,function()return true end,model.resource_hex)
local layers,images=0,0
for _,v in ipairs(expanded)do if v.type=='texture'then images=images+1;if v.shader_layer then layers=layers+1;assert(v.shader_alpha_masked and v.coverage_mask and v.texture_resource==Art.atlas and v.atlas_rect==out[2].atlas_rect)end end end
assert(images==24 and layers==4,'Selected shader layers were lost to the texture image budget')
assert(not Scene.shader_layer_status[model.resource_hex],'Shader-layer fallback warning on supported primary art')
HUD.config.texture_policy=policy
print('PASS primary HUD Texture integration: 54 identities, existing faithful/alternative/Simple selections, cached fallback, shared palette/decorations/themes and four shader layers; no special renderer flags')
