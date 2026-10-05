local M={}
function M.new(sr)
    local gui,world;local ids={};local G,W,A=sr.Gui,sr.World,sr.Application
    local font='core/performance_hud/debug'
    local self={}
    local blur;local probe_frames=0
    local candidates={'content/ui/shared/material/gui_blur','content/ui/shared/material/blur_background'}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if v==w then return true end end
        return false
    end
    function self.clear()
        if gui and live(world) then
            for _,v in ipairs(ids) do pcall(G['destroy_'..v.type],gui,v.id) end
        end
        ids={}
    end
    function self.release()
        if gui and live(world) then self.clear();W.destroy_gui(world,gui) end
        gui,world,ids=nil,nil,{};blur=nil;probe_frames=0
    end
    local function ensure()
        if gui and not live(world) then gui,world,ids=nil,nil,{};blur=nil;probe_frames=0 end
        if not gui then
            local main=A.main_world()
            for _,v in pairs(A.worlds() or {}) do if v~=main then world=v;break end end
            world=world or main;if not world then return end
            gui=W.create_screen_gui(world,'scale',1,1)
        end
        return gui~=nil
    end
    function self.draw(commands)
        if not ensure() then return end
        self.clear()
        if not blur and probe_frames%120==0 and type(A.can_get)=='function' and type(G.bitmap)=='function' then
            for _,name in ipairs(candidates) do
                local ok,available=pcall(A.can_get,'material',name)
                if ok and available then blur=name;break end
            end
        end
        probe_frames=probe_frames+1
        for _,c in ipairs(commands) do
            local color=sr.Color(math.floor(c.a*255+0.5),c.c[1],c.c[2],c.c[3])
            local id
            local kind=c.type
            if c.type=='panel' then
                local drawn=false
                if c.frosted and blur then
                    local ok,bid=pcall(G.bitmap,gui,blur,sr.Vector3(c.x,c.y,48),sr.Vector2(c.w,c.h),sr.Color(math.floor((c.frost_a or c.a)*255+.5),255,255,255))
                    if ok and bid then ids[#ids+1]={type='bitmap',id=bid};drawn=true
                    else blur=nil;probe_frames=1 end
                end
                self.material_status=drawn and ('native frost: '..blur) or 'opaque panel (native frost unavailable or disabled)'
                -- No fake translucent fallback when the game's blur resource is unavailable.
                if not drawn then color=sr.Color(math.floor(c.a*255+.5),c.c[1],c.c[2],c.c[3]) end
                id=G.rect(gui,sr.Vector3(c.x,c.y,49),sr.Vector2(c.w,c.h),color);kind='rect'
            elseif c.type=='rect' then
                id=G.rect(gui,sr.Vector3(c.x,c.y,c.fuel_marker_piece and 51 or 50),sr.Vector2(c.w,c.h),color)
            else
                local resource,material=HUD.native_font.resolve(sr,c.font,false)
                if resource and not c.fuel_endpoint then
                    for _,part in ipairs(HUD.font.numeric_parts(c)) do
                        local ink=part.c or c.c
                        local part_color=sr.Color(math.floor(c.a*part.alpha*255+.5),ink[1],ink[2],ink[3])
                        local tid=G.text(gui,part.text,resource,c.size,material,sr.Vector3(c.x+part.dx,c.y,51),part_color)
                        if tid then ids[#ids+1]={type=kind,id=tid} end
                    end
                end

            end
            if id then ids[#ids+1]={type=kind,id=id} end
        end
    end
    return self
end
return M
