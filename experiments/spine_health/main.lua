local backend,renderer,bar,menu,provider,dirty
local enabled,offset=false,.16
local elapsed,retry,last_status=0,0,nil
local samples,total,worst=0,0,0
local function log(s)mod.log('SPINE '..tostring(s))end
local function clear()if renderer then renderer.clear()end end
local function shutdown()
 if bar then bar.release()else clear()end
 if menu then assert(menu.unregister()~=false,'Spine menu unregister pending')end
 backend,renderer,bar,menu,provider=nil,nil,nil,nil,nil
 return true
end
local function settings()
 if menu then enabled=menu.get('spine_enabled');offset=menu.get('rear_offset')end
 assert(type(enabled)=='boolean' and type(offset)=='number' and offset>=.04 and offset<=.4,'Spine settings invalid')
 if enabled and not backend then
  local sr=assert(rawget(_G,'stingray'),'Spine engine unavailable')
  backend=mod.require('backend.lua').new(sr)
  renderer=mod.require('renderer.lua').new(sr)
 end
 bar.enable(enabled);retry=0;dirty=false
end
local function register()
 local api=rawget(_G,'DBFMCM')
 if api==provider then return end
 if menu then assert(menu.unregister()~=false,'Spine menu unregister pending');menu=nil end
 provider=api
 if api and type(api.register)=='function' then
  menu=assert(api.register({id='dbf_spine_health',name='DBF Experiments',parent_name="Diver's Best Friend",
   description='Unsupported experiments. Optional, self-contained add-on.',pages={{id='experiments',name='Experiments',controls={
   {type='section',label='Unsupported experiments'},
   {type='text',label="I will not support these experiments. These are just little things I'm trying or toying around with. They may break or be removed at any time."},
   {type='section',label='Spine health bar'},
   {id='spine_enabled',type='toggle',label='Spine health bar (unsupported)',default=false,
    description='Off by default. Experimental bone-following health display.',on_change=function()dirty=true end},
   {id='rear_offset',type='slider',label='Distance behind spine (m)',default=.16,min=.04,max=.4,step=.01,
    description='Placement experiment. Capes and backpacks may cover the bar.',on_change=function()dirty=true end},
  }}}}),'Spine menu registration failed')
  dirty=true
 end
end
return {live_lua_api=1,name='DBF Experiments (Unsupported)',author='Goose',
 on_enable=function()
  bar=mod.require('spine_health.lua').new({
   clear=clear,frame=function()return backend.frame()end,
   bones=function(frame)return backend.bones(frame,offset)end,
   valid=function(frame)return backend.valid(frame)end,
   submit=function(frame,geometry)return renderer.submit(frame,geometry)end})
  settings();register();log('candidate.5 ready; unsupported Experiments tab; spine defaults Off; optional standalone add-on')
 end,
 on_update=function(dt)
  if not bar then return end
  register();if dirty then settings()end
  if not enabled then return end
  dt=type(dt)=='number' and math.max(0,math.min(dt,1)) or 0
  elapsed=elapsed+dt
  if elapsed<retry then return end
  local started=samples<600 and backend.clock()
  bar.draw()
  if samples<600 then
   local cost=(backend.clock()-started)*1000
   samples=samples+1;total=total+cost;worst=math.max(worst,cost)
   if samples==1 or samples==120 or samples==600 then
    log(string.format('PERF frames=%d mean_elapsed_ms=%.4f worst_elapsed_ms=%.4f enumerations=%d GUI_created=%d moved=%d ink_updates=%d material=%s',
     samples,total/samples,worst,backend.stats.enumerations,renderer.stats.created,renderer.stats.moved,renderer.stats.updated,renderer.material))
   end
  end
  local status=bar.status
  if status=='hidden' then
   -- No avatar lifecycle subscription in the LLL public API: bounded reacquire.
   -- Visible animation follows each render update; unavailable/FP path is 4 Hz.
   retry=elapsed+.25
  end
  if status~=last_status then log(status);last_status=status end
 end,
 on_disable=shutdown,on_cleanup_poll=shutdown,
}
