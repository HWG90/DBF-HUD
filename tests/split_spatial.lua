-- Spatial Split uses the established renderer and native planar snapshots.
-- Independent projections validate pod transforms, UVs, material ownership and recovery.
HUD={shader_catalog={{id='crt_scan',material='mods/dbf_hud/materials/lab_crt_scan'}}}
for _,name in ipairs({'native_font_data','native_font_uv','config','font','compass','layout','shader_layers','texture_theme','projection','world_style','pose_motion','placement'})do
 HUD[name]=dofile('src/'..name..'.lua')
end
HUD.scene_test={mount=function()return 0,0,0 end}
local Scene=dofile('src/screen_scene.lua')
local function close(a,b)assert(math.abs(a-b)<1e-7,tostring(a)..' ~= '..tostring(b))end
local function copy(t)if type(t)~='table'then return t end;local q={};for k,v in pairs(t)do q[k]=copy(v)end;return q end
local function rotation(heading,elevation,roll,x,y,z)
 local h,p,r=math.rad(heading),math.rad(elevation),math.rad(roll)
 local right={math.cos(h),-math.sin(h),0};local forward={math.sin(h)*math.cos(p),math.cos(h)*math.cos(p),math.sin(p)}
 local up={-math.sin(h)*math.sin(p),-math.cos(h)*math.sin(p),math.cos(p)}
 local m={0,0,0,0,forward[1],forward[2],forward[3],0,0,0,0,0,x,y,z,1}
 for i=1,3 do m[i]=right[i]*math.cos(r)+up[i]*math.sin(r);m[i+8]=up[i]*math.cos(r)-right[i]*math.sin(r)end
 return m
