-- Existing HUD Texture alpha materials mask backing, layers and shared decoration.
-- Native calls are mocked; material bindings are isolated by GUI AND material name.
HUD={shader_catalog={{id='crt_scan',material='mods/dbf_hud/materials/lab_crt_scan'}}}
for _,name in ipairs({'native_font_data','native_font_uv','segmented_primary_specs','ballistic_family_specs','config','font','compass','layout','shader_layers','texture_theme','projection','world_style'})do
 HUD[name]=dofile('src/'..name..'.lua')
end
HUD.scene_test={mount=function()return 0,0,0 end}
HUD.edge_mask=dofile('src/edge_mask.lua')
HUD.segmented_fancy=dofile('src/segmented_fancy.lua')
local Art=HUD.segmented_fancy;local Family=dofile('src/ballistic_family.lua');local Scene=dofile('src/screen_scene.lua')
local function close(a,b)assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b))end
local function same(a,b)
 if type(a)~=type(b)then return false end
 if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
for _,item in ipairs({{0,0},{1.49,1},{1.5,2},{5.99,6},{6,6},{10,10},{25,24},{-1,0}})do
 assert(Art.edge_softness(item[1])==item[2],'Softness quantization changed')
end
assert(Art.edge_softness(nil)==4 and Art.edge_softness(0/0)==4)
local dynamic=HUD.edge_mask.resource
local resources={[Art.face]={id='face'},[Art.atlas]={id='atlas'},[Art.full_white]={id='hard'},[dynamic]={id='generated'}}
local mask_pending=false
local function resource(name)
 if name==dynamic and mask_pending then return nil end
 return resources[name]
end
local cfg=HUD.config.new();cfg.font='bigblue';cfg.hud_presentation='weapon_specific';cfg.texture_art_trial=true;cfg.texture_art_variant='faithful'
cfg.style_3d='standard';cfg.scale=.8;cfg.occlusion_mode='gui_depth';cfg.visibility_alpha=.8;cfg.world_texture_depth=2.5
cfg.panel_opacity=.3;cfg.text_opacity=1;cfg.text_color_alpha=255;cfg.style_clock=12.3125
cfg.shader_layers={}
for i,size in ipairs({.25,1,4,.5})do
 cfg.shader_layers[i]={id=i,shader='crt_scan',scale=2,pattern_size=size,opacity=.1+i*.1,enabled=true,animate=i%2==1,speed=i*.5}
