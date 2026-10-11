-- The maintained HUD Texture renderer must scale patterns in complete panel UVs.
-- Fake native drawing records real compositor/material parameters; no game calls.
HUD={shader_catalog={{id='crt_scan',material='mods/dbf_hud/materials/lab_crt_scan'}}}
for _,name in ipairs({'native_font_data','native_font_uv','segmented_primary_specs','ballistic_family_specs','config','font','compass','layout','shader_layers','texture_theme','projection','world_style'})do
 HUD[name]=dofile('src/'..name..'.lua')
end
HUD.scene_test={mount=function()return 0,0,0 end}
HUD.edge_mask=dofile('src/edge_mask.lua')
HUD.segmented_fancy=dofile('src/segmented_fancy.lua')
local Art=HUD.segmented_fancy;local Family=dofile('src/ballistic_family.lua');local Scene=dofile('src/screen_scene.lua')
assert(Art.full_white=='mods/dbf_hud/textures/primary_full_white_v1','Immutable full-UV carrier missing')
local resources={[Art.face]={id='face'},[Art.atlas]={id='atlas'},[Art.full_white]={id='white',width=16,height=16}}
local function resource(name)return resources[name]end
local cfg=HUD.config.new();cfg.texture_art_trial=true;cfg.texture_art_variant='faithful';cfg.hud_presentation='weapon_specific'
cfg.style_3d='standard';cfg.font='bigblue';cfg.decoration='none';cfg.scale=.5;cfg.occlusion_mode='scene'
cfg.visibility_alpha=.7;cfg.panel_opacity=.3;cfg.world_texture_depth=2.5;cfg.style_clock=12.3125
cfg.shader_layers={}
for i,size in ipairs({.25,1,4,.5})do
 cfg.shader_layers[i]={id=i,shader='crt_scan',pattern_size=size,scale=2,opacity=.42,enabled=true,animate=i%2==1,speed=i*.5}
