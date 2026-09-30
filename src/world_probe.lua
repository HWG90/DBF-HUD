-- Minimal world-space GUI experiment; only engine-returned world/GUI handles.
local M={}
function M.new(sr,log,direct)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local smooth={};local depth_fill;local blur;local gui,world;local failed=false;local first=true
    local self={status='not started'}
    local function identity(handle)
        -- LuaJIT %p bypasses the engine's generic '[Material]' __tostring.
        -- This identifies Lua userdata storage, not necessarily its native object.
        local ok,address=pcall(string.format,'%p',handle)
        local native_ok,native=pcall(function()return string.format('0x%X',tonumber(require('ffi').cast('uintptr_t',handle)))end)
        return tostring(handle)..(ok and (' lua_address='..address) or '')..(native_ok and (' native_address='..native) or '')
    end
    local function live(w)
        if not w then return false end
        for _,v in pairs(A.worlds() or {})do if v==w then return true end end
        return false
    end
    function self.release()
        if gui and live(world) then
            log('WORLD_GUI destroy begin');W.destroy_gui(world,gui);log('WORLD_GUI destroy complete')
        end
        gui,world=nil,nil;blur=nil;depth_fill=nil;smooth={}
    end
    local function draw(p,c,commands,dt)
        if (not c.world_probe and not commands) or not p then self.release();return end
        if not W.create_world_gui or not G.move or not sr.Matrix4x4 or not sr.Matrix4x4.from_axes then
            self.status='world GUI functions missing';return
        end
        if gui and not live(world) then gui,world=nil,nil;smooth={} end
        local main=A.main_world()
        if not live(main) then self.status='no live main world';return end
        if gui and main~=world then self.release() end
        local m=p.matrix
        local x,y,z=HUD.scene_test.mount(p,c)
        local px=p.x+m[1]*x+m[5]*y+m[9]*z
        local py=p.y+m[2]*x+m[6]*y+m[10]*z
        local pz=p.z+m[3]*x+m[7]*y+m[11]*z
        m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
        px,py,pz=m[13],m[14],m[15]
        if first then log('WORLD_GUI matrix begin') end
        local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),
            sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(px,py,pz))
        if not gui then
            world=main;log('WORLD_GUI create begin')
            gui=assert(W.create_world_gui(world,pose,1000,1000,'immediate'),'world GUI returned nil')
            log('WORLD_GUI create complete')
            local name='mods/dbf_hud/materials/depth_fill'
            local state_test='mods/dbf_hud/materials/depth_state_test'
            if not direct and A.can_get and A.can_get('material',state_test) then
                depth_fill=state_test
                log('WORLD_GUI isolated depth-enable shader selected; occlusion requires visual verification')
            elseif not direct and A.can_get and A.can_get('material',name) then depth_fill=name
            elseif not direct and A.can_get and A.can_get('material','mods/astra_ammo/materials/depth_fill') then
                depth_fill='mods/astra_ammo/materials/depth_fill' -- Previously deployed optional material.
            end
            log('WORLD_GUI depth material '..(depth_fill and 'available' or 'missing; install depth material addon'))
            -- One-time observation only: resolve the same material used by bitmap.
            -- Keep no native material handles across frames or GUI destruction.
            log('WORLD_GUI instance '..identity(gui)..' world '..identity(world))
            if type(G.material)=='function' and A.can_get then
                for _,material_name in ipairs({'content/ui/shared/material/gui_fill',
                    depth_fill or 'mods/dbf_hud/materials/depth_fill','mods/dbf_hud/materials/depth_blur'}) do
                    if A.can_get('material',material_name) then
                        local ok,handle=pcall(G.material,gui,material_name)
                        log('WORLD_GUI material instance '..material_name..' '..(ok and identity(handle) or 'lookup failed'))
                    end
                end
            else log('WORLD_GUI material inspection unavailable') end
        else
            if first then log('WORLD_GUI move begin') end
            G.move(gui,pose)
        end
        if commands then
            -- Native screen frost renders white on the verified world-GUI path.
            -- Keep the user's frost preference for screen modes; omit it here.
            -- Bitmap takes the material as a required argument. This avoids relying
            -- on the game's optional rect material overload matching upstream.
            local function solid(x,y,w,h,layer,color)
                if depth_fill then
                    G.bitmap(gui,depth_fill,sr.Vector3(x,y,layer),sr.Vector2(w,h),color)
                else G.rect(gui,sr.Vector3(x,y,layer),sr.Vector2(w,h),color) end
            end
            for _,v in ipairs(commands) do
                local color=sr.Color(math.floor(v.a*255+.5),v.c[1],v.c[2],v.c[3])
                if v.type=='panel' then
                    -- Match the known-working hybrid background; leave experimental
                    -- depth fill on foreground primitives only during this comparison.
                    solid(v.x,v.y,v.w,v.h,1,color)
                elseif v.type=='rect' then
                    solid(v.x,v.y,v.w,v.h,2,color)
                elseif v.font=='bigblue' then
                    HUD.font.draw(v.text,v.size,v.x,v.y,function(x,y,w,h)
                        solid(x,y,w,h,3,color)
                    end)
                else
                    local font='core/performance_hud/debug'
                    G.text(gui,v.text,font,v.size,font,sr.Vector3(v.x,v.y,3),color)
                end
            end
            if first then log('WORLD_GUI panel submitted: '..(depth_fill and 'explicit material bitmap path' or 'default rectangle path'));first=false end
            self.status='world panel; frost unavailable on this rendering path';return true
        end
        if first then log('WORLD_GUI rect begin') end
        G.rect(gui,sr.Vector3(0,0,0),sr.Vector2(240,140),sr.Color(255,45,52,55))
        G.rect(gui,sr.Vector3(0,0,1),sr.Vector2(12,140),sr.Color(255,231,200,92))
        if first then log('WORLD_GUI rect complete');first=false end
        self.status='world rectangle submitted'
    end
    function self.draw(p,c,commands,dt)
        if failed then return end
        local ok,err=pcall(draw,p,c,commands,dt)
        if not ok then
            failed=true;self.status=tostring(err);log('WORLD_GUI Lua failure: '..self.status)
            pcall(self.release)
        end
        return ok and err==true
    end
    return self
end
return M
