-- Generated Split image groups use the established staged uploader and pool.
-- Exercise real publication/reclamation with only the native adapter mocked.
local Core=dofile('src/runtime_textures.lua')
local Manager=dofile('src/hot_panel_art.lua')
local Pool=dofile('src/texture_pool.lua')
local lifetime='dbf_hud.hot_panel_art.lifetime.v1'
package.loaded[lifetime]=nil
local callbacks,phase,tick={},false,0
local blocked_pixels,retirement_allowed=nil,true
local events,factories={},{};local serial,detaches=0,0
local function event(name)
 assert(phase,'Native '..name..' ran outside the render callback')
 events[name]=(events[name]or 0)+1
end
HUD={runtime_textures=Core,texture_pool=Pool,runtime_texture_native={new=function()
 return {
  set_phase=function(v)phase=v end,
  create=function(image,r)
   event('create');serial=serial+1;r.resource={id=serial,pixels=image.rgba}
   r.width=image.width;r.height=image.height
  end,
  copy=function(image,r)event('copy');assert(r.resource and not r.resource.destroyed);r.copied=true;r.source={pixels=image.rgba}end,
  check=function(r)event('check');assert(r.resource and not r.resource.destroyed)end,
  submit=function(r)event('submit');assert(r.copied);r.uploaded=true end,
  ready=function(r)
   event('ready');assert(r.uploaded and not r.resource.destroyed)
   if r.rgba==blocked_pixels then return false end
   r.consumed=true;return true
  end,
  retirement_token=function(r)event('retirement_token');assert(r.consumed and r.ready);return tick end,
  retirement_done=function(token)event('retirement_done');return retirement_allowed and tick>token+3 end,
  destroy_retired=function(r,token,detached)
   event('destroy');assert(detached and retirement_allowed and tick>token+3)
   for _,active in pairs(package.loaded[lifetime].active)do assert(active~=r,'Published image was destroyed')end
   assert(not r.resource.destroyed);r.resource.destroyed=true;return true
  end
 }
end}}
HUDRenderBridge={api=1,subscribe=function(id,cb)callbacks[id]=cb;return function()callbacks[id]=nil end end}
local root='virtual-generated-image-batch';local files={};local manifest={}
for i=1,70 do
 local name=i==1 and 'atlas'or string.format('static_%02d',i)
 manifest[#manifest+1]=name..'\t1\t1'
 files[root..'/'..name..'.rgba']=string.format('S%03d',i)
end
files[root..'/manifest.tsv']=table.concat(manifest,'\n')..'\n'
local old_open=io.open
io.open=function(path,mode)
 if mode=='a'then return {write=function()end,close=function()end}end
 if mode=='rb'and files[path]then return {read=function(_,n)return files[path]:sub(1,n)end,close=function()end}end
 return nil
end
local function frame()
 tick=tick+1;for _,cb in pairs(callbacks)do cb()end;assert(not phase,'Render phase leaked')
end
local function frames(n)for i=1,n do frame()end end
local function settle(manager)
 for i=1,1024 do frame();local s=manager.stats();if not s.pending and s.retiring==0 then return end end
 error('Image group did not settle: '..manager.progress())
end
local function count(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
local function image(pixels)return {format='RGBA8',width=1,height=1,row_pitch=4,rgba=pixels}end
local prefix='mods/dbf_hud/textures/'
local names={'split_hud_dynamic_coverage_v1','split_hud_dynamic_face_v1','split_hud_dynamic_soft_v1'}
local function request(manager,signature,stem)
 return manager.request_generated(signature,function()
  factories[signature]=(factories[signature]or 0)+1
  local images={};for i,name in ipairs(names)do images[name]=image(stem..i)end
  return {images=images}
 end)
end
local manager=Manager.new({}, {},root)
manager.register_consumer('existing-hud-materials',function()detaches=detaches+1;return true end)
manager.reload();settle(manager)
local store=package.loaded[lifetime];local atlas=manager.resource(prefix..'atlas')
assert(atlas and store.bytes==280 and #store.resources==70)
local active_static={};for name,r in pairs(store.active)do active_static[name]=r.resource end

-- Active pixels are available by strict resource name, without exposing owners.
local original=manager.image(prefix..'atlas')
assert(original.format=='RGBA8'and original.width==1 and original.height==1 and original.row_pitch==4 and original.rgba=='S001')
original.width=999;original.rgba='oops'
assert(manager.image(prefix..'atlas').width==1 and manager.image(prefix..'atlas').rgba=='S001')
assert(not manager.image('atlas')and not manager.image(prefix..'../atlas')and not manager.image(prefix..'missing'))

-- A last member waiting for transfer acknowledgment holds the entire group.
blocked_pixels='A003';assert(request(manager,'group-a','A00'))
for i=1,100 do frame();if store.resources[#store.resources].rgba=='A003'and manager.stats().stage=='ready'then break end end
assert(manager.stats().stage=='ready'and not manager.resource(prefix..names[1]))
assert(not manager.image(prefix..names[2])and not next(store.generated_names))
assert(manager.stats().generated_signature==nil and manager.stats().active_images==70)
blocked_pixels=nil;settle(manager)
local first={};for i,name in ipairs(names)do first[i]=manager.resource(prefix..name);assert(first[i].pixels=='A00'..i)end
assert(count(store.generated_names)==3 and manager.stats().generated_signature=='group-a')
assert(store.bytes==292 and #store.resources==73)
for name,resource in pairs(active_static)do assert(manager.resource(prefix..name)==resource,'Generated group replaced static artwork')end

-- Stable signatures are free; editing coalesces before generating any pixels.
local creates=events.create
for i=1,100 do assert(not request(manager,'group-a','A00'));frame()end
assert(factories['group-a']==1 and events.create==creates and not manager.stats().pending)
request(manager,'discarded-b','B00');frames(5);request(manager,'discarded-c','C00');frames(5)
blocked_pixels='D003';request(manager,'group-d','D00');frames(11)
assert(not factories['discarded-b']and not factories['discarded-c']and not factories['group-d'])
for i=1,100 do frame();if store.resources[#store.resources].rgba=='D003'and manager.stats().stage=='ready'then break end end
for i,name in ipairs(names)do assert(manager.resource(prefix..name)==first[i])end
assert(manager.stats().generated_signature=='group-a'and count(store.generated_names)==3)

-- Later selections leave the in-flight atomic upload intact and coalesce.
request(manager,'discarded-e','E00');frames(4);request(manager,'group-f','F00');frames(16)
assert(not factories['discarded-e']and not factories['group-f'])
blocked_pixels=nil;frame();frame()
for i,name in ipairs(names)do assert(manager.resource(prefix..name).pixels=='D00'..i)end
assert(manager.stats().generated_signature=='group-d')
settle(manager)
for i,name in ipairs(names)do assert(manager.resource(prefix..name).pixels=='F00'..i)end
assert(not factories['discarded-e']and factories['group-f']==1 and store.bytes==292)

-- File reload preserves all generated members alongside every manifest image.
local group={};for i,name in ipairs(names)do group[i]=manager.resource(prefix..name)end
files[root..'/static_02.rgba']='NEW2';manager.reload();settle(manager)
for i,name in ipairs(names)do assert(manager.resource(prefix..name)==group[i])end
assert(manager.resource(prefix..'atlas')==atlas and not atlas.destroyed)
assert(count(store.generated_names)==3 and manager.stats().generated_signature=='group-f'and store.bytes==292)

-- Old image owners and pixels remain alive until the existing fence permits it.
retirement_allowed=false;request(manager,'held-fence','G00')
for i=1,120 do frame();if not manager.stats().pending then break end end
assert(manager.stats().retiring==3 and store.bytes==304)
for i,resource in ipairs(group)do assert(not resource.destroyed)end
frames(12);for i,resource in ipairs(group)do assert(not resource.destroyed)end
retirement_allowed=true;settle(manager)
for i,resource in ipairs(group)do assert(resource.destroyed)end
assert(store.bytes==292 and #store.resources==73 and not atlas.destroyed)

-- 100 distinct groups reclaim all previous members and keep all 70 statics.
for i=1,100 do
 local stem=string.format('%03d',i);request(manager,'bounded-'..i,stem);settle(manager)
 assert(store.bytes==292 and #store.resources==73 and manager.stats().active_images==73)
 assert(manager.resource(prefix..'atlas')==atlas and not atlas.destroyed)
 for index,name in ipairs(names)do assert(manager.image(prefix..name).rgba==stem..index)end
end
assert(detaches>=105)

-- The original single-mask request remains supported and removes the old group.
manager.request_generated('legacy-mask',function()return image('MASK')end);settle(manager)
assert(manager.resource(prefix..'primary_edge_mask_dynamic_v2').pixels=='MASK')
for _,name in ipairs(names)do assert(not manager.resource(prefix..name)and not store.generated_names[name])end
assert(count(store.generated_names)==1 and store.bytes==284 and #store.resources==71)
request(manager,'return-to-split','H00');settle(manager)
assert(not manager.resource(prefix..'primary_edge_mask_dynamic_v2')and count(store.generated_names)==3)
manager.reload();settle(manager)
for _,name in ipairs(names)do assert(manager.resource(prefix..name))end
assert(store.bytes==292 and manager.resource(prefix..'atlas')==atlas)

-- Restore and close clear pending generation without resuming it later.
request(manager,'restore-pending','R00');frames(3);manager.restore();settle(manager);frames(20)
assert(not factories['restore-pending']and not next(store.generated_names)and store.bytes==0)
assert(manager.stats().generated_signature==nil and not manager.image(prefix..'atlas'))
manager.reload();settle(manager);request(manager,'close-pending','X00');frames(3)
local closed=false;manager.after_close(function()closed=true end);manager.close();settle(manager)
assert(closed and next(callbacks)==nil and not factories['close-pending']and store.bytes==0 and not next(store.generated_names))
assert(not manager.image(prefix..'atlas')and manager.stats().generated_signature==nil)

-- Reject names before retaining or exposing any part of a generated group.
package.loaded[lifetime]=nil
local invalid=Manager.new({}, {},root);invalid.reload();settle(invalid)
local before=invalid.stats().retained_resources
invalid.request_generated('bad-name',function()return {images={untrusted_texture=image('BAD1')}}end)
frames(12)
assert(invalid.stats().failed and invalid.stats().retained_resources==before and invalid.stats().active_images==70)
assert(not invalid.resource(prefix..'untrusted_texture')and invalid.progress():find('not allowed'))
invalid.close();io.open=old_open;package.loaded[lifetime]=nil
print('PASS generated image groups: atomic three-image acknowledgment, immutable active pixel access, 70 static images preserved, debounce/coalescing, reload retention, fenced retirement, 100 bounded swaps, legacy mask, restore/close and name validation')
