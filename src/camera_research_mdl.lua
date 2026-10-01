local backend,reader,file,next_poll= nil,nil,nil,0
local ammo_watch,last_ammo
local function cleanup() if file then file:close();file=nil end;backend=nil;reader=nil end
return {
 name='DBF-HUD Camera Research',version='0.1',author='DBF-HUD',
 description='Read-only, on-request camera state snapshots. No HUD or camera changes.',
 on_enable=function(ctx)
  ctx.on_cleanup(cleanup);backend=HUD.memory.native();reader=HUD.reader.new(backend)
  file=assert(io.open(backend.camera_log_path(),'a'))
  file:write('CAMERA_RESEARCH enabled\n');file:flush()
 end,
 on_update=function(ctx,dt)
  if ammo_watch then
   ammo_watch=ammo_watch-(dt or 0)
   local raw=reader.poll()
   if raw and raw.binding and raw.binding.ammo_state then
    local b=raw.binding
    local function hex(s)return s:gsub('.',function(ch)return string.format('%02X',ch:byte())end)end
    local state=string.format('AMMO_WATCH weapon=%s id=%d kind=%s count=%d capacity=%s chamber=%s flags=%X state=%s runtime=%s',
     raw.resource_hex,raw.id,raw.kind,raw.rounds or -1,tostring(raw.capacity),tostring(raw.chamber_rounds),b.driver_flags,hex(b.ammo_state),hex(b.ammo_runtime))
    if state~=last_ammo then file:write(string.format('%.3f %s\n',os.clock(),state));file:flush();last_ammo=state end
   end
   if ammo_watch<=0 then ammo_watch=nil;file:write('AMMO_WATCH complete\n');file:flush() end
  end
  next_poll=next_poll-(dt or 0);if next_poll>0 then return end;next_poll=1
  local hud=rawget(_G,'DBFHUD');if not hud or not hud.config or not hud.config.debug_logging then return end
  local label=backend.camera_request();if not label then return end
  if label:match('^ammo_driver_') then
   local ok,err=pcall(function()
    local raw=assert(reader.poll(),reader.status);local r=HUD.memory.new(backend)
    local record=r.read(raw.binding.record,24)
    -- Native getter at RVA 0x754980 resolves this manager's map at +0x30.
    local manager=r.p(raw.binding.module_base+0x3326ce0)
    local index=assert(r.map(manager+0x30,raw.id,4096));assert(index<4096)
    local count=r.u(r.read(manager+0x20,4),0)
    assert(count<=4096 and index<count,'control runtime bounds')
    assert(r.read(r.p(r.p(manager+0x48)+index*8),24)==record,'control runtime owner mismatch')
    local data=r.read(r.p(manager+0x58)+index*0x3f0,0x3f0)
    -- Getter at RVA 0x756730 reads the selected controls from a separate array.
    local controls=r.read(r.p(manager+0x60)+index*12,12)
    assert(r.read(raw.binding.record,24)==record,'weapon identity changed')
    local hex=data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
    file:write(string.format('AMMO_DRIVER weapon=%s id=%d state=%s\n',raw.resource_hex,raw.id,hex))
    file:write('AMMO_CONTROLS '..controls:gsub('.',function(ch)return string.format('%02X',ch:byte())end)..'\n')
    file:write('AMMO_FIRE_MODE '..tostring(raw.fire_mode)..'\n')
    file:write(string.format('AMMO_PRESENTATION kind=%s count=%s capacity=%s reserve=%s reserve_kind=%s label=%s resource=%s alternate=%s\n',tostring(raw.kind),tostring(raw.rounds),tostring(raw.capacity),tostring(raw.reserve),tostring(raw.reserve_kind),tostring(raw.label),tostring(raw.ammo_resource_hex),tostring(raw.alternate_fire)))
    local auxiliary=r.p(raw.binding.module_base+0x3326a38)
    local auxiliary_index=r.map(auxiliary+0x278,raw.id,4096)
    if auxiliary_index and auxiliary_index<4096 then
        local state=r.read(r.p(auxiliary+0x2a0)+auxiliary_index*128,128)
        file:write('AMMO_AUXILIARY '..state:gsub('.',function(ch)return string.format('%02X',ch:byte())end)..'\n')
    end
   end)
   file:write('CAMERA_CAPTURE '..(ok and 'complete' or 'failure')..' label='..label..(ok and '' or ' '..tostring(err))..'\n');file:flush();return
  end
  local ammo_page=label:match('^ammo_code_page_(%d+)$') or label:match('^ammo_alias_page_(%d+)$')
  if ammo_page then
   local ok,err=pcall(function()
    reader.validate();local r=HUD.memory.new(backend);local base=assert(backend.module('game.dll'))
    local page=tonumber(ammo_page);assert(page>=0 and page<96)
    for chunk=0,47 do
     local offset=0x700000+page*49152+chunk*1024
     local data=r.read(base+offset,1024);local match=false
     for at=0,1020 do
      local displacement=r.u(data,at)
      if displacement>=0x80000000 then displacement=displacement-0x100000000 end
      local target=offset+at+4+displacement
      if target==0x3326B28 or target==0x3326B98 or
       (label:match('^ammo_alias_page_') and (target==0x3326640 or target==0x3326698 or target==0x3326730 or
        target==0x3326940 or target==0x3326A68 or target==0x3326AC0 or target==0x3326BE8)) then match=true;break end
     end
     if match then
      local hex=data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
      file:write(string.format('AMMO_CODE_MATCH rva=%X hex=%s\n',offset,hex))
     end
    end
   end)
   file:write('CAMERA_CAPTURE '..(ok and 'complete' or 'failure')..' label='..label..(ok and '' or ' '..tostring(err))..'\n');file:flush();return
  end
  if label:match('^ammo_component_') or label:match('^ammo_projectile_') then
   local ok,err=pcall(function()
    local raw=assert(reader.poll(),reader.status);local r=HUD.memory.new(backend)
    local record=r.read(raw.binding.record,24)
    local projectile=label:match('^ammo_projectile_')~=nil
    local manager=r.p(raw.binding.module_base+(projectile and 0x3326B28 or 0x3326DC0))
    local index=assert(r.map(manager+(projectile and 0x28 or 0x20),raw.id,4096))
    assert(index<4096)
    assert(r.read(r.p(r.p(manager+(projectile and 0x40 or 0x38))+index*8),24)==record,'component owner mismatch')
    local stride=projectile and 32 or 48
    local data=r.read(r.p(manager+(projectile and 0x50 or 0x40))+index*stride,stride)
    assert(r.read(raw.binding.record,24)==record,'weapon identity changed')
    local hex=data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
    file:write(string.format('AMMO_COMPONENT weapon=%s id=%d state=%s\n',raw.resource_hex,raw.id,hex))
   end)
   file:write('CAMERA_CAPTURE '..(ok and 'complete' or 'failure')..' label='..label..(ok and '' or ' '..tostring(err))..'\n');file:flush();return
  end
  local manager_page=label:match('^weapon_function_managers_(%d+)$')
  if manager_page then
   local ok,err=pcall(function()
    local raw=assert(reader.poll(),reader.status);local r=HUD.memory.new(backend)
    local record=r.read(raw.binding.record,24);local base=raw.binding.module_base
    local page=tonumber(manager_page);assert(page>=0 and page<=9)
    for slot=0x3326400+page*256,0x3326400+page*256+248,8 do
     for _,shape in ipairs({{0x18,0x30},{0x20,0x38},{0x28,0x40}}) do
      local found,manager,index,header=pcall(function()
       local manager=r.p(base+slot)
       local capacity=r.u(r.read(manager+shape[1]+8,4),0);assert(capacity>0 and capacity<=4096)
       local index=r.map(manager+shape[1],raw.id,4096)
       assert(index and index<4096)
       assert(r.read(r.p(r.p(manager+shape[2])+index*8),24)==record)
       return manager,index,r.read(manager,128)
      end)
      if found then
       local hex=header:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
       file:write(string.format('WEAPON_MANAGER slot=%X index=%d shape=%X address=%X header=%s\n',slot,index,shape[1],manager,hex))
      end
     end
    end
    assert(r.read(raw.binding.record,24)==record,'weapon identity changed')
   end)
   file:write('CAMERA_CAPTURE '..(ok and 'complete' or 'failure')..' label='..label..(ok and '' or ' '..tostring(err))..'\n');file:flush();return
  end
  if label=='ammo_control_code' then
   local ok,err=pcall(function()
    reader.validate()
    local r=HUD.memory.new(backend);local base=assert(backend.module('game.dll'))
    for _,start in ipairs({0x788000,0x752000}) do
     for i=0,23 do
      local address=base+start+i*1024;local data=r.read(address,1024)
      local hex=data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
      file:write(string.format('CAMERA_CAPTURE label=%s part=ammo_code_%x address=0x%X hex=%s\n',label,start+i*1024,address,hex))
     end
    end
   end)
   file:write('CAMERA_CAPTURE '..(ok and 'complete' or 'failure')..' label='..label..(ok and '' or ' '..tostring(err))..'\n');file:flush();return
  end
  if label=='ammo_reload_watch' then
   ammo_watch=20;last_ammo=nil
   file:write('CAMERA_CAPTURE complete label='..label..'\n');file:flush();return
  end
  if label=='native_fonts' then
   local sr=assert(rawget(_G,'stingray'))
   for _,name in ipairs({'core/performance_hud/debug','content/fonts/core_sans','content/fonts/cyborg_style','content/fonts/runtime_font','content/fonts/samples','content/fonts/runtime_font_terminal_layer'}) do
    for _,kind in ipairs({'font','material'}) do
     local ok,available=pcall(sr.Application.can_get,kind,name)
     file:write('NATIVE_FONT '..name..' '..kind..' '..tostring(ok and available)..'\n')
    end
   end
   file:write('CAMERA_CAPTURE complete label='..label..'\n');file:flush();return
  end
  if label=='camera_apis' or label=='weapon_node_apis' or label=='ammo_apis' then
   local sr=rawget(_G,'stingray') or {};local names={}
   for name,namespace in pairs(sr) do
    if type(name)=='string' and (name:lower():find('camera',1,true) or name:lower():find('input',1,true) or name:lower():find('player',1,true) or name:lower():find('controller',1,true) or ((label=='weapon_node_apis' or label=='ammo_apis') and name=='Unit') or (label=='ammo_apis' and (name:lower():find('weapon',1,true) or name:lower():find('ammo',1,true)))) then
     names[#names+1]=name
     if type(namespace)=='table' then local entries={};for key,value in pairs(namespace) do if type(value)=='function' then entries[#entries+1]=tostring(key) end end;table.sort(entries)
      file:write('CAMERA_API '..name..' '..table.concat(entries,' ')..'\n')
     end
    end
   end
   table.sort(names);file:write('CAMERA_API namespaces '..table.concat(names,' ')..'\nCAMERA_CAPTURE complete label='..label..'\n');file:flush();return
  end
  local probe=label=='trace_code' or (label:find('wide_state',1,true) and 'wide_state')
  if label:find('camera_links',1,true) then probe='camera_links' end
  if label:find('control_links',1,true) then probe='control_links' end
  if label:match('^code_probe_%d+$') then probe=label end
  if label:find('avatar_control',1,true) then probe='avatar_control' end
  if label:match('^avatar_page_%d+_') then probe=label end
  if label:find('shoulder_code',1,true) then probe='shoulder_code' end
  if label:find('command_flags',1,true) then probe='command_flags' end
  if label:find('camera_preferences',1,true) then probe='camera_preferences' end
  local ok,parts
  if label:find('avatar_nodes',1,true) then
   ok,parts=pcall(function()
    local raw=assert(reader.poll());local b=raw.binding
    local r=HUD.memory.new(backend);local rec=r.read(b.avatar_record,24)
    assert(r.u(rec,8)==b.avatar_id and r.u(rec,12)==b.avatar_candidate and r.u(rec,16)==raw.avatar_unit_ref,'avatar identity changed')
    return HUD.pose.new(backend).snapshot({id=b.avatar_id,unit_ref=raw.avatar_unit_ref,
     binding={module_base=b.module_base,record=b.avatar_record,candidate=b.avatar_candidate}},'avatar').node_parts
   end)
  elseif label:find('weapon_nodes',1,true) then
   ok,parts=pcall(function()return HUD.pose.new(backend).snapshot(reader.poll(),label:find('unit_api',1,true) and 'api' or true).node_parts end)
  else ok,parts=pcall(HUD.camera_state.capture,backend,reader.poll(),probe) end
  if ok then
   for _,part in ipairs(parts) do
    local hex=part.data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
    file:write(string.format('CAMERA_CAPTURE label=%s part=%s address=0x%X hex=%s\n',label,part.name,part.address,hex))
   end
   file:write('CAMERA_CAPTURE complete label='..label..'\n')
  else file:write('CAMERA_CAPTURE failure label='..label..' '..tostring(parts)..'\n') end
  file:flush()
 end,
 on_disable=cleanup,
}
