-- Isolated per-primitive depth marker. No Gui.move, profile edits or shared material writes.
local M={}
function M.new(sr,log)
    local gui,world,failed,access_reported,compare_reported;local ids={};local self={status='not started'}
    local material='mods/dbf_hud/materials/depth_state_test_loader_control'
    local access_material='mods/dbf_hud/materials/screen_scene_depth_access'
    local compare_material='mods/dbf_hud/materials/screen_scene_depth_compare'
    local function live(w)
        for _,v in pairs(sr.Application.worlds() or {}) do if v==w then return true end end
        return false
    end
    function self.release()
        if gui and live(world) then sr.World.destroy_gui(world,gui) end
        gui,world=nil,nil;ids={}
    end
    function self.draw(position,camera,fov,height,width)
        if failed then return false end
        if not position or not camera then self.release();return false end
        local ok,err=pcall(function()
            assert(type(sr.Gui.bitmap_3d)=='function','bitmap_3d unavailable')
            assert(sr.Application.can_get('material',material),'depth marker material unavailable')
            local main=sr.Application.main_world()
            local target=main
            if width then
                for _,candidate in pairs(sr.Application.worlds() or {}) do
                    if candidate~=main then target=candidate;break end
                end
            end
            if world~=target or not live(world) then self.release() end
            assert(live(target),'no GUI world')
            if not gui then
                world=target
                if width then gui=assert(sr.World.create_screen_gui(world,'scale',1,1))
                else gui=assert(sr.World.create_world_gui(world,sr.Matrix4x4.identity(),1,1,'immediate')) end
            end
            if width then
                for _,id in ipairs(ids) do sr.Gui.destroy_bitmap(gui,id) end
                ids={}
                local point=HUD.projection.project(camera,position.x,position.y,position.z,fov,width/height,.05)
                if not point then return end
                local radius,stroke=14*height/1080,1.5*height/1080
                local comparing=sr.Application.can_get('material',compare_material)
                local encoded=math.floor(math.max(0,math.min(64,point.depth))*65535/64+.5)
                local color=comparing and sr.Color(255,encoded%256,math.floor(encoded/256),0) or sr.Color(255,0,255,0)
                for _,edge in ipairs({{-radius,-radius,2*radius,stroke},{-radius,radius-stroke,2*radius,stroke},
                    {-radius,-radius,stroke,2*radius},{radius-stroke,-radius,stroke,2*radius}}) do
                    local id=sr.Gui.bitmap(gui,comparing and compare_material or material,sr.Vector3(point.x*width+edge[1],point.y*height+edge[2],50),
                        sr.Vector2(edge[3],edge[4]),color)
                    if id then ids[#ids+1]=id end
                end
                if comparing and not compare_reported then
                    compare_reported=true;log('SCENE_DEPTH comparison material loaded; green outline submitted; depth units provisional')
                end
                if not comparing and sr.Application.can_get('material',access_material) then
                    local side=128*height/1080
                    local id=sr.Gui.bitmap(gui,access_material,sr.Vector3(point.x*width+24*height/1080,
                        point.y*height-side*.5,50),sr.Vector2(side,side),sr.Color(255,255,255,255))
                    if id then ids[#ids+1]=id end
                    if not access_reported then
                        access_reported=true;log('SCENE_DEPTH access material loaded; screen tile submitted; texture contents unverified')
                    end
                end
                self.status='screen depth material submitted';return
            end
            local v=sr.Vector3
            local tm=sr.Matrix4x4.from_axes(v(camera[1],camera[2],camera[3]),
                v(camera[5],camera[6],camera[7]),v(camera[9],camera[10],camera[11]),
                v(position.x,position.y,position.z))
            local depth=(position.x-camera[13])*camera[5]+(position.y-camera[14])*camera[6]+(position.z-camera[15])*camera[7]
            if depth<=0 then return end
            local unit=2*depth*math.tan(fov*.5)/height
            local radius,stroke=10*height/1080*unit,1.5*height/1080*unit
            local color=sr.Color(255,255,0,255)
            for _,edge in ipairs({{-radius,-radius,2*radius,stroke},{-radius,radius-stroke,2*radius,stroke},
                {-radius,-radius,stroke,2*radius},{radius-stroke,-radius,stroke,2*radius}}) do
                sr.Gui.bitmap_3d(gui,material,tm,v(edge[1],edge[2],0),2,sr.Vector2(edge[3],edge[4]),color)
            end
            self.status='depth marker submitted'
        end)
        if not ok then failed=true;self.status=tostring(err);log('DEPTH_MARKER failure '..self.status);pcall(self.release) end
        return ok and (self.status=='depth marker submitted' or self.status=='screen depth material submitted')
    end
    return self
end
return M

