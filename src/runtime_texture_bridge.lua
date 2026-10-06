-- No native work until an explicit registration/swap request.
local M={}
function M.new(sr,backend)
    local bridge=assert(rawget(_G,'HUDRenderBridge'),'render bridge unavailable')
    assert(bridge.api==1 and type(bridge.subscribe)=='function','verified render bridge required')
    local native=HUD.runtime_texture_native.new(sr,backend)
    local key='dbf_hud.runtime_texture_lifetime.v1'
    local store=package.loaded[key]
    if not store then store={bytes=0,resources={},claims={},serial=0};package.loaded[key]=store end
    store.serial=store.serial+1
    local manager=HUD.runtime_textures.new(native,store)
    local unsubscribe
    unsubscribe=bridge.subscribe('dbf_hud.runtime_textures.'..store.serial,function()
        native.set_phase(true)
        local ok,complete=pcall(manager.step)
        native.set_phase(false)
        if not ok then manager.status=tostring(complete)end
        if ok and complete==true and unsubscribe then local off=unsubscribe;unsubscribe=nil;off()end
    end)
    local self={}
    function self.register(id,spec,original)
        return manager.register(id,native.target(spec),original)
    end
    self.image=HUD.runtime_textures.read_image
    function self.swap_file(id,path)
        local t=assert(manager.targets[id],'unknown texture target')
        return manager.swap(id,HUD.runtime_textures.read_image(path,t.width,t.height))
    end
    self.swap=manager.swap;self.restore=manager.restore;self.reload_files=manager.reload_files
    self.close=manager.close;self.stats=manager.stats
    return self
end
return M
