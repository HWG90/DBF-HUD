-- Project saved world layouts into the UI world; compare scene depth in shaders.
-- Native atlas glyphs become textured quads, not replacement bitmap lettering.
local M={}
function M.panel_pose(p,c,commands)
    local m=p.matrix;local x,y,z=HUD.scene_test.mount(p,c)
    local at={x=p.x+m[1]*x+m[5]*y+m[9]*z,
        y=p.y+m[2]*x+m[6]*y+m[10]*z,z=p.z+m[3]*x+m[7]*y+m[11]*z}
    if p.attach_point~='root' and p.sight and p.sight.matrix then
        local anchor=p.sight
        local dx,dy,dz=x-anchor.x,y-anchor.y,z-anchor.z
        m=anchor.matrix
        at={x=m[13]+m[1]*dx+m[5]*dy+m[9]*dz,
            y=m[14]+m[2]*dx+m[6]*dy+m[10]*dz,
            z=m[15]+m[3]*dx+m[7]*dy+m[11]*dz}
    elseif c.placement_mode=='auto' and p.first_person then m=HUD.pose_motion.upright(m) end
    if c.keep_hud_upright then m=HUD.pose_motion.upright(m) end
    local angle=math.rad(c.panel_rotation or 0)
    if angle~=0 then
        local rotated={};for i=1,16 do rotated[i]=m[i] end
        local co,si=math.cos(angle),math.sin(angle)
        for i=1,3 do
            rotated[i]=m[i]*co+m[i+8]*si
            rotated[i+8]=m[i+8]*co-m[i]*si
        end
        m=rotated
    end
    for _,turn in ipairs({{c.panel_pitch or 0,5,9},{c.panel_yaw or 0,1,5}}) do
        if turn[1]~=0 then
            local rotated={};for i=1,16 do rotated[i]=m[i] end
            local co,si=math.cos(math.rad(turn[1])),math.sin(math.rad(turn[1]))
            for i=0,2 do
                local a,b=turn[2]+i,turn[3]+i
                rotated[a]=m[a]*co+m[b]*si;rotated[b]=m[b]*co-m[a]*si
            end
            m=rotated
        end
    end
    return m,at
end
function M.point(m,at,x,y)
    return at.x+(m[1]*x+m[9]*y)/1000,
        at.y+(m[2]*x+m[10]*y)/1000,at.z+(m[3]*x+m[11]*y)/1000
