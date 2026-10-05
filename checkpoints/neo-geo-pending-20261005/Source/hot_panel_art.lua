-- File-backed HUD artwork; uploads run only on the render bridge.
local M={}
function M.new(sr,backend,root)
 local self={pending={},active={},status='No hot artwork loaded',closing=false}
 local native,off
 local key='dbf_hud.hot_panel_art.lifetime.v1'
 local store=package.loaded[key] or {bytes=0,resources={}};package.loaded[key]=store
 local function initialize()
  if native then return end
  local bridge=assert(rawget(_G,'HUDRenderBridge'),'render bridge unavailable')
  assert(bridge.api==1,'verified render bridge required')
  native=HUD.runtime_texture_native.new(sr,backend)
  off=bridge.subscribe('dbf_hud.hot_panel_art.'..tostring(self),function()
   if not self.closing and next(self.pending)==nil then return end
   native.set_phase(true)
   local ok,err=pcall(function()
    if self.closing then self.pending={};self.active={};return end
    for name,image in pairs(self.pending)do
     self.pending[name]=nil
     local prior=self.active[name]
     if not prior or prior.rgba~=image.rgba then
      local size=HUD.runtime_textures.validate(image)
      assert(store.bytes+size<=HUD.runtime_textures.max_retained_bytes,'Hot artwork budget exhausted; restart required')
      local record={bytes=size,rgba=image.rgba};store.bytes=store.bytes+size;store.resources[#store.resources+1]=record
      native.upload(image,record);self.active[name]=record
     end
    end
    self.status='Hot artwork uploaded; verify appearance'
   end)
   native.set_phase(false)
   if not ok then self.status=tostring(err)end
   if self.closing and off then local stop=off;off=nil;stop()end
  end)
 end
 function self.reload()
  local f=assert(io.open(root..'/manifest.tsv','rb'),'Hot artwork manifest missing')
  local text=f:read(65537);f:close();assert(#text<=65536,'Manifest too large')
  local queue={};local count=0
  for line in text:gmatch('[^\r\n]+')do
   if line:sub(1,1)~='#' then
    local name,w,h=line:match('^([%w_%-]+)\t(%d+)\t(%d+)$');assert(name,'Invalid artwork manifest row')
    assert(not queue[name],'Duplicate artwork');count=count+1;assert(count<=512,'Too many artwork entries')
    queue[name]=HUD.runtime_textures.read_image(root..'/'..name..'.rgba',tonumber(w),tonumber(h))
   end
  end
  assert(count>0,'Manifest has no artwork');initialize();self.pending=queue
  self.status='Queued '..count..' artwork files';return self.status
 end
 function self.resource(texture)
  if self.closing then return nil end
  local name=texture and texture:match('^mods/dbf_hud/textures/([%w_%-]+)$')
  return name and self.active[name] and self.active[name].resource
 end
 function self.restore()self.pending={};self.active={};self.status='Packaged artwork restored';return self.status end
 function self.close()self.closing=true;self.pending={};self.active={}end
 return self
end
return M

