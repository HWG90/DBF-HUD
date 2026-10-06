-- Approved upright retro sprite atlas. All dynamic lettering samples cells.
local M={atlas=HUD.df_retro_spec.resource,backing='mods/dbf_hud/textures/dbs2_retro_backing_v1'}
local material='mods/dbf_hud/materials/mechanical_72170a55a1f37ff1'
local spec=HUD.df_retro_spec;local w,h=128,128*988/600
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.ready(resource)return resource(M.atlas)~=nil and resource(M.backing)~=nil end
function M.compose(m,x,y,s,opacity,cfg,resource)
    cfg=HUD.config.texture_policy(cfg)
    if cfg.texture_art_trial==false or cfg.texture_art_variant=='original' or not M.ready(resource) then return nil end
    local out={{type='panel',x=x,y=y,w=w*s,h=h*s,c={0,0,0},a=0,frosted=false,atlas_frame=true,world_reference_width=256*s,df_retro=true}}
    local k=128/600;local order=49
    local function image(resource,uv,px,py,pw,ph,alpha,color,region)
        out[#out+1]={type='texture',x=x+px*k*s,y=y+(h-(py+ph)*k)*s,w=pw*k*s,h=ph*k*s,
            c=color or {255,255,255},a=opacity*alpha,texture_resource=resource,texture_material=material,
            atlas_rect=uv,texture_theme=false,texture_layer=order,df_retro=true,texture_color_linear=false,atlas_region=region,
            texture_feather_x=region and 6/spec.regions[region].pixels[3] or nil,
            texture_feather_y=region and 6/spec.regions[region].pixels[4] or nil}
        order=order+.01
    end
    local function cell(name,px,py,pw,ph,alpha)
        image(M.atlas,spec.regions[name].uv,px,py,pw,ph,alpha or 1,nil,name)
    end
    -- Mask is from the original 1536x1024 layout; atlas v2 has different UVs.
    image(M.backing,{16/1536,12/1024,600/1536,988/1024},0,0,600,988,cfg.panel_opacity or .8,HUD.config.rgb(cfg.background_color))
    cell('frame',0,0,600,988)
    local n=finite(m.value) and m.value%1==0 and m.value>=0 and m.value<=2 and m.value or nil
    if n then
        local states=spec.state_contract[tostring(n)]
        for side=1,2 do cell(states[side],side==1 and 95 or 365,330,128,384,states[side]=='fired_shell' and .55 or 1)end
    end
    local ink_alpha=cfg.text_opacity or 1
    cell('reserve_label',70,777,100,35,ink_alpha);cell('shells_label',435,777,100,35,ink_alpha)
    if finite(m.reserve) and m.reserve>=0 and m.reserve<=100000 then
        local value=string.format('%03d',math.floor(m.reserve));local dw=math.min(35,140/#value);local left=300-#value*dw/2
        for i=1,#value do cell('digit_'..value:sub(i,i),left+(i-1)*dw,752,dw,55,ink_alpha)end
    end
    cell('semi',105,868,180,89,(m.fire_mode=='SEMI' and 1 or .3)*ink_alpha)
    cell('volley',315,868,180,89,(m.fire_mode=='VOLLEY' and 1 or .3)*ink_alpha)
    if m.fire_mode=='SEMI' or m.fire_mode=='VOLLEY' then cell('selector',m.fire_mode=='SEMI' and 174 or 384,840,42,35,ink_alpha)end
    local ticks=HUD.compass.ticks(m.compass_heading)
    if ticks then
        for _,tick in ipairs(ticks)do
            local tx=56+488*tick.position
            if tick.label and tick.position>.05 and tick.position<.95 then
                local total=#tick.label*24
                for i=1,#tick.label do cell('compass_'..tick.label:sub(i,i),tx-total/2+(i-1)*24,51,24,32,ink_alpha)end
            end
            out[#out+1]={type='rect',x=x+tx*k*s,y=y+(h-95*k)*s,w=k*s,h=(tick.label and 12 or 6)*k*s,c={223,216,177},a=opacity*ink_alpha}
        end
        cell('selector',288,88,24,20,ink_alpha)
    end
    return out
end
function M.primitive(m,x,y,s,opacity,cfg)
    local model={};for k,v in pairs(m)do model[k]=v end;model.heading=m.compass_heading
    local pw,ph=128*s,264*s
    local raw=HUD.df_retro_primitive.compose(model,0,0,pw,ph,opacity)
    local out={{type='panel',x=x,y=y,w=pw,h=ph,c={0,0,0},a=0,frosted=false,world_reference_width=256*s,df_retro=true}}
    for _,v in ipairs(raw)do
        if v.type=='rect' then
            v.y=y+ph-v.y-v.h
            if v.c[1]==37 and v.c[2]==44 and v.c[3]==40 then v.c=HUD.config.rgb(cfg.background_color);v.a=math.min(opacity,v.a*(cfg.panel_opacity or .8)/.52)end
        else
            local left,bottom,right,top=HUD.font.measure(v.text,v.size,cfg.font,true)
            if v.shell_center_x or v.center_x then v.x=(v.shell_center_x or v.center_x)-(left+right)/2 end
            v.y=y+ph-v.y-top;v.font=cfg.font;v.a=v.a*(cfg.text_opacity or 1)
        end
        v.x=x+v.x;v.df_retro=true;out[#out+1]=v
    end
    local reserve={};for _,v in ipairs(out)do if v.reserve_part then reserve[v.reserve_part]=v end end
    if reserve.label and reserve.value and reserve.unit then
        local parts={reserve.label,reserve.value,reserve.unit};local width=16*s;local metrics={}
        for i,v in ipairs(parts)do local l,b,r,t=HUD.font.measure(v.text,v.size,v.font,true);metrics[i]={l,b,r,t};width=width+r-l end
        local left=x+(pw-width)/2;local center=reserve.value.y+(metrics[2][2]+metrics[2][4])/2
        for i,v in ipairs(parts)do local m=metrics[i];v.x=left-m[1];v.y=center-(m[2]+m[4])/2;left=left+m[3]-m[1]+8*s end
    end
    HUD.layout.decorate(out,out[1],s,cfg,opacity)
    return out
end
return M
