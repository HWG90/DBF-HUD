-- Exercise the production screen scene, not just label command conversion.
HUD={shader_catalog={}}
for _,name in ipairs({'native_font_data','native_font_uv','config','font','projection','native_label_data','native_labels'})do HUD[name]=dofile('src/'..name..'.lua')end
HUD.scene_test={mount=function()return 0,0,0 end};HUD.world_style={prepare=function(v)return v end}
HUD.texture_theme={material=function(name)return name end}
local Scene=dofile('src/screen_scene.lua')
local triangles,bitmaps,params,bindings={},{},{},{};local available=true;local moved=0;local native_calls=0
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Matrix4x4={from_axes=function(r,f,u,at)return {right=r,forward=f,up=u,at=at}end},
 Application={main_world=function()return'main'end,worlds=function()return{'main','ui'}end,can_get=function(kind)return kind~='texture'or available end},
 World={create_screen_gui=function()return{}end,destroy_gui=function()end},
 Gui={material=function(g,name)local h={gui=g,name=name};params[h]={};return h end,
  triangle=function(g,a,b,c,layer,ink,name)triangles[#triangles+1]={g=g,a=a,b=b,c=c,layer=layer,ink=ink,name=name};return #triangles end,
  destroy_triangle=function()end,
  bitmap_3d_uv=function(...)bitmaps[#bitmaps+1]={...};return #bitmaps end,destroy_bitmap_3d=function()end},
 Material={set_scalar=function(h,k,v)params[h][k]=v end,set_vector4=function(h,k,v)params[h][k]=v end,
  set_texture=function(h,k,v)bindings[h]={slot=k,texture=v}end}}
local function project(x,y,z)native_calls=native_calls+1;return{x=.5+.3*x/y+moved,y=.5+.3*z/y,depth=y}end
local cfg={font='hack',occlusion_mode='scene',native_panel_projector=project,world_texture_depth=.147,style_3d='standard'}
local commands={{type='panel',split_hud=true,spatial_metadata=true,x=0,y=0,w=320,h=161,c={9,27,53},a=0},
 {type='text',text='RELOADING',font='hack',x=87,y=70,size=11.5,c={233,196,93},a=.43,spatial_plane='main',spatial_depth=0}}
cfg.layout_cache_token=commands
local pose={matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},x=.1,y=1,z=.04,attach_point='root',resource_hex='968211c0033dce64'}
local scene=Scene.new(sr,function()end)
assert(scene.draw(pose,cfg,commands,nil,nil,1920,1080,.05),scene.status)
assert(#triangles==2 and #bitmaps==0,'Complete label did not replace eighteen glyph submissions with two triangles')
assert(scene.native_label_count==1,'Prepared label diagnostic missing')
assert(native_calls==4,'Label sprite added native camera projections')
local original=triangles[1];assert(original.layer==51 and original.ink[1]==math.floor(.43*255+.5)and original.ink[2]==233)
local bound=false
for h,b in pairs(bindings)do
 if b.texture==HUD.native_label_data.faces.hack.resource then
  bound=true;assert(b.slot=='artwork_texture'and params[h].scissor_mode==1 and params[h].threshold_fade==1,'Label lost scene-depth or texture binding')
 end
end
assert(bound,'Static label atlas was not bound')
moved=.05;assert(scene.draw(pose,cfg,commands,nil,nil,1920,1080,.05),scene.status)
assert(#triangles==4 and #bitmaps==0,'Camera movement changed label submission count')
assert(math.abs(triangles[3].a[1]-original.a[1]-.05*1920)<1e-6,'Cached label did not move at full frame rate')
cfg.native_label_sprites=false
assert(scene.draw(pose,cfg,commands,nil,nil,1920,1080,.05),scene.status)
assert(#triangles==4 and #bitmaps==18,'A/B toggle retained label sprites behind immutable command cache')
assert(scene.native_label_count==0,'Prepared label diagnostic survived disable')
cfg.native_label_sprites=true
assert(scene.draw(pose,cfg,commands,nil,nil,1920,1080,.05),scene.status)
assert(#triangles==6 and #bitmaps==18,'A/B toggle failed to restore label sprites')
cfg.profile_skip_text=true
assert(scene.draw(pose,cfg,commands,nil,nil,1920,1080,.05),scene.status)
assert(#triangles==6 and #bitmaps==18,'Text profiling mask continued to submit label sprites')
cfg.profile_skip_text=false
scene.release()
available=false;local fallback=Scene.new(sr,function()end);local before=#triangles
assert(fallback.draw(pose,cfg,commands,nil,nil,1920,1080,.05),fallback.status)
assert(#triangles==before and #bitmaps==36,'Undeployed atlas did not preserve the full native glyph fallback')
fallback.release()
print('PASS production label scene: 18 native glyph submissions -> 2 triangles; full-rate motion, depth, alpha and missing-asset fallback preserved')
