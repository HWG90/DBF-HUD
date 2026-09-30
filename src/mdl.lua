-- MDL API 2 lifecycle; this module never hooks global update or shutdown.
local hud
local offscreen
local function disable()
    if offscreen then offscreen.release();offscreen=nil end
    if hud then hud.retire();hud=nil end
end
return {
    name='Astra Ammo (Live)',version='0.3.34',author='Astra Ammo',
    description='Reloadable HUD and weapon binding diagnostics. Replaces the running Astra instance when enabled.',
    on_enable=function(ctx)
        assert(ctx.api==2 and type(ctx.on_cleanup)=='function' and type(ctx.global)=='function','MDL API 2 required')
        local sr=assert(rawget(_G,'stingray'),'stingray missing')
        local backend=AA.memory.native()
        local started=false
        ctx.on_cleanup(function() disable();if not started and backend.close then backend.close() end end)
        hud=AA.runtime.start(sr,backend,{managed=true})
        started=true
        ctx.global('AstraAmmo',hud)
        -- Offscreen experiment disabled after a live CTD. MDL reload may also
        -- retire the global render callback; do not install render hooks here.
        ctx.log('Enabled Astra '..hud.version..' with MDL-owned updates')
    end,
    on_update=function(ctx,dt) if hud then hud.tick(dt) end end,
    on_disable=disable,
}
