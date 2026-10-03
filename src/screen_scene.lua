-- Project saved world layouts into the UI world; compare scene depth in shaders.
-- Native atlas glyphs become textured quads, not replacement bitmap lettering.
local M={}
function M.panel_pose(p,c,commands)
    local m=p.matrix;local x,y,z=HUD.scene_test.mount(p,c)
    local at={x=p.x+m[1]*x+m[5]*y+m[9]*z,
        y=p.y+m[2]*x+m[6]*y+m[10]*z,z=p.z+m[3]*x+m[7]*y+m[11]*z}
    if not c.debug_sight_root_orientation and p.attach_point~='root' and p.sight and p.sight.matrix then
        local anchor=p.sight
        local dx,dy,dz=x-anchor.x,y-anchor.y,z-anchor.z
        m=anchor.matrix
        at={x=m[13]+m[1]*dx+m[5]*dy+m[9]*dz,
            y=m[14]+m[2]*dx+m[6]*dy+m[10]*dz,
            z=m[15]+m[3]*dx+m[7]*dy+m[11]*dz}
    end
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
function M.text_parts(command,face)
    local parts=HUD.font.numeric_parts(command)
    if not face then return parts end
    local advance
    for digit=48,57 do
        local glyph=face.glyphs[digit]
        if not glyph or (advance and glyph[1]~=advance) then return parts end
        advance=glyph[1]
    end
    local out={}
    for _,part in ipairs(parts) do
        local previous=out[#out]
        if previous and previous.alpha==part.alpha and previous.c==part.c and previous.text:match('^%d+$') and part.text:match('^%d$') then
            previous.text=previous.text..part.text
        else out[#out+1]={text=part.text,dx=part.dx,alpha=part.alpha,c=part.c} end
    end
    return out
end
function M.new(sr,log)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local fill='mods/dbf_hud/materials/screen_hud_fill'
    local gui,child_gui,world,atlas_gui;local ids={};local glyphs={};local bitmap_updates=0;local reuse_glyphs=type(G.update_bitmap_3d_uv)=='function';local recycled={};local allocated,reused=0,0;local failed=false;local first=true
    local self={status='screen scene assets not loaded'}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if v==w then return true end end
        return false
    end
    local created,destroyed,released=0,0,0
    function self.resource_stats()
        local count=#ids;for _,pool in pairs(glyphs) do count=count+#pool.ids end
        return created,destroyed,released,count,allocated,reused,bitmap_updates
    end
    local function recycle(item)
        item.gui,item.id,item.kind=nil,nil,nil
        if #recycled<4096 then recycled[#recycled+1]=item end
    end
    local function track(draw_gui,id,kind)
        if not id then return end
        local item=recycled[#recycled]
        if item then recycled[#recycled]=nil;reused=reused+1 else item={};allocated=allocated+1 end
        item.gui,item.id,item.kind=draw_gui,id,kind
        ids[#ids+1]=item
    end
    local function clear()
        if gui and live(world) then for _,item in ipairs(ids) do G[item.kind=='text_3d' and 'destroy_text_3d' or item.kind=='text' and 'destroy_text' or item.kind=='bitmap_3d' and 'destroy_bitmap_3d' or item.kind=='bitmap' and 'destroy_bitmap' or 'destroy_triangle'](item.gui,item.id) end end
        destroyed=destroyed+#ids
        for i=#ids,1,-1 do recycle(ids[i]);ids[i]=nil end
    end
    function self.release()
        if gui and live(world) then
            if child_gui then W.destroy_gui(world,child_gui) end
            if atlas_gui then W.destroy_gui(world,atlas_gui) end
            W.destroy_gui(world,gui)
        end
        released=released+#ids;for _,pool in pairs(glyphs) do released=released+#pool.ids end;glyphs={};gui,child_gui,world,atlas_gui=nil,nil,nil,nil
        for i=#ids,1,-1 do recycle(ids[i]);ids[i]=nil end
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
        for _,pool in pairs(glyphs) do pool.used=0 end
        commands=HUD.world_style.prepare(commands,p,c)
        if c.style_3d=='hologram' then
            for _,v in ipairs(commands) do if v.type=='panel' then v.a=math.min(1,v.a/.18) end end
        end
        local m,at=M.panel_pose(p,c,commands)
        -- Temporary zoom demo: retain the widest observed first-person FOV per weapon.
        if c.first_person_zoom_demo and fov then
            self.zoom_reference=self.zoom_reference or {}
            local key=p.resource_hex or 'unknown'
            local reference=math.max(self.zoom_reference[key] or fov,fov)
            self.zoom_reference[key]=reference
            local ratio=math.max(.1,math.min(1,math.tan(fov*.5)/math.tan(reference*.5)))
            local dx,dy,dz=at.x-camera[13],at.y-camera[14],at.z-camera[15]
            local right=dx*camera[1]+dy*camera[2]+dz*camera[3]
            local up=dx*camera[9]+dy*camera[10]+dz*camera[11]
            at={x=at.x+(ratio-1)*(right*camera[1]+up*camera[9]),
                y=at.y+(ratio-1)*(right*camera[2]+up*camera[10]),
                z=at.z+(ratio-1)*(right*camera[3]+up*camera[11])}
            local scaled={};for i=1,16 do scaled[i]=m[i] end
            for _,base in ipairs({1,5,9}) do for j=0,2 do scaled[base+j]=m[base+j]*ratio end end
            m=scaled
        end

        local scan_generated,scan_emitted,scan_clipped=0,0,0
        local body,fold={},{ }
        for _,v in ipairs(commands) do
            local list=v.fold_child and fold or body;list[#list+1]=v
        end
        -- First-person surfaces can sit closer than the world camera near plane.
        if first then log('SCREEN_FONT_API bitmap='..type(G.bitmap_3d_uv)..' destroy='..type(G.destroy_bitmap_3d)) end
        local hud_near=p.first_person and math.min(near or .05,.005) or (near or .05)
        local project_snapshot=HUD.projection.projector(camera,fov,width/height,hud_near)
        local function render(list,axes,origin,draw_gui)
            local dx,dy,dz=origin.x-camera[13],origin.y-camera[14],origin.z-camera[15]
            local depth=dx*camera[5]+dy*camera[6]+dz*camera[7]
            depth=math.max(depth,hud_near)
            local enabled=c.occlusion_mode~='gui' and 1 or 0
            if first and list[1] then
                local panel=list[1];local depths={}
                for _,corner in ipairs({{panel.x,panel.y},{panel.x+panel.w,panel.y},{panel.x+panel.w,panel.y+panel.h},{panel.x,panel.y+panel.h}}) do
                    local wx,wy,wz=M.point(axes,origin,corner[1],corner[2])
                    depths[#depths+1]=(wx-camera[13])*camera[5]+(wy-camera[14])*camera[6]+(wz-camera[15])*camera[7]
                end
                log(string.format('SCREEN_CLIP near=%.6f enabled=%d corners=%.6f,%.6f,%.6f,%.6f',hud_near,enabled,unpack(depths)))
            end
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
                local point=project_snapshot(wx,wy,wz)
                if point then return sr.Vector3(point.x*width,0,point.y*height),{x=point.x*width,y=point.y*height} end
            end
            -- This scratch quad is consumed synchronously by clipping; never stored by native drawing.
            local corners={{},{},{},{}}
            local clipping_scratch={camera={{},{},{},{}},result={{},{},{},{}}}
            local function vertex(p)return sr.Vector3(p.x*width,0,p.y*height) end
            local function quad(x,y,w,h,name,color,layer,uv,texture,points,effect)
                if w<=0 or h<=0 then return end
                for i=1,4 do
                    local right=i==2 or i==3;local upper=i>=3
                    local wx,wy,wz=M.point(axes,origin,points and points[i][1] or (right and x+w or x),points and points[i][2] or (upper and y+h or y))
                    local corner=corners[i];corner.x,corner.y,corner.z=wx,wy,wz
                    corner.s=uv and (right and uv[3] or uv[1]) or 0
                    corner.v=uv and (upper and uv[2] or uv[4]) or 0
                end
                local polygon=HUD.projection.clip_polygon(camera,corners,fov,width/height,hud_near,clipping_scratch)
                if effect then scan_generated=scan_generated+1 end
                if #polygon<3 then if effect then scan_clipped=scan_clipped+1 end;return end
                if effect and #polygon==4 and not self.scanline_probe then
                    local a,b,d=polygon[1],polygon[2],polygon[4]
                    local dx,dy=(b.x-a.x)*width,(b.y-a.y)*height
                    local length=math.sqrt(dx*dx+dy*dy)
                    local thickness=length>0 and math.abs(dx*(d.y-a.y)*height-dy*(d.x-a.x)*width)/length or 0
                    log(string.format('SCANLINE_PIXEL_PROBE projected_length_px=%.3f projected_thickness_px=%.4f',length,thickness));self.scanline_probe=true
                end
                name=material(name,texture)
                for i=2,#polygon-1 do
                    local a,b,d=polygon[1],polygon[i],polygon[i+1]
                    local id=G.triangle(draw_gui,vertex(a),vertex(b),vertex(d),layer,color,name,
                        uv and sr.Vector2(a.s,a.v) or nil,uv and sr.Vector2(b.s,b.v) or nil,uv and sr.Vector2(d.s,d.v) or nil)
                    track(draw_gui,id)
                    if effect and id then scan_emitted=scan_emitted+1 end
                end
            end
            for _,v in ipairs(list) do
                local function color(alpha,ink)ink=ink or v.c;return sr.Color(math.floor(v.a*alpha*255+.5),ink[1],ink[2],ink[3]) end
                if (v.type=='rect' or v.type=='panel') and not c.profile_skip_geometry then
                    quad(v.x,v.y,v.w,v.h,fill,color(1),v.type=='panel' and 48 or (v.scanline_layer and 50.5 or (v.fuel_marker_piece and 51 or 50)),nil,nil,v.quad,v.df_effect_frame)
                elseif v.type=='text' and not v.fuel_endpoint and not c.profile_skip_text then
                    local key=v.font or 'bigblue';local face=HUD.native_font_data.faces[key]
                    local uv=HUD.native_font_uv[key]
                    assert(face and uv,'native screen font atlas unavailable: '..key)
                    local size=v.size/(face.em or 48)
                    local name=face.clear:sub(1,-7)..'_scene'
                    for _,part in ipairs(M.text_parts(v,face)) do
                        local x=v.x+part.dx
                        if G.bitmap_3d_uv and G.destroy_bitmap_3d and sr.Matrix4x4 and sr.Matrix4x4.from_axes then
                            material(name,face.font)
                            for i=1,#part.text do
                                local code=part.text:byte(i)
                                local metric=assert(face.glyphs[code] or face.glyphs[63])
                                local coords=assert(uv[code] or uv[63])
                                local left,bottom=metric[2]*size,metric[3]*size
                                local span,height=(metric[4]-metric[2])*size,(metric[5]-metric[3])*size
                                -- Small atlas strips follow changing perspective across the glyph.
                                local strips=2
                                for strip=0,strips-1 do
                                    local low,high=strip/strips,(strip+1)/strips
                                    local _,base=project(x+left,v.y+bottom+height*low)
                                    local _,right=project(x+left+span,v.y+bottom+height*low)
                                    local _,up=project(x+left,v.y+bottom+height*high)
                                    if span>0 and height>0 and base and right and up then
                                        local transform=sr.Matrix4x4.from_axes(
                                            sr.Vector3(right.x-base.x,0,right.y-base.y),sr.Vector3(0,1,0),
                                            sr.Vector3(up.x-base.x,0,up.y-base.y),sr.Vector3(base.x,0,base.y))
                                        local top=coords[4]+(coords[2]-coords[4])*high
                                        local bottom_uv=coords[4]+(coords[2]-coords[4])*low
                                        local uv0,uv1=sr.Vector2(coords[1],top),sr.Vector2(coords[3],bottom_uv)
                                        local pos,extent,ink=sr.Vector3(0,0,0),sr.Vector2(1,1),color(part.alpha,part.c)
                                        if reuse_glyphs then
                                            local pool=glyphs[draw_gui]
                                            if not pool then pool={ids={},used=0};glyphs[draw_gui]=pool end
                                            pool.used=pool.used+1;local id=pool.ids[pool.used]
                                            if id then
                                                local ok,err=pcall(G.update_bitmap_3d_uv,draw_gui,id,name,uv0,uv1,transform,pos,51,extent,ink)
                                                if ok then bitmap_updates=bitmap_updates+1 else
                                                    log('GLYPH_REUSE failed; recreating: '..tostring(err));reuse_glyphs=false
                                                    G.destroy_bitmap_3d(draw_gui,id);destroyed=destroyed+1;id=nil
                                                end
                                            end
                                            if not id then
                                                id=G.bitmap_3d_uv(draw_gui,name,uv0,uv1,transform,pos,51,extent,ink)
                                                pool.ids[pool.used]=id;if id then created=created+1 end
                                            end
                                        else
                                            local id=G.bitmap_3d_uv(draw_gui,name,uv0,uv1,transform,pos,51,extent,ink)
                                            track(draw_gui,id,'bitmap_3d')
                                        end
                                    end
                                end
                                x=x+metric[1]*size
                            end
                        elseif G.text_3d and sr.Matrix4x4 and sr.Matrix4x4.from_axes then
                            material(name,face.font)
                            -- Fit each native character to its projected advance and height.
                            for i=1,#part.text do
                                local char=part.text:sub(i,i)
                                local metric=assert(face.glyphs[char:byte()] or face.glyphs[63])
                                local advance=metric[1]*size
                                local left,bottom=metric[2]*size,metric[3]*size
                                local span,height=(metric[4]-metric[2])*size,(metric[5]-metric[3])*size
                                local _,base=project(x+left,v.y+bottom)
                                local _,right=project(x+left+span,v.y+bottom)
                                local _,up=project(x+left,v.y+bottom+height)
                                if span>0 and height>0 and base and right and up then
                                    local rx,ry=(right.x-base.x)/span,(right.y-base.y)/span
                                    local ux,uy=(up.x-base.x)/height,(up.y-base.y)/height
                                    local transform=sr.Matrix4x4.from_axes(
                                        sr.Vector3(rx,0,ry),sr.Vector3(0,1,0),sr.Vector3(ux,0,uy),
                                        sr.Vector3(base.x-rx*left-ux*bottom,0,base.y-ry*left-uy*bottom))
                                    local id=G.text_3d(draw_gui,char,face.font,v.size,name,transform,sr.Vector3(0,0,0),51,color(part.alpha,part.c))
                                    track(draw_gui,id,'text_3d')
                                end
                                x=x+advance
                            end
                        elseif G.text then
                            material(name,face.font)
                            local _,base=project(x,v.y);local _,up=project(x,v.y+v.size)
                            if base and up then
                                local pixels=math.sqrt((up.x-base.x)^2+(up.y-base.y)^2)
                                local id=G.text(draw_gui,part.text,face.font,pixels,name,sr.Vector3(base.x,base.y,51),color(part.alpha,part.c))
                                track(draw_gui,id,'text')
                            end
                        else
                        for i=1,#part.text do
                            local code=part.text:byte(i);local metric=face.glyphs[code] or face.glyphs[63];local coords=uv[code] or uv[63]
                            assert(metric and coords,'native screen glyph unavailable')
                            quad(x+metric[2]*size,v.y+metric[3]*size,(metric[4]-metric[2])*size,(metric[5]-metric[3])*size,name,color(part.alpha,part.c),51,coords,face.font)
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
            if glyphs[child_gui] then released=released+#glyphs[child_gui].ids;glyphs[child_gui]=nil end
            W.destroy_gui(world,child_gui);child_gui=nil
        end
        for draw_gui,pool in pairs(glyphs) do
            for i=#pool.ids,pool.used+1,-1 do G.destroy_bitmap_3d(draw_gui,pool.ids[i]);pool.ids[i]=nil;destroyed=destroyed+1 end
        end
        if scan_generated>0 and not self.scanline_emission_logged then
            log(string.format('SCANLINE_EMISSION strips=%d native_triangles=%d fully_clipped=%d separate_layer=50.5',scan_generated,scan_emitted,scan_clipped));self.scanline_emission_logged=true
        end
        created=created+#ids
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
