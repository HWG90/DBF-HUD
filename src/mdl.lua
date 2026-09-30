-- MDL API 2 lifecycle; this module never hooks global update or shutdown.
local hud
local offscreen
local scene
local live_log
local function disable()
    if scene then scene.release();scene=nil end
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
        offscreen=HUD.offscreen_test.start(sr,live_log,nil,function()return hud and hud.texture_commands()end,false)
        scene=HUD.scene_test.new(sr,live_log)
        ctx.log('Enabled DBF-HUD '..hud.version..' with MDL-owned updates')
    end,
    on_update=function(ctx,dt)
        if hud then
            hud.scene_test_only=scene~=nil and offscreen~=nil and offscreen.texture~=nil and hud.weapon_pose~=nil
            hud.tick(dt)
        end
        if offscreen and offscreen.tick then offscreen.tick(dt,hud and hud.config.texture_refresh_hz) end
        if scene and hud then scene.draw(hud.weapon_pose,hud.config,offscreen and offscreen.texture,dt,offscreen and offscreen.aspect) end
        -- Rebuild only when prerequisites arrive or content bounds change.
        if offscreen then
            local bridge=rawget(_G,'HUDRenderBridge')
            local bridge_ready=bridge and bridge.api==1 and type(bridge.subscribe)=='function'
            local panel_ready=hud and hud.texture_commands()~=nil
            if bridge_ready and panel_ready and (offscreen.waiting_for_bridge or offscreen.waiting_for_panel or offscreen.resize_required) then
                if scene then scene.release() end
                offscreen.release()
                offscreen=HUD.offscreen_test.start(assert(rawget(_G,'stingray')),live_log,nil,function()return hud and hud.texture_commands()end,false)
            end
        end
    end,
    on_disable=disable,
}
