-- Experimental retained Split compositor. Production remains screen_scene until
-- this candidate passes live artwork, depth, lifecycle and total-cost checks.
local M={}
local function copy(t)local q={};for k,v in pairs(t)do q[k]=v end;return q end
function M.new(sr,log,globals,hot)
 local self={status='idle',mode=nil,stats={frames=0,ready_frames=0},surfaces={}}
 local entries,input,prepared,output,display_config,prepare_key
 local pool={}
 local screen
 local facade={resource=function(name)
  for _,e in pairs(entries or {})do if name==e.resource then return e.surface.texture end end
  return hot and hot.resource(name)
 end}
 if hot then
  facade.register_consumer=hot.register_consumer
  facade.image=hot.image
 end
 function self.release()
  if screen then screen.release()end
  for _,e in pairs(pool)do if e.carrier then local ok,why=e.carrier.release();if ok==false then return false,why end end end
  for _,e in pairs(pool)do local ok,why=e.surface.release();if ok==false then return false,why end end
  entries={};input,prepared,output,display_config,prepare_key=nil,nil,nil,nil,nil;self.surfaces={};self.mode=nil
  return true
 end
 function self.timing()
  local total,calls,updates=0,0,0
  for _,e in pairs(pool)do local s=e.surface.stats or{};total=total+(s.render_seconds or 0);calls=calls+(s.render_calls or 0);updates=updates+(s.rebuilds or 0)end
  return {render_seconds=total,render_calls=calls,compositions=updates,frames=self.stats.frames,ready_frames=self.stats.ready_frames}
 end
 local function fail(why)
  self.status=tostring(why);local ok,err=self.release();if ok==false then self.status=self.status..'; cleanup: '..tostring(err)end;return false,self.status
 end
 local function draw(p,c,commands,camera,fov,w,h,near)
  self.stats.frames=self.stats.frames+1
  local mode=c.retained_mode
  if mode~='mesh'and mode~='worldgui'and mode~='screen_texture'then return fail('retained mode unavailable')end
  if not commands[1].split_hud or c.style_3d~='standard'then return fail('retained candidate requires standard Split')end
  if self.mode~=mode then local ok,why=self.release();if ok==false then return false,why end;self.mode=mode end
  local key=table.concat({tostring(c.scale),tostring(c.presentation_view),tostring(p.first_person),tostring(c.placement_mode),tostring(c.first_person_zoom_demo),tostring(c.retained_surface_density),tostring(c.theme_shader),tostring(c.theme_shader_scale),tostring(c.theme_shader_speed),tostring(c.theme_shader_animate)},':')
  if input~=commands or prepare_key~=key then
   local ok,ready=pcall(HUD.screen_scene.prepare_commands,commands,p,c,sr.Application.can_get)
   if not ok then return fail(ready)end
   prepared=ready
   local groups=HUD.screen_scene.spatial_groups(ready);if not groups then return fail('Split planes unavailable')end
   local present={};entries=entries or{}
   for _,group in ipairs(groups)do
    present[group.name]=true
    local e=pool[group.name]
    if not e then
     e={resource='mods/dbf_hud/textures/retained_'..group.name}
     e.surface=HUD.retained_surface.new(sr,log,globals,hot)
     e.surface.detach_consumer=function()
      input=nil
      if screen then screen.release()end
      if e.carrier then return e.carrier.release()end
      return true
     end
     pool[group.name]=e
    end
    if mode~='screen_texture'and(not e.carrier or e.carrier.mode~=mode)then e.carrier=HUD.retained_carrier.new(sr,log,mode)end
    entries[group.name]=e
    local success,why=e.surface.prepare(group.commands,c)
    if not success and why=='surface dimensions changed; release required'then
     local released,err=e.surface.release();if not released then return fail(err)end
     success,why=e.surface.prepare(group.commands,c)
    end
    if not success then return fail(why)end
    e.depth=group.depth;self.surfaces[group.name]=e.surface
   end
   for name,e in pairs(entries)do if not present[name]then local ok,why=e.surface.release();if not ok then return fail(why)end;entries[name]=nil;self.surfaces[name]=nil end end
   input=commands;prepare_key=key
   -- Return the composed planes through the existing HUD Texture renderer as
   -- a control. Undo only the preparation scale; its normal placement runs once.
   local f,r=commands[1],prepared[1];local scale=r.w/f.w
   local meta=copy(f);meta.a=0;meta.edge_mask_resource=nil;meta.edge_mask_material=nil
   output={meta}
   for _,group in ipairs(groups)do
    local e=entries[group.name];local b=e.surface.bounds
    output[#output+1]={type='texture',x=(b.x-r.x)/scale+f.x,y=(b.y-r.y)/scale+f.y,w=b.w/scale,h=b.h/scale,
     a=1,c={255,255,255},texture_material='mods/dbf_hud/materials/adjudicator_tall_v1',texture_resource=e.resource,
     atlas_rect={0,0,1,1},texture_theme=false,texture_layer=50,spatial_plane=group.name,spatial_depth=e.depth/scale}
   end
  end
  local ready=true
  for _,e in pairs(entries)do
   local ok,why=e.surface.tick(c.style_clock or 0)
   if ok==false then return fail(why)end
   if not e.surface.ready then ready=false end
  end
  if not ready then
   if screen then screen.release()end
   for _,e in pairs(entries)do if e.carrier then local ok,why=e.carrier.release();if ok==false then return fail(why)end end end
   self.status='awaiting retained render';return false,self.status
  end
  if mode=='screen_texture'then
   if not screen then screen=HUD.screen_scene.new(sr,log,facade)end
   display_config=copy(c);display_config.shader_layers={};display_config.theme_shader='none';display_config.effect_shader='none'
   display_config.effect_scanlines=false;display_config.effect_sweep=false;display_config.effect_flicker=false
   display_config.layout_cache_token=output
   if not screen.draw(p,display_config,output,camera,fov,w,h,near)then
    local why=screen.status;screen.release();screen=nil;return fail(why)
   end
  else
   local axes,at=HUD.screen_scene.panel_pose(p,c,prepared)
   for _,e in pairs(entries)do
    local origin=HUD.screen_scene.spatial_origin(axes,at,e.depth)
    local ok,why=e.carrier.draw(axes,origin,e.surface.bounds,e.surface.texture,c)
    if not ok then return fail(why)end
   end
  end
  self.stats.ready_frames=self.stats.ready_frames+1;self.status='retained '..mode;return true
 end
 function self.draw(...)
  local ok,result,why=pcall(draw,...)
  if not ok then return fail(result)end
  return result,why
 end
 return self
end
return M
