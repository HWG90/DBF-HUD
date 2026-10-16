-- Candidate offscreen compositor. The caller owns and moves the consuming plane.
-- Content is retained; camera motion never invalidates these pixels. This module
-- does not change the production route or promise offscreen alpha equivalence.
local M={}
local serial=0
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function copy(v)
 if type(v)~='table'then return v end
 local out={};for k,x in pairs(v)do out[k]=copy(x)end;return out
end
local function signature(v)
 if type(v)~='table'then return type(v)..':'..tostring(v)end
 local keys={};for k in pairs(v)do keys[#keys+1]=k end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local out={'{'};for _,k in ipairs(keys)do out[#out+1]=signature(k);out[#out+1]=signature(v[k])end
 out[#out+1]='}';return table.concat(out,'|')
end
function M.new(sr,log,globals,hot)
 globals=globals or _G;log=log or function()end;serial=serial+1
 local id='dbf_hud.retained_surface.'..serial
 local A,W,R,V,U,G=sr.Application,sr.World,sr.Renderer,sr.Viewport,sr.Unit,sr.Gui
 local self={ready=false,stats={prepares=0,rebuilds=0,renders=0,render_calls=0,render_seconds=0,unchanged=0,uniform_updates=0}}
 local world,viewport,camera,environment,unsubscribe,content_key
 local guis,animations={},{};local dirty=false;local last_commands,last_config
 local fill='mods/dbf_hud/materials/screen_hud_fill'
 local function error_result(reason)self.ready=false;self.error=tostring(reason);return false,self.error end
 local function destroy_guis()
  for i=#guis,1,-1 do W.destroy_gui(world,guis[i]);guis[i]=nil end
  animations={}
 end
 function self.release(detach)
  -- The consumer may still reference this target; never free it first.
  local ok,err=pcall(function()
   local fn=detach or self.detach_consumer
   if fn then assert(fn()~=false,'surface consumer did not detach')end
   if unsubscribe then unsubscribe();unsubscribe=nil end
   self.ready=false;dirty=false
   destroy_guis()
   if viewport then A.destroy_viewport(world,viewport);viewport=nil end
   if environment then W.destroy_shading_environment(world,environment);environment=nil end
   if world then A.release_world(world);world=nil end
   if self.texture then R.destroy_resource(self.texture);self.texture=nil end
   self.bounds=nil;content_key=nil;last_commands=nil;last_config=nil;self.error=nil
  end)
  if not ok then return error_result(err)end
  return true
 end
 local function api_preflight()
  local bridge=rawget(globals,'HUDRenderBridge')
  assert(bridge and bridge.api==1 and type(bridge.subscribe)=='function','startup HUD render bridge required')
  for _,pair in ipairs({{A,'new_world'},{A,'release_world'},{A,'create_viewport'},{A,'destroy_viewport'},
   {A,'render_world'},{A,'can_get'},{W,'spawn_unit'},{W,'update'},{W,'create_screen_gui'},
   {W,'destroy_gui'},{W,'destroy_shading_environment'},{U,'camera'},{R,'create_resource'},
   {R,'destroy_resource'},{V,'set_output_render_target'},{G,'triangle'},{G,'material'},
   {sr.Material,'set_scalar'},{sr.Material,'set_vector4'},{sr.Material,'set_texture'},
   {sr.Material,'set_resource'}})do assert(pair[1]and type(pair[1][pair[2]])=='function','missing '..pair[2])end
  return bridge
 end
 local function material_available(name)
  assert(type(name)=='string'and A.can_get('material',name),'surface material unavailable: '..tostring(name))
 end
 local function build_plan(commands,c)
  assert(type(commands)=='table'and type(commands[1])=='table','planar commands required')
  local frame=commands[1];assert(frame.type=='panel','surface frame required')
  for _,k in ipairs({'x','y','w','h'})do assert(finite(frame[k]),'invalid surface '..k)end
  assert(frame.w>0 and frame.h>0,'empty surface bounds')
  local density=c.retained_surface_density or 4
  assert(finite(density)and density>=1 and density<=8,'invalid retained density')
  local bounds={x=frame.x,y=frame.y,w=frame.w,h=frame.h,density=density}
  local right,top=frame.x+frame.w,frame.y+frame.h
  local ops={}
  local function include(x,y,w,h)
   assert(finite(x)and finite(y)and finite(w)and finite(h)and w>=0 and h>=0,'invalid surface geometry')
   bounds.x,bounds.y=math.min(bounds.x,x),math.min(bounds.y,y)
   right,top=math.max(right,x+w),math.max(top,y+h)
  end
  local function texture(v,box,rect)
   local name=HUD.texture_theme.material(v.texture_material,v.texture_theme_shader or(v.texture_theme==false and'none'or c.theme_shader),A.can_get)
   material_available(name)
   local binding=hot and hot.resource(v.texture_resource)
   assert(binding or A.can_get('texture',v.texture_resource),'surface texture unavailable: '..tostring(v.texture_resource))
   local shader=name:find('_texture_theme_',1,true)~=nil
   local layer=v.shader_layer
   local scale=layer and(layer.pattern_size or HUD.shader_layers.scales[layer.scale or 2])or c.theme_shader_scale or 1
   local speed=layer and(layer.speed or 1)or c.theme_shader_speed or 1
   local animate=layer and layer.animate==true or(not layer and c.theme_shader_animate==true)
   local uv=v.atlas_rect or{0,0,1,1}
   assert(#uv==4 and finite(uv[1])and finite(uv[2])and finite(uv[3])and finite(uv[4])and uv[1]>=0 and uv[2]>=0 and uv[3]>0 and uv[4]>0 and uv[1]+uv[3]<=1+1e-9 and uv[2]+uv[4]<=1+1e-9,'invalid surface atlas rectangle')
   assert(box.w>0 and box.h>0,'empty artwork mapping')
   return {kind='image',x=rect.x,y=rect.y,w=rect.w,h=rect.h,quad=copy(rect.quad),box={x=box.x,y=box.y,w=box.w,h=box.h},uv=copy(uv),
    name=name,binding=binding or v.texture_resource,resource=binding~=nil,color=copy(v.c),alpha=v.a or 1,
    layer=v.texture_layer or 49,linear=v.texture_color_linear==true,shader=shader,scale=scale,speed=speed,animate=animate}
  end
  for _,v in ipairs(commands)do
   assert(not v.fold_child,'folded commands require their own surface')
   assert(v.spatial_plane==nil or frame.spatial_plane==nil or v.spatial_plane==frame.spatial_plane,'mixed spatial planes')
   assert(v.spatial_depth==nil or frame.spatial_depth==nil or v.spatial_depth==frame.spatial_depth,'mixed spatial depths')
   assert(not v.texture_layers,'expand texture layers before composition')
   if v.visible~=false and(v.a or 1)>0 and not v.spatial_metadata then
    assert(not v.fuel_endpoint and not v.heat_fill,'specialized fuel/heat geometry is unsupported')
    assert(not v.df_effect_sweep and not v.scanline_layer and not v.effect_shader_band,'mapped primitive effects are unsupported')
    local op
    if v.type=='texture'then
     op=texture(v,v,v)
     op.feather_x,op.feather_y=v.texture_feather_x,v.texture_feather_y
    elseif v.type=='text'then
     local face=assert(HUD.native_font_data.faces[v.font or'bigblue'],'surface font unavailable')
     local uv=assert(HUD.native_font_uv[v.font or'bigblue'],'surface font atlas unavailable')
     assert(type(G.bitmap_3d_uv)=='function'and sr.Matrix4x4 and(type(sr.Matrix4x4.from_elements)=='function'or type(sr.Matrix4x4.from_axes)=='function'),'surface native glyph API unavailable')
     local name=face.clear:sub(1,-7)..'_scene';material_available(name)
     assert(A.can_get('font',face.font),'surface native font unavailable')
     assert(finite(v.size)and v.size>0 and type(v.text)=='string','invalid surface text')
     op={kind='text',name=name,font=face.font,color=copy(v.c),alpha=v.a or 1,layer=51,glyphs={}}
     for _,part in ipairs(HUD.font.numeric_parts(v))do
      local plan=HUD.screen_scene.glyph_plan(part.text,v.x+part.dx,v.y,v.size/(face.em or 48),face,uv)
      for _,g in ipairs(plan)do
       g.color=copy(part.c or v.c);g.alpha=(part.alpha or 1)*(v.a or 1)
       op.glyphs[#op.glyphs+1]=g;include(g.x,g.bottom,g.right-g.x,g.top-g.bottom)
      end
     end
    elseif v.type=='rect'or v.type=='panel'then
     assert(not v.shader_layer,'mapped primitive shader layers are unsupported')
     assert(v.type~='panel'or c.theme_shader==nil or c.theme_shader=='none','themed panel primitives are unsupported')
     if v.decoration and not v.charge_meter and frame.edge_mask_resource then
      assert(hot and hot.resource(frame.edge_mask_resource),'decoration edge mask unavailable')
      local mask={texture_material=frame.edge_mask_material,texture_resource=frame.edge_mask_resource,
       texture_theme=false,c=v.c,a=v.a,texture_layer=50}
      op=texture(mask,frame.edge_mask_box or frame,v)
     else
      material_available(fill);op={kind='rect',name=fill,x=v.x,y=v.y,w=v.w,h=v.h,quad=copy(v.quad),color=copy(v.c),alpha=v.a or 1,layer=v.type=='panel'and 48 or 50}
     end
    else error('unsupported retained command: '..tostring(v.type))end
    if op.kind~='text'then
     include(op.x,op.y,op.w,op.h)
     if op.quad then assert(#op.quad==4,'invalid quad');for _,p in ipairs(op.quad)do include(p[1],p[2],0,0)end end
    end
    assert(type(op.color)=='table','surface tint required')
    for i=1,3 do assert(finite(op.color[i])and op.color[i]>=0 and op.color[i]<=255,'invalid surface tint')end
    assert(finite(op.alpha)and op.alpha>=0 and op.alpha<=1,'invalid surface alpha')
    ops[#ops+1]=op
   end
  end
  bounds.w,bounds.h=right-bounds.x,top-bounds.y
  bounds.pixel_width,bounds.pixel_height=math.ceil(bounds.w*density),math.ceil(bounds.h*density)
  assert(bounds.pixel_width<=2048 and bounds.pixel_height<=2048,'surface exceeds resolution budget; no downsampling allowed')
  return ops,bounds
 end
 local function create_target(bounds,bridge)
  local name='core/units/camera'
  if not A.can_get('unit',name)then name='core/appkit/units/camera/camera'end
  assert(A.can_get('unit',name),'offscreen camera unavailable')
  world=assert(A.new_world());camera=assert(U.camera(assert(W.spawn_unit(world,name)),1))
  if W.create_default_shading_environment then environment=assert(W.create_default_shading_environment(world))
  else
   local path='core/stingray_renderer/environments/midday/midday'
   assert(W.create_shading_environment and A.can_get('shading_environment',path),'offscreen environment unavailable')
   environment=assert(W.create_shading_environment(world,path))
  end
  viewport=assert(A.create_viewport(world,'offscreen_ui_weapon_screen'))
  self.texture=assert(R.create_resource('render_target','R8G8B8A8',bounds.pixel_width,bounds.pixel_height))
  V.set_output_render_target(viewport,self.texture);self.bounds=bounds
  unsubscribe=bridge.subscribe(id,function()
   if not dirty or not world then return end
   local began=os.clock()
   local ok,err=pcall(A.render_world,world,camera,viewport,environment)
   self.stats.render_seconds=self.stats.render_seconds+(os.clock()-began)
   self.stats.render_calls=self.stats.render_calls+1
   if ok then dirty=false;self.ready=true;self.stats.renders=self.stats.renders+1
   else self.ready=false;dirty=false;self.error=tostring(err);log('RETAINED_SURFACE render failed '..self.error)end
  end)
 end
 local function compose(ops,bounds)
  destroy_guis()
  local sx,sy=bounds.pixel_width/bounds.w,bounds.pixel_height/bounds.h
  local function ink(alpha,rgb,linear)
   if linear then rgb=HUD.config.native_rgb(rgb)end
   return sr.Color(math.floor(alpha*255+.5),rgb[1],rgb[2],rgb[3])
  end
  local function point(x,y)return sr.Vector3((x-bounds.x)*sx,0,(y-bounds.y)*sy)end
  for _,op in ipairs(ops)do
   -- Independent image materials retain their own binding and mapping uniforms.
   local gui=assert(W.create_screen_gui(world,'scale',1,1));guis[#guis+1]=gui
   local handle=assert(G.material(gui,op.name))
   sr.Material.set_scalar(handle,'threshold_fade',0);sr.Material.set_scalar(handle,'scissor_mode',0)
   if op.kind=='image'then
    sr.Material[op.resource and'set_resource'or'set_texture'](handle,'artwork_texture',op.binding)
    local b,uv=op.box,op.uv
    -- Inverse affine map from offscreen normalized (top-left) UV into atlas UV.
    local row1={bounds.w/b.w*uv[3],0,(bounds.x-b.x)/b.w*uv[3]+uv[1],0}
    local row2={0,bounds.h/b.h*uv[4],(b.y+b.h-bounds.y-bounds.h)/b.h*uv[4]+uv[2],0}
    sr.Material.set_vector4(handle,'scissor_rect',sr.Vector4(unpack(row1)))
    sr.Material.set_vector4(handle,'atlas_scissor',sr.Vector4(unpack(row2)))
    sr.Material.set_vector4(handle,'clip_box',sr.Vector4(0,0,1,0))
    if op.shader then animations[#animations+1]={handle=handle,scale=op.scale,speed=op.speed,animate=op.animate}end
   elseif op.kind=='text'then sr.Material.set_texture(handle,'diffuse_map',op.font)end
   if op.kind=='text'then
    for _,g in ipairs(op.glyphs)do
     local bx,by=(g.x-bounds.x)*sx,(g.bottom-bounds.y)*sy
     local w,h=(g.right-g.x)*sx,(g.top-g.bottom)*sy
     local tm
     if sr.Matrix4x4.from_elements then tm=sr.Matrix4x4.from_elements(w,0,0,0,1,0,0,0,h,bx,0,by)
     else tm=sr.Matrix4x4.from_axes(sr.Vector3(w,0,0),sr.Vector3(0,1,0),sr.Vector3(0,0,h),sr.Vector3(bx,0,by))end
     G.bitmap_3d_uv(gui,op.name,sr.Vector2(g.coords[1],g.coords[2]),sr.Vector2(g.coords[3],g.coords[4]),tm,sr.Vector3(0,0,0),op.layer,sr.Vector2(1,1),ink(g.alpha,g.color))
    end
   else
    local boxes=op.feather_x and HUD.screen_scene.feather_boxes(op.w,op.h,op.feather_x,op.feather_y)or{{0,0,op.w,op.h,1}}
    assert(not op.quad or #boxes==1,'feathered arbitrary quads are unsupported')
    for _,box in ipairs(boxes)do
     local x,y,w,h=op.x+box[1],op.y+box[2],box[3],box[4]
     local p=op.quad or{{x,y},{x+w,y},{x+w,y+h},{x,y+h}}
     local color=ink(op.alpha*box[5],op.color,op.linear)
     G.triangle(gui,point(unpack(p[1])),point(unpack(p[2])),point(unpack(p[3])),op.layer,color,op.name)
     G.triangle(gui,point(unpack(p[1])),point(unpack(p[3])),point(unpack(p[4])),op.layer,color,op.name)
    end
   end
  end
 end
 function self.tick(clock)
  if not world or self.error then return false,self.error end
  assert(finite(clock or 0),'invalid surface clock');clock=clock or 0
  for _,a in ipairs(animations)do
   local value=HUD.texture_theme.parameters(0,a.scale,clock*a.speed,a.animate and 1 or 0)
   -- Static shaders ignore time; retaining their original word avoids redraws.
   if not a.animate then value=HUD.texture_theme.parameters(0,a.scale,0,0)end
   if a.value~=value then
    sr.Material.set_scalar(a.handle,'scissor_mode',value);a.value=value;dirty=true
    self.stats.uniform_updates=self.stats.uniform_updates+1
   end
  end
  if dirty then
   local ok,err=pcall(W.update,world,0)
   if not ok then self.ready=false;return error_result(err)end
  end
  return true
 end
 function self.prepare(commands,c)
  c=c or {};self.stats.prepares=self.stats.prepares+1
  local cfg={theme_shader=c.theme_shader,theme_shader_scale=c.theme_shader_scale,theme_shader_speed=c.theme_shader_speed,
   theme_shader_animate=c.theme_shader_animate,retained_surface_density=c.retained_surface_density}
  local config_key=signature(cfg)
  if commands==last_commands and config_key==last_config and not self.error then self.stats.unchanged=self.stats.unchanged+1;return true end
  local ok,ops,bounds=pcall(build_plan,commands,c)
  if not ok then return error_result(ops)end
  local key=signature({ops,bounds})
  if key==content_key and not self.error then
   last_commands,last_config=commands,config_key;self.stats.unchanged=self.stats.unchanged+1;return true
  end
  if self.texture and(bounds.pixel_width~=self.bounds.pixel_width or bounds.pixel_height~=self.bounds.pixel_height)then
   return error_result('surface dimensions changed; release required')
  end
  local done,err=pcall(function()
   local bridge=api_preflight()
   if not self.texture then create_target(bounds,bridge)end
   self.bounds=bounds;compose(ops,bounds)
   -- A dirty producer still owns the last completed image. Keep that valid
   -- texture consumable until the next bridge render; only a new target or a
   -- failure is unready. Otherwise a changing compass would force fallback on
   -- every update before the render callback could run.
   dirty=true;self.error=nil;content_key=key;last_commands,last_config=commands,config_key
   self.stats.rebuilds=self.stats.rebuilds+1
   assert(self.tick(c.style_clock or 0))
  end)
  if not done then self.release();return error_result(err)end
  return true
 end
 if hot and hot.register_consumer then hot.register_consumer(id,function()return self.release()end)end
 return self
end
return M