end
local model={resource_hex='968211c0033dce64',kind='magazine',value=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',fraction=.6,state='READY'}
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local pose={matrix=matrix,x=.12,y=2,z=.1,attach_point='root',resource_hex=model.resource_hex,first_person=true}
local shift_x,shift_y=0,0
local function project(x,y,z)
 local d=y+.08*x+.03*z
 return {x=.5+.34*x/d+shift_x,y=.4+.4*z/d+shift_y,depth=d}
end
cfg.native_panel_projector=project
local made,states,bindings,triangles,labels={},{},{},{},{}
local function state(g,name)
 states[g]=states[g]or {};states[g][name]=states[g][name]or {};return states[g][name]
end
local function capture(g,name)
 local out={};for k,v in pairs(state(g,name))do out[k]=v end;return out
end
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Application={main_world=function()return 'main'end,worlds=function()return {'main','ui'}end,can_get=function()return true end},
 World={create_screen_gui=function()local g={};made[#made+1]=g;return g end,destroy_gui=function()end},
 Gui={material=function(g,name)return {gui=g,name=name}end,
  triangle=function(g,a,b,c,layer,ink,name)
   triangles[#triangles+1]={gui=g,name=name,ink=ink,resource=bindings[g],params=capture(g,name)};return #triangles
  end,destroy_triangle=function()end,
  text=function(g,str,font,size,name,pos,ink)labels[#labels+1]={text=str,ink=ink};return #labels end,destroy_text=function()end},
 Material={set_scalar=function(h,k,v)state(h.gui,h.name)[k]=v end,
  set_vector4=function(h,k,v)state(h.gui,h.name)[k]=v end,
  set_resource=function(h,k,v)assert(k=='artwork_texture');bindings[h.gui]=v end,
  set_texture=function(h,k,v)assert(k=='diffuse_map');bindings[h.gui]=v end}}
local hot={resource=resource}
local renderer=Scene.new(sr,function()end,hot)
local function close(a,b)assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b))end
local function compose()
 local out=assert(Family.compose(model,17,23,1,.8,cfg,resource,function()return true end))
 local images=0;for _,v in ipairs(out)do if v.type=='texture'then images=images+1 end end
 assert(images==20 and out[2].coverage_mask,'Primary image budget or coverage changed')
 return out
end
local function map(params,x,y)
 local a,b,c=params.scissor_rect,params.atlas_scissor,params.clip_box
 local d=c[1]*x+c[2]*y+c[3]
 return (a[1]*x+a[2]*y+a[3])/d,(b[1]*x+b[2]*y+b[3])/d
end
local function draw_and_check(commands)
 local ready,axes,origin=Scene.prepare_commands(commands,pose,cfg,function()return true end)
 local images,layers=0,{}
 for _,v in ipairs(ready)do if v.type=='texture'then
  images=images+1
  if v.shader_layer then
   layers[#layers+1]=v
   assert(v.texture_slot==20+#layers,'Shader layer reused the artwork carrier material slot')
   assert(v.texture_resource==Art.full_white and v.coverage_mask and v.shader_alpha_masked)
   assert(v.atlas_rect[1]==0 and v.atlas_rect[2]==0 and v.atlas_rect[3]==1 and v.atlas_rect[4]==1,'Layer inherited a small atlas crop')
   close(v.a,cfg.visibility_alpha*v.shader_layer.opacity)
  end
 end end
 assert(images==24 and #layers==4,'Four layers exceeded or reduced the established image budget')
 local before=#triangles
 assert(renderer.draw(pose,cfg,commands,nil,nil,3840,2160,.05),renderer.status)
 local seen,rendered={},{ }
 for i=before+1,#triangles do local image=triangles[i]
  if image.name:find('_texture_theme_crt_scan',1,true)and not seen[image.gui]then
   seen[image.gui]=true;rendered[#rendered+1]=image
  end
 end
 assert(#rendered==4 and #labels>0,'Shader layers or native labels vanished')
 local frame=ready[1]
 for i,image in ipairs(rendered)do
  assert(image.resource==resources[Art.full_white],'Renderer bound the digit atlas to a shader carrier')
  local row=layers[i].shader_layer;local word=image.params.scissor_mode
  assert(word%2==1 and image.params.threshold_fade==2.5,'Shared depth controls changed')
  close(math.floor(word/2)%256/32,row.pattern_size)
  close(math.floor(word/512)%16384/16,math.floor(cfg.style_clock*row.speed*16)%16384/16)
  assert(math.floor(word/8388608)==(row.animate and 1 or 0),'Animation switch changed')
  assert(image.ink[1]==math.floor(cfg.visibility_alpha*row.opacity*255+.5),'Layer opacity changed')
  for _,p in ipairs({{0,0},{1,0},{0,1},{1,1},{.21,.63}})do
   local native=project(Scene.point(axes,origin,frame.x+p[1]*frame.w,frame.y+(1-p[2])*frame.h))
   local u,v=map(image.params,native.x,1-native.y)
   close(u,p[1]);close(v,p[2])
   close(u*256/row.pattern_size,p[1]*256/row.pattern_size)
   close(v*128/row.pattern_size,p[2]*128/row.pattern_size)
  end
 end
end
for i,size in ipairs({{16,16},{1,1},{1024,512}})do
 resources[Art.full_white]={id='white_'..i,width=size[1],height=size[2]}
 shift_x,shift_y=(i-1)*.06,-(i-1)*.04
 local commands=compose();assert(commands[2].texture_resource==Art.full_white)
 -- Moving the face to another atlas region must not move or shrink shader UVs.
 commands[3].atlas_rect={0,0,.4,.5}
 draw_and_check(commands)
end
-- Uploading the optional white carrier must not gate face/digit availability.
resources[Art.full_white]=nil
local fallback=compose();assert(Art.assets_ready(resource))
assert(fallback[2].texture_resource==Art.atlas and fallback[2].atlas_rect[3]<.1,'Old cropped carrier fallback changed')
local before=#triangles;assert(renderer.draw(pose,cfg,fallback,nil,nil,3840,2160,.05));assert(#triangles>before,'Missing optional carrier blanked the panel')
resources[Art.full_white]={id='white_restored',width=16,height=16};draw_and_check(compose())
-- Panel opacity changes its backing only. A zero-alpha coverage carrier remains
-- metadata for shader layers, but must not produce a backing draw of its own.
cfg.shader_layers={};cfg.visibility_alpha=.8;cfg.text_opacity=1;cfg.text_color_alpha=255
local function opacity_draw()
 local commands=assert(Family.compose(model,17,23,1,cfg.visibility_alpha,cfg,resource,function()return true end))
 local before,lb=#triangles,#labels
 assert(renderer.draw(pose,cfg,commands,nil,nil,3840,2160,.05),renderer.status)
 local backing,foreground,shaders,text={},{},{},{}
 for i=before+1,#triangles do local v=triangles[i]
  if v.name:find('_texture_theme_crt_scan',1,true)then shaders[#shaders+1]=v
  elseif v.resource==resources[Art.full_white]then backing[#backing+1]=v
  elseif v.resource==resources[Art.face]or v.resource==resources[Art.atlas]then foreground[#foreground+1]=v.ink[1]end
 end
 for i=lb+1,#labels do text[#text+1]=labels[i].ink[1]end
 return commands,backing,foreground,shaders,text
end
local baseline_fg,baseline_text
for _,opacity in ipairs({0,.01,.25,.5,1})do
 cfg.panel_opacity=opacity
 local commands,backing,fg,shaders,text=opacity_draw()
 assert(commands[2].coverage_mask and commands[2].texture_resource==Art.full_white)
 close(commands[2].a,cfg.visibility_alpha*opacity)
 assert(#shaders==0 and #backing==(opacity==0 and 0 or 2),'Zero panel opacity submitted white backing geometry')
 for _,v in ipairs(backing)do assert(v.ink[1]==math.floor(cfg.visibility_alpha*opacity*255+.5))end
 if not baseline_fg then baseline_fg,baseline_text=fg,text else
  assert(#fg==#baseline_fg and #text==#baseline_text,'Panel opacity changed foreground submission')
  for i,a in ipairs(fg)do assert(a==baseline_fg[i],'Panel opacity changed foreground texture alpha')end
  for i,a in ipairs(text)do assert(a==baseline_text[i],'Panel opacity changed native label alpha')end
 end
end
cfg.shader_layers={{id=1,shader='crt_scan',pattern_size=1,scale=2,opacity=.37,enabled=true,animate=true,speed=1}}
for _,opacity in ipairs({0,.01,.25,.5,1})do
 cfg.panel_opacity=opacity
 local commands,backing,fg,shaders,text=opacity_draw()
 assert(#shaders==2,'Independent shader layer vanished with the panel backing')
 local ready,axes,origin=Scene.prepare_commands(commands,pose,cfg,function()return true end)
 local frame=ready[1]
 for _,v in ipairs(shaders)do
  assert(v.resource==resources[Art.full_white],'Zero opacity changed the shader carrier to the face atlas')
  assert(v.ink[1]==math.floor(cfg.visibility_alpha*.37*255+.5),'Panel opacity multiplied independent shader opacity')
  for _,p in ipairs({{0,0},{1,1}})do
   local native=project(Scene.point(axes,origin,frame.x+p[1]*frame.w,frame.y+(1-p[2])*frame.h))
   local u,w=map(v.params,native.x,1-native.y);close(u,p[1]);close(w,p[2])
  end
 end
end
-- Visibility applies once to every component; text opacity and text-color alpha
-- apply to foreground only, including native labels and digit textures.
cfg.panel_opacity=.5;cfg.visibility_alpha=.6;cfg.text_opacity=.4;cfg.text_color_alpha=128
local commands,backing,fg,shaders,text=opacity_draw()
close(commands[2].a,.3)
for _,v in ipairs(backing)do assert(v.ink[1]==77,'Backing visibility was applied more than once')end
for _,v in ipairs(shaders)do assert(v.ink[1]==57,'Shader visibility was applied more than once')end
local expected=math.floor(.6*.4*(128/255)*255+.5)
for _,a in ipairs(text)do assert(a==expected or a==math.floor(expected*.55+.5),'Native text opacity factors were duplicated')end
local lit
for _,v in ipairs(commands)do if v.segmented_role=='loaded'and v.segment_lit and not v.leading_zero then
 close(v.a,.6*.4*(128/255));lit=true
end end
assert(lit)
cfg.text_opacity=0
commands,backing,fg,shaders,text=opacity_draw()
assert(#fg==0 and #backing==2 and #shaders==2,'Zero text opacity affected independent backing or shader layers')
for _,a in ipairs(text)do assert(a==0,'Zero text opacity left a visible native label')end
renderer.release()
print('PASS HUD Texture shader scale/opacity: full-UV white carrier, .25/1/4 pattern frequencies, texture/atlas/plane independence, four isolated layers within 24 images, panel 0/.01/.25/.5/1 native backing alpha with unchanged foreground, independent shader opacity at zero backing, visibility applied once, text-only opacity, depth/time/animation, fallback/recovery')
