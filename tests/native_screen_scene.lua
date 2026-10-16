-- UI-world rendering from live native point projection, independent of raw camera offsets.
HUD={shader_catalog={},segmented_primary_specs=dofile('src/segmented_primary_specs.lua')}
for _,name in ipairs({'native_font_data','native_font_uv','config','font','projection'})do HUD[name]=dofile('src/'..name..'.lua')end
HUD.scene_test={mount=function()return 0,0,0 end};HUD.world_style={prepare=function(v)return v end}
HUD.texture_theme={material=function(name)return name end}
HUD.edge_mask=dofile('src/edge_mask.lua')
local Scene=dofile('src/screen_scene.lua');local Fancy=dofile('src/segmented_fancy.lua')
local made,freed,triangles,glyphs,params,bindings,callbacks={},{},{},{},{},{},{}
local function state(g,name)
 local p=params[g]and params[g][name]or {};local copy={};for k,v in pairs(p)do copy[k]=v end;return copy
end
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Matrix4x4={from_axes=function(r,f,u,at)return {right=r,forward=f,up=u,at=at}end},
 Application={main_world=function()return 'main'end,worlds=function()return {'main','ui'}end,can_get=function()return true end},
 World={create_screen_gui=function(world,mode,x,y)
  assert(world=='ui'and mode=='scale'and x==1 and y==1);local g={id=#made+1};made[#made+1]=g;return g
 end,destroy_gui=function(world,g)assert(world=='ui'and not freed[g]);freed[g]=true end},
 Gui={material=function(g,name)assert(not freed[g]);return {gui=g,name=name}end,
  triangle=function(g,a,b,c,layer,ink,name)
   triangles[#triangles+1]={gui=g,a=a,b=b,c=c,layer=layer,ink=ink,name=name,params=state(g,name),resource=bindings[g]};return #triangles
  end,destroy_triangle=function()end,
  bitmap_3d_uv=function(g,name,uv0,uv1,tm,pos,layer,extent,ink)
   assert(name:sub(-6)=='_scene');glyphs[#glyphs+1]={gui=g,name=name,tm=tm,uv0=uv0,uv1=uv1,params=state(g,name),resource=bindings[g]};return #glyphs
  end,destroy_bitmap_3d=function()end},
 Material={set_scalar=function(h,k,v)assert(v==v and math.abs(v)<math.huge);params[h.gui]=params[h.gui]or {};params[h.gui][h.name]=params[h.gui][h.name]or {};params[h.gui][h.name][k]=v end,
  set_vector4=function(h,k,v)for i=1,4 do assert(v[i]==v[i]and math.abs(v[i])<math.huge)end;params[h.gui][h.name][k]=v end,
  set_resource=function(h,k,v)assert(k=='artwork_texture');bindings[h.gui]=v end,
  set_texture=function(h,k,v)assert(k=='diffuse_map');bindings[h.gui]=v end}}
local material_calls={}
for _,group in ipairs({'Gui','Material'})do
 for _,name in ipairs(group=='Gui'and {'material'}or {'set_scalar','set_vector4','set_resource','set_texture'})do
  local fn=sr[group][name]
  sr[group][name]=function(...)material_calls[name]=(material_calls[name]or 0)+1;return fn(...)end
 end
end
local resources={[Fancy.face]={id='face'},[Fancy.atlas]={id='atlas'}}
local hot={resource=function(name)return resources[name]end,register_consumer=function(owner,detach)callbacks[#callbacks+1]={owner,detach}end}
local shift_x,shift_y=0,0;local invalid;local native_calls=0
local function project(x,y,z)
 native_calls=native_calls+1
 if invalid=='throw'then error('transient native rejection')end
 if invalid=='nil'then return nil end
 if invalid=='nan'then return {x=0/0,y=.5,depth=1}end
 if invalid=='infinite'then return {x=.5,y=math.huge,depth=1}end
 if invalid=='near'then return {x=.5,y=.5,depth=.005}end
 if invalid=='behind'then return {x=.5,y=.5,depth=-1}end
 local depth=y+.08*x+.03*z
 return {x=.5+.34*x/depth+shift_x,y=.4+.4*z/depth+shift_y,depth=depth}
end
local cfg={font='bigblue',occlusion_mode='scene',native_panel_projector=project,world_texture_depth=.147,
 panel_rotation=13,panel_pitch=5,panel_yaw=-7,first_person_zoom_demo=true}
local model={resource_hex='968211c0033dce64',kind='magazine',value=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',fraction=.6,state='READY'}
local commands=assert(Fancy.compose(model,-87,-152,1,.8,cfg,0,hot.resource,function()return true end))
commands[#commands+1]={type='rect',x=-90,y=-155,w=2,h=310,c={233,196,93},a=.8,decoration=true}
local textures={};for _,v in ipairs(commands)do if v.type=='texture'then textures[#textures+1]=v end end;assert(#textures==20)
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};local pose={matrix=matrix,x=.1,y=1,z=.04,attach_point='root',resource_hex=model.resource_hex,first_person=true}
local axes,origin=Scene.panel_pose(pose,cfg,commands)
local original={HUD.projection.projector,HUD.projection.panel_inverse,HUD.projection.clip_polygon}
local function forbidden()error('Native mode reached raw camera projection')end
HUD.projection.projector,HUD.projection.panel_inverse,HUD.projection.clip_polygon=forbidden,forbidden,forbidden
local renderer=Scene.new(sr,function()end,hot);assert(#callbacks==1)
local function draw_native(camera,fov)
 local before=native_calls
 assert(renderer.draw(pose,cfg,commands,camera,fov,1920,1080,.05),renderer.status)
 assert(native_calls-before==4,'Valid planar frame projected more than its four corners: '..(native_calls-before))
end
draw_native(matrix,1)
assert(#made==21 and #glyphs>0,'Native textures/labels did not use the UI world')
local function close(a,b)assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b))end
local function check_image(image,command)
 local state=image.params;assert(state.scissor_mode==1 and state.threshold_fade==.147)
 assert(image.resource==resources[command.texture_resource]and image.name==Fancy.material)
 local rows={};for i=1,3 do rows[i]=state.scissor_rect[i];rows[i+3]=state.atlas_scissor[i];rows[i+6]=state.clip_box[i]end
 local expected={{0,0},{1,0},{1,1},{0,1}};local crop=command.atlas_rect
 for i,c in ipairs({{command.x,command.y+command.h},{command.x+command.w,command.y+command.h},{command.x+command.w,command.y},{command.x,command.y}})do
  local point=project(Scene.point(axes,origin,c[1],c[2]));local x,y=point.x,1-point.y
  local d=rows[7]*x+rows[8]*y+rows[9]
  close((rows[1]*x+rows[2]*y+rows[3])/d,crop[1]+crop[3]*expected[i][1])
  close((rows[4]*x+rows[5]*y+rows[6])/d,crop[2]+crop[4]*expected[i][2])
 end
 local point=project(Scene.point(axes,origin,command.x,command.y))
 close(image.a[1],point.x*1920);close(image.a[3],point.y*1080)
end
local images={};local seen={}
for _,t in ipairs(triangles)do if t.name==Fancy.material then if not seen[t.gui]then seen[t.gui]=true;images[#images+1]=t end end
 assert(t.params.scissor_mode==1 and t.params.threshold_fade==.147,'Decoration lost shared scene depth')
end
assert(#images==20,'Not all atlas images submitted');for i,image in ipairs(images)do check_image(image,textures[i])end
for _,g in ipairs(glyphs)do assert(g.params.scissor_mode==1 and g.params.threshold_fade==.147 and g.resource==HUD.native_font_data.faces.bigblue.font,'Native font material/depth changed')end
local triangle_count,glyph_count=#triangles,#glyphs
-- Engine from_elements takes twelve affine components, in axis order.
sr.Matrix4x4.from_elements=function(a,b,c,d,e,f,g,h,i,j,k,l)
 return {right={a,b,c},forward={d,e,f},up={g,h,i},at={j,k,l}}
end
shift_x,shift_y=.06,-.04
draw_native(matrix,1)
assert(#made==21 and #triangles==triangle_count*2 and #glyphs==glyph_count*2,'Shake changed submission count or GUI ownership')
for i=1,triangle_count do local a,b=triangles[i],triangles[i+triangle_count]
 assert(a.gui==b.gui);close(b.a[1]-a.a[1],.06*1920);close(b.a[3]-a.a[3],-.04*1080)
end
for i=1,glyph_count do local a,b=glyphs[i],glyphs[i+glyph_count]
 close(b.tm.at[1]-a.tm.at[1],.06*1920);close(b.tm.at[3]-a.tm.at[3],-.04*1080)
 for _,axis in ipairs({'right','forward','up'})do for j=1,3 do close(a.tm[axis][j],b.tm[axis][j])end end
 for j=1,2 do close(a.uv0[j],b.uv0[j]);close(a.uv1[j],b.uv1[j])end
end
seen={};local index=0
for i=triangle_count+1,#triangles do local t=triangles[i];if t.name==Fancy.material and not seen[t.gui]then seen[t.gui]=true;index=index+1;check_image(t,textures[index])end end
local nt,ng=#triangles,#glyphs;shift_x=1.2
draw_native()
assert(#triangles==nt+triangle_count and #glyphs==ng+glyph_count,'Native offscreen quads incorrectly used CPU viewport clipping')
shift_x=.06
-- No accepted raw camera snapshot is needed, and occlusion toggles affect every material.
cfg.occlusion_mode='gui';draw_native()
for _,p in pairs(params)do for _,s in pairs(p)do assert(s.scissor_mode==0 and s.threshold_fade==.147)end end
cfg.occlusion_mode='scene'
for _,depth in ipairs({0,-1,math.huge,0/0})do cfg.world_texture_depth=depth;draw_native();for _,p in pairs(params)do for _,s in pairs(p)do assert(s.scissor_mode==0 and s.threshold_fade==0)end end end
cfg.world_texture_depth=.147
-- A rejected plane snapshot keeps the existing guarded point projection usable.
local snapshot=HUD.projection.native_panel_snapshot
HUD.projection.native_panel_snapshot=function()return nil end
local fallback_calls,ft,fg=native_calls,#triangles,#glyphs
assert(renderer.draw(pose,cfg,commands,nil,nil,1920,1080,.05),renderer.status)
assert(native_calls-fallback_calls>4,'Rejected snapshot did not use guarded point fallback')
assert(#triangles==ft+triangle_count and #glyphs==fg+glyph_count,'Rejected snapshot blanked otherwise valid geometry')
HUD.projection.native_panel_snapshot=snapshot
draw_native()
for _,bad in ipairs({'nil','nan','infinite','near','behind','throw'})do
 invalid=bad;local nt,ng=#triangles,#glyphs;assert(renderer.draw(pose,cfg,commands,nil,nil,1920,1080,.05),renderer.status)
 assert(#triangles==nt and #glyphs==ng,'Invalid native point reached the GUI or fell back to CPU')
end
invalid=nil;draw_native()
-- Stationary frames keep drawing but do not repeat unchanged native material work.
material_calls={}
for i=1,120 do draw_native()end
for name,calls in pairs(material_calls)do assert(calls==0,'Unchanged frame repeated material work: '..name..'='..calls)end
-- Publication changes must rebind even when the texture name is unchanged.
resources[Fancy.face]={id='replacement-face'};draw_native()
assert((material_calls.set_resource or 0)>0,'Replacement artwork was not rebound')
assert(callbacks[1][2]());renderer.release();assert(#made==21);for _,g in ipairs(made)do assert(freed[g])end
material_calls={};draw_native()
assert((material_calls.material or 0)>0 and (material_calls.set_resource or 0)>0,'GUI recreation reused stale handles')
renderer.release()
print('PASS material lifetime cache: 120 unchanged frames make zero material calls; replacement artwork rebinds and GUI recreation reacquires handles')
-- Reusing immutable commands skips preparation, but never skips pose/draw updates.
local prepare=Scene.prepare_commands;local prepares=0
Scene.prepare_commands=function(...)prepares=prepares+1;return prepare(...)end
local group,parts=Scene.spatial_groups,Scene.text_parts;local groups,partitions=0,0
local glyph_plan=Scene.glyph_plan;local plans=0
Scene.glyph_plan=function(...)plans=plans+1;return glyph_plan(...)end
Scene.spatial_groups=function(...)groups=groups+1;return group(...)end
Scene.text_parts=function(...)partitions=partitions+1;return parts(...)end
cfg.style_3d='standard';cfg.layout_cache_token=commands
local cached=Scene.new(sr,function()end,hot)
local gt=#glyphs
assert(cached.draw(pose,cfg,commands,nil,nil,1920,1080,.05))
local first_glyph=glyphs[gt+1];local n=#glyphs-gt
local first_parts=partitions
local first_plans=plans;assert(first_plans>0)
shift_x=shift_x+.03;gt=#glyphs
assert(cached.draw(pose,cfg,commands,nil,nil,1920,1080,.05))
assert(prepares==1 and #glyphs-gt==n,'Layout reuse changed frame submission')
assert(groups==1 and partitions==first_parts,'Immutable text or panel grouping repeated')
assert(plans==first_plans,'Unchanged text rebuilt glyph geometry')
close(glyphs[gt+1].tm.at[1]-first_glyph.tm.at[1],.03*1920)
cached.release()
assert(cached.draw(pose,cfg,commands,nil,nil,1920,1080,.05));assert(prepares==2,'Released geometry cache survived material publication')
assert(groups==2 and partitions==first_parts*2,'Released partition cache survived publication')
assert(plans==first_plans*2,'Released glyph plan survived publication')
cached.release();cfg.layout_cache_token=nil;Scene.prepare_commands=prepare
Scene.spatial_groups,Scene.text_parts=group,parts
Scene.glyph_plan=glyph_plan
print('PASS immutable preparation cache retains full-rate pose updates and clears on GUI release')
-- The original raw-camera branch remains usable when no callback is provided.
HUD.projection.projector,HUD.projection.panel_inverse,HUD.projection.clip_polygon=unpack(original)
cfg.native_panel_projector=nil;cfg.first_person_zoom_demo=false
local legacy=Scene.new(sr,function()end,hot);assert(legacy.draw(pose,cfg,commands,matrix,1,1920,1080,.05),legacy.status);legacy.release()
print('PASS native UI projection: exactly four callback points per valid frame including 20 atlas images, native glyphs and decoration; live shake/labels, projective crops, shared depth, rejection and raw-camera fallback')
