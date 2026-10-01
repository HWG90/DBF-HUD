-- Independent registration check; no draw calls or changes to DBFHUD.
local elapsed,last=0,nil
local gui,world,draw_failed,draw_logged
local function live(sr,w)
    for _,v in pairs(sr.Application.worlds() or {}) do if v==w then return true end end
    return false
end
local function cleanup()
    local sr=rawget(_G,'stingray')
    if gui and sr and live(sr,world) then pcall(sr.World.destroy_gui,world,gui) end
    gui,world=nil,nil
end
local function draw(ctx)
    if draw_failed then return end
    local sr=rawget(_G,'stingray');local hud=rawget(_G,'DBFHUD')
    local p=hud and hud.weapon_pose
    if not sr or not p or not p.matrix then cleanup();return end
    local material='mods/dbf_hud/materials/native_font_depth_loader_control'
    if not sr.Application.can_get('material',material) then cleanup();return end
    local ok,err=pcall(function()
        local main=sr.Application.main_world()
        if not live(sr,main) then cleanup();return end
        if gui and (world~=main or not live(sr,world)) then cleanup() end
        local m=p.matrix
        local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),sr.Vector3(m[5],m[6],m[7]),
            sr.Vector3(m[9],m[10],m[11]),sr.Vector3(p.x,p.y,p.z))
        if not gui then world=main;gui=assert(sr.World.create_world_gui(world,pose,1000,1000,'immediate'))
        else sr.Gui.move(gui,pose) end
        local font='core/performance_hud/debug'
        local hack='mods/dbf_hud/fonts/hack_regular_test'
        local hack_material='mods/dbf_hud/materials/hack_regular_test'
        local use_hack=sr.Application.can_get('font',hack) and sr.Application.can_get('material',hack_material)
        sr.Gui.text(gui,use_hack and 'HACK 0123456789' or 'DEPTH TEST',use_hack and hack or font,32,use_hack and hack_material or material,sr.Vector3(0,200,3),sr.Color(255,90,255,255))
        sr.Gui.text(gui,'ORIGINAL',font,32,font,sr.Vector3(0,155,3),sr.Color(255,255,200,80))
        if not draw_logged then ctx.log('Native font probe: separate comparison text submitted');draw_logged=true end
    end)
    if not ok then cleanup();draw_failed=true;ctx.log('Native font probe draw failed: '..tostring(err)) end
end
local function inspect(ctx)
    local sr=rawget(_G,'stingray')
    local app=sr and sr.Application
    if not app or type(app.can_get)~='function' then ctx.log('Native font probe: availability API unavailable');return end
    local results={}
    for _,entry in ipairs({
        {'font','core/performance_hud/debug'},
        {'material','core/performance_hud/debug'},
        {'material','mods/dbf_hud/materials/native_font_depth_loader_control'},
        {'shader_library','mods/dbf_hud/shaders/native_font_depth_loader_control'},
        {'font','mods/dbf_hud/fonts/hack_regular_test'},
        {'material','mods/dbf_hud/materials/hack_regular_test'}
    }) do
        local ok,value=pcall(app.can_get,entry[1],entry[2])
        results[#results+1]=entry[1]..' '..entry[2]..'='..(ok and tostring(value) or 'unavailable')
    end
    local state=table.concat(results,'; ')
    if state~=last then
        ctx.log('Native font registration: '..state)
        local file=io.open('DBF-HUD-native-font-probe.log','a')
        if file then file:write('Native font registration: '..state..'\n');file:close() end
        last=state
    end
end
return {
    name='DBF-HUD Native Font Probe',version='0.1',author='DBF-HUD',
    description='Separate native-font comparison text; the main HUD is unchanged.',
    on_enable=function(ctx)elapsed=0;last=nil;draw_failed=false;draw_logged=false;ctx.on_cleanup(cleanup);inspect(ctx)end,
    on_update=function(ctx,dt)draw(ctx);elapsed=elapsed+(dt or 0);if elapsed>=2 then elapsed=0;inspect(ctx)end end,
    on_disable=function()cleanup();elapsed=0;last=nil end
}
