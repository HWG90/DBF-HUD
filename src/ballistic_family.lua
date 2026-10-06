local M={specs=HUD.ballistic_family_specs,mask='mods/dbf_hud/textures/ballistic_family_coverage_v1'}
local material='mods/dbf_hud/materials/adjudicator_tall_v1'
local function number(v)return type(v)=='number'and v==v and v>=0 and v<=100000 and math.floor(v)or nil end
function M.ready(id,resource)
    return M.specs[id] and resource(M.mask)~=nil and resource('mods/dbf_hud/textures/ballistic_family_'..id)~=nil
end
function M.compose(m,x,y,s,opacity,cfg,resource)
    cfg=HUD.config.texture_policy(cfg);local spec=M.specs[m.resource_hex]
    if not spec or cfg.texture_art_trial==false or cfg.texture_art_variant~='faithful' or not M.ready(m.resource_hex,resource) then return nil end
    local w,h=148*s,148*640/520*s
    local out={{type='panel',x=x,y=y,w=w,h=h,a=0,c={0,0,0},frosted=false,atlas_frame=true,ballistic_family=true}}
    out[#out+1]={type='texture',x=x,y=y,w=w,h=h,c=HUD.config.rgb(cfg.background_color),a=opacity*(cfg.panel_opacity or .3),texture_material=material,texture_resource=M.mask,texture_theme=false,texture_layer=49,coverage_mask=true,ballistic_family=true}
    out[#out+1]={type='texture',x=x,y=y,w=w,h=h,c={255,255,255},a=opacity,texture_material=material,texture_resource='mods/dbf_hud/textures/ballistic_family_'..m.resource_hex,texture_theme=false,texture_layer=49.1,ballistic_family=true}
    local ink=HUD.config.rgb(cfg.text_color);local warning=m.warning and HUD.config.rgb(cfg.heat_red)or ink
    local function text(value,key,color)
        local z=spec.zones[key];if not z then return end
        local size=z[4]*h/.75;local l,b,r,t=HUD.font.measure(tostring(value),size,cfg.font,true)
        size=size*math.min(1,z[3]*w/math.max(.001,r-l),z[4]*h/math.max(.001,t-b));l,b,r,t=HUD.font.measure(tostring(value),size,cfg.font,true)
        out[#out+1]={type='text',text=tostring(value),font=cfg.font,size=size,x=x+(z[1]+z[3]/2)*w-(l+r)/2,y=y+(1-z[2]-z[4]/2)*h-(b+t)/2,c=color or ink,a=opacity*(cfg.text_opacity or 1),ballistic_live=true}
    end
    local loaded,capacity,reserve=number(m.value),number(m.capacity),number(m.reserve)
    text(loaded and tostring(loaded)or '--','count',warning);text(capacity and ('/ '..capacity)or '/ --','capacity')
    local unit=m.reserve_kind or 'RES';if unit=='ROUNDS' and spec.semantics.reserve:find('shells',1,true)then unit='SHELLS'end
    text(reserve and (reserve..' '..unit)or '-- RES','reserve')
    text(m.ammo_mode or m.fire_mode or '--','mode')
    local total='--'
    if spec.semantics.total=='remaining load only' and loaded then total=tostring(loaded)
    elseif spec.semantics.reserve=='magazine_units_from_wiki; confirmreaderunit' and m.reserve_kind=='MAGS' and m.kind=='magazine' and loaded and capacity and reserve then total='~'..(loaded+capacity*reserve)end
    text(total,'total')
    text(m.reloading==true and 'RELOADING'or m.chamber_rounds==1 and 'CHAMBERED'or (m.state=='EMPTY' or m.state=='SPENT')and m.state or '--','status')
    local g=spec.zones.gauge
    if g and type(m.fraction)=='number'and m.fraction==m.fraction and m.fraction>0 then out[#out+1]={type='rect',x=x+g[1]*w,y=y+(1-g[2]-g[4])*h,w=g[3]*w*math.max(0,math.min(1,m.fraction)),h=g[4]*h,c=warning,a=opacity}end
    local ticks,heading=HUD.compass.ticks(m.compass_heading);local z=spec.zones.compass
    if ticks and z then
        for _,tick in ipairs(ticks)do
            local tx=x+(z[1]+z[3]*tick.position)*w
            out[#out+1]={type='rect',x=tx,y=y+(1-z[2]-z[4]*.55)*h,w=.4*s,h=(tick.label and .23 or .12)*z[4]*h,c=ink,a=opacity}
            if tick.label and tick.position>.05 and tick.position<.95 then
                local size=z[4]*h*.30;local l,b,r,t=HUD.font.measure(tick.label,size,cfg.font,true)
                out[#out+1]={type='text',text=tick.label,font=cfg.font,size=size,x=tx-(l+r)/2,y=y+(1-z[2]-.15*z[4])*h-(b+t)/2,c=ink,a=opacity}
            end
        end
        out[#out+1]={type='rect',x=x+(z[1]+z[3]/2)*w,y=y+(1-z[2]-z[4])*h,w=s,h=z[4]*h*.3,c={230,198,112},a=opacity}
    end
    return out
end
return M
