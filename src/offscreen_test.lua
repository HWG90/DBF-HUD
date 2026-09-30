-- Isolated one-frame render test. Never renders from the update callback.
local M={}
function M.start(sr,log,globals)
    globals=globals or _G
    local self={};local active=true;local submitted=false
    local A,W,R,V,U,G=sr.Application,sr.World,sr.Renderer,sr.Viewport,sr.Unit,sr.Gui
    local world,viewport,target,camera,environment,gui
    local original=rawget(globals,'render');local wrapper
    function self.release()
        active=false
        if wrapper and rawget(globals,'render')==wrapper then rawset(globals,'render',original) end
        local ok=true
        local function destroy(fn,...)
            if not ok then return end
            local done,err=pcall(fn,...);ok=done
            if not done then log('OFFSCREEN cleanup failed '..tostring(err)) end
        end
        if gui then destroy(W.destroy_gui,world,gui);if ok then gui=nil end end
        if viewport then destroy(A.destroy_viewport,world,viewport);if ok then viewport=nil end end
        if environment then destroy(W.destroy_shading_environment,world,environment);if ok then environment=nil end end
        if world then destroy(A.release_world,world);if ok then world=nil end end
        if target then destroy(R.destroy_resource,target);if ok then target=nil end end
        if ok then log('OFFSCREEN cleanup complete') end
    end
    if type(original)~='function' then log('OFFSCREEN blocked: no global render callback');return self end
    local ok,err=pcall(function()
        for _,pair in ipairs({{A,'new_world'},{A,'release_world'},{A,'create_viewport'},{A,'destroy_viewport'},
            {A,'render_world'},{A,'can_get'},{W,'spawn_unit'},{W,'create_screen_gui'},
            {W,'destroy_gui'},{W,'destroy_shading_environment'},
            {U,'camera'},{R,'create_resource'},{R,'destroy_resource'},{V,'set_output_render_target'},
            {G,'rect'}}) do assert(pair[1] and type(pair[1][pair[2]])=='function','missing '..pair[2]) end
        local name='core/appkit/units/camera/camera'
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
        target=assert(R.create_resource('render_target','R8G8B8A8',64,64))
        V.set_output_render_target(viewport,target)
        gui=assert(W.create_screen_gui(world,'scale',1,1))
        for i,color in ipairs({{230,60,60},{60,210,100},{60,110,230},{230,200,60}}) do
            G.rect(gui,sr.Vector3(((i-1)%2)*32,math.floor((i-1)/2)*32,1),sr.Vector2(32,32),
                sr.Color(255,color[1],color[2],color[3]))
        end
        log('OFFSCREEN camera and four-color GUI ready')
    end)
    if not ok then log('OFFSCREEN setup stopped '..tostring(err));self.release();return self end
    wrapper=function(...)
        if active and not submitted then
            submitted=true
            log('OFFSCREEN render callback entered')
            local done,why=pcall(A.render_world,world,camera,viewport,environment)
            log(done and 'OFFSCREEN render submitted; pixels unverified' or ('OFFSCREEN render failed '..tostring(why)))
        end
        return original(...)
    end
    rawset(globals,'render',wrapper)
    log('OFFSCREEN waiting for render callback')
    return self
end
return M
