-- Generated edge masks use the same staged uploader and fenced texture pool.
-- The native adapter is mocked; publication and reclamation are real modules.
local Core=dofile('src/runtime_textures.lua')
local Manager=dofile('src/hot_panel_art.lua')
local Pool=dofile('src/texture_pool.lua')
local lifetime='dbf_hud.hot_panel_art.lifetime.v1'
package.loaded[lifetime]=nil
local callbacks,phase,tick={},false,0
local ready_allowed,retirement_allowed=true,true
local events={};local factories={};local detaches=0;local serial=0
local function event(name)
 assert(phase,'Native '..name..' ran outside the render callback')
 events[name]=(events[name]or 0)+1
end
HUD={runtime_textures=Core,texture_pool=Pool,runtime_texture_native={new=function()
 return {
  set_phase=function(v)phase=v end,
  create=function(image,r)
   event('create');serial=serial+1
   r.resource={id=serial,pixels=image.rgba};r.width=image.width;r.height=image.height
  end,
  copy=function(image,r)
   event('copy');assert(r.resource and not r.resource.destroyed)
   r.copied=true;r.source={pixels=image.rgba}
  end,
  check=function(r)event('check');assert(r.resource and not r.resource.destroyed)end,
  submit=function(r)event('submit');assert(r.copied);r.uploaded=true end,
  ready=function(r)
   event('ready');assert(r.uploaded and not r.resource.destroyed)
   if not ready_allowed then return false end
   r.consumed=true;return true
  end,
  retirement_token=function(r)
   event('retirement_token');assert(r.consumed and r.ready)
   return tick
  end,
  retirement_done=function(token)
   event('retirement_done');return retirement_allowed and tick>token+3
  end,
  destroy_retired=function(r,token,detached)
   event('destroy');assert(detached and retirement_allowed and tick>token+3)
   for _,active in pairs(package.loaded[lifetime].active)do
    assert(active~=r,'A published resource was destroyed')
   end
   assert(not r.resource.destroyed);r.resource.destroyed=true;return true
  end
 }
end}}
HUDRenderBridge={api=1,subscribe=function(id,cb)
 callbacks[id]=cb;return function()callbacks[id]=nil end
end}
local root='virtual-generated-edge-art'
local files={
 [root..'/manifest.tsv']='base\t1\t1\nlayer\t1\t1\n',
 [root..'/base.rgba']='BASE',[root..'/layer.rgba']='LAYR'
}
local old_open=io.open
io.open=function(path,mode)
 if mode=='a'then return {write=function()end,close=function()end}end
 if mode=='rb'and files[path]then
  return {read=function(_,n)return files[path]:sub(1,n)end,close=function()end}
 end
 return nil
end
local function frame()
 tick=tick+1
 for _,cb in pairs(callbacks)do cb()end
 assert(not phase,'Render phase leaked from a callback')
end
local function frames(n)for i=1,n do frame()end end
local function settle(manager)
 for i=1,240 do
  frame();local s=manager.stats()
  if not s.pending and(s.retiring or 0)==0 then return end
 end
 error('Generated texture lifecycle did not settle: '..manager.progress())
