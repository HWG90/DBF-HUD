-- File-backed artwork: one native stage per render callback, atomic publication.
local M={}
function M.new(sr,backend,root)
 local key='dbf_hud.hot_panel_art.lifetime.v1'
 local store=package.loaded[key] or {bytes=0,resources={}}
 package.loaded[key]=store;store.images=store.images or {};store.active=store.active or {}
 store.cache=store.cache or {};store.orphans=store.orphans or {}
 local function cache(record)
  if not(record and record.ready and record.uploaded and record.consumed and record.source and type(record.rgba)=='string')then return end
  local size=record.width..'x'..record.height
  store.cache[size]=store.cache[size]or {};store.cache[size][record.rgba]=record
 end
 -- Published records from the earlier staged implementation are ready too.
 for _,record in pairs(store.images)do if record.uploaded then record.ready=true;cache(record)end end
 local function cached(image)
  local bucket=store.cache[image.width..'x'..image.height]
  local record=bucket and bucket[image.rgba]
  return record and record.source and record.consumed and record
 end
 -- Retire callbacks from an older HUD before installing a replacement owner.
 if store.owner then store.owner.close()end
 local self={status='Packaged artwork',closing=false}
 local validation_remaining,validation_cycle,validation_baseline,validation_image
 local registered={}
 local native,off,busy,job,pool,restore_requested,after_close;local frame=0;local serial=store.serial or 0
 local function trace(v)
  local line='HOT_ART_STAGE staged_v3 job='..serial..' frame='..frame..' '..v
  local f=io.open(root..'/upload-stages.log','a')
  if f then f:write(os.date('%Y-%m-%d %H:%M:%S')..' '..line..'\n');f:close()end
  if backend.log then pcall(backend.log,line)end
 end
 local function cancel(reason)
  if validation_cycle and validation_cycle>0 then validation_remaining=nil end
  if pool and job then
   local function abandoned(r)
    if not r or r.orphaned or r.retiring then return end
    if not r.resource then
     if not store.failure and job.stage=='create' then
      store.bytes=store.bytes-r.bytes
      for i=#store.resources,1,-1 do if store.resources[i]==r then table.remove(store.resources,i)end end
      r.rgba=nil;r.orphaned=true
     end
     return
    end
    for _,active in pairs(store.active)do if active==r then return end end
    r.orphaned=true;store.orphans[#store.orphans+1]=r
   end
   abandoned(job.record);for _,r in pairs(job.prepared)do abandoned(r)end
  end
  job=nil;self.status=reason
 end
 local function step()
  if store.owner~=self then if off then local stop=off;off=nil;stop()end;if after_close then local done=after_close;after_close=nil;done()end;return end
  if busy or (not job and not restore_requested and validation_remaining==nil and not (pool and (#store.retirements>0 or #store.orphans>0))) then return end
  busy=true;frame=frame+1;native.set_phase(true)
  local ok,err=pcall(function()
   if pool then
    if store.failure then error(store.failure)end
    local orphan=store.orphans[1]
    if orphan then
     local image={format='RGBA8',width=orphan.width,height=orphan.height,row_pitch=orphan.width*4,rgba=orphan.rgba}
     if not orphan.copied then native.copy(image,orphan)
     elseif not orphan.uploaded then native.submit(orphan)
     elseif native.ready(orphan)==true then orphan.ready=true;pool.discard(orphan);table.remove(store.orphans,1)end
    end
    local before=store.bytes;pool.step()
    if store.bytes<before then trace('reclaimed bytes='..(before-store.bytes)..' retained='..store.bytes..' resources='..#store.resources)end
    if store.failure then error(store.failure)end
    if restore_requested then pool.publish({});restore_requested=nil;pool.step()end
    if self.closing and #store.retirements==0 and #store.orphans==0 then store.consumers={};store.owner=nil;if off then local stop=off;off=nil;stop()end;if after_close then local done=after_close;after_close=nil;done()end;return end
   end
   if not job and validation_remaining~=nil and #store.retirements==0 and #store.orphans==0 then
    local prepared={};for name,r in pairs(store.active)do if name~='__reclaim_validation' then prepared[name]=r end end
    if validation_remaining>0 then
     validation_cycle=validation_cycle+1;validation_remaining=validation_remaining-1
     if not validation_image then
      for _,r in pairs(prepared)do if not validation_image or #r.rgba>#validation_image.rgba then
       validation_image={format='RGBA8',width=r.width,height=r.height,row_pitch=r.width*4,rgba=r.rgba}
      end end
     end
     local image=assert(validation_image,'validation needs active artwork')
     job={items={{name='__reclaim_validation',image=image}},index=1,stage='select',prepared=prepared}
     trace('validation cycle='..validation_cycle..' image_bytes='..#image.rgba..' retained='..store.bytes..' resources='..#store.resources)
    else
     validation_remaining=nil;validation_image=nil;job={items={},index=1,stage='publish',prepared=prepared}
     trace('validation final cleanup baseline='..tostring(validation_baseline))
    end
   end
   if not job then return end
   local j=job;local item=j.items[j.index]
   if j.stage=='select' then
    local record=item.name~='__reclaim_validation' and cached(item.image) or nil
    -- Only fully submitted records are reusable. Never reuse a failed attempt.
    if not(record and record.uploaded and record.width==item.image.width and record.height==item.image.height and record.rgba==item.image.rgba)then record=nil end
    if record then j.record=record;j.stage='validate';trace('reuse '..item.name)
    else
     local size=HUD.runtime_textures.validate(item.image)
     assert(store.bytes+size<=HUD.runtime_textures.max_retained_bytes,'Hot artwork budget exhausted; restart required')
     record={bytes=size,rgba=item.image.rgba,width=item.image.width,height=item.image.height}
     store.bytes=store.bytes+size;store.resources[#store.resources+1]=record
     j.record=record;j.stage='create';trace('retained '..item.name)
    end
   elseif j.stage=='validate' then
    native.check(j.record);trace('retained resource verified '..item.name);j.stage='ready'
   elseif j.stage=='create' then
    trace('create begin '..item.name);native.create(item.image,j.record);trace('create returned '..item.name);j.stage='copy'
   elseif j.stage=='copy' then
    trace('copy/readback begin '..item.name);native.copy(item.image,j.record);trace('copy/readback matched '..item.name);j.stage='submit'
   elseif j.stage=='submit' then
    trace('submit begin '..item.name);native.submit(j.record);trace('submit returned '..item.name);j.stage='ready'
   elseif j.stage=='ready' then
    if native.ready(j.record)~=true then return end
    -- Queue consumption is acknowledged; the whole batch publishes together.
    j.record.ready=true;cache(j.record)
    j.prepared[item.name]=j.record;j.index=j.index+1
    if j.index>#j.items then j.stage='publish' else j.stage='select' end
   elseif j.stage=='publish' then
    if pool then pool.publish(j.prepared) else store.active=j.prepared end
    for name,record in pairs(j.prepared)do store.images[name]=record;cache(record)end
    job=nil;self.status='Texture files loaded ('..#j.items..')'
    trace('published '..#j.items..' artwork files')
   end
  end)
  native.set_phase(false);busy=false
  if not ok then
   -- Native work may have partially queued despite a Lua error. Quarantine the
   -- session rather than repeatedly attempting another allocation/submission.
   store.failure=tostring(err)
   cancel('Texture reload failed; restart required: '..store.failure);trace(self.status)
   if pool and off then local stop=off;off=nil;stop()end
  end
 end
 local function initialize()
  if native then return end
  local bridge=assert(rawget(_G,'HUDRenderBridge'),'render bridge unavailable')
  assert(bridge.api==1,'verified render bridge required')
  native=HUD.runtime_texture_native.new(sr,backend)
  if HUD.texture_pool and native.destroy_retired and native.retirement_token then pool=HUD.texture_pool.new(native,store) end
  local test=io.open(root..'/RECLAIM-TEST.txt','rb')
  if pool and test then
   local count=tonumber(test:read(16));test:close()
   assert(count and count%1==0 and count>=1 and count<=64,'invalid one-shot reclaim validation')
   assert(os.remove(root..'/RECLAIM-TEST.txt'),'cannot consume validation request')
   validation_remaining=count;validation_cycle=0;validation_baseline=store.bytes
  elseif test then test:close()end
  off=bridge.subscribe('dbf_hud.hot_panel_art.staged.'..tostring(self),step)
 end
 function self.reload()
  local quarantine=io.open(root..'/UPLOADS-QUARANTINED.txt','rb')
  if quarantine then
   local reason=quarantine:read(4096);quarantine:close()
   error('Texture uploads quarantined: '..tostring(reason),0)
  end
  assert(not self.closing and store.owner==self,'Artwork manager retired')
  assert(not store.failure,'Texture uploads blocked after a stage failure; restart required: '..tostring(store.failure))
  if job then return 'Reload already running; wait for completion before reloading another edit' end
  local f=assert(io.open(root..'/manifest.tsv','rb'),'Hot artwork manifest missing')
  local text=f:read(65537);f:close();assert(#text<=65536,'Manifest too large')
  local items,names,total,unique={}, {},0,{}
  for line in text:gmatch('[^\r\n]+')do
   if line:sub(1,1)~='#'then
    local name,w,h,file=line:match('^([%w_%-]+)\t(%d+)\t(%d+)\t([%w_%-]+%.rgba)$')
    if not name then name,w,h=line:match('^([%w_%-]+)\t(%d+)\t(%d+)$')end
    assert(name,'Invalid artwork manifest row')
    assert(not names[name],'Duplicate artwork');names[name]=true;assert(#items<512,'Too many artwork entries')
    local image=HUD.runtime_textures.read_image(root..'/'..(file or name..'.rgba'),tonumber(w),tonumber(h))
    local prior=cached(image)
    local size=image.width..'x'..image.height
    unique[size]=unique[size]or {}
    if not unique[size][image.rgba] and not(prior and prior.uploaded and prior.width==image.width and prior.height==image.height and prior.rgba==image.rgba)then
     total=total+#image.rgba
     assert(store.bytes+total<=HUD.runtime_textures.max_retained_bytes,'Hot artwork budget exhausted; restart required')
    end
    unique[size][image.rgba]=true
    items[#items+1]={name=name,image=image}
   end
  end
  assert(#items>0,'Manifest has no artwork')
  assert(store.bytes+total<=HUD.runtime_textures.max_retained_bytes,'Hot artwork budget exhausted; restart required')
  initialize();serial=serial+1;store.serial=serial
  job={items=items,index=1,stage='select',prepared={}}
  self.status='Loading '..#items..' texture files';trace('queued '..#items..' files')
  return self.status
 end
 function self.register_consumer(id,detach)
  store.consumers=store.consumers or {}
  assert(not store.consumers[id] and type(detach)=='function','unique artwork material owner required')
  store.consumers[id]=detach;registered[id]=true
 end
 function self.resource(texture)
  if self.closing or store.owner~=self then return nil end
  local name=texture and texture:match('^mods/dbf_hud/textures/([%w_%-]+)$')
  return name and store.active[name] and store.active[name].resource
 end
 function self.restore()
  assert(not self.closing and store.owner==self,'Artwork manager retired')
  cancel('Packaged artwork restored');if pool then restore_requested=true else store.active={} end;trace('restored packaged artwork');return self.status
 end
 function self.after_close(fn)assert(type(fn)=='function');after_close=fn end
 function self.close()
  if self.closing then return end
  self.closing=true;validation_remaining=nil;cancel('Artwork manager retired')
  -- This owner cannot draw again. Detach its GUI owners before forgetting them.
  for id in pairs(registered)do local detach=store.consumers and store.consumers[id];if detach then assert(detach()==true,'retired material owner did not detach');store.consumers[id]=nil end end
  if pool then restore_requested=true
  else if off then local stop=off;off=nil;stop()end;if store.owner==self then store.owner=nil end;if after_close then local done=after_close;after_close=nil;done()end end
  -- No Material handles or input hooks are held here. Persistent resources and
  -- pixels remain retained even when interrupted after factory/submission.
 end
 store.owner=self
 if (store.retirements and #store.retirements>0) or #store.orphans>0 then initialize()end
 function self.progress()return self.status end
 function self.stats()
  local count=0;for _ in pairs(store.active)do count=count+1 end
  return {retained_bytes=store.bytes,retained_resources=#store.resources,active_images=count,
   pending=job~=nil,stage=job and job.stage or 'idle',failed=store.failure~=nil,job=serial,retiring=store.retirements and #store.retirements or 0,reclamation=pool~=nil,validation_cycles=validation_cycle or 0}
 end
 return self
end
return M
