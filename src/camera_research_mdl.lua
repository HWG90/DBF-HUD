local backend,reader,file,next_poll= nil,nil,nil,0
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
  next_poll=next_poll-(dt or 0);if next_poll>0 then return end;next_poll=1
  local hud=rawget(_G,'DBFHUD');if not hud or not hud.config or not hud.config.debug_logging then return end
  local label=backend.camera_request();if not label then return end
  if label=='camera_apis' or label=='weapon_node_apis' then
   local sr=rawget(_G,'stingray') or {};local names={}
   for name,namespace in pairs(sr) do
    if type(name)=='string' and (name:lower():find('camera',1,true) or name:lower():find('input',1,true) or name:lower():find('player',1,true) or name:lower():find('controller',1,true) or (label=='weapon_node_apis' and name=='Unit')) then
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
  local ok,parts=pcall(HUD.camera_state.capture,backend,reader.poll(),probe)
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
