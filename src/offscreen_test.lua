-- Isolated one-frame render test. Never renders from the update callback.
local M={}
function M.start(sr,log,globals,panel_provider,show_preview)
    globals=globals or _G
    local self={};local active=true;local submitted=false;local first_render=true
    local A,W,R,V,U,G=sr.Application,sr.World,sr.Renderer,sr.Viewport,sr.Unit,sr.Gui
    local world,viewport,target,camera,environment,gui
    local preview,preview_world
    local world_ready=false
    local source_ids={};local elapsed=0
    local texture_w,texture_h=64,64
    local density=panel_provider and 4 or 1
    function self.tick(dt,refresh_hz,scanline_strength)
        elapsed=elapsed+(dt or 0)
        if panel_provider and active and world and gui and (not world_ready or refresh_hz==0 or elapsed>=1/(refresh_hz or 60)) then
            elapsed=0
            local commands=panel_provider()
            if commands then
                local f=commands[1]
                assert(f.w>0 and f.h>0,'invalid panel bounds')
                if math.ceil(f.w*density)~=texture_w or math.ceil(f.h*density)~=texture_h then
                    self.resize_required=true;return
                end
                self.aspect=texture_w/texture_h
                local sx,sy=density,density
                for _,id in ipairs(source_ids) do G.destroy_rect(gui,id) end
                source_ids={}
                local function rect(x,y,w,h,c,a)
                    -- Color-space trial: assume scene sampling treats this UNORM target as linear.
                    -- Decode display-space palette values before storing scene RGB.
                    local function linear(v)
                        v=v/255
                        return 255*(v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4)
                    end
                    local rgb={linear(c[1]),linear(c[2]),linear(c[3])}
                    local function strip(bottom,height,factor)
                        local id=G.rect(gui,sr.Vector3((x-f.x)*sx,(bottom-f.y)*sy,1),sr.Vector2(w*sx,height*sy),sr.Color(math.floor(255*(a or 1)),math.floor(rgb[1]*factor+0.5),math.floor(rgb[2]*factor+0.5),math.floor(rgb[3]*factor+0.5)))
                        source_ids[#source_ids+1]=id
                    end
                    local strength=scanline_strength or 0
                    if strength<=0 then strip(y,h,1);return end
                    -- One dim row per four source pixels, aligned across all primitives.
                    -- Modulate RGB only: never paint opaque bands into clear texels.
                    local bottom=y
                    while bottom<y+h do
                        local row=math.floor(bottom-f.y+0.000001)
                        local top=math.min(y+h,f.y+row+1)
                        if top<=bottom then break end
                        strip(bottom,top-bottom,row%4==0 and (1-strength) or 1)
                        bottom=top
                    end
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
    if panel_provider then
        local commands=panel_provider()
        if not commands then self.waiting_for_panel=true;return self end
        texture_w,texture_h=math.ceil(commands[1].w*density),math.ceil(commands[1].h*density)
        assert(texture_w>0 and texture_h>0 and texture_w<=2048 and texture_h<=2048,'panel texture bounds invalid')
        self.aspect=texture_w/texture_h
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
        local unit=assert(W.spawn_unit(world,name))
        camera=assert(U.camera(unit,1),'camera unavailable')
        environment=assert(default_environment and W.create_default_shading_environment(world)
            or W.create_shading_environment(world,environment_name))
        viewport=assert(A.create_viewport(world,'offscreen_ui_weapon_screen'))
        target=assert(R.create_resource('render_target','R8G8B8A8',texture_w,texture_h))
        V.set_output_render_target(viewport,target)
        self.texture=target
        gui=assert(W.create_screen_gui(world,'scale',1,1))
        if not panel_provider then
        for i,color in ipairs({{230,60,60},{60,210,100},{60,110,230},{230,200,60}}) do
            G.rect(gui,sr.Vector3(((i-1)%2)*32,math.floor((i-1)/2)*32,1),sr.Vector2(32,32),
                sr.Color(255,color[1],color[2],color[3]))
        end
        end
        log(string.format('OFFSCREEN source GUI ready at %dx%d',texture_w,texture_h))
    end)
    if not ok then log('OFFSCREEN setup stopped '..tostring(err));self.release();return self end
    unsubscribe=bridge.subscribe('dbf_hud.offscreen',function(...)
        if active and world_ready and not submitted then
            submitted=true
            if first_render then log('OFFSCREEN render callback entered') end
            local done,why=pcall(A.render_world,world,camera,viewport,environment)
            if first_render or not done then log(done and 'OFFSCREEN render submitted; pixels unverified' or ('OFFSCREEN render failed '..tostring(why))) end
            first_render=false
            if done and show_preview~=false and not preview then
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
                    G.rect(preview,sr.Vector3(896,296,79),sr.Vector2(panel_provider and texture_w/density+8 or 200,panel_provider and texture_h/density+8 or 200),sr.Color(255,255,0,255))
                    G.rect(preview,sr.Vector3(panel_provider and 916+texture_w/density or 1104,300,80),sr.Vector2(48,48),sr.Color(255,255,255,255))
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
                    G.bitmap(preview,'content/ui/shared/material/gui_diffuse_map',sr.Vector3(900,300,80),sr.Vector2(panel_provider and texture_w/density or 192,panel_provider and texture_h/density or 192),sr.Color(255,255,255,255))
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
