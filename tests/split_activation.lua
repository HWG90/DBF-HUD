-- Run the production MDL entrypoint with bounded lifecycle/config mocks.
-- Activation is acknowledged only after both the HUD reset and native ctx.set succeed.
local previous_stingray,previous_bridge=rawget(_G,'stingray'),rawget(_G,'HUDRenderBridge')
local function copy(t)if type(t)~='table'then return t end;local q={};for k,v in pairs(t)do q[k]=copy(v)end;return q end
local function same(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
_G.stingray={Application={can_get=function()return true end}};_G.HUDRenderBridge=nil
local function session(native_config,saved,failures,persisted)
 failures=failures or {}
 local stats={resets=0,sets=0,retired=0,closed=0,started=0,saves=0,ticks=0,log={},globals={},cleanups={}}
 local backend={read_tuning=function()return copy(saved)end,close=function()stats.closed=stats.closed+1 end,log=function()end}
 local hud={version='fixture',config=copy(saved)}
 hud.config.render_sync_trial=false
 function hud.use_split_defaults()
  stats.resets=stats.resets+1
  if failures.reset=='throw'then error('reset threw')end
  if failures.reset then return false,'reset failed'end
  hud.config.texture_art_variant='split';hud.config.panel_spatial_depth=16;hud.config.decoration='split'
  return true,'baseline saved'
 end
 function hud.save_tuning()stats.saves=stats.saves+1;return true,'saved'end
 function hud.retire()stats.retired=stats.retired+1 end
 function hud.tick(dt)stats.ticks=stats.ticks+1;stats.last_dt=dt end
 HUD={shader_catalog={},memory={native=function()return backend end},runtime={start=function(sr,native,options)
  assert(sr==_G.stingray and native==backend and options.managed and options.disable_segmented_fancy)
  stats.started=stats.started+1;return hud
 end}}
 local ctx={api=2,dir='fixture',config=native_config,settings=persisted or {}}
 function ctx.on_cleanup(callback)stats.cleanups[#stats.cleanups+1]=callback end
 function ctx.global(name,value)stats.globals[name]=value end
 function ctx.log(line)stats.log[#stats.log+1]=line end
 function ctx.set(name,value)
  stats.sets=stats.sets+1
  assert(name=='split_activation_applied'and value==ctx.config.split_activation)
  -- LLL src/live.lua writes settings, rolls back before raising on failure,
  -- and returns nil on success. Project ctx.config remains read-only.
  local previous=ctx.settings[name];ctx.settings[name]=value
  if failures.set then ctx.settings[name]=previous;error('Settings could not be saved: '..failures.set)end
 end
 local mdl=dofile('src/mdl.lua')
 local ok,why=pcall(mdl.on_enable,ctx)
 return {mdl=mdl,ctx=ctx,hud=hud,stats=stats,ok=ok,why=why}
end
local function completed(test)
 local n=0
 for _,line in ipairs(test.stats.log)do if line:find('SPLIT_ACTIVATION applied=',1,true)then n=n+1 end end
 return n
end
local function cleanup(test)
 assert(#test.stats.cleanups==1)
 test.stats.cleanups[1]()
 assert(test.stats.retired==1,'Activation lifecycle did not retire its runtime')
 if test.ok then assert(test.stats.closed==0,'MDL closed a backend whose runtime owns it')
 else assert(test.stats.closed==1,'Failed activation left its native backend open')end
end

local revision='split-study08-v1'
local native={split_activation=revision}
local persisted={}
local first=session(native,{texture_art_variant='faithful',panel_spatial_depth=2,decoration='outline'},nil,persisted)
assert(first.ok,tostring(first.why));assert(first.stats.started==1 and first.stats.resets==1 and first.stats.sets==1)
assert(persisted.split_activation_applied==revision and not native.split_activation_applied and first.hud.config.texture_art_variant=='split'and first.hud.config.panel_spatial_depth==16)
assert(completed(first)==1 and first.stats.globals.DBFHUD==first.hud,'Activation was not published/logged after acknowledgment')
first.mdl.on_update(first.ctx,.125);assert(first.stats.ticks==1 and first.stats.last_dt==.125,'Ordinary MDL updates changed')
cleanup(first)

-- A later normal reload carries the acknowledgment and keeps new user choices.
local choices={texture_art_variant='split',panel_spatial_depth=31,decoration='brackets',render_sync_trial=false,background_color='#102030'}
local reloaded=session(native,choices,nil,persisted)
assert(reloaded.ok and reloaded.stats.resets==0 and reloaded.stats.sets==0 and completed(reloaded)==0)
assert(same(reloaded.hud.config,choices),'Acknowledged reload replaced the user edits')
cleanup(reloaded)

local absent=session({split_activation_applied='earlier-candidate'},choices)
assert(absent.ok and absent.stats.resets==0 and absent.stats.sets==0 and completed(absent)==0)
assert(same(absent.hud.config,choices),'Ordinary MDL enable changed appearance without an activation')
cleanup(absent)

for _,failure in ipairs({'false','throw'})do
 local config={split_activation=revision};local failed=session(config,choices,{reset=failure})
 assert(not failed.ok and failed.stats.resets==1 and failed.stats.sets==0 and not failed.ctx.settings.split_activation_applied)
 assert(completed(failed)==0 and not failed.stats.globals.DBFHUD,'Failed reset claimed a completed activation')
 cleanup(failed)
end
for _,failure in ipairs({'serialization','write'})do
 local config={split_activation=revision};local stored={split_activation_applied='earlier-candidate'};local failed=session(config,choices,{set=failure},stored)
 assert(not failed.ok and failed.stats.resets==1 and failed.stats.sets==1 and stored.split_activation_applied=='earlier-candidate')
 assert(completed(failed)==0 and not failed.stats.globals.DBFHUD,'Failed native acknowledgment claimed success')
 cleanup(failed)
 -- No persisted acknowledgment means the next enable retries the reset.
 local retry=session(config,choices,nil,stored);assert(retry.ok and retry.stats.resets==1 and completed(retry)==1)
 cleanup(retry)
end
_G.stingray=previous_stingray;_G.HUDRenderBridge=previous_bridge
print('PASS Split activation: production MDL applies once, acknowledges/logs only after native config success, preserves later user edits, leaves ordinary enables unchanged, and cleans up/retries reset or acknowledgment failures')
