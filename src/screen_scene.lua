-- Project saved world layouts into the UI world; compare scene depth in shaders.
-- Native atlas glyphs become textured quads, not replacement bitmap lettering.
local M={max_texture_images=24}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
-- Non-overlapping edge bands use the existing material mapping and triangle
-- alpha. No new native shader library or per-band GUI/material is required.
function M.feather_boxes(w,h,fx,fy)
    fx=math.max(0,math.min(.2,fx or 0));fy=math.max(0,math.min(.2,fy or 0))
    if fx==0 or fy==0 then return {{0,0,w,h,1}} end
    local out={};local n=4;local dx,dy=w*fx/n,h*fy/n
    for i=0,n-1 do
        local x,y=i*dx,i*dy;local bw,bh=w-2*x,h-2*y
        local t=(i+.5)/n;local a=t*t*(3-2*t)
        out[#out+1]={x,y,dx,bh,a};out[#out+1]={w-x-dx,y,dx,bh,a}
        out[#out+1]={x+dx,y,bw-2*dx,dy,a};out[#out+1]={x+dx,h-y-dy,bw-2*dx,dy,a}
    end
    out[#out+1]={w*fx,h*fy,w*(1-2*fx),h*(1-2*fy),1}
    return out
end
function M.expand_shader_layers(commands,c,can_get,resource)
 if c.shader_layers==nil then return commands end
 local out={};for _,v in ipairs(commands)do out[#out+1]=v end
 local frame;for _,v in ipairs(commands)do if v.type=='panel' and not v.fold_child then frame=v;break end end
 if not frame then return out end
 local carrier;local count=0
 for _,v in ipairs(commands)do if v.type=='texture' then count=count+1;if not carrier then carrier=v end end end
 local notes={}
 for slot,r in ipairs(c.shader_layers)do if r.enabled~=false then
  local opacity=r.opacity or (c.panel_opacity or 1)*HUD.shader_layers.strengths[r.strength or 1]
  if carrier then
   local variant=can_get and HUD.texture_theme.material(carrier.texture_material,r.shader,can_get)
   if variant and variant~=carrier.texture_material and count<M.max_texture_images then
    local q={};for k,v in pairs(carrier)do q[k]=v end
    q.a=(c.visibility_alpha or 1)*opacity;q.c=carrier.coverage_mask and {96,106,101}or {255,255,255}
    q.texture_layers=nil;q.texture_theme_shader=r.shader;q.texture_theme=false
    q.shader_layer=r;q.texture_layer=frame.split_hud and (40+slot)or (50+slot*.08);q.shader_alpha_masked=true
    q.texture_slot=count+1 -- Each layer owns independent scale/time uniforms.
    out[#out+1]=q;count=count+1
   else notes[#notes+1]='Layer '..slot..': texture-alpha material unavailable or image budget reached' end
  else
   local masks=frame.shader_mask or {{0,0,1,1}}
   for _,box in ipairs(masks)do out[#out+1]={type='rect',x=frame.x+frame.w*box[1],y=frame.y+frame.h*(1-box[2]-box[4]),w=frame.w*box[3],h=frame.h*box[4],c={96,106,101},a=opacity,shader_layer=r,shader_slot=slot}end
  end
 end end
 M.shader_layer_status=M.shader_layer_status or {};M.shader_layer_status[resource or 'preview']=#notes>0 and table.concat(notes,'; ')or nil
 return out
end

function M.expand_texture_layers(commands)
    local out,slots={},0
    local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
    local function emit(v)
        -- Keep an invisible backing as shader coverage metadata. Dropping it
        -- at zero opacity would make independent layers adopt the face atlas.
        if v.visible==false or ((v.a or 1)<=0 and not(v.coverage_mask and v.a==0)) then return end
        slots=slots+1;assert(slots<=M.max_texture_images,'too many visible texture images per panel')
        local q={};for k,value in pairs(v)do q[k]=value end
        q.texture_layers=nil;q.texture_slot=slots;q.a=q.a or 1;q.c=q.c or {255,255,255}
        if q.atlas_rect then local r=q.atlas_rect;for i=1,4 do assert(finite(r[i]),'invalid atlas coordinate')end;assert(r[1]>=0 and r[2]>=0 and r[3]>0 and r[4]>0 and r[1]+r[3]<=1+1e-9 and r[2]+r[4]<=1+1e-9,'atlas rectangle outside image')end
        assert(type(q.texture_material)=='string' and type(q.texture_resource)=='string','texture layer requires material and resource')
        assert(finite(q.x) and finite(q.y) and finite(q.w) and finite(q.h) and q.w>0 and q.h>0,'invalid texture layer rectangle')
        assert(finite(q.a) and q.a<=1,'invalid texture layer alpha')
        q.texture_layer=q.texture_layer or (49+(slots-1)*.1)
        assert(finite(q.texture_layer) and math.abs(q.texture_layer)<=8192,'invalid texture layer order')
        for i=1,3 do assert(finite(q.c[i]) and q.c[i]>=0 and q.c[i]<=255,'invalid texture layer tint')end
        out[#out+1]=q
    end
    for _,v in ipairs(commands)do
        if v.type~='texture' then out[#out+1]=v
        else
            emit(v)
            assert(not v.texture_layers or #v.texture_layers<=8,'too many texture layers')
            for _,layer in ipairs(v.texture_layers or {})do
                if layer.visible~=false then
                    local r=layer.rect or {0,0,1,1}
                    for i=1,4 do assert(finite(r[i]),'invalid normalized texture rectangle')end
                    local q={type='texture',x=v.x+r[1]*v.w,y=v.y+r[2]*v.h,w=r[3]*v.w,h=r[4]*v.h,
                        texture_material=layer.material or v.texture_material,texture_resource=layer.texture or v.texture_resource,
                        a=(v.a or 1)*(layer.alpha or 1),c=layer.tint or v.c,texture_layer=layer.order,
                        fold_child=v.fold_child,texture_theme=layer.theme,atlas_rect=layer.atlas_rect}
                    q.spatial_plane,q.spatial_depth=v.spatial_plane,v.spatial_depth
                    if layer.theme==nil then q.texture_theme=v.texture_theme end
                    emit(q)
                end
            end
        end
    end
    return out
end
-- Compose an atlas subrectangle with the existing perspective homography.
-- Coordinates use top-left texture UVs: {u, v, width, height}.
function M.atlas_rows(rows,rect)
    if not rect then return rows end
    assert(type(rect)=='table','atlas rectangle required')
    for i=1,4 do local n=rect[i];assert(type(n)=='number' and n==n and math.abs(n)<math.huge,'invalid atlas coordinate')end
    local u,v,w,h=rect[1],rect[2],rect[3],rect[4]
    assert(u>=0 and v>=0 and w>0 and h>0 and u+w<=1+1e-9 and v+h<=1+1e-9,'atlas rectangle outside image')
    local result={};for i=1,#rows do result[i]=rows[i]end
    for i=1,3 do
        result[i]=w*rows[i]+u*rows[i+6]
        result[i+3]=h*rows[i+3]+v*rows[i+6]
    end
    return result
end
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
-- Split pods share one authored coordinate system and the existing planar
-- projection machinery, while their origins sit at distinct weapon-local depths.
function M.spatial_origin(m,at,depth)
    assert(finite(depth),'invalid spatial HUD depth')
    return {x=at.x-m[5]*depth/1000,y=at.y-m[6]*depth/1000,z=at.z-m[7]*depth/1000}
end
function M.spatial_groups(commands)
    local frame=commands[1]
    if not frame or not frame.split_hud then return nil end
    local groups={};local names={'main','reserve','context','status'};local allowed={}
    for _,name in ipairs(names)do allowed[name]=true end
    for index,v in ipairs(commands)do
        if index~=1 and not v.fold_child then
            local name=v.spatial_plane or 'main';assert(allowed[name],'invalid spatial HUD plane')
            local group=groups[name]
            if not group then group={name=name,commands={},depth=nil};groups[name]=group end
            if v.spatial_depth~=nil then
                assert(finite(v.spatial_depth),'invalid spatial HUD depth')
                assert(group.depth==nil or math.abs(group.depth-v.spatial_depth)<1e-7,'inconsistent spatial HUD depth')
                group.depth=v.spatial_depth
            end
            group.commands[#group.commands+1]=v
        end
    end
    local ordered={}
    for _,name in ipairs(names)do
        local group=groups[name]
        if group then
            group.depth=group.depth or 0
            local metadata={};for k,v in pairs(frame)do metadata[k]=v end
            metadata.a=0;metadata.spatial_plane=name;metadata.spatial_depth=group.depth;metadata.spatial_metadata=true
            table.insert(group.commands,1,metadata);ordered[#ordered+1]=group
        end
    end
    return ordered
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
-- Numeric Lua data only: native vectors and matrices remain frame-local.
function M.glyph_plan(text,x,y,size,face,uv)
    local plan={}
    for i=1,#text do
        local code=text:byte(i)
        local metric=assert(face.glyphs[code] or face.glyphs[63])
        local coords=assert(uv[code] or uv[63])
        local left,bottom=metric[2]*size,metric[3]*size
        local span,height=(metric[4]-metric[2])*size,(metric[5]-metric[3])*size
        if span>0 and height>0 then
            plan[#plan+1]={code=code,coords=coords,x=x+left,right=x+left+span,
                bottom=y+bottom,middle=y+bottom+height*.5,top=y+bottom+height}
        end
        x=x+metric[1]*size
    end
    return plan
end
-- Keep numeric projection in one Lua loop, separate from native GUI calls.
-- This lets LuaJIT trace the arithmetic across a complete label; no frame or
-- native transform is retained, only reusable numeric output slots.
function M.project_glyph_plan(plan,plane,width,height)
    local project=plane.project_values
    for _,g in ipairs(plan)do
        local bx,by=project(g.x,g.bottom)
        local mx,my=project(g.x,g.middle)
        local tx,ty=project(g.x,g.top)
        local rx,ry=project(g.right,g.bottom)
        local sx,sy=project(g.right,g.middle)
        local out=g.projected
        if not out then out={{},{}};g.projected=out end
        local a,b=out[1],out[2]
        a.visible=bx~=nil and rx~=nil and mx~=nil
        b.visible=mx~=nil and sx~=nil and tx~=nil
        if a.visible then a[1],a[2],a[3],a[4],a[5],a[6]=bx*width,by*height,rx*width,ry*height,mx*width,my*height end
        if b.visible then b[1],b[2],b[3],b[4],b[5],b[6]=mx*width,my*height,sx*width,sy*height,tx*width,ty*height end
    end
end
-- Pure command preparation completes before touching native GUI ownership.
function M.prepare_commands(commands,p,c,can_get)
    assert(type(commands)=='table' and commands[1],'HUD commands missing frame')
    c=HUD.config.texture_policy(c)
    commands=HUD.world_style.prepare(commands,p,c)
    if c.style_3d=='hologram' then
        for _,v in ipairs(commands)do if v.type=='panel'then v.a=math.min(1,v.a/.18)end end
    end
    local m,at=M.panel_pose(p,c,commands)
    if c.texture_art_trial and not (commands[1] and commands[1].atlas_frame) then commands=HUD.texture_art.prepare(commands,p.resource_hex,can_get,HUD.texture_art_assets,c.texture_art_variant)end
    commands=M.expand_shader_layers(M.expand_texture_layers(commands),c,can_get,p.resource_hex)
    for _,v in ipairs(commands)do
        assert(type(v.x)=='number' and v.x==v.x and math.abs(v.x)<math.huge and type(v.y)=='number' and v.y==v.y and math.abs(v.y)<math.huge,'invalid HUD coordinates')
        if v.spatial_depth~=nil then assert(finite(v.spatial_depth),'invalid spatial HUD depth')end
        if v.spatial_plane~=nil then assert(v.spatial_plane=='main'or v.spatial_plane=='reserve'or v.spatial_plane=='context'or v.spatial_plane=='status','invalid spatial HUD plane')end
        if v.type=='text' then assert(HUD.native_font_data.faces[v.font or 'bigblue'] and HUD.native_font_uv[v.font or 'bigblue'],'HUD font unavailable')end
    end
    return commands,m,at
end
function M.new(sr,log,hot_panel_art)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local prepared_cache,partition_cache
    local fill='mods/dbf_hud/materials/screen_hud_fill'
    local dither='mods/dbf_hud/materials/scythe_dither_fill';local dither_available
    local panel_effects={['11c27d3babb38956']='mods/dbf_hud/materials/lab_brushed_steel',['a6a735accb4a327f']='mods/dbf_hud/materials/lab_brushed_steel',['2152d5147b0ac418']='mods/dbf_hud/materials/lab_gunmetal',['89c5493e08ca4207']='mods/dbf_hud/materials/lab_brushed_steel',['4d58c77087b774c5']='mods/dbf_hud/materials/lab_ceramic',['cdf28be026bb7d84']='mods/dbf_hud/materials/lab_crt_scan',['e8d5f49ad7780e54']='mods/dbf_hud/materials/lab_glass_sheen'};local effect_availability={};local shader_submitted={}
    local shader_materials={};for _,entry in ipairs(HUD.shader_catalog)do shader_materials[entry.id]=entry.material end
    local function panel_material(v,weapon,c)
        local selected,name
        if v.shader_layer then selected=v.shader_layer.shader;name=shader_materials[selected] and shader_materials[selected]:gsub('/lab_','/mapped_')
        elseif v.type=='panel' and (not v.frosted or (c.theme_shader and c.theme_shader~='auto' and c.theme_shader~='none')) then
            selected=c.theme_shader or 'auto';name=selected=='auto' and panel_effects[weapon] or shader_materials[selected]
        elseif v.df_effect_sweep or v.scanline_layer or v.effect_shader_band then
            selected=c.effect_shader or 'none';name=selected=='auto' and panel_effects[weapon] or shader_materials[selected]
        end
        if not name then return nil end
        if effect_availability[name]==nil then effect_availability[name]=A.can_get('material',name)==true;log('HUD_SHADER material='..name..' available='..tostring(effect_availability[name])) end
        return effect_availability[name] and name or nil
    end

    -- Material state belongs to its GUI. Never retain handles after GUI destruction.
    local material_states={}
    local function destroy_gui(w,g)
        material_states[g]=nil
        W.destroy_gui(w,g)
    end
    local function material_state(g,name)
        local states=material_states[g]
        if not states then states={};material_states[g]=states end
        local state=states[name]
        if not state then
            assert(A.can_get('material',name),'screen scene font material missing: '..name)
            state={handle=assert(G.material(g,name),'screen scene material unavailable'),values={}}
            states[name]=state
        end
        return state
    end
    local function scalar(state,key,value)
        if state.values[key]~=value then
            sr.Material.set_scalar(state.handle,key,value);state.values[key]=value
        end
    end
    local function vector(state,key,x,y,z,w)
        local old=state.values[key]
        if not old or old[1]~=x or old[2]~=y or old[3]~=z or old[4]~=w then
            sr.Material.set_vector4(state.handle,key,sr.Vector4(x,y,z,w))
            if not old then old={};state.values[key]=old end
            old[1],old[2],old[3],old[4]=x,y,z,w
        end
    end
    local effect_guis={};local texture_guis={};local shader_guis={};local spatial_guis={}
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
        prepared_cache=nil
        partition_cache=nil
        if gui and live(world) then
            for _,layers in pairs(texture_guis)do for _,layer_gui in pairs(layers)do destroy_gui(world,layer_gui)end end
            for _,layers in pairs(shader_guis)do for _,layer_gui in pairs(layers)do destroy_gui(world,layer_gui)end end
            for _,effect_gui in pairs(effect_guis) do destroy_gui(world,effect_gui) end;effect_guis={}
            if child_gui then destroy_gui(world,child_gui) end
            if atlas_gui then destroy_gui(world,atlas_gui) end
            for _,spatial_gui in pairs(spatial_guis)do destroy_gui(world,spatial_gui)end
            destroy_gui(world,gui)
        end
        texture_guis={};shader_guis={};spatial_guis={};material_states={}
        released=released+#ids;for _,pool in pairs(glyphs) do released=released+#pool.ids end;glyphs={};gui,child_gui,world,atlas_gui=nil,nil,nil,nil
        for i=#ids,1,-1 do recycle(ids[i]);ids[i]=nil end
    end
    local function draw(p,c,commands,camera,fov,width,height,near,m,at)
        local native_projection=type(c.native_panel_projector)=='function'
        if not p or (not native_projection and not camera) or not A.can_get or not A.can_get('material',fill) then self.release();return false end
        if native_projection and (not finite(width) or not finite(height) or width<=0 or height<=0 or
            type(HUD.projection.native_panel_inverse)~='function') then return false end
        assert(type(G.triangle)=='function' and type(G.destroy_triangle)=='function','screen triangle API unavailable')
        assert(type(G.material)=='function' and sr.Material and type(sr.Material.set_scalar)=='function','material parameters unavailable')
        if dither_available==nil then dither_available=A.can_get('material',dither)==true;log('SCYTHE_DITHER material_available='..tostring(dither_available)) end
        local target;local main=A.main_world()
        for _,v in pairs(A.worlds() or {}) do if v~=main then target=v;break end end
        if not target then self.release();return false end
        if gui and (world~=target or not live(world)) then self.release() end
        if not gui then world=target;gui=assert(W.create_screen_gui(world,'scale',1,1),'screen scene GUI missing') end
        clear()
        for _,pool in pairs(glyphs) do pool.used=0 end
        -- Temporary zoom demo: retain the widest observed first-person FOV per weapon.
        if not native_projection and c.first_person_zoom_demo and fov then
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
        local glyph_uv_cache={} -- Native vectors live only for this draw callback.
        local immutable=prepared_cache and prepared_cache.commands==commands
        local partition=immutable and partition_cache and partition_cache.commands==commands and partition_cache
        if not partition then
            local body,fold={},{}
            for _,v in ipairs(commands)do local list=v.fold_child and fold or body;list[#list+1]=v end
            partition={commands=commands,body=body,fold=fold,spatial=M.spatial_groups(body),text={}}
            partition_cache=immutable and partition or nil
        end
        local body,fold=partition.body,partition.fold
        -- First-person surfaces can sit closer than the world camera near plane.
        if first then log('SCREEN_FONT_API bitmap='..type(G.bitmap_3d_uv)..' destroy='..type(G.destroy_bitmap_3d)) end
        local hud_near=p.first_person and math.min(near or .05,.005) or (near or .05)
        local project_snapshot;local native_points=0
        if native_projection then
            if not finite(hud_near) or hud_near<0 then return false end
            project_snapshot=function(x,y,z)
                if not finite(x) or not finite(y) or not finite(z) then return nil end
                native_points=native_points+1
                local ok,point=pcall(c.native_panel_projector,x,y,z)
                if not ok or type(point)~='table' or not finite(point.x) or not finite(point.y) or
                    math.abs(point.x)>1e7 or math.abs(point.y)>1e7 or not finite(point.depth) or
                    point.depth<=math.max(hud_near,.0001) then return nil end
                return point -- Native callback returns normalized GUI-up coordinates.
            end
        else project_snapshot=HUD.projection.projector(camera,fov,width/height,hud_near) end
        local function render(list,axes,origin,draw_gui,spatial)
            local plane;local frame
            for _,entry in ipairs(list)do if entry.type=='panel'and entry.w>0 and entry.h>0 then frame=entry;break end end
            if native_projection then
                if frame then
                    local points={}
                    for i,corner in ipairs({{frame.x,frame.y+frame.h},{frame.x+frame.w,frame.y+frame.h},{frame.x+frame.w,frame.y},{frame.x,frame.y}})do
                        local point=project_snapshot(M.point(axes,origin,corner[1],corner[2]))
                        if not point then points=nil;break end
                        points[i]={x=point.x,y=1-point.y,depth=point.depth}
                    end
                    if points then plane=HUD.projection.native_panel_snapshot(frame,points,hud_near)end
                end
            end
            local function local_project(x,y)
                if plane then return plane.project(x,y)end
                return project_snapshot(M.point(axes,origin,x,y))
            end
            local depth,enabled
            if native_projection then
                depth=finite(c.world_texture_depth) and c.world_texture_depth>0 and c.world_texture_depth or 0
                if spatial and plane and frame then
                    local center=plane.project(frame.x+frame.w/2,frame.y+frame.h/2)
                    if center and finite(center.depth)and center.depth>hud_near then depth=center.depth end
                end
                enabled=c.occlusion_mode~='gui' and depth>0 and 1 or 0
            else
                local dx,dy,dz=origin.x-camera[13],origin.y-camera[14],origin.z-camera[15]
                depth=math.max(dx*camera[5]+dy*camera[6]+dz*camera[7],hud_near)
                enabled=c.occlusion_mode~='gui' and 1 or 0
            end
            if first and list[1] then
                local panel=list[1];local depths={}
                for _,corner in ipairs({{panel.x,panel.y},{panel.x+panel.w,panel.y},{panel.x+panel.w,panel.y+panel.h},{panel.x,panel.y+panel.h}}) do
                    if native_projection then local point=local_project(corner[1],corner[2]);depths[#depths+1]=point and point.depth or -1
                    else local wx,wy,wz=M.point(axes,origin,corner[1],corner[2]);depths[#depths+1]=(wx-camera[13])*camera[5]+(wy-camera[14])*camera[6]+(wz-camera[15])*camera[7] end
                end
                log(string.format('SCREEN_CLIP near=%.6f enabled=%d corners=%.6f,%.6f,%.6f,%.6f',hud_near,enabled,unpack(depths)))
            end
            -- One panel coordinate system per GUI/pose, shared by its shader materials.
            -- Child folds already use a separate GUI and render pose.
            local function panel_rows(x,y,w,h)
                if native_projection then
                    if plane then return plane.image_rows(x,y,w,h)end
                    local points={}
                    for i,corner in ipairs({{x,y+h},{x+w,y+h},{x+w,y},{x,y}}) do
                        local point=project_snapshot(M.point(axes,origin,corner[1],corner[2]))
                        if not point then return nil end
                        points[i]={x=point.x,y=1-point.y} -- D3D screen UVs are downwards.
                    end
                    return HUD.projection.native_panel_inverse(points)
                end
                local wx,wy,wz=M.point(axes,origin,x,y+h)
                local rx,ry,rz=M.point(axes,origin,x+w,y+h)
                local bx,by,bz=M.point(axes,origin,x,y)
                local rows={HUD.projection.panel_inverse(camera,fov,width/height,wx,wy,wz,rx-wx,ry-wy,rz-wz,bx-wx,by-wy,bz-wz)}
                return rows[1] and rows or nil
            end
            local mapping_rows,mapping_checked
            local edge_mask,edge_material,edge_box
            for _,entry in ipairs(list)do
                if entry.type=='panel'and (entry.hud_texture_primary or entry.split_hud) and entry.edge_mask_resource and type(entry.edge_mask_material)=='string'and
                    hot_panel_art and hot_panel_art.resource(entry.edge_mask_resource)then
                    edge_mask,edge_material,edge_box=entry.edge_mask_resource,entry.edge_mask_material,entry.edge_mask_box;break
                end
            end
            local function panel_mapping()
                if mapping_checked then return mapping_rows end
                mapping_checked=true
                local frame
                for _,entry in ipairs(list) do if entry.type=='panel' then frame=entry;break end end
                if not frame or frame.w<=0 or frame.h<=0 then return nil end
                mapping_rows=panel_rows(frame.x,frame.y,frame.w,frame.h)
                return mapping_rows
            end
            local edge_rows,edge_checked
            local function decoration_mapping()
                if not edge_box then return panel_mapping()end
                if edge_checked then return edge_rows end
                edge_checked=true
                if finite(edge_box.x)and finite(edge_box.y)and finite(edge_box.w)and finite(edge_box.h)and edge_box.w>0 and edge_box.h>0 then
                    edge_rows=panel_rows(edge_box.x,edge_box.y,edge_box.w,edge_box.h)
                end
                return edge_rows
            end
            local materials={}
            local function role_gui(role)
                if type(role)=='string' and role:match('^shader:%d+$')then
                    local slot=tonumber(role:match('%d+'));assert(slot>=1 and slot<=4,'invalid shader slot');shader_guis[draw_gui]=shader_guis[draw_gui] or {};local layers=shader_guis[draw_gui];layers[slot]=layers[slot] or assert(W.create_screen_gui(world,'scale',1,1),'shader layer GUI missing');return layers[slot]
                end
                if type(role)=='string' and role:match('^texture:%d+$')then
                    local slot=tonumber(role:match('%d+'));assert(slot>=1 and slot<=M.max_texture_images,'invalid texture slot')
                    texture_guis[draw_gui]=texture_guis[draw_gui] or {}
                    local layers=texture_guis[draw_gui]
                    layers[slot]=layers[slot] or assert(W.create_screen_gui(world,'scale',1,1),'screen texture GUI missing')
                    return layers[slot]
                end
                if role~='effect' then return draw_gui end
                effect_guis[draw_gui]=effect_guis[draw_gui] or assert(W.create_screen_gui(world,'scale',1,1),'screen effect GUI missing')
                return effect_guis[draw_gui]
            end
            local function material(name,texture,role,art_rows,art_params)
                local cache_key=(role or 'panel')..':'..name
                if not materials[cache_key] then
                    local state=material_state(role_gui(role),name)
                    local hot=art_rows and hot_panel_art and hot_panel_art.resource(texture)
                    local binding=hot or texture
                    local binding_kind=hot and 'resource' or 'texture'
                    local binding_slot=art_rows and 'artwork_texture' or 'diffuse_map'
                    if binding and (state.binding~=binding or state.binding_kind~=binding_kind or state.binding_slot~=binding_slot) then
                        sr.Material[hot and 'set_resource' or 'set_texture'](state.handle,binding_slot,binding)
                        state.binding,state.binding_kind,state.binding_slot=binding,binding_kind,binding_slot
                    end
                    scalar(state,'threshold_fade',depth)
                    scalar(state,'scissor_mode',enabled)
                    if art_rows then
                        if name:find('_texture_theme_',1,true)then
                            local seconds,animated=HUD.config.shader_animation_values(c,nil,c.style_clock)
                            local size=c.theme_shader_scale
                            if art_params then size=art_params.pattern_size or HUD.shader_layers.scales[art_params.scale or 2];seconds=(c.style_clock or 0)*(art_params.speed or 1);animated=art_params.animate and 1 or 0 end
                            scalar(state,'scissor_mode',HUD.texture_theme.parameters(enabled,size,seconds,animated))
                        end
                        vector(state,'scissor_rect',art_rows[1],art_rows[2],art_rows[3],0)
                        vector(state,'atlas_scissor',art_rows[4],art_rows[5],art_rows[6],0)
                        vector(state,'clip_box',art_rows[7],art_rows[8],art_rows[9],0)
                    elseif name:find('/mapped_',1,true) then
                        local rows=assert(panel_mapping(),'panel shader mapping unavailable')
                        local slot=type(role)=='string' and tonumber(role:match('^shader:(%d+)$'));local layer=slot and c.shader_layers and c.shader_layers[slot]
                        local scale=layer and (layer.pattern_size or HUD.shader_layers.scales[layer.scale]) or tonumber(c[role=='effect' and 'effect_shader_scale' or 'theme_shader_scale']) or 1
                        if scale~=scale then scale=1 end;scale=math.max(.25,math.min(4,scale))
                        local seconds,animated=HUD.config.shader_animation_values(c,role,c.style_clock)
                        if layer then seconds=(c.style_clock or 0)*(layer.speed or 1);animated=layer.animate and 1 or 0 end
                        vector(state,'scissor_rect',rows[1]/scale,rows[2]/scale,rows[3]/scale,seconds)
                        vector(state,'atlas_scissor',rows[4]/scale,rows[5]/scale,rows[6]/scale,animated)
                        vector(state,'clip_box',rows[7],rows[8],rows[9],0)
                    end
                    materials[cache_key]=true
                end
                return name
            end
            local function project(x,y)
                local point=local_project(x,y)
                if point then return nil,{x=point.x*width,y=point.y*height} end
            end
            local function glyph_project(x,y)
                local nx,ny
                if plane and plane.project_values then nx,ny=plane.project_values(x,y)
                else local point=local_project(x,y);if point then nx,ny=point.x,point.y end end
                if nx then return nx*width,ny*height end
            end
            -- This scratch quad is consumed synchronously by clipping; never stored by native drawing.
            local corners={{},{},{},{}}
            local clipping_scratch={camera={{},{},{},{}},result={{},{},{},{}}}
            local native_polygon={{},{},{},{}}
            local function vertex(p)return sr.Vector3(p.x*width,0,p.y*height) end
            local function quad(x,y,w,h,name,color,layer,uv,texture,points,effect,role,art_rows,art_params)
                if w<=0 or h<=0 then return end
                for i=1,4 do
                    local right=i==2 or i==3;local upper=i>=3
                    local lx,ly=points and points[i][1] or (right and x+w or x),points and points[i][2] or (upper and y+h or y)
                    local corner=corners[i];corner.lx,corner.ly=lx,ly
                    if not native_projection then corner.x,corner.y,corner.z=M.point(axes,origin,lx,ly)end
                    corner.s=uv and (right and uv[3] or uv[1]) or 0
                    corner.v=uv and (upper and uv[2] or uv[4]) or 0
                end
                local polygon
                if native_projection then
                    polygon=native_polygon
                    for i,corner in ipairs(corners) do
                        local point=local_project(corner.lx,corner.ly)
                        if not point then polygon={};break end
                        local result=polygon[i];result.x,result.y,result.s,result.v=point.x,point.y,corner.s,corner.v
                    end
                else polygon=HUD.projection.clip_polygon(camera,corners,fov,width/height,hud_near,clipping_scratch) end
                if effect then scan_generated=scan_generated+1 end
                if #polygon<3 then if effect then scan_clipped=scan_clipped+1 end;return end
                if effect and #polygon==4 and not self.scanline_probe then
                    local a,b,d=polygon[1],polygon[2],polygon[4]
                    local dx,dy=(b.x-a.x)*width,(b.y-a.y)*height
                    local length=math.sqrt(dx*dx+dy*dy)
                    local thickness=length>0 and math.abs(dx*(d.y-a.y)*height-dy*(d.x-a.x)*width)/length or 0
                    log(string.format('SCANLINE_PIXEL_PROBE projected_length_px=%.3f projected_thickness_px=%.4f',length,thickness));self.scanline_probe=true
                end
                name=material(name,texture,role,art_rows,art_params)
                local primitive_gui=role_gui(role)
                for i=2,#polygon-1 do
                    local a,b,d=polygon[1],polygon[i],polygon[i+1]
                    local id=G.triangle(primitive_gui,vertex(a),vertex(b),vertex(d),layer,color,name,
                        uv and sr.Vector2(a.s,a.v) or nil,uv and sr.Vector2(b.s,b.v) or nil,uv and sr.Vector2(d.s,d.v) or nil)
                    track(primitive_gui,id)
                    if id and (name:find('/lab_',1,true) or name:find('/local_',1,true) or name:find('/mapped_',1,true) or name:find('/texture_liberator_',1,true) or name:find('/texture_bespoke_',1,true) or name:find('/faithful_',1,true)) and not shader_submitted[name] then shader_submitted[name]=true;log('HUD_SHADER_SUBMITTED material='..name..' weapon='..tostring(p.resource_hex)..' triangle='..tostring(id)) end
                    if effect and id then scan_emitted=scan_emitted+1 end
                end
            end
            -- Native temporaries are shared only within this synchronous render call.
            local glyph_forward,glyph_zero,glyph_extent
            for _,v in ipairs(list) do
                local function color(alpha,ink)ink=ink or v.c;if v.texture_color_linear then ink=HUD.config.native_rgb(ink)end;return sr.Color(math.floor(v.a*alpha*255+.5),ink[1],ink[2],ink[3]) end
                if v.type=='texture' and v.a>0 then
                    local rows=panel_rows(v.x,v.y,v.w,v.h)
                    if rows then rows=M.atlas_rows(rows,v.atlas_rect) end
                    local artwork_material=HUD.texture_theme.material(v.texture_material,v.texture_theme_shader or (v.texture_theme==false and 'none' or c.theme_shader),A.can_get)
                    if rows then for _,box in ipairs(M.feather_boxes(v.w,v.h,v.texture_feather_x,v.texture_feather_y))do
                        quad(v.x+box[1],v.y+box[2],box[3],box[4],artwork_material,color(box[5]),v.texture_layer or 49,nil,v.texture_resource,nil,nil,'texture:'..v.texture_slot,rows,v.shader_layer)
                    end end
                end
                if v.type=='rect' and v.decoration and not v.charge_meter and edge_mask and not c.profile_skip_geometry then
                    -- The shared decoration rectangles use one panel-wide alpha
                    -- map on the existing root GUI; their geometry/color stay intact.
                    local rows=decoration_mapping()
                    if rows then quad(v.x,v.y,v.w,v.h,edge_material,color(1),50,nil,edge_mask,v.quad,nil,'decoration',rows)
                    else quad(v.x,v.y,v.w,v.h,fill,color(1),50,nil,nil,v.quad)end
                elseif (v.type=='rect' or v.type=='panel') and not v.spatial_metadata and not c.profile_skip_geometry then
                    local selected_material=not v.contrast_backing and panel_material(v,p.resource_hex,c)
                    local panel_uv
                    if selected_material and selected_material:find("/lab_",1,true) then
                        local mapped_material=selected_material:gsub('/lab_','/mapped_')
                        if effect_availability[mapped_material]==nil then effect_availability[mapped_material]=A.can_get('material',mapped_material)==true end
                        if effect_availability[mapped_material] and panel_mapping() then selected_material=mapped_material end
                    end
                    local shader_ink=v.c
                    -- Multiplicative textures cannot produce detail from pure black.
                    -- Keep the saved palette intact; only explicit textured backdrops use a dim carrier.
                    if v.type=='panel' and selected_material and c.theme_shader~='auto' and math.max(v.c[1],v.c[2],v.c[3])<16 then shader_ink={48,48,48} end
                    if not v.shader_layer or selected_material then
                    quad(v.x,v.y,v.w,v.h,(p.resource_hex=='27ee1ed8f6fb6356' and v.heat_fill and dither_available) and dither or selected_material or fill,color(1,shader_ink),v.shader_layer and (50.1+v.shader_slot*.1) or v.type=='panel' and 48 or (v.scanline_layer and 50.5 or (v.fuel_marker_piece and 51 or 50)),panel_uv,nil,v.quad,v.df_effect_frame,v.shader_layer and ('shader:'..v.shader_slot) or (v.type~='panel' and selected_material and selected_material:find('/mapped_',1,true)) and 'effect' or nil)
                    end
                elseif v.type=='text' and not v.fuel_endpoint and not c.profile_skip_text then
                    local key=v.font or 'bigblue';local face=HUD.native_font_data.faces[key]
                    local uv=HUD.native_font_uv[key]
                    assert(face and uv,'native screen font atlas unavailable: '..key)
                    local size=v.size/(face.em or 48)
                    local name=face.clear:sub(1,-7)..'_scene'
                    local text=partition.text[v]
                    if not text or text.face~=face then text={face=face,parts=M.text_parts(v,face)};partition.text[v]=text end
                    for _,part in ipairs(text.parts) do
                        local x=v.x+part.dx
                        if G.bitmap_3d_uv and G.destroy_bitmap_3d and sr.Matrix4x4 and sr.Matrix4x4.from_axes then
                            material(name,face.font)
                            if not glyph_zero then glyph_forward=sr.Vector3(0,1,0);glyph_zero=sr.Vector3(0,0,0);glyph_extent=sr.Vector2(1,1)end
                            local ink=color(part.alpha,part.c)
                            local cached_uv=glyph_uv_cache[uv];if not cached_uv then cached_uv={};glyph_uv_cache[uv]=cached_uv end
                            local plan=part.glyph_plan
                            if not plan then plan=M.glyph_plan(part.text,x,v.y,size,face,uv);part.glyph_plan=plan end
                            local projected=plane and plane.project_values
                            if projected then M.project_glyph_plan(plan,plane,width,height)end
                            for _,glyph in ipairs(plan)do
                                local code,coords=glyph.code,glyph.coords
                                local next_x,next_y
                                -- Small atlas strips follow changing perspective across the glyph.
                                local strips=2
                                for strip=0,strips-1 do
                                    local low,high=strip/strips,(strip+1)/strips
                                    local bx,by,rx,ry,ux,uy
                                    if projected then
                                        local q=glyph.projected[strip+1]
                                        if q.visible then bx,by,rx,ry,ux,uy=q[1],q[2],q[3],q[4],q[5],q[6]end
                                    else
                                        bx,by=next_x,next_y
                                        if strip==0 then bx,by=glyph_project(glyph.x,glyph.bottom)end
                                        rx,ry=glyph_project(glyph.right,strip==0 and glyph.bottom or glyph.middle)
                                        ux,uy=glyph_project(glyph.x,strip==0 and glyph.middle or glyph.top)
                                        next_x,next_y=ux,uy
                                    end
                                    if bx and rx and ux then
                                        local transform
                                        if sr.Matrix4x4.from_elements then
                                            transform=sr.Matrix4x4.from_elements(rx-bx,0,ry-by,
                                                0,1,0,ux-bx,0,uy-by,bx,0,by)
                                        else
                                            transform=sr.Matrix4x4.from_axes(
                                                sr.Vector3(rx-bx,0,ry-by),glyph_forward,
                                                sr.Vector3(ux-bx,0,uy-by),sr.Vector3(bx,0,by))
                                        end
                                        local top=coords[4]+(coords[2]-coords[4])*high
                                        local bottom_uv=coords[4]+(coords[2]-coords[4])*low
                                        local glyph_uv=cached_uv[code];if not glyph_uv then glyph_uv={};cached_uv[code]=glyph_uv end
                                        local pair=glyph_uv[strip+1]
                                        if not pair then pair={sr.Vector2(coords[1],top),sr.Vector2(coords[3],bottom_uv)};glyph_uv[strip+1]=pair end
                                        local uv0,uv1=pair[1],pair[2]
                                        local pos,extent=glyph_zero,glyph_extent
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
        local spatial=partition.spatial;local used_spatial={}
        if spatial then
            for _,group in ipairs(spatial)do
                local draw_gui=gui
                if group.name~='main'then
                    draw_gui=spatial_guis[group.name]
                    if not draw_gui then draw_gui=assert(W.create_screen_gui(world,'scale',1,1),'spatial HUD GUI missing');spatial_guis[group.name]=draw_gui end
                    used_spatial[group.name]=true
                end
                render(group.commands,m,M.spatial_origin(m,at,group.depth),draw_gui,true)
            end
        else render(body,m,at,gui)end
        for name,spatial_gui in pairs(spatial_guis)do if not used_spatial[name]then
            if shader_guis[spatial_gui]then for _,layer_gui in pairs(shader_guis[spatial_gui])do destroy_gui(world,layer_gui)end;shader_guis[spatial_gui]=nil end
            if texture_guis[spatial_gui]then for _,layer_gui in pairs(texture_guis[spatial_gui])do destroy_gui(world,layer_gui)end;texture_guis[spatial_gui]=nil end
            if glyphs[spatial_gui]then released=released+#glyphs[spatial_gui].ids;glyphs[spatial_gui]=nil end
            if effect_guis[spatial_gui]then destroy_gui(world,effect_guis[spatial_gui]);effect_guis[spatial_gui]=nil end
            destroy_gui(world,spatial_gui);spatial_guis[name]=nil
        end end
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
            if shader_guis[child_gui]then for _,layer_gui in pairs(shader_guis[child_gui])do destroy_gui(world,layer_gui)end;shader_guis[child_gui]=nil end
            if texture_guis[child_gui]then for _,layer_gui in pairs(texture_guis[child_gui])do destroy_gui(world,layer_gui)end;texture_guis[child_gui]=nil end
            if glyphs[child_gui] then released=released+#glyphs[child_gui].ids;glyphs[child_gui]=nil end
            if effect_guis[child_gui] then destroy_gui(world,effect_guis[child_gui]);effect_guis[child_gui]=nil end
            destroy_gui(world,child_gui);child_gui=nil
        end
        for draw_gui,pool in pairs(glyphs) do
            for i=#pool.ids,pool.used+1,-1 do G.destroy_bitmap_3d(draw_gui,pool.ids[i]);pool.ids[i]=nil;destroyed=destroyed+1 end
        end
        if scan_generated>0 and not self.scanline_emission_logged then
            log(string.format('SCANLINE_EMISSION strips=%d native_triangles=%d fully_clipped=%d separate_layer=50.5',scan_generated,scan_emitted,scan_clipped));self.scanline_emission_logged=true
        end
        created=created+#ids
        self.native_point_calls=native_points
        self.status='screen-projected scene-depth HUD'
        if first then
            if native_projection then log('SCREEN_PLANAR_SNAPSHOT native_points='..native_points..' commands='..#commands..' existing_renderer=true')end
            log('SCREEN_SCENE HUD submitted; native atlas glyphs; saved mounts retained; live validation pending');first=false
        end
        return true
    end
    function self.draw(p,c,commands,camera,fov,width,height,near)
        if failed then return false end
        if not p or (not camera and type(c.native_panel_projector)~='function') then return false end
        local started=c.debug_hud_timing and os.clock()
        local cacheable=c.layout_cache_token==commands and c.style_3d=='standard'
        local prepared,ready,m,at
        if cacheable and prepared_cache and prepared_cache.input==commands and prepared_cache.first_person==p.first_person then
            ready=prepared_cache.commands
            prepared,m,at=pcall(M.panel_pose,p,c,ready)
        else
            prepared,ready,m,at=pcall(M.prepare_commands,commands,p,c,A.can_get)
            prepared_cache=prepared and cacheable and {input=commands,first_person=p.first_person,commands=ready}or nil
        end
        local prepare_done=started and os.clock()
        if not prepared then
            self.status='Command preparation rejected: '..tostring(ready)
            if self.command_error~=self.status then self.command_error=self.status;log('SCREEN_COMMAND_REJECTED '..self.status)end
            return false -- No native calls; valid later frames remain usable.
        end
        self.command_error=nil
        local ok,result=pcall(draw,p,c,ready,camera,fov,width,height,near,m,at)
        if started then
            local stats=self.costs or {frames=0,prepare=0,native=0};self.costs=stats
            stats.frames=stats.frames+1;stats.prepare=stats.prepare+prepare_done-started;stats.native=stats.native+os.clock()-prepare_done
        end
        if not ok then failed=true;self.status=tostring(result);log('SCREEN_SCENE failure: '..self.status);pcall(self.release);return false end
        return result
    end
    if hot_panel_art and hot_panel_art.register_consumer then
        hot_panel_art.register_consumer(self,function()self.release();return true end)
    end
    return self
end
return M