end
local model={resource_hex='968211c0033dce64',kind='magazine',value=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',fraction=.6,state='READY'}
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local pose={matrix=matrix,x=.12,y=2,z=.1,attach_point='root',resource_hex=model.resource_hex,first_person=true}
local function direct(x,y,z)
 local d=y+.08*x+.03*z
 return {x=.5+.34*x/d,y=.4+.4*z/d,depth=d}
end
local native_calls=0
cfg.native_panel_projector=function(...)native_calls=native_calls+1;return direct(...)end
local made,freed,params,bindings,triangles,glyphs={},{},{},{},{},{}
local function state(g,name)
 params[g]=params[g]or {};params[g][name]=params[g][name]or {};return params[g][name]
end
local function capture(g,name)
 local out={};for k,v in pairs(state(g,name))do out[k]=v end;return out
end
local function binding(g,name)return bindings[g]and bindings[g][name]end
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Matrix4x4={from_axes=function(r,f,u,at)return {right=r,forward=f,up=u,at=at}end},
 Application={main_world=function()return 'main'end,worlds=function()return {'main','ui'}end,can_get=function()return true end},
 World={create_screen_gui=function(world,mode,x,y)
  assert(world=='ui'and mode=='scale'and x==1 and y==1);local g={id=#made+1};made[#made+1]=g;return g
 end,destroy_gui=function(world,g)freed[g]=true end},
 Gui={material=function(g,name)assert(not freed[g]);return {gui=g,name=name}end,
  triangle=function(g,a,b,c,layer,ink,name)
   triangles[#triangles+1]={gui=g,a=a,b=b,c=c,ink=ink,name=name,layer=layer,resource=binding(g,name),params=capture(g,name)};return #triangles
  end,destroy_triangle=function()end,
  bitmap_3d_uv=function(g,name,uv0,uv1,tm,pos,layer,extent,ink)
   glyphs[#glyphs+1]={gui=g,name=name,uv0=uv0,uv1=uv1,tm=tm,ink=ink,resource=binding(g,name),params=capture(g,name)};return #glyphs
  end,destroy_bitmap_3d=function()end},
 Material={set_scalar=function(h,k,v)state(h.gui,h.name)[k]=v end,
  set_vector4=function(h,k,v)state(h.gui,h.name)[k]=v end,
  set_resource=function(h,k,v)assert(k=='artwork_texture');bindings[h.gui]=bindings[h.gui]or {};bindings[h.gui][h.name]=v end,
  set_texture=function(h,k,v)assert(k=='diffuse_map');bindings[h.gui]=bindings[h.gui]or {};bindings[h.gui][h.name]=v end}}
local hot={resource=resource}
local renderer=Scene.new(sr,function()end,hot)
local function compose()
 return assert(Family.compose(model,17,23,1,cfg.visibility_alpha,cfg,resource,function()return true end))
end
local function map(rows,x,y)
 local d=rows[7]*x+rows[8]*y+rows[9]
 return (rows[1]*x+rows[2]*y+rows[3])/d,(rows[4]*x+rows[5]*y+rows[6])/d
end
local function rows(v)
 local a,b,c=v.params.scissor_rect,v.params.atlas_scissor,v.params.clip_box
 return {a[1],a[2],a[3],b[1],b[2],b[3],c[1],c[2],c[3]}
end
local function draw(commands,mask)
 local ready,axes,origin=Scene.prepare_commands(commands,pose,cfg,function()return true end)
 local textures,layers,decor=0,{},{}
 for _,v in ipairs(ready)do
  if v.type=='texture'then
   textures=textures+1
   if v.shader_layer then layers[#layers+1]=v;assert(v.texture_slot==20+#layers)
    assert(v.texture_resource==(mask or Art.full_white)and same(v.atlas_rect,{0,0,1,1}))
   end
  elseif v.decoration and not v.charge_meter then decor[#decor+1]=v end
 end
 assert(textures==24 and #layers==4,'Soft edges changed the image/layer budget')
 local nt,ng,nc,gui_count=#triangles,#glyphs,native_calls,#made
 assert(renderer.draw(pose,cfg,commands,nil,nil,3840,2160,.05),renderer.status)
 assert(native_calls-nc==4,'Soft edges added native point projections')
 assert(#made==25,'Soft edges created another texture slot or GUI')
 if gui_count>0 then assert(#made==gui_count,'Changing edge masks rebuilt GUIs')end
 local emitted,letters={},{ }
 for i=nt+1,#triangles do emitted[#emitted+1]=triangles[i]end
 for i=ng+1,#glyphs do letters[#letters+1]=glyphs[i]end
 assert(#emitted==2*(24+(cfg.panel_opacity==0 and -1 or 0)+#decor+1),'Soft edges added feather-band quads')
 local masked,shaders,seen=0,{},{}
 for _,v in ipairs(emitted)do
  if mask and v.gui==made[1]and v.name==Art.material then
   masked=masked+1;assert(v.resource==resources[mask],'Decoration gradient binding changed')
   local source=decor[math.ceil(masked/2)]
   assert(source and same(v.ink,{math.floor(source.a*255+.5),source.c[1],source.c[2],source.c[3]}),'Shared decoration color or alpha changed')
   assert(v.params.scissor_mode==1 and v.params.threshold_fade==2.5)
   local m=rows(v);local frame=ready[1]
   for _,p in ipairs({{0,0},{1,1},{.3,.6}})do
    local q=direct(Scene.point(axes,origin,frame.x+p[1]*frame.w,frame.y+(1-p[2])*frame.h))
    local u,w=map(m,q.x,1-q.y);close(u,p[1]);close(w,p[2])
   end
  elseif v.name:find('_texture_theme_crt_scan',1,true)and not seen[v.gui]then
   seen[v.gui]=true;shaders[#shaders+1]=v
  end
 end
 assert(masked==(mask and #decor*2 or 0),'Some shared decoration bypassed the edge mask')
 assert(#shaders==4,'Soft edges lost a shader layer')
 for i,v in ipairs(shaders)do
  local r=layers[i].shader_layer;local word=v.params.scissor_mode
  assert(v.resource==resources[mask or Art.full_white])
  close(math.floor(word/2)%256/32,r.pattern_size)
  close(math.floor(word/512)%16384/16,math.floor(cfg.style_clock*r.speed*16)%16384/16)
  assert(math.floor(word/8388608)==(r.animate and 1 or 0)and word%2==1 and v.params.threshold_fade==2.5)
  local frame=ready[1]
  local q=direct(Scene.point(axes,origin,frame.x+frame.w,frame.y))
  local u,w=map(rows(v),q.x,1-q.y);close(u,1);close(w,1)
 end
 local face=HUD.native_font_data.faces.bigblue
 assert(#letters>0)
 for _,v in ipairs(letters)do
  assert(v.gui==made[1]and v.name==face.clear:sub(1,-7)..'_scene'and v.resource==face.font,'Decoration replaced the glyph texture binding')
  assert(v.params.scissor_mode==1 and v.params.threshold_fade==2.5,'Glyph scene depth changed')
 end
 return emitted,letters
end
local cases=0
for _,style in ipairs({'none','outline','brackets','helldivers','double','deadeye'})do
 cfg.decoration=style;cfg.panel_opacity=.3;cfg.panel_edge_softness=0
 local hard=compose();assert(hard[1].edge_mask_resource==nil and hard[2].texture_resource==Art.full_white)
 local hard_tri,hard_glyph=draw(hard)
 for _,percent in ipairs({1,4,8,12,24})do
  cfg.panel_edge_softness=percent
  local soft=compose();local mask=dynamic
  assert(soft[1].edge_mask_resource==mask and soft[1].edge_mask_material==Art.material)
  assert(soft[2].texture_resource==mask and same(soft[2].atlas_rect,{0,0,1,1}))
  for i=3,#hard do assert(same(hard[i],soft[i]),'Softness changed crisp foreground/status or shared decoration commands')end
  local soft_tri,soft_glyph=draw(soft,mask)
  assert(#hard_tri==#soft_tri and #hard_glyph==#soft_glyph)
  for i,a in ipairs(hard_tri)do local b=soft_tri[i]
   assert(same(a.a,b.a)and same(a.b,b.b)and same(a.c,b.c)and same(a.ink,b.ink),'Masked decoration geometry or colors changed')
  end
  for i,a in ipairs(hard_glyph)do local b=soft_glyph[i]
   assert(same(a.tm,b.tm)and same(a.uv0,b.uv0)and same(a.uv1,b.uv1)and same(a.ink,b.ink),'Edge softness affected native glyphs')
  end
  cfg.panel_opacity=0;local zero=compose();assert(zero[2].coverage_mask and zero[2].a==0 and zero[2].texture_resource==mask)
  draw(zero,mask);cfg.panel_opacity=.3;cases=cases+1
 end
 -- A not-yet-published mask keeps the original complete HUD usable.
 mask_pending=true;cfg.panel_edge_softness=8
 local pending=compose();assert(pending[1].edge_mask_resource==nil and pending[2].texture_resource==Art.full_white)
 draw(pending);mask_pending=false
 cfg.panel_edge_softness=0;local restored=compose();assert(same(restored,hard));draw(restored)
end
-- Per-weapon appearance survives serialization without changing shader controls.
local config=HUD.config.new();assert(config.panel_edge_softness==4)
HUD.config.set_panel(config,model.resource_hex,{panel_edge_softness=17,panel_edge_curve=2.3,panel_edge_dither=75,panel_edge_grain=3,shader_layers=cfg.shader_layers,panel_opacity=.3})
local saved=HUD.config.serialize(config);local chunk=assert(loadstring(saved));setfenv(chunk,{})
local reloaded=HUD.config.new();HUD.config.apply(reloaded,chunk(),true)
assert(reloaded.panel_edge_softness==4 and reloaded.weapon_panels[model.resource_hex].panel_edge_softness==17)
local saved_layers=reloaded.weapon_panels[model.resource_hex].shader_layers
local expected_layers=HUD.shader_layers.validate(cfg.shader_layers);assert(#saved_layers==#expected_layers)
for i,r in ipairs(expected_layers)do for key,value in pairs(r)do
 if type(value)=='number'then close(saved_layers[i][key],value)else assert(saved_layers[i][key]==value)end
end end
assert(HUD.config.effective(reloaded,model.resource_hex).panel_edge_softness==17)
assert(reloaded.weapon_panels[model.resource_hex].panel_edge_curve==2.3 and reloaded.weapon_panels[model.resource_hex].panel_edge_dither==75 and reloaded.weapon_panels[model.resource_hex].panel_edge_grain==3)
for _,bad in ipairs({-1,25,0/0})do assert(not pcall(HUD.config.apply,config,{panel_edge_softness=bad}))end
renderer.release();for _,g in ipairs(made)do assert(freed[g])end
print(string.format('PASS primary edge feather: %d soft-mask/style cases, all six shared decorations, full-panel backing/layer/decor UVs, isolated font bindings, unchanged quads/colors/glyphs, four native points and 25 GUIs, four shader slots 21-24, zero-opacity metadata, hard/pending restoration, per-weapon roundtrip, shader scale/time/depth invariance',cases))