end
local names={'main','reserve','context','status'}
local depth={main=16,reserve=-8,context=28.8,status=0}
local material='mods/dbf_hud/materials/adjudicator_tall_v1'
local resources={mask={id='mask'},main={id='main'},reserve={id='reserve'},context={id='context'},status={id='status'}}
local function resource(name)return resources[name]end
local function commands(scale)
 scale=scale or 1
 local out={{type='panel',x=10*scale,y=20*scale,w=320*scale,h=161*scale,world_reference_width=320*scale,a=0,c={9,27,53},atlas_frame=true,split_hud=true,edge_mask_resource='mask',edge_mask_material=material,edge_mask_box={x=10*scale,y=20*scale,w=320*scale,h=161*scale}}}
 for i,name in ipairs(names)do
  out[#out+1]={type='texture',x=(70+i*5)*scale,y=(50+i*7)*scale,w=40*scale,h=30*scale,a=.8,c={245,246,240},texture_material=material,texture_resource=name,atlas_rect=name=='main'and{0,0,1,1}or{.1,.2,.3,.4},coverage_mask=name=='main',spatial_plane=name,spatial_depth=depth[name]*scale,texture_theme=false}
  out[#out+1]={type='text',x=(80+i*5)*scale,y=(70+i*7)*scale,text=({'M','R','C','S'})[i],size=11.5*scale,font='hack',a=.8,c={245,246,240},texture_readout=true,font_scale_applied=true,spatial_plane=name,spatial_depth=depth[name]*scale}
 end
 out[#out+1]={type='rect',x=74*scale,y=51*scale,w=1*scale,h=75*scale,a=.7,c={233,196,93},decoration=true,spatial_plane='main',spatial_depth=16*scale}
 return out
end
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local pose={matrix=matrix,x=.12,y=2,z=.1,attach_point='root',resource_hex='968211c0033dce64',first_person=false}
local cfg=HUD.config.new();cfg.font='hack';cfg.scale=.7;cfg.style_3d='standard';cfg.placement_mode='auto';cfg.texture_art_trial=true;cfg.texture_art_variant='faithful';cfg.occlusion_mode='scene';cfg.world_texture_depth=7;cfg.panel_yaw=-12;cfg.panel_pitch=9;cfg.panel_rotation=5
cfg.visibility_alpha=.8;cfg.style_clock=9.375;cfg.shader_layers={}
for i,size in ipairs({.25,1,4,.5})do cfg.shader_layers[i]={id=i,shader='crt_scan',scale=2,pattern_size=size,opacity=.4+i*.1,enabled=true,animate=i%2==1,speed=i*.5}end
local native_calls=0;local shake_x,shake_y=0,0
local function project(x,y,z)
 local d=y+.08*x+.03*z
 return {x=.5+.34*x/d+shake_x,y=.4+.4*z/d+shake_y,depth=d}
end
cfg.native_panel_projector=function(...)native_calls=native_calls+1;return project(...)end
local made,freed,triangles,glyphs,params,bindings,callbacks={},{},{},{},{},{},{}
local function state(g,n)params[g]=params[g]or {};params[g][n]=params[g][n]or {};return params[g][n]end
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Matrix4x4={from_axes=function(r,f,u,at)return {right=r,forward=f,up=u,at=at}end},
 Application={main_world=function()return 'main'end,worlds=function()return {'main','ui'}end,can_get=function()return true end},
 World={create_screen_gui=function(world,mode,x,y)assert(world=='ui'and mode=='scale'and x==1 and y==1);local g={id=#made+1};made[#made+1]=g;return g end,destroy_gui=function(world,g)assert(world=='ui'and not freed[g]);freed[g]=true end},
 Gui={material=function(g,n)assert(not freed[g]);return {gui=g,name=n}end,
  triangle=function(g,a,b,c,layer,ink,n)triangles[#triangles+1]={gui=g,a=a,b=b,c=c,layer=layer,ink=ink,name=n,params=copy(state(g,n)),resource=bindings[g]and bindings[g][n]};return #triangles end,destroy_triangle=function()end,
  bitmap_3d_uv=function(g,n,uv0,uv1,tm,pos,layer,extent,ink)glyphs[#glyphs+1]={gui=g,name=n,tm=tm,params=copy(state(g,n)),resource=bindings[g]and bindings[g][n]};return #glyphs end,destroy_bitmap_3d=function()end},
 Material={set_scalar=function(h,k,v)state(h.gui,h.name)[k]=v end,set_vector4=function(h,k,v)state(h.gui,h.name)[k]=v end,
  set_resource=function(h,k,v)assert(k=='artwork_texture');bindings[h.gui]=bindings[h.gui]or {};bindings[h.gui][h.name]=v end,
  set_texture=function(h,k,v)assert(k=='diffuse_map');bindings[h.gui]=bindings[h.gui]or {};bindings[h.gui][h.name]=v end}}
local hot={resource=resource,register_consumer=function(owner,detach)callbacks[#callbacks+1]=detach end}
local renderer=Scene.new(sr,function()end,hot)
local authored=commands(2);local prepared,axes,at=Scene.prepare_commands(authored,pose,cfg,function()return true end)
local groups=assert(Scene.spatial_groups(prepared));assert(#groups==4)
local world_scale=240*cfg.scale/(320*2)
for _,group in ipairs(groups)do
 close(group.depth,depth[group.name]*2*world_scale)
 assert(group.commands[1].spatial_metadata and group.commands[1].a==0 and group.commands[1].w==prepared[1].w)
 assert(group.commands[1].x==prepared[1].x and group.commands[1].y==prepared[1].y and group.commands[1].h==prepared[1].h)
end
local count=native_calls
assert(renderer.draw(pose,cfg,authored,nil,nil,3840,2160,.05),renderer.status)
assert(native_calls-count==16,'Spatial renderer projected per glyph/image instead of four corners per pod')
assert(renderer.native_point_calls==16 and #glyphs==8)
assert(#made==12,'Four plane roots + eight global texture/shader slots expected')
local root_guis={}
for i,group in ipairs(groups)do
 local origin=Scene.spatial_origin(axes,at,group.depth)
 local frame=group.commands[1]
 local expected=project(Scene.point(axes,origin,frame.x+frame.w/2,frame.y+frame.h/2)).depth
 local glyph=glyphs[(i-1)*2+1]
 assert(not root_guis[glyph.gui],'Different depths reused a font material GUI');root_guis[glyph.gui]=true
 close(glyph.params.threshold_fade,expected);assert(glyph.params.scissor_mode==1)
 assert(glyph.resource==HUD.native_font_data.faces.hack.font)
 local command
 for _,v in ipairs(group.commands)do if v.type=='texture'and not v.shader_layer then command=v;break end end
 local image
 for _,v in ipairs(triangles)do if v.resource==resources[group.name]and v.name==material then image=v;break end end
 assert(image,'Missing spatial texture '..group.name);close(image.params.threshold_fade,expected)
 local a,b,c=image.params.scissor_rect,image.params.atlas_scissor,image.params.clip_box
 for _,corner in ipairs({{0,0},{1,0},{1,1},{0,1},{.27,.63}})do
  local point=project(Scene.point(axes,origin,command.x+corner[1]*command.w,command.y+(1-corner[2])*command.h))
  local x,y=point.x,1-point.y;local den=c[1]*x+c[2]*y+c[3]
  close((a[1]*x+a[2]*y+a[3])/den,command.atlas_rect[1]+corner[1]*command.atlas_rect[3])
  close((b[1]*x+b[2]*y+b[3])/den,command.atlas_rect[2]+corner[2]*command.atlas_rect[4])
 end
end
local shader_guis={};local shaders=0
for _,v in ipairs(triangles)do if v.name:find('_texture_theme_crt_scan',1,true)and not shader_guis[v.gui]then
 shader_guis[v.gui]=true;shaders=shaders+1
 local row=cfg.shader_layers[shaders];close(math.floor(v.params.scissor_mode/2)%256/32,row.pattern_size)
 assert(v.resource==resources.main,'Shader adopted another pod/atlas')
end end
assert(shaders==4)
-- Inspect adds canvas space while outer-decoration coverage retains authored
-- 320x161 UVs anchored at the canvas top, independently of shader image rows.
local inspect=copy(authored);inspect[1].w=410*2;inspect[1].h=178*2
inspect[1].edge_mask_box.y=inspect[1].y+inspect[1].h-161*2
local inspection,ia,io=Scene.prepare_commands(inspect,pose,cfg,function()return true end)
local imain=Scene.spatial_groups(inspection)[1];local iorigin=Scene.spatial_origin(ia,io,imain.depth)
local start=#triangles;count=native_calls;assert(renderer.draw(pose,cfg,inspect,nil,nil,3840,2160,.05));assert(native_calls-count==16)
local decor
for i=start+1,#triangles do if triangles[i].resource==resources.mask then decor=triangles[i];break end end
assert(decor,'Inspect decoration did not retain its coverage material')
local box=imain.commands[1].edge_mask_box;local rr,bb,cc=decor.params.scissor_rect,decor.params.atlas_scissor,decor.params.clip_box
for _,uv in ipairs({{0,0},{1,1},{.23,.68}})do
 local hit=project(Scene.point(ia,iorigin,box.x+box.w*uv[1],box.y+box.h*(1-uv[2])))
 local x,y=hit.x,1-hit.y;local denominator=cc[1]*x+cc[2]*y+cc[3]
 close((rr[1]*x+rr[2]*y+rr[3])/denominator,uv[1]);close((bb[1]*x+bb[2]*y+bb[3])/denominator,uv[2])
end
-- Return to the combat geometry before comparing shake offsets.
assert(renderer.draw(pose,cfg,authored,nil,nil,3840,2160,.05))
-- Camera shake updates positions, retaining sixteen projections and GUI ownership.
local old_triangles,old_glyphs=#triangles,#glyphs;count=native_calls;shake_x=.06;shake_y=-.03
assert(renderer.draw(pose,cfg,authored,nil,nil,3840,2160,.05),renderer.status)
assert(native_calls-count==16 and #made==12)
for i=1,8 do close(glyphs[old_glyphs+i].tm.at[1]-glyphs[old_glyphs-8+i].tm.at[1],.06*3840);close(glyphs[old_glyphs+i].tm.at[3]-glyphs[old_glyphs-8+i].tm.at[3],-.03*2160)end
-- Removing optional pods retires their GUI/material children, never reusing stale roots.
local lean={authored[1]};for i=2,#authored do if authored[i].spatial_plane=='main'then lean[#lean+1]=authored[i]end end
count=native_calls;assert(renderer.draw(pose,cfg,lean,nil,nil,3840,2160,.05));assert(native_calls-count==4)
for g in pairs(root_guis)do if g~=glyphs[1].gui then assert(freed[g],'Removed pod GUI was retained')end end
-- Hard-edge legacy commands remain a single plane with the configured depth.
local legacy=copy(lean);legacy[1].split_hud=nil
for _,v in ipairs(legacy)do v.spatial_plane=nil;v.spatial_depth=nil end
count=native_calls;local first_triangle=#triangles;assert(renderer.draw(pose,cfg,legacy,nil,nil,3840,2160,.05));assert(native_calls-count==4)
for i=first_triangle+1,#triangles do close(triangles[i].params.threshold_fade,7)end
assert(callbacks[1]());renderer.release();for _,g in ipairs(made)do assert(freed[g],'Owned GUI leaked on release')end
-- Recovery fits actual text/image extents at the nearest of the four depths.
local recovery_cases=0;shake_x,shake_y=0,0
HUD.scene_test=dofile('src/scene_test.lua')
for _,first in ipairs({false,true})do for _,spacing in ipairs({0,16,32})do for _,fov in ipairs({.16,.7,1.4})do for _,aspect in ipairs({16/9,.75})do for _,angles in ipairs({{0,0,0,0,0,0},{-45,80,-120,40,-25,20},{0,90,0,0,0,0}})do
 local settings=HUD.config.new();settings.anchor_mode='world';settings.placement_mode='auto';settings.scale=2;settings.fp_auto_side='right'
 local camera=rotation(angles[4],angles[5],angles[6],10,20,30)
 local p={matrix=rotation(angles[1],angles[2],angles[3],10.2,19.8,29.9),x=10.2,y=19.8,z=29.9,attach_point='root',resource_hex=pose.resource_hex,first_person=first}
 p.matrix[13],p.matrix[14],p.matrix[15]=p.x,p.y,p.z
 local config=copy(settings);config.font='hack';config.keep_hud_upright=false;config.scale=2*3*(first and 1 or settings.third_person_scale);config.shader_layers={};config.style_3d='standard';config.decoration='none'
 local input=commands(2*config.scale)
 for _,v in ipairs(input)do if v.spatial_depth then v.spatial_depth=v.spatial_depth*spacing/16 end end
 local offset,proof=HUD.placement.recover(p,config,input,camera,fov,aspect,settings,3)
 assert(proof.nearest_depth>.005)
 local holder={weapon_pose=copy(p),first_person=first,config=settings,clock=0,weapon_clearance={[pose.resource_hex]={[first and 'first_right'or'right']=offset}}}
 HUD.placement.update(holder,{}, {},{avatar_unit_ref=1},function()end)
 config.scale=settings.scale*offset.scale*(first and 1 or settings.third_person_scale)
 config.panel_rotation,config.panel_pitch,config.panel_yaw=offset.rotation,offset.pitch,offset.yaw
 local ready=HUD.world_style.prepare(input,holder.weapon_pose,config);local aa,oo=Scene.panel_pose(holder.weapon_pose,config,ready)
 for _,v in ipairs(ready)do
  local origin=Scene.spatial_origin(aa,oo,v.spatial_depth or 0)
  local left,bottom,right,top=v.x,v.y,v.x+(v.w or 0),v.y+(v.h or 0)
  if v.type=='text'then local l,b,r,t=HUD.font.measure(v.text,v.size,v.font,true);left,bottom,right,top=v.x+l,v.y+b,v.x+r,v.y+t end
  for _,point in ipairs({{left,bottom},{right,bottom},{right,top},{left,top}})do
   local wx,wy,wz=Scene.point(aa,origin,point[1],point[2])
   local hit=assert(HUD.projection.project(camera,wx,wy,wz,fov,aspect,.005))
   assert(hit.x>=.08 and hit.x<=.92 and hit.y>=.08 and hit.y<=.92,'Recovery clipped a spatial pod')
  end
 end
 recovery_cases=recovery_cases+1
end end end end end
-- Actual production composition joins the same renderer, not a hand-authored
-- approximation. Twelve cases exercise combat/inspect, state and opacity.
HUD.weapon_names=dofile('src/weapon_names.lua');HUD.segmented_primary_specs=dofile('src/segmented_primary_specs.lua')
HUD.model=dofile('src/model.lua');HUD.split_hud_assets=dofile('src/split_hud_assets.lua');HUD.split_hud=dofile('src/split_hud.lua')
HUD.scene_test={mount=function()return 0,0,0 end}
local Split,A=HUD.split_hud,HUD.split_hud_assets
for _,name in ipairs({A.face,A.atlas,A.coverage,A.hard_coverage,Split.dynamic_coverage,Split.dynamic_face,Split.dynamic_soft})do resources[name]={id=name}end
local actual=Scene.new(sr,function()end,hot);local integration_cases=0
local foreground={}
for _,view in ipairs({'combat','inspect'})do for _,status in ipairs({'normal','empty','chamber'})do for _,opacity in ipairs({.35,0})do
 local config=HUD.config.new();config.texture_art_trial=true;config.texture_art_variant='split';config.hud_presentation='weapon_specific';config.font='hack';config.font_scale=1;config.decoration='split'
 config.style_3d='standard';config.panel_spatial_depth=16;config.split_readout_view=view;config.scale=.8;config.visibility_alpha=.8;config.panel_opacity=opacity;config.occlusion_mode='scene';config.world_texture_depth=7
 config.style_clock=11.75;config.shader_layers=copy(cfg.shader_layers);config.native_panel_projector=cfg.native_panel_projector
 local rounds,capacity=view=='inspect'and 123 or 27,view=='inspect'and 200 or 45
 if status=='empty'then rounds=0 elseif status=='chamber'then rounds=capacity+1 end
 local raw={resource_hex='968211c0033dce64',kind='magazine',rounds=rounds,capacity=capacity,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',reloadable=true,chamber_supported=true,chamber_rounds=status=='chamber'and 1 or 0}
 if view=='inspect'then raw.rpm=900;raw.rpm_selectable=true;raw.ammo_mode='HE';raw.safety_mode='UNSAFE';raw.reserve_kind='BELTS'end
 local model=assert(HUD.model.normalize(raw));local out=assert(Split.compose(model,10,20,2,.8,config,0,resource,function()return true end))
 local baseline_key=view..'/'..status
 if opacity==0 then
  local before=foreground[baseline_key];assert(before and #before==#out)
  for i,v in ipairs(out)do if v.split_role~='backing'then
   local old=before[i];assert(v.x==old.x and v.y==old.y and v.w==old.w and v.h==old.h and v.a==old.a and v.text==old.text,'Opacity changed production foreground')
  end end
 else foreground[baseline_key]=copy(out)end
 local turn=integration_cases%3
 local axes_pose=rotation(turn==0 and-18 or turn==1 and-27 or-38,turn==2 and 18 or 8,turn==0 and-3 or turn==1 and-7 or-12,.12,2,.1)
 local p={matrix=axes_pose,x=.12,y=2,z=.1,attach_point='root',resource_hex=model.resource_hex,first_person=integration_cases%2==1}
 shake_x,shake_y=turn*.025,-turn*.02
 local ready,aa,oo=Scene.prepare_commands(out,p,config,function()return true end);local grouped=assert(Scene.spatial_groups(ready))
 local image_count,layers=0,{}
 for _,v in ipairs(ready)do if v.type=='texture'then image_count=image_count+1;if v.shader_layer then layers[#layers+1]=v end end end
 assert(image_count<=24 and #layers==4,'Production Split exceeded the texture budget or dropped a shader')
 for i,v in ipairs(layers)do
  assert(v.texture_slot==image_count-4+i and v.spatial_plane=='main'and v.texture_resource==Split.dynamic_coverage and v.coverage_mask)
  assert(v.atlas_rect[1]==0 and v.atlas_rect[2]==0 and v.atlas_rect[3]==1 and v.atlas_rect[4]==1,'Production shader inherited an atlas crop')
 end
 local backing=ready[2];assert(backing.split_role=='backing'and backing.texture_resource==Split.dynamic_coverage and backing.coverage_mask)
 close(backing.a,.8*opacity)
 local prep_scale=240*config.scale/out[1].world_reference_width*(p.first_person and .5 or 1)
 close(ready[1].edge_mask_box.w,320*2*prep_scale);close(ready[1].edge_mask_box.h,161*2*prep_scale)
 close(ready[1].edge_mask_box.y,ready[1].y+ready[1].h-ready[1].edge_mask_box.h)
 assert(out[1].w==(view=='inspect'and 410 or 320)*2 and out[1].h==(view=='inspect'and 178 or 161)*2)
 local nt,ng,nc=#triangles,#glyphs,native_calls
 assert(actual.draw(p,config,out,nil,nil,3840,2160,.05),actual.status)
 assert(native_calls-nc==4*#grouped and native_calls-nc<=16,'Production native projection escaped the four-point-per-pod budget')
 -- Chamber bonus now lives on the ones digit; only the empty warning adds a status pod.
 if status=='empty'then assert(#grouped==4)else assert(#grouped==3)end
 local images,seen={},{}
 for i=nt+1,#triangles do local v=triangles[i];if v.name:find(A.material,1,true)and not seen[v.gui]then seen[v.gui]=true;images[#images+1]=v end end
 local expected_images,expected_depths={},{}
 for _,group in ipairs(grouped)do
  local origin=Scene.spatial_origin(aa,oo,group.depth);local frame=group.commands[1]
  expected_depths[group.name]=project(Scene.point(aa,origin,frame.x+frame.w/2,frame.y+frame.h/2)).depth
  for _,v in ipairs(group.commands)do if v.type=='texture'and v.a>0 then expected_images[#expected_images+1]={command=v,origin=origin,depth=expected_depths[group.name]}end end
 end
 assert(#images==#expected_images,'Production alpha-zero backing was drawn or a visible image disappeared')
 local shader_roots={};local shader_count=0
 for i,image in ipairs(images)do
  local expected=expected_images[i];local command=expected.command
  assert(image.resource==resources[command.texture_resource],'Production texture binding moved between pods')
  close(image.params.threshold_fade,expected.depth)
  local a,b,c=image.params.scissor_rect,image.params.atlas_scissor,image.params.clip_box
  for _,uv in ipairs({{0,0},{1,1},{.31,.67}})do
   local hit=project(Scene.point(aa,expected.origin,command.x+uv[1]*command.w,command.y+(1-uv[2])*command.h))
   local x,y=hit.x,1-hit.y;local denominator=c[1]*x+c[2]*y+c[3]
   close((a[1]*x+a[2]*y+a[3])/denominator,command.atlas_rect[1]+uv[1]*command.atlas_rect[3])
   close((b[1]*x+b[2]*y+b[3])/denominator,command.atlas_rect[2]+uv[2]*command.atlas_rect[4])
  end
  if command.shader_layer then
   assert(not shader_roots[image.gui]);shader_roots[image.gui]=true;shader_count=shader_count+1
   close(math.floor(image.params.scissor_mode/2)%256/32,command.shader_layer.pattern_size)
   assert(image.params.scissor_mode%2==1 and image.ink[1]==math.floor(.8*command.shader_layer.opacity*255+.5))
  end
 end
 assert(shader_count==4)
 local font_roots={},{}
 local matched={}
 for i=ng+1,#glyphs do
  local glyph=glyphs[i];assert(glyph.params.scissor_mode==1 and glyph.resource==HUD.native_font_data.faces.hack.font)
  if not font_roots[glyph.gui]then
   local name
   for plane,d in pairs(expected_depths)do if math.abs(glyph.params.threshold_fade-d)<1e-7 then name=plane;break end end
   assert(name and not matched[name],'Production pods shared native font/depth material ownership')
   matched[name]=true;font_roots[glyph.gui]=name
  end
  close(glyph.params.threshold_fade,expected_depths[font_roots[glyph.gui]])
 end
 for name in pairs(expected_depths)do assert(matched[name],'Production readout pod lost native labels: '..name)end
 integration_cases=integration_cases+1
end end end
actual.release();for _,g in ipairs(made)do assert(freed[g],'Production GUI leaked on release')end
print('PASS Split spatial: four native snapshots/16 calls, pod UV/depth and native-font GUI isolation, independent shader layers, shake, optional retirement, legacy depth, '..recovery_cases..' recovery cases and '..integration_cases..' production compositor/native cases')
