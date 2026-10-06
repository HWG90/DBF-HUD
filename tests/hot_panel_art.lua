local Core=dofile('src/runtime_textures.lua')
local M=dofile('src/hot_panel_art.lua')
package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
local callbacks,phase,events={},false,{};local fail;local tick=0
local function event(name)assert(phase);events[#events+1]={name,tick};if fail==name then error('injected '..name)end end
HUD={runtime_textures=Core,runtime_texture_native={new=function()return{
 set_phase=function(v)phase=v end,
 create=function(image,r)event('create');r.resource={};r.width=image.width;r.height=image.height end,
 copy=function(image,r)event('copy');r.copied=true;r.source={} end,
 check=function(r)assert(phase and r.resource)end,
 ready=function(r)assert(phase and r.uploaded);r.consumed=true;return true end,
 submit=function(r)event('submit');assert(r.copied);r.uploaded=true end}end}}
HUDRenderBridge={api=1,subscribe=function(id,cb)callbacks[id]=cb;return function()callbacks[id]=nil end end}
local function frame()tick=tick+1;for _,cb in pairs(callbacks)do cb()end;assert(not phase)end
local function finish()for i=1,20 do frame()end end
local root='virtual-hot-art'
local files={};local old_open=io.open
io.open=function(path,mode)
 if mode=='a' then return {write=function()end,close=function()end}end
 if mode=='rb' and files[path] then return {read=function(_,n)return files[path]:sub(1,n)end,close=function()end}end
 return nil
end
local function write(name,bytes)files[root..'/'..name]=bytes end
local name='mechanical_test';local path='mods/dbf_hud/textures/'..name
write('manifest.tsv',name..'\t1\t1\n');write(name..'.rgba','abcd')
local a=M.new({}, {},root);a.reload();assert(#events==0 and not a.resource(path));a.reload();finish()
assert(#events==3 and events[1][2]<events[2][2] and events[2][2]<events[3][2]);local first=a.resource(path);assert(first)
a.reload();finish();assert(#events==3 and a.resource(path)==first,'unchanged reload allocated')
write(name..'.rgba','efgh');a.reload();frame();frame();assert(a.resource(path)==first,'in-flight image exposed');finish()
assert(#events==6 and a.resource(path)~=first);local second=a.resource(path)
write(name..'.rgba','abcd');a.reload();finish();assert(a.resource(path)==first and #events==6,'earlier image allocated again')
write(name..'.rgba','efgh');a.reload();finish();assert(a.resource(path)==second and #events==6)
local stale;for _,cb in pairs(callbacks)do stale=cb end
local b=M.new({}, {},root);stale();assert(a.resource(path)==nil and b.resource(path)==second,'lifecycle ownership')
b.reload();finish();assert(#events==6,'HUD reload duplicated upload')
write(name..'.rgba','ijkl');b.reload();frame();frame();local retained=package.loaded['dbf_hud.hot_panel_art.lifetime.v1'].resources
local count=#retained;b.restore();finish();assert(not b.resource(path) and #retained==count,'cancel resurrected upload')
b.reload();finish();assert(b.resource(path));local good=b.resource(path)
write(name..'.rgba','mnop');fail='copy';b.reload();finish();assert(b.resource(path)==good and b.progress():find('injected copy') and not phase)
fail=nil;write(name..'.rgba','bad');assert(not pcall(b.reload));assert(b.resource(path)==good)
assert(package.loaded['dbf_hud.hot_panel_art.lifetime.v1'].failure,'native stage failure was not quarantined')
package.loaded['dbf_hud.hot_panel_art.lifetime.v1'].failure=nil -- Reset the injected fault for independent cases.
write(name..'.rgba','qrst');b.reload();frame();frame();local n=#events;b.close();finish();assert(#events==n and next(callbacks)==nil,'closed job advanced')
local c=M.new({}, {},root);assert(c.resource(path)==good,'active art did not survive replacement')
write(name..'.rgba','ijkl');write('other.rgba','wxyz');write('manifest.tsv',name..'\t1\t1\nother\t1\t1\n')
fail='copy';c.reload();finish();assert(c.resource(path)==good and not c.resource('mods/dbf_hud/textures/other'),'failed batch published partially')
assert(not pcall(c.reload),'quarantined session retried native work')
package.loaded['dbf_hud.hot_panel_art.lifetime.v1'].failure=nil -- Independent successful batch case.
fail=nil;c.reload();finish();assert(c.resource(path)==good and c.resource('mods/dbf_hud/textures/other'),'successful batch not published')
c.restore();c.close();assert(next(callbacks)==nil)
write('immutable.rgba','ijkl');write('manifest.tsv',name..'\t1\t1\timmutable.rgba\n')
local immutable=M.new({}, {},root);immutable.reload();finish();assert(immutable.resource(path)==good,'versioned manifest not read')
write('manifest.tsv',name..'\t1\t1\t../outside.rgba\n');assert(not pcall(immutable.reload),'manifest traversal accepted');immutable.close()
write('manifest.tsv',name..'\t1\t1\nother\t1\t1\n')
local store=package.loaded['dbf_hud.hot_panel_art.lifetime.v1'];store.bytes=Core.max_retained_bytes
write('other.rgba','zzzz')
local d=M.new({}, {},root);assert(not pcall(d.reload));d.close()
print('PASS separate native frames, repeated reload, lifecycle dedup, atomic publication, restore/cancel, failure rollback, stale callback retirement and budget')

-- Two independently named layers sharing pixels consume one native allocation.
package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
write('manifest.tsv','base\t1\t1\nlayer\t1\t1\n')
write('base.rgba','same');write('layer.rgba','same')
local shared=M.new({}, {},root)
local fresh=package.loaded['dbf_hud.hot_panel_art.lifetime.v1']
fresh.bytes=Core.max_retained_bytes-4
local before=#events;shared.reload();finish()
assert(#events==before+3 and #fresh.resources==1 and fresh.bytes==Core.max_retained_bytes)
assert(shared.resource('mods/dbf_hud/textures/base')==shared.resource('mods/dbf_hud/textures/layer'))
shared.close()
local weak=setmetatable({fresh.resources[1].resource},{__mode='v'})
shared=nil;fresh=nil;collectgarbage('collect');collectgarbage('collect')
assert(weak[1]~=nil,'closed manager lost the process-lifetime resource anchor')
-- Restore at every queued stage must never publish or resume cancelled work.
for stop_at=0,5 do
 package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
 write('manifest.tsv','base\t1\t1\n')
 local manager=M.new({}, {},root);manager.reload()
 for i=1,stop_at do frame()end
 manager.restore();local prior_events=#events;finish()
 assert(#events==prior_events and not manager.resource('mods/dbf_hud/textures/base'))
 manager.close()
end
print('PASS shared layer pixels at exact budget and restore at every pending stage')

-- Neither one elapsed callback nor only one member of a batch is sufficient.
package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
local factory=HUD.runtime_texture_native.new;local allow_ready=false
HUD.runtime_texture_native.new=function(...)
 local adapter=factory(...);local ready=adapter.ready
 adapter.ready=function(r)if not allow_ready then return false end;return ready(r)end
 return adapter
end
write('manifest.tsv','base\t1\t1\n');write('base.rgba','abcd')
local waiting=M.new({}, {},root);waiting.reload();finish()
assert(waiting.stats().pending and waiting.stats().stage=='ready' and not waiting.resource('mods/dbf_hud/textures/base'))
allow_ready=true;finish();assert(waiting.resource('mods/dbf_hud/textures/base'))
allow_ready=false;write('base.rgba','efgh');waiting.reload();finish()
local previous=waiting.resource('mods/dbf_hud/textures/base')
waiting.restore();allow_ready=true;finish()
assert(previous and not waiting.resource('mods/dbf_hud/textures/base'),'canceled waiting batch resurfaced')
waiting.close();HUD.runtime_texture_native.new=factory
print('PASS pending queue acknowledgment and cancel before publication')

-- Exercise reclamation through the actual staged uploader, not just pool unit tests.
package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
HUD.texture_pool=dofile('src/texture_pool.lua')
HUD.runtime_texture_native.new=function(...)
 local n=factory(...)
 n.retirement_token=function(r)assert(phase and r.consumed);return tick end
 n.retirement_done=function(t)assert(phase);return tick>t+1 end
 n.destroy_retired=function(r,t,detached)assert(phase and detached and tick>t+1);return true end
 return n
end
write('manifest.tsv','base\t1\t1\n');write('base.rgba','0000')
local reclaim=M.new({}, {},root);local detaches=0
reclaim.register_consumer('gui',function()detaches=detaches+1;return true end)
reclaim.reload();finish()
for i=1,1000 do
 write('base.rgba',string.format('%04d',i));reclaim.reload();finish()
 assert(reclaim.stats().retained_bytes==4 and reclaim.stats().retained_resources==1 and reclaim.stats().reclamation)
end
reclaim.restore();finish();assert(reclaim.stats().retained_bytes==0)
write('base.rgba','next');reclaim.reload();finish();assert(detaches>=1003,'restore lost material consumer')
for cut=1,7 do
 write('base.rgba',string.format('c%03d',cut));reclaim.reload();for i=1,cut do frame()end
 reclaim.restore();finish();assert(reclaim.stats().retained_bytes==0,'canceled staged candidate leaked at '..cut)
 write('base.rgba','next');reclaim.reload();finish()
end
local backend_closed=false;reclaim.after_close(function()backend_closed=true end)
reclaim.close();assert(not backend_closed);finish()
assert(backend_closed and reclaim.stats().retained_bytes==0 and next(callbacks)==nil)
print('PASS actual uploader 1000 unique swaps, restore/reload, material detach retention and deferred backend closure')
package.loaded['dbf_hud.hot_panel_art.lifetime.v1']=nil
write('manifest.tsv','base\t1\t1\n');write('base.rgba','test');write('RECLAIM-TEST.txt','32')
local old_remove=os.remove;os.remove=function(path)if files[path]then files[path]=nil;return true end return nil end
local trial=M.new({}, {},root);trial.reload();trial.restore();trial.reload()
for i=1,500 do frame()end
assert(trial.stats().validation_cycles==32 and trial.stats().retained_bytes==4 and trial.stats().retained_resources==1 and not trial.stats().pending,'one-shot validation failed to run 32 cycles and return to baseline')
trial.close();finish();os.remove=old_remove
print('PASS startup restore preserves one-shot 32-cycle validation, returns to baseline and closes')
io.open=old_open
