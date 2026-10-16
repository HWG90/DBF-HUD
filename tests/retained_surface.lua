-- Pure API doubles: resource ownership, retained content, exact atlas geometry,
-- animation invalidation, and fail-closed unsupported command coverage.
HUD={shader_catalog={}}
for _,name in ipairs({'native_font_data','native_font_uv','font','config','screen_scene'})do HUD[name]=dofile('src/'..name..'.lua')end
HUD.shader_layers={scales={.5,1,2,4}}
HUD.texture_theme={material=function(name,id)return id=='test'and name..'_texture_theme_test'or name end,
 parameters=function(depth,scale,time,animate)return depth+scale*2+(animate==1 and math.floor(time*16)*512+8388608 or 0)end}
local Surface=dofile('src/retained_surface.lua')
local events,callbacks,triangles,glyphs,materials={},{},{},{},{}
local function event(s)events[#events+1]=s end
local count=0;local function object(kind)count=count+1;return {kind=kind,id=count}end
local sr={Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,
 Vector4=function(...)return {...}end,Color=function(...)return {...}end,
 Matrix4x4={from_elements=function(...)return {...}end},
 Application={can_get=function()return true end,new_world=function()event('world');return object('world')end,
  release_world=function()event('free world')end,
  create_viewport=function(w,name)assert(w.kind=='world'and name=='offscreen_ui_weapon_screen');return object('viewport')end,
  destroy_viewport=function()event('free viewport')end,
  render_world=function(w,c,v,e)assert(w.kind=='world'and c.kind=='camera'and v.kind=='viewport'and e.kind=='environment');event('render')end},
 World={spawn_unit=function()return object('unit')end,update=function(w,dt)assert(dt==0);event('update')end,
  create_default_shading_environment=function()return object('environment')end,
  destroy_shading_environment=function()event('free environment')end,
  create_screen_gui=function(w,mode,x,y)assert(mode=='scale'and x==1 and y==1);return object('gui')end,
  destroy_gui=function(w,g)assert(not g.dead);g.dead=true;event('free gui')end},
 Unit={camera=function()return object('camera')end},
 Renderer={create_resource=function(kind,format,w,h)assert(kind=='render_target'and format=='R8G8B8A8');local t=object('target');t.w,t.h=w,h;return t end,
  destroy_resource=function(t)assert(not t.dead);t.dead=true;event('free target')end},
 Viewport={set_output_render_target=function(v,t)assert(v.kind=='viewport'and t.kind=='target')end},
 Gui={material=function(g,name)local h={gui=g,name=name,values={}};materials[#materials+1]=h;return h end,
  triangle=function(g,a,b,c,layer,ink,name)assert(not g.dead);triangles[#triangles+1]={gui=g,a=a,b=b,c=c,layer=layer,ink=ink,name=name};return #triangles end,
  bitmap_3d_uv=function(g,name,u0,u1,tm,pos,layer,extent,ink)
   assert(not g.dead);glyphs[#glyphs+1]={gui=g,name=name,u0=u0,u1=u1,tm=tm,pos=pos,layer=layer,extent=extent,ink=ink};return #glyphs
  end},
 Material={set_scalar=function(h,k,v)assert(not h.gui.dead);h.values[k]=v end,
  set_vector4=function(h,k,v)assert(not h.gui.dead);h.values[k]=v end,
  set_texture=function(h,k,v)assert(not h.gui.dead);h.values[k]=v end,
  set_resource=function(h,k,v)assert(not h.gui.dead);h.values[k]=v end}}
local globals={HUDRenderBridge={api=1,subscribe=function(id,fn)
 assert(not callbacks[id]);callbacks[id]=fn;return function()callbacks[id]=nil;event('unsubscribe')end
end}}
local consumers={};local art={image=object('image'),mask=object('mask')}
local hot={resource=function(name)return art[name]end,register_consumer=function(id,fn)assert(not consumers[id]);consumers[id]=fn end}
local function render()for _,fn in pairs(callbacks)do fn()end end
local function clone(v)if type(v)~='table'then return v end;local r={};for k,x in pairs(v)do r[k]=clone(x)end;return r end
local frame={type='panel',x=10,y=20,w=80,h=40,c={0,0,0},a=0,spatial_plane='main',spatial_depth=2,
 edge_mask_resource='mask',edge_mask_material='image_material',edge_mask_box={x=10,y=20,w=80,h=40}}
local commands={frame,
 {type='texture',x=20,y=25,w=30,h=20,c={255,211,90},a=.75,texture_resource='image',texture_material='image_material',texture_theme=false,texture_layer=40,atlas_rect={.25,.5,.5,.25}},
 {type='text',x=12,y=30,size=10,text='08',font='hack',c={250,250,240},a=.8,numeric_display=true,last_digit_color={255,210,70}},
 {type='rect',x=10,y=20,w=3,h=40,c={255,220,60},a=.6,decoration=true}}
local surface=Surface.new(sr,function()end,globals,hot)
assert(surface.prepare(commands,{}));assert(surface.texture and not surface.ready)
assert(surface.bounds.pixel_width==320 and surface.bounds.pixel_height==160)
assert(surface.stats.rebuilds==1 and surface.stats.renders==0)
assert(#triangles==4 and #glyphs==2,'orthographic source must use one exact atlas bitmap per glyph')
local face=HUD.native_font_data.faces.hack;local metric=face.glyphs[48];local coords=HUD.native_font_uv.hack[48]
assert(glyphs[1].u0[1]==coords[1]and glyphs[1].u0[2]==coords[2]and glyphs[1].u1[2]==coords[4])
assert(math.abs(glyphs[1].tm[1]-(metric[4]-metric[2])*10/face.em*4)<1e-9,'glyph width changed')
assert(glyphs[1].ink[1]==math.floor(.8/3*255+.5)and glyphs[2].ink[2]==255,'numeric alpha/tint changed')
assert(materials[1].values.artwork_texture==art.image and materials[1].values.scissor_mode==0)
local row1,row2=materials[1].values.scissor_rect,materials[1].values.atlas_scissor
assert(math.abs(row1[1]*(20-10)/80+row1[3]-.25)<1e-9,'left atlas mapping')
assert(math.abs(row2[2]*(1-(45-20)/40)+row2[3]-.5)<1e-9,'top atlas mapping')
assert(materials[3].values.artwork_texture==art.mask,'decoration mask omitted')
render();assert(surface.ready and surface.stats.renders==1 and surface.stats.render_calls==1 and surface.stats.render_seconds>=0)
for i=1,5 do assert(surface.prepare(commands,{}));assert(surface.tick(i));render()end
assert(surface.stats.renders==1 and surface.stats.rebuilds==1,'unchanged content redrawn')
local same=clone(commands);same[1].unrelated_heading=135;same[1].spatial_depth=3
same[2].texture_slot=19;same[2].unrelated_parent_revision=99
assert(surface.prepare(same,{}));render();assert(surface.stats.renders==1,'unrelated parent metadata invalidated surface')
local changed=clone(commands);changed[3].text='07'
assert(surface.prepare(changed,{}));assert(surface.ready,'dirty content discarded the last completed image');render();assert(surface.stats.renders==2)
assert(surface.texture and not surface.texture.dead,'content refresh replaced target')
local animated=clone(commands);animated[2].texture_theme_shader='test';animated[2].shader_layer={animate=true,speed=1,pattern_size=.5}
assert(surface.prepare(animated,{style_clock=0}));render();local before=surface.stats.renders
assert(surface.tick(.1));render();assert(surface.stats.renders==before+1,'animation was throttled')
assert(surface.tick(.1));render();assert(surface.stats.renders==before+1,'same shader state redrawn')
local still=clone(animated);still[2].shader_layer.animate=false
assert(surface.prepare(still,{}));render();before=surface.stats.renders
for i=1,10 do assert(surface.tick(i));render()end
assert(surface.stats.renders==before,'frozen shader was treated as animated')
local bad=clone(commands);bad[4].effect_shader_band=true
local ok,reason=surface.prepare(bad,{});assert(not ok and reason:find('unsupported',1,true))
local resize=clone(commands);resize[1].w=100
ok,reason=surface.prepare(resize,{});assert(not ok and reason:find('release required',1,true),'target resized while consumer may hold it')
local texture=surface.texture;surface.detach_consumer=function()event('detach');return true end
assert(surface.release());assert(texture.dead and not surface.texture)
assert(surface.error==nil,'explicit release retained stale failure state')
local tail=table.concat(events,',');assert(tail:find('detach,unsubscribe,free gui,free gui,free gui,free viewport,free environment,free world,free target',1,true),'consumer/producer release order changed')
assert(surface.release());assert(surface.prepare(commands,{}));render();assert(surface.ready,'surface could not be safely rebuilt')
for _,fn in pairs(consumers)do assert(fn())end;assert(not surface.texture,'artwork invalidation retained material consumers')
local render_world=sr.Application.render_world
sr.Application.render_world=function()error('simulated offscreen rejection')end
assert(surface.prepare(commands,{}));render()
assert(not surface.ready and surface.error:find('offscreen rejection',1,true))
local failures=surface.stats.render_calls;render();assert(surface.stats.render_calls==failures,'failed callback retried without a new preparation')
assert(surface.release());assert(surface.error==nil,'render failure survived release')
sr.Application.render_world=render_world
assert(surface.prepare(resize,{}));render();assert(surface.ready and surface.bounds.pixel_width==400,'resize failed after explicit release')
assert(surface.release())
local cold=Surface.new(sr,function()end,{},nil)
ok,reason=cold.prepare(commands,{});assert(not ok and reason,'bridge-less surface must fail closed')
local mixed=clone(commands);mixed[2].spatial_plane='status'
ok,reason=surface.prepare(mixed,{});assert(not ok and reason:find('mixed spatial planes',1,true))
print('retained_surface: geometry, tint, mappings, content retention, animation, ownership and fallback passed')
