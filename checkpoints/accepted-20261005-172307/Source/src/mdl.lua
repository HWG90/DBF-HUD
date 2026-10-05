-- MDL API 2 lifecycle; this module never hooks global update or shutdown.
local hud
local offscreen
local scene
local live_log
local render_unsubscribe,pending_dt,render_seen,missed_render
local sync_probe_render,sync_probe_fallback=0,0
local function disable()
    if render_unsubscribe then render_unsubscribe();render_unsubscribe=nil end
    pending_dt=nil;render_seen=false;missed_render=0
    sync_probe_render=0;sync_probe_fallback=0
    if scene then scene.release();scene=nil end
    if offscreen then offscreen.release();offscreen=nil end
    if hud then hud.retire();hud=nil end
end
return {
    name='DBF-HUD (Live)',version='0.3.42',author='DBF-HUD',
    description='Reloadable HUD and weapon binding diagnostics. Replaces the running DBF-HUD instance when enabled.',
    on_enable=function(ctx)
        assert(ctx.api==2 and type(ctx.on_cleanup)=='function' and type(ctx.global)=='function','MDL API 2 required')
        local sr=assert(rawget(_G,'stingray'),'stingray missing')
        local backend=HUD.memory.native()
        local started=false
        ctx.on_cleanup(function() disable();if not started and backend.close then backend.close() end end)
        hud=HUD.runtime.start(sr,backend,{managed=true,screen_bone_hud=false,frame_trial=false})
        if backend.log then backend.log('GLYPH_REUSE_BUILD 20261003-NATIVE-RENDER-STATS local only read-only profiler statistics') end
        if backend.log then
            local available=0
            for _,entry in ipairs(HUD.shader_catalog) do if sr.Application.can_get('material',entry.material:gsub('/lab_','/mapped_')) then available=available+1 end end
            backend.log('PANEL_MAPPING_PRODUCTION source='..tostring(ctx.dir)..' variants='..available..' diagnostic_geometry=false')
        end
        started=true
        ctx.global('DBFHUD',hud)
        local render_bridge=rawget(_G,'HUDRenderBridge')
        if render_bridge and render_bridge.api==1 and type(render_bridge.subscribe)=='function' then
            render_unsubscribe=render_bridge.subscribe('dbf_hud.rigid_sync_trial',function()
                render_seen=true;missed_render=0
                if hud and hud.config.render_sync_trial and pending_dt then
                    local dt=pending_dt;pending_dt=nil;hud.tick(dt)
                    sync_probe_render=sync_probe_render+1
                    if sync_probe_render==1 or sync_probe_render==120 then ctx.log("RIGID_SYNC_EXECUTED render_ticks="..sync_probe_render.." fallback_ticks="..sync_probe_fallback) end
                end
            end)
            ctx.log('Render synchronization: bridge subscribed; normal HUD path')
        else ctx.log('Render synchronization: no render bridge; update fallback retained')end
        -- Startup bridge owns render; this MDL mod only subscribes/unsubscribes.
        live_log=function(line)if backend.log then pcall(backend.log,line) end end
        -- Mesh/offscreen setup archived: WorldGUI draws directly in runtime.
        -- offscreen=HUD.offscreen_test.start(sr,live_log,nil,function()return hud and hud.texture_commands()end,false)
        -- scene=HUD.scene_test.new(sr,live_log)
        ctx.log('Enabled DBF-HUD '..hud.version..' with MDL-owned updates')
    end,
    on_update=function(ctx,dt)
        if hud then
            if hud.config.render_sync_trial and render_unsubscribe and render_seen then
                missed_render=(missed_render or 0)+1
                if missed_render<=2 then pending_dt=(pending_dt or 0)+dt;return end
            end
            if hud.config.render_sync_trial and sync_probe_fallback<120 then
                sync_probe_fallback=sync_probe_fallback+1
                if sync_probe_fallback==1 or sync_probe_fallback==120 then ctx.log("RIGID_SYNC_FALLBACK fallback_ticks="..sync_probe_fallback.." render_ticks="..sync_probe_render) end
            end
            local elapsed=(pending_dt or 0)+dt;pending_dt=nil;hud.tick(elapsed)
        end
    end,
    on_disable=disable,
}