end
function M.new(sr,log)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local fill='mods/dbf_hud/materials/screen_hud_fill'
    local gui,child_gui,world,atlas_gui;local ids={};local failed=false;local first=true
    local self={status='screen scene assets not loaded'}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if v==w then return true end end
        return false
    end
    local function clear()
        if gui and live(world) then for _,item in ipairs(ids) do G[item.kind=='text_3d' and 'destroy_text_3d' or item.kind=='text' and 'destroy_text' or item.kind=='bitmap' and 'destroy_bitmap' or 'destroy_triangle'](item.gui,item.id) end end
        ids={}
    end
    function self.release()
        if gui and live(world) then
            if child_gui then W.destroy_gui(world,child_gui) end
            if atlas_gui then W.destroy_gui(world,atlas_gui) end
            W.destroy_gui(world,gui)
        end
        gui,child_gui,world,atlas_gui=nil,nil,nil,nil;ids={}
    end
    local function draw(p,c,commands,camera,fov,width,height,near)
        if not p or not camera or not A.can_get or not A.can_get('material',fill) then self.release();return false end
        assert(type(G.triangle)=='function' and type(G.destroy_triangle)=='function','screen triangle API unavailable')
        assert(type(G.material)=='function' and sr.Material and type(sr.Material.set_scalar)=='function','material parameters unavailable')
        local target;local main=A.main_world()
        for _,v in pairs(A.worlds() or {}) do if v~=main then target=v;break end end
        if not target then self.release();return false end
        if gui and (world~=target or not live(world)) then self.release() end
        if not gui then world=target;gui=assert(W.create_screen_gui(world,'scale',1,1),'screen scene GUI missing') end
        clear()
        commands=HUD.world_style.prepare(commands,p,c)
        if c.style_3d=='hologram' then
            for _,v in ipairs(commands) do if v.type=='panel' then v.a=math.min(1,v.a/.18) end end
        end
        local m,at=M.panel_pose(p,c,commands)
        local body,fold={},{ }
        for _,v in ipairs(commands) do
            local list=v.fold_child and fold or body;list[#list+1]=v
        end
        local function render(list,axes,origin,draw_gui)
            local dx,dy,dz=origin.x-camera[13],origin.y-camera[14],origin.z-camera[15]
            local depth=dx*camera[5]+dy*camera[6]+dz*camera[7]
            if depth<=math.max(near or .05,.05) then return end
            local enabled=c.occlusion_mode~='gui' and 1 or 0
            local materials={}
            local function material(name,texture)
                if not materials[name] then
                    assert(A.can_get('material',name),'screen scene font material missing: '..name)
                    local handle=assert(G.material(draw_gui,name),'screen scene material unavailable')
                    if texture then sr.Material.set_texture(handle,'diffuse_map',texture) end
                    sr.Material.set_scalar(handle,'threshold_fade',depth)
                    sr.Material.set_scalar(handle,'scissor_mode',enabled)
                    materials[name]=true
                end
                return name
            end
            local function project(x,y)
                local wx,wy,wz=M.point(axes,origin,x,y)
                local point=HUD.projection.project(camera,wx,wy,wz,fov,width/height,near or .05)
                if point then return sr.Vector3(point.x*width,0,point.y*height),{x=point.x*width,y=point.y*height} end
            end
            local function quad(x,y,w,h,name,color,layer,uv,texture)
                if w<=0 or h<=0 then return end
                local a,pa=project(x,y);local b,pb=project(x+w,y);local d,pd=project(x+w,y+h);local e,pe=project(x,y+h)
                if not a or not b or not d or not e then return end
                name=material(name,texture)
                if uv and G.bitmap then
                    local left=math.min(pa.x,pb.x,pd.x,pe.x);local bottom=math.min(pa.y,pb.y,pd.y,pe.y)
                    local right=math.max(pa.x,pb.x,pd.x,pe.x);local top=math.max(pa.y,pb.y,pd.y,pe.y)
                    local id=G.bitmap(draw_gui,name,sr.Vector3(left,bottom,layer),sr.Vector2(right-left,top-bottom),color,
                        sr.Vector2(uv[1],uv[2]),sr.Vector2(uv[3],uv[4]))
                    ids[#ids+1]={gui=draw_gui,id=id,kind='bitmap'}
                    return
                end
                local u0,u1,u2,u3
                if uv then
                    u0=sr.Vector2(uv[1],uv[4]);u1=sr.Vector2(uv[3],uv[4])
                    u2=sr.Vector2(uv[3],uv[2]);u3=sr.Vector2(uv[1],uv[2])
                end
                ids[#ids+1]={gui=draw_gui,id=G.triangle(draw_gui,a,b,d,layer,color,name,u0,u1,u2)}
                ids[#ids+1]={gui=draw_gui,id=G.triangle(draw_gui,a,d,e,layer,color,name,u0,u2,u3)}
            end
            for _,v in ipairs(list) do
                local function color(alpha)return sr.Color(math.floor(v.a*alpha*255+.5),v.c[1],v.c[2],v.c[3]) end
                if v.type=='rect' or v.type=='panel' then
                    quad(v.x,v.y,v.w,v.h,fill,color(1),v.type=='panel' and 48 or (v.fuel_marker_piece and 51 or 50))
                elseif v.type=='text' and not v.fuel_endpoint then
                    local key=v.font or 'bigblue';local face=HUD.native_font_data.faces[key]
                    local uv=HUD.native_font_uv[key]
                    assert(face and uv,'native screen font atlas unavailable: '..key)
                    local size=v.size/(face.em or 48)
                    local name=face.clear:sub(1,-7)..'_scene'
                    for _,part in ipairs(HUD.font.numeric_parts(v)) do
                        local x=v.x+part.dx
                        if G.text_3d and sr.Matrix4x4 and sr.Matrix4x4.from_axes then
                            material(name,face.font)
                            local _,base=project(x,v.y);local _,right=project(x+1,v.y);local _,up=project(x,v.y+1)
                            if base and right and up then
                                local transform=sr.Matrix4x4.from_axes(
                                    sr.Vector3(right.x-base.x,0,right.y-base.y),sr.Vector3(0,1,0),
                                    sr.Vector3(up.x-base.x,0,up.y-base.y),sr.Vector3(base.x,0,base.y))
                                local id=G.text_3d(draw_gui,part.text,face.font,v.size,name,transform,sr.Vector3(0,0,0),51,color(part.alpha))
                                ids[#ids+1]={gui=draw_gui,id=id,kind='text_3d'}
                            end
                        elseif G.text then
                            material(name,face.font)
                            local _,base=project(x,v.y);local _,up=project(x,v.y+v.size)
                            if base and up then
                                local pixels=math.sqrt((up.x-base.x)^2+(up.y-base.y)^2)
                                local id=G.text(draw_gui,part.text,face.font,pixels,name,sr.Vector3(base.x,base.y,51),color(part.alpha))
                                ids[#ids+1]={gui=draw_gui,id=id,kind='text'}
                            end
                        else
                        for i=1,#part.text do
                            local code=part.text:byte(i);local metric=face.glyphs[code] or face.glyphs[63];local coords=uv[code] or uv[63]
                            assert(metric and coords,'native screen glyph unavailable')
                            quad(x+metric[2]*size,v.y+metric[3]*size,(metric[4]-metric[2])*size,(metric[5]-metric[3])*size,name,color(part.alpha),51,coords,face.font)
                            x=x+metric[1]*size
                        end
                        end
                    end
                end
            end
        end
        render(body,m,at,gui)
        if #fold>0 then
            local child_panel=fold[1];local edge=child_panel.y+child_panel.h;local child={}
            for _,v in ipairs(fold) do
                local copy={};for k,value in pairs(v) do copy[k]=value end;copy.y=v.y-edge
                if copy.type=='text' then
                    local a,b,e,f=HUD.font.measure(copy.text,copy.size,copy.font,true)
                    copy.x=child_panel.x+child_panel.w/2-(a+e)/2;copy.y=-child_panel.h/2-(b+f)/2
                end
                child[#child+1]=copy
            end
            local hinge=body[1].y-2
            child_gui=child_gui or assert(W.create_screen_gui(world,'scale',1,1),'screen child GUI missing')
            render(child,HUD.pose_motion.forward_tilt(m,-math.pi/2),
                {x=at.x+m[9]*hinge/1000,y=at.y+m[10]*hinge/1000,z=at.z+m[11]*hinge/1000},child_gui)
        elseif child_gui then
            W.destroy_gui(world,child_gui);child_gui=nil
        end
        self.status='screen-projected scene-depth HUD'
        if first then log('SCREEN_SCENE HUD submitted; native atlas glyphs; saved mounts retained; live validation pending');first=false end
        return true
    end
    function self.draw(...)
        if failed then return false end
        local ok,result=pcall(draw,...)
        if not ok then failed=true;self.status=tostring(result);log('SCREEN_SCENE failure: '..self.status);pcall(self.release);return false end
        return result
    end
    return self
end
return M
