-- MDL API 2 lifecycle; this module never hooks global update or shutdown.
local hud
local offscreen
local live_log
local function disable()
    if offscreen then offscreen.release();offscreen=nil end
    if hud then hud.retire();hud=nil end
end
return {
    name='DBF-HUD (Live)',version='0.3.36',author='DBF-HUD',
    description='Reloadable HUD and weapon binding diagnostics. Replaces the running DBF-HUD instance when enabled.',
    on_enable=function(ctx)
        assert(ctx.api==2 and type(ctx.on_cleanup)=='function' and type(ctx.global)=='function','MDL API 2 required')
        local sr=assert(rawget(_G,'stingray'),'stingray missing')
        local backend=HUD.memory.native()
        local started=false
        ctx.on_cleanup(function() disable();if not started and backend.close then backend.close() end end)
        hud=HUD.runtime.start(sr,backend,{managed=true})
        started=true
        ctx.global('DBFHUD',hud)
        -- Startup bridge owns render; this MDL mod only subscribes/unsubscribes.
        live_log=function(line)if backend.log then pcall(backend.log,line) end end
        offscreen=HUD.offscreen_test.start(sr,live_log)
        ctx.log('Enabled DBF-HUD '..hud.version..' with MDL-owned updates')
    end,
    on_update=function(ctx,dt)
        if hud then hud.tick(dt) end
        if offscreen and offscreen.tick then offscreen.tick() end
        -- Startup addons can load after MDL. Retry only once the bridge exists.
        if offscreen and offscreen.waiting_for_bridge then
            local bridge=rawget(_G,'HUDRenderBridge')
            if bridge and bridge.api==1 and type(bridge.subscribe)=='function' then
                offscreen.release()
                offscreen=HUD.offscreen_test.start(assert(rawget(_G,'stingray')),live_log)
            end
        end
    end,
    on_disable=disable,
}
