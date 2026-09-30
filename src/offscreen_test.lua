-- Isolated one-frame render test. Never renders from the update callback.
local M={}
function M.start(sr,log,globals,panel_provider)
    globals=globals or _G
    local self={};local active=true;local submitted=false
    local A,W,R,V,U,G=sr.Application,sr.World,sr.Renderer,sr.Viewport,sr.Unit,sr.Gui
    local world,viewport,target,camera,environment,gui
    local preview,preview_world
    local world_ready=false
    local source_ids={};local elapsed=0
    function self.tick(dt)
        elapsed=elapsed+(dt or 0)
        if panel_provider and active and world and gui and (not world_ready or elapsed>=0.1) then
            elapsed=0
            local commands=panel_provider()
            if commands then
                for _,id in ipairs(source_ids) do G.destroy_rect(gui,id) end
                source_ids={}
                local f=commands[1]
                local function rect(x,y,w,h,c,a)
                    local id=G.rect(gui,sr.Vector3(x-f.x+8,y-f.y+8,1),sr.Vector2(w,h),sr.Color(math.floor(255*(a or 1)),c[1],c[2],c[3]))
                    source_ids[#source_ids+1]=id
                end
                for _,c in ipairs(commands) do
                    if c.type=='text' then
                        HUD.font.draw(c.text,c.size,c.x,c.y,function(x,y,w,h)rect(x,y,w,h,c.c,c.a)end)
                    else rect(c.x,c.y,c.w,c.h,c.c,c.a) end
                end
                world_ready=false;submitted=false
            end
        end
        if active and world and not world_ready then
            world_ready=true
            if type(W.update)=='function' then
                if not panel_provider then log('OFFSCREEN private world update begin') end
                local ok,err=pcall(W.update,world,0)
                if not panel_provider or not ok then log(ok and 'OFFSCREEN private world update complete' or ('OFFSCREEN private world update failed '..tostring(err))) end
                if not ok then active=false end
            else log('OFFSCREEN private world update unavailable') end
        end
    end
    local bridge=rawget(globals,'HUDRenderBridge');local unsubscribe
    function self.release()
        active=false
        if unsubscribe then unsubscribe();unsubscribe=nil end
        local ok=true
        local function destroy(fn,...)
            if not ok then return end
            local done,err=pcall(fn,...);ok=done
            if not done then log('OFFSCREEN cleanup failed '..tostring(err)) end
        end
        if preview then
            local live=false
            for _,w in pairs(A.worlds() or {}) do if w==preview_world then live=true end end
            if live then destroy(W.destroy_gui,preview_world,preview) end
            if ok then preview=nil end
        end
        if gui then destroy(W.destroy_gui,world,gui);if ok then gui=nil end end
        if viewport then destroy(A.destroy_viewport,world,viewport);if ok then viewport=nil end end
        if environment then destroy(W.destroy_shading_environment,world,environment);if ok then environment=nil end end
        if world then destroy(A.release_world,world);if ok then world=nil end end
        if target then destroy(R.destroy_resource,target);if ok then target=nil end end
        if ok then log('OFFSCREEN cleanup complete') end
    end
    if not bridge or bridge.api~=1 or type(bridge.subscribe)~='function' then
        local loader=rawget(globals,'CowboyBingusModLoader')
        local state=loader and loader.modules and loader.modules['mods/holographic_utility_display/render_bridge']
        log('OFFSCREEN blocked: startup HUD render bridge required; loader='..tostring(state)..'; render='..type(rawget(globals,'render')))
        self.waiting_for_bridge=true
        return self
    end
    local ok,err=pcall(function()
        for _,pair in ipairs({{A,'new_world'},{A,'release_world'},{A,'create_viewport'},{A,'destroy_viewport'},
            {A,'render_world'},{A,'can_get'},{W,'spawn_unit'},{W,'create_screen_gui'},
            {W,'destroy_gui'},{W,'destroy_shading_environment'},
            {U,'camera'},{R,'create_resource'},{R,'destroy_resource'},{V,'set_output_render_target'},
            {G,'rect'}}) do assert(pair[1] and type(pair[1][pair[2]])=='function','missing '..pair[2]) end
        local name='core/units/camera'
        if not A.can_get('unit',name) then name='core/appkit/units/camera/camera' end
        if not A.can_get('unit',name) then
            for _,ns_name in ipairs({'Camera','World','Application'}) do
                local names={};local ns=sr[ns_name]
                if type(ns)=='table' then for key,value in pairs(ns) do
                    if type(key)=='string' and type(value)=='function' and
                        (ns_name=='Camera' or key:lower():find('camera',1,true)) then names[#names+1]=key end
                end end
                table.sort(names);log('OFFSCREEN CAMERA_API '..ns_name..' '..table.concat(names,' '))
            end
            for _,candidate in ipairs({'core/appkit/units/camera','content/markers/camera_marker',
                'core/editor_slave/stingray_editor/editor_camera'}) do
                log('OFFSCREEN CAMERA_RESOURCE '..candidate..' '..tostring(A.can_get('unit',candidate)))
            end
        end
        assert(A.can_get('unit',name),'camera resource unavailable: '..name)
        local environment_name='core/stingray_renderer/environments/midday/midday'
        local default_environment=type(W.create_default_shading_environment)=='function'
        if not default_environment then
            assert(type(W.create_shading_environment)=='function','missing create_shading_environment')
            assert(A.can_get('shading_environment',environment_name),'default environment resource unavailable')
        end
        log('OFFSCREEN setup begin')
        world=assert(A.new_world())
        if type(U.num_meshes)=='function' then
            for _,candidate in ipairs({'content/art_shared/meshes/plane_2x2m','content/art_shared/meshes/plane_primitive','content/env_ship/hologram/units/plane'}) do
                local available=A.can_get('unit',candidate)
                log('SURFACE unit '..candidate..' available='..tostring(available))
                if available then
                    local probe=assert(W.spawn_unit(world,candidate))
                    local count=U.num_meshes(probe)
                    log('SURFACE unit '..candidate..' meshes='..tostring(count))
                    if count==1 and type(U.mesh)=='function' and sr.Mesh and type(sr.Mesh.num_materials)=='function' then
                        local mesh=U.mesh(probe,1)
                        local slots=sr.Mesh.num_materials(mesh)
                        log('SURFACE first mesh material slots='..tostring(slots))
                        if slots==1 and type(sr.Mesh.material)=='function' then
                            local material=sr.Mesh.material(mesh,1)
                            local ffi=require('ffi')
                            log(string.format('SURFACE material pointer=0x%X',tonumber(ffi.cast('uintptr_t',material))))
                        end
                    end
                    -- Private world owns this probe; no scene attachment or material changes.
                end
            end
        end
        local unit=assert(W.spawn_unit(world,name))
        camera=assert(U.camera(unit,1),'camera unavailable')
        environment=assert(default_environment and W.create_default_shading_environment(world)
            or W.create_shading_environment(world,environment_name))
        viewport=assert(A.create_viewport(world,'offscreen_ui_weapon_screen'))
        target=assert(R.create_resource('render_target','R8G8B8A8',panel_provider and 512 or 64,panel_provider and 256 or 64))
        V.set_output_render_target(viewport,target)
        self.texture=target
        gui=assert(W.create_screen_gui(world,'scale',1,1))
        if not panel_provider then
        for i,color in ipairs({{230,60,60},{60,210,100},{60,110,230},{230,200,60}}) do
            G.rect(gui,sr.Vector3(((i-1)%2)*32,math.floor((i-1)/2)*32,1),sr.Vector2(32,32),
                sr.Color(255,color[1],color[2],color[3]))
        end
        end
        log('OFFSCREEN camera and source GUI ready')
    end)
    if not ok then log('OFFSCREEN setup stopped '..tostring(err));self.release();return self end
    unsubscribe=bridge.subscribe('dbf_hud.offscreen',function(...)
        if active and world_ready and not submitted then
            submitted=true
            if not preview then log('OFFSCREEN render callback entered') end
            local done,why=pcall(A.render_world,world,camera,viewport,environment)
            if not preview or not done then log(done and 'OFFSCREEN render submitted; pixels unverified' or ('OFFSCREEN render failed '..tostring(why))) end
            if done and not preview then
                local shown,reason=pcall(function()
                    log('OFFSCREEN preview preflight begin')
                    assert(type(G.material)=='function','Gui.material unavailable')
                    assert(sr.Material and type(sr.Material.set_resource)=='function','Material.set_resource unavailable')
                    assert(type(G.bitmap)=='function','Gui.bitmap unavailable')
                    assert(type(A.main_world)=='function','Application.main_world unavailable')
                    assert(A.can_get('material','content/ui/shared/material/gui_diffuse_map'),'preview material unavailable')
                    local main=assert(A.main_world())
                    preview_world=main
                    for _,candidate in pairs(A.worlds() or {}) do
                        if candidate~=main and candidate~=world then preview_world=candidate;break end
                    end
                    log('OFFSCREEN preview world '..(preview_world==main and 'main fallback' or 'HUD world'))
                    log('OFFSCREEN preview GUI create begin')
                    preview=assert(W.create_screen_gui(preview_world,'scale',1,1))
                    -- Independent control: visible geometry does not depend on the render target.
                    G.rect(preview,sr.Vector3(896,296,79),sr.Vector2(panel_provider and 392 or 200,panel_provider and 200 or 200),sr.Color(255,255,0,255))
                    G.rect(preview,sr.Vector3(panel_provider and 1300 or 1104,300,80),sr.Vector2(48,48),sr.Color(255,255,255,255))
                    log('OFFSCREEN placement control: magenta frame and white square')
                    log('OFFSCREEN preview material lookup begin')
                    for _,candidate in ipairs({'core/performance_hud/gui','content/ui/shared/material/gui_diffuse_map','content/ui/shared/material/gui_fill','content/ui/shared/material/gui_white_alpha'}) do
                        if A.can_get('material',candidate) then
                            local valid,result=pcall(function()
                                local ffi=require('ffi')
                                return string.format('0x%X',tonumber(ffi.cast('uintptr_t',G.material(preview,candidate))))
                            end)
                            log('OFFSCREEN material candidate '..candidate..' '..(valid and result or 'lookup failed'))
                        else log('OFFSCREEN material candidate '..candidate..' unavailable') end
                    end
                    local material=assert(G.material(preview,'content/ui/shared/material/gui_diffuse_map'))
                    log('OFFSCREEN material Lua type='..type(material)..'; target Lua type='..type(target))
                    local pointer_ok,pointers=pcall(function()
                        local ffi=require('ffi')
                        local mp=tonumber(ffi.cast('uintptr_t',material))
                        local tp=tonumber(ffi.cast('uintptr_t',target))
                        assert(mp and mp>=65536,'Gui.material returned a null or invalid native pointer')
                        assert(tp and tp>=65536,'render target returned a null or invalid native pointer')
                        return string.format('material=0x%X target=0x%X',mp,tp)
                    end)
                    assert(pointer_ok,pointers)
                    log('OFFSCREEN native pointer check '..pointers)
                    -- Native signature and diffuse_map slot verified; null handles rejected above.
                    log('OFFSCREEN verified texture binding begin')
                    sr.Material.set_resource(material,'diffuse_map',target)
                    log('OFFSCREEN preview bitmap draw begin')
                    G.bitmap(preview,'content/ui/shared/material/gui_diffuse_map',sr.Vector3(900,300,80),sr.Vector2(panel_provider and 384 or 192,192),sr.Color(255,255,255,255))
                    log('OFFSCREEN four-color preview placed above/right of native bottom-left HUD')
                end)
                if not shown then log('OFFSCREEN preview stopped '..tostring(reason)) end
            end
        end
    end)
    log('OFFSCREEN waiting for render callback')
    return self
end
return M
