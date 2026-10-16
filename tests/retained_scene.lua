-- Orchestration contracts with deferred render completion and owned resources.
local Retained=dofile('src/retained_scene.lua')
local RealScene=dofile('src/screen_scene.lua')
local names={'main','reserve','context','status'}
local depths={main=16,reserve=-8,context=28,status=0}
local function copy(v)if type(v)~='table'then return v end;local q={};for k,x in pairs(v)do q[k]=copy(x)end;return q end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function close(a,b)assert(math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b))end
local function commands()
 local q={{type='panel',split_hud=true,x=-80,y=-100,w=240,h=160,a=.5,edge_mask_resource='edge',edge_mask_material='edge_material'}}
 for i,name in ipairs(names)do q[#q+1]={type='text',text=tostring(i),x=-60+i*10,y=-90+i*8,w=15,h=20,a=1,c={255,255,255},spatial_plane=name,spatial_depth=depths[name]}end
 return q
end
local function fixture(mode)
 local s={events={},surfaces={},carriers={},callbacks={},prepare_calls=0,screen_draws=0,screen_releases=0,sources={edge={}},target_refs={}}
 local function event(kind,id)s.events[#s.events+1]={kind=kind,id=id}end
 local hot={resource=function(name)return s.sources[name]end,image=function()return 'image'end,
  register_consumer=function(owner,detach)s.callbacks[owner]=detach end}
 local sr={Application={can_get=function()return true end}}
 HUD={screen_scene={spatial_groups=RealScene.spatial_groups,spatial_origin=RealScene.spatial_origin},retained_surface={},retained_carrier={}}
 function HUD.screen_scene.prepare_commands(list,p,c)
  s.prepare_calls=s.prepare_calls+1
  if s.reject_prepare then error('rejected preparation')end
  local q=copy(list);local scale=c.scale or 1
  if c.placement_mode=='auto'and p.first_person then scale=scale*.5 end
  for _,v in ipairs(q)do for _,k in ipairs({'x','y','w','h','spatial_depth'})do if v[k]then v[k]=v[k]*scale end end end
  return q
 end
 function HUD.screen_scene.panel_pose(p)return p.matrix,{x=p.x,y=p.y,z=p.z}end
 function HUD.screen_scene.new(_,_,facade)
  local screen={status='mock screen'};local failed=false;s.facade=facade;s.screen_instances=(s.screen_instances or 0)+1
  function screen.release()s.screen_releases=s.screen_releases+1;event('screen_release');return true end
  function screen.draw(p,c,list)
   s.screen_draws=s.screen_draws+1;s.output=list;s.display_config=c
   for i=2,#list do assert(facade.resource(list[i].texture_resource),'screen lost retained target')end
   if s.reject_screen then failed=true;screen.status='screen submission rejected' end
   if failed then return false end
   return true
  end
  return screen
 end
 function HUD.retained_surface.new(_,_,_,provider)
  local surf={ready=false,stats={rebuilds=0,render_calls=0,render_seconds=0},id=#s.surfaces+1}
  s.surfaces[#s.surfaces+1]=surf
  function surf.prepare(list,c)
   if s.reject_surface then return false,'surface rejected' end
   local density=c.retained_surface_density or 4
   if surf.texture and(surf.bounds.w~=list[1].w or surf.bounds.h~=list[1].h or surf.bounds.density~=density)then return false,'surface dimensions changed; release required'end
   surf.group=list[2].spatial_plane;surf.commands=list;surf.bounds={x=list[1].x,y=list[1].y,w=list[1].w,h=list[1].h,density=density}
   surf.texture=surf.texture or {owner=surf.id};surf.released=false;surf.stats.rebuilds=surf.stats.rebuilds+1
   event('compose',surf.id);return true
  end
  function surf.tick(clock)
   surf.clock=clock
   if s.throw_tick then error('native tick threw')end
   if s.reject_tick then return false,'surface tick rejected'end
   return true
  end
  function surf.render()
   assert(surf.texture and not surf.released);surf.ready=true;surf.stats.render_calls=surf.stats.render_calls+1;surf.stats.render_seconds=surf.stats.render_seconds+.001
  end
  function surf.release()
   if surf.detach_consumer then local ok,err=surf.detach_consumer();if ok==false then return false,err end end
   if surf.texture then
    assert(not s.target_refs[surf.texture],'target freed before carrier detached')
    if s.reject_surface_release then return false,'target release rejected'end
    event('target_release',surf.id);surf.texture=nil
   end
   surf.ready=false;surf.bounds=nil;surf.released=true;return true
  end
  provider.register_consumer('mock_surface_'..surf.id,function()return surf.release()end)
  return surf
 end
 function HUD.retained_carrier.new(_,_,carrier_mode)
  local carrier={id=#s.carriers+1,mode=carrier_mode,moves=0};s.carriers[#s.carriers+1]=carrier
  function carrier.draw(axes,origin,bounds,target)
   if s.throw_carrier then error('native carrier threw')end
   if s.reject_carrier then return false,'carrier rejected'end
   assert(target and bounds);carrier.target=target;s.target_refs[target]=carrier
   carrier.axes=axes;carrier.origin=copy(origin);carrier.bounds=copy(bounds);carrier.moves=carrier.moves+1
   event('move',carrier.id);return true
  end
  function carrier.release()
   if carrier.target and s.reject_carrier_release then return false,'carrier detach rejected'end
   if carrier.target then s.target_refs[carrier.target]=nil;carrier.target=nil;event('carrier_release',carrier.id)end
   return true
  end
  return carrier
 end
 local renderer=Retained.new(sr,function()end,{},hot)
 local p={matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},x=.1,y=2,z=.3,first_person=false}
 local c={retained_mode=mode or 'worldgui',style_3d='standard',placement_mode='auto',scale=.7,style_clock=0,shader_layers={{shader='test',enabled=true}},theme_shader='test',effect_shader='test',effect_scanlines=true,effect_sweep=true,effect_flicker=true}
 local list=commands()
 function s.draw()return renderer.draw(p,c,list,nil,nil,1920,1080,.05)end
 function s.render()for _,surf in pairs(renderer.surfaces)do surf.render()end end
 function s.change_input(value)list=value end
 function s.invalidate()
  local pending={};for _,fn in pairs(s.callbacks)do pending[#pending+1]=fn end
  for _,fn in ipairs(pending)do assert(fn()~=false,'hot invalidation failed')end
 end
 return s,renderer,p,c,list
end
local tests={}
local function test(name,fn)tests[#tests+1]={name,fn}end
test('four planes wait for rendering and then move without recomposition',function()
 local s,r,p,c=fixture('worldgui')
 local ok,why=s.draw();assert(not ok and why:find('awaiting',1,true));assert(count(r.surfaces)==4 and #s.carriers==4)
 for _,carrier in ipairs(s.carriers)do assert(carrier.moves==0,'unrendered target became visible')end
 assert(not s.draw()and s.prepare_calls==1)
 s.render();assert(s.draw());assert(r.timing().render_calls==4)
 for i=1,90 do p.x=p.x+.001;p.z=p.z-.002;c.style_clock=i/60;assert(s.draw())end
 assert(s.prepare_calls==1,'camera movement recomposed the surface')
 for _,surf in ipairs(s.surfaces)do assert(surf.stats.rebuilds==1 and surf.clock==90/60)end
 for _,carrier in ipairs(s.carriers)do
  assert(carrier.moves==91);local group=carrier.target.owner;local name=s.surfaces[group].group
  close(carrier.origin.x,p.x);close(carrier.origin.y,p.y-depths[name]*c.scale/1000);close(carrier.origin.z,p.z)
 end
end)
test('input and appearance changes invalidate while clock alone does not',function()
 local s,r,p,c,list=fixture();assert(not s.draw());s.render();assert(s.draw())
 local next_list=copy(list);next_list[2].text='42';s.change_input(next_list)
 assert(s.draw());assert(s.prepare_calls==2)
 assert(count(s.target_refs)==4,'content change unnecessarily hid completed targets')
 s.render();assert(s.draw())
 c.style_clock=100;assert(s.draw()and s.prepare_calls==2)
 c.theme_shader='other_shader';assert(s.draw(),'shader change discarded usable targets');assert(s.prepare_calls==3)
 s.render();assert(s.draw());c.retained_surface_density=6;assert(not s.draw(),'density change reused stale surface');s.render();assert(s.draw())
end)
test('first person and placement scaling invalidate prepared geometry',function()
 local s,r,p,c=fixture();assert(not s.draw());s.render();assert(s.draw());local initial=r.surfaces.main.bounds.w
 p.first_person=true;assert(not s.draw(),'view transition reused third-person geometry');s.render();assert(s.draw())
 close(r.surfaces.main.bounds.w,initial*.5)
 c.placement_mode='manual';assert(not s.draw(),'placement mode reused half-scale geometry');s.render();assert(s.draw())
 close(r.surfaces.main.bounds.w,initial)
end)
test('screen texture control uses four baked targets without applying effects twice',function()
 local s,r,p,c,list=fixture('screen_texture');assert(not s.draw());s.render();assert(s.draw())
 assert(#s.carriers==0 and s.screen_draws==1 and #s.output==5)
 local q=s.display_config
 assert(#q.shader_layers==0 and q.theme_shader=='none'and q.effect_shader=='none'and not q.effect_scanlines and not q.effect_sweep and not q.effect_flicker)
 assert(c.theme_shader=='test'and c.effect_scanlines and #c.shader_layers==1,'display copy mutated user settings')
 assert(not s.output[1].edge_mask_resource and not s.output[1].edge_mask_material,'edge mask was baked twice')
 for i=2,#s.output do local v=s.output[i]
  close(v.x,list[1].x);close(v.y,list[1].y);close(v.w,list[1].w);close(v.h,list[1].h)
  close(v.spatial_depth,depths[v.spatial_plane]);assert(v.atlas_rect[3]==1 and v.a==1 and v.texture_theme==false)
 end
 assert(s.facade.resource('edge')==s.sources.edge,'source facade fallback changed')
 assert(r.release()~=false);local first_target,first_screen
 for i,e in ipairs(s.events)do if e.kind=='screen_release'then first_screen=first_screen or i elseif e.kind=='target_release'then first_target=first_target or i end end
 assert(first_screen and first_target and first_screen<first_target)
end)
test('screen submission failure can recover with a new screen renderer',function()
 local s,r=fixture('screen_texture');assert(not s.draw());s.render();s.reject_screen=true
 local ok,why=s.draw();assert(not ok and why:find('screen submission rejected',1,true))
 s.reject_screen=false;assert(not s.draw());s.render();assert(s.draw(),'failed screen renderer remained permanently latched')
 assert(s.screen_instances==2,'native failure did not replace the failed screen renderer')
end)
test('all consumers detach before targets retire and timing survives release',function()
 local s,r=fixture('mesh');assert(not s.draw());s.render();assert(s.draw())
 local before=r.timing();assert(before.compositions==4,'timing did not count actual surface rebuilds')
 assert(r.release()~=false);assert(count(s.target_refs)==0 and count(r.surfaces)==0)
 local last_carrier,first_target
 for i,e in ipairs(s.events)do if e.kind=='carrier_release'then last_carrier=i elseif e.kind=='target_release'then first_target=first_target or i end end
 assert(last_carrier and first_target and last_carrier<first_target,'target destruction began before all carriers detached')
 local after=r.timing();close(after.render_seconds,before.render_seconds);assert(after.render_calls==before.render_calls and after.compositions==before.compositions,'release reset measured work')
end)
test('rejections fail closed and cleanup failure retains target ownership',function()
 for _,kind in ipairs({'reject_prepare','reject_surface','reject_tick','reject_carrier'})do
  local s,r=fixture();s[kind]=true
  local ok,why=s.draw()
  if kind=='reject_carrier'then s.render();ok,why=s.draw()end
  assert(not ok and type(why)=='string'and why:find('reject',1,true),kind)
  assert(count(s.target_refs)==0,kind..' left a bound target')
 end
 local s,r=fixture();assert(not s.draw());s.render();assert(s.draw());s.reject_carrier_release=true
 local ok,why=r.release();assert(ok==false and count(s.target_refs)==4,'cleanup failure discarded owned targets')
 for _,surf in ipairs(s.surfaces)do assert(surf.texture,'cleanup failure destroyed a still-bound target')end
 s.reject_carrier_release=false;assert(r.release()~=false and count(s.target_refs)==0)
end)
test('hot source invalidation re-prepares same commands before using new targets',function()
 local s,r=fixture();assert(not s.draw());s.render();assert(s.draw());local prepares=s.prepare_calls
 s.invalidate();assert(count(s.target_refs)==0)
 local ok,why=s.draw();assert(not ok and why:find('awaiting',1,true),'hot invalidation did not restart target preparation')
 assert(s.prepare_calls>prepares and count(r.surfaces)==4)
 s.render();assert(s.draw());for _,carrier in ipairs(s.carriers)do if carrier.target then assert(s.target_refs[carrier.target]==carrier)end end
end)
test('native exceptions reject safely and invalidation preserves bound target on cleanup failure',function()
 for _,kind in ipairs({'throw_tick','throw_carrier'})do
  local s,r=fixture();assert(not s.draw());s.render();s[kind]=true
  local returned,ok,why=pcall(s.draw)
  assert(returned and ok==false and type(why)=='string'and why:find('native',1,true),'native exception escaped candidate: '..kind)
  assert(count(s.target_refs)==0)
 end
 local s,r=fixture();assert(not s.draw());s.render();assert(s.draw());s.reject_carrier_release=true
 local ok=pcall(s.invalidate);assert(not ok and count(s.target_refs)==4,'invalidation discarded bound target after failed detachment')
 for _,surf in ipairs(s.surfaces)do assert(surf.texture,'invalidation destroyed owned target')end
 s.reject_carrier_release=false;s.invalidate();assert(count(s.target_refs)==0)
end)
local failures={}
for _,item in ipairs(tests)do local ok,err=pcall(item[2]);print((ok and 'PASS 'or'FAIL ')..item[1]..(ok and ''or(': '..tostring(err))));if not ok then failures[#failures+1]=item[1]end end
assert(#failures==0,tostring(#failures)..' retained scene contract failures')