end
local function request(manager,signature,pixels)
 assert(#pixels==4)
 return manager.request_generated(signature,function()
  factories[signature]=(factories[signature]or 0)+1
  return {format='RGBA8',width=1,height=1,row_pitch=4,rgba=pixels}
 end)
end
local base_path='mods/dbf_hud/textures/base'
local layer_path='mods/dbf_hud/textures/layer'
local mask_path='mods/dbf_hud/textures/primary_edge_mask_dynamic_v2'
local manager=Manager.new({}, {},root)
manager.register_consumer('existing-hud-materials',function()detaches=detaches+1;return true end)
manager.reload();settle(manager)
local base,layer=manager.resource(base_path),manager.resource(layer_path)
assert(base and layer and base~=layer and manager.stats().retained_bytes==8)

-- No pixel generation or allocation while the user continues editing sliders.
local creates=events.create
request(manager,'rapid-a','A001');frames(5)
request(manager,'rapid-b','B001');frames(5)
request(manager,'rapid-c','C001');frames(11)
assert(manager.stats().pending and not manager.resource(mask_path))
assert(not factories['rapid-a']and not factories['rapid-b']and not factories['rapid-c'])
assert(events.create==creates,'Debounce allocated an intermediate mask')
settle(manager)
local first=manager.resource(mask_path)
assert(first and first.pixels=='C001'and factories['rapid-c']==1)
assert(not factories['rapid-a']and not factories['rapid-b'])
assert(manager.stats().generated_signature=='rapid-c')
assert(manager.resource(base_path)==base and manager.resource(layer_path)==layer)
assert(manager.stats().retained_bytes==12 and manager.stats().retained_resources==3)

-- Repeated compositor requests for an unchanged key must remain free of work.
local before={};for k,v in pairs(events)do before[k]=v end
for i=1,100 do request(manager,'rapid-c','C001');frame()end
assert(factories['rapid-c']==1 and not manager.stats().pending)
for k,v in pairs(events)do assert(v==(before[k]or 0),'Stable key performed native '..k)end

-- In-flight work finishes; only the newest queued selection follows it.
ready_allowed=false;request(manager,'flight-d','D001')
for i=1,80 do if manager.stats().stage=='ready'then break end;frame()end
assert(manager.stats().stage=='ready'and manager.resource(mask_path)==first)
request(manager,'flight-e','E001');frames(4)
request(manager,'flight-f','F001');frames(24)
assert(manager.resource(mask_path)==first,'Unacknowledged texture became visible')
assert(manager.stats().generated_signature=='rapid-c','Signature changed before publication')
assert(factories['flight-d']==1 and not factories['flight-e']and not factories['flight-f'])
ready_allowed=true;frame();frame()
local completed=manager.resource(mask_path)
assert(completed and completed.pixels=='D001','Finishing upload was canceled by a later edit')
assert(manager.stats().generated_signature=='flight-d')
settle(manager)
assert(manager.resource(mask_path).pixels=='F001'and factories['flight-f']==1 and not factories['flight-e'])
assert(manager.resource(base_path)==base and manager.resource(layer_path)==layer)

-- Normal file reload changes its files while retaining the generated overlay.
local generated=manager.resource(mask_path)
files[root..'/base.rgba']='BAS2';manager.reload();settle(manager)
assert(manager.resource(base_path)~=base and manager.resource(layer_path)==layer)
assert(manager.resource(mask_path)==generated and manager.stats().generated_signature=='flight-f')
assert(manager.stats().retained_bytes==12)

-- Publication detaches owners, but old pixels live until the fence completes.
retirement_allowed=false;local destroyed=events.destroy or 0
request(manager,'held-fence','G001')
for i=1,100 do frame();if not manager.stats().pending then break end end
assert(manager.resource(mask_path).pixels=='G001'and not generated.destroyed)
assert(manager.stats().retained_bytes==16 and manager.stats().retiring==1)
frames(12);assert((events.destroy or 0)==destroyed and not generated.destroyed)
retirement_allowed=true;settle(manager)
assert(generated.destroyed and manager.stats().retained_bytes==12)

-- Unique slider combinations must not build an ever-growing pixel cache.
for i=1,100 do
 local signature='bounded-'..i;request(manager,signature,string.format('%04d',i));settle(manager)
 local s=manager.stats()
 assert(s.generated_signature==signature and s.retained_bytes==12 and s.retained_resources==3 and s.reclamation)
 assert(manager.resource(layer_path)==layer,'Mask replacement retired unrelated artwork')
 assert(factories[signature]==1)
end
assert(detaches>=105,'Generated publication bypassed material-owner detachment')

-- Restore and close erase lazy pending requests, including their key.
request(manager,'restore-pending','R001');frames(3);manager.restore();settle(manager);frames(30)
assert(not factories['restore-pending']and not manager.resource(mask_path))
assert(not manager.stats().pending and manager.stats().generated_signature==nil and manager.stats().retained_bytes==0)
manager.reload();settle(manager)
request(manager,'close-pending','X001');frames(3)
local backend_closed=false;manager.after_close(function()backend_closed=true end)
manager.close();settle(manager);frames(30)
assert(backend_closed and next(callbacks)==nil and not factories['close-pending'])
assert(not manager.resource(mask_path)and manager.stats().generated_signature==nil and manager.stats().retained_bytes==0)
io.open=old_open;package.loaded[lifetime]=nil
print('PASS generated masks: debounce/coalescing, acknowledgment, stable keys, artwork preservation, fenced retirement, 100 bounded swaps, restore and close')
