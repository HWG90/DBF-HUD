-- Native art is presentation only. All numbers and warnings come from the model.
local M={}
local function count(n)
    return type(n)=='number' and n==n and n>=0 and n<=100000 and n%1==0 and n or nil
end
function M.fit(v,measure)
    local z=v.readout_zone
    for _=1,8 do
        local a,b,e,f=measure(v.text,v.size,v.font)
        local factor=math.min(1,z.w/math.max(.001,e-a),z.h/math.max(.001,f-b))
        if factor>=.99999 then v.x=z.cx-(a+e)/2;v.y=z.cy-(b+f)/2;return true end
        v.size=v.size*factor*.96
    end
    local a,b,e,f=measure(v.text,v.size,v.font)
    v.x=z.cx-(a+e)/2;v.y=z.cy-(b+f)/2
    return e-a<=z.w+1e-6 and f-b<=z.h+1e-6
end
function M.compose(fallback,m,x,y,s,opacity,cfg,clock,measure,available)
    local spec=HUD.bespoke_texture_specs[m.resource_hex]
    if not measure and HUD.font.supported(cfg.font) then measure=function(t,size)return HUD.font.measure(t,size,cfg.font) end end
    -- Faithful conversions auto-enable; redesigned studies require an explicit selection.
    if not spec or (spec.faithful~=true and cfg.texture_art_variant~='study') or cfg.texture_art_variant=='original' or cfg.texture_art_trial==false or cfg.anchor_mode~='world' or not measure or
        not available('material',spec.material) or not available('texture',spec.texture) then return fallback end
    local frame={type='panel',x=x,y=y,w=spec.w*s,h=spec.h*s,
        c=HUD.config.rgb(cfg.background_color),a=(cfg.panel_opacity or .8)*opacity,
        frosted=cfg.frosted,bespoke_texture_frame=true}
    local out={frame,{type='texture',x=x,y=y,w=frame.w,h=frame.h,c={255,255,255},a=opacity,
        texture_material=spec.material,texture_resource=spec.texture,texture_layer=49.03}}
    local loaded,capacity,reserve=count(m.value),count(m.capacity),count(m.reserve)
    local warn=m.warning==true or loaded==0
    local pulse=warn and (.65+.35*(.5+.5*math.sin((clock or 0)*(cfg.flash_hz or 4)*math.pi*2))) or 1
    local function text(str,key,size,ink,numeric)
        local region=spec.zones[key];if not region then return end
        local v={type='text',text=str,size=size*s,font=cfg.font,c=ink,a=opacity*(cfg.text_opacity or 1),
            numeric_display=numeric,texture_readout=true,readout_key=key,
            readout_zone={cx=x+region.cx*s,cy=y+region.cy*s,w=region.w*s,h=region.h*s}}
        if key=='count' then
            v.a=v.a*pulse
            if m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end
        if not M.fit(v,measure) then return false end
        out[#out+1]=v;return true
    end
    local digits=spec.key=='m7s' and '%03d' or '%02d'
    if not text(loaded and string.format(digits,loaded) or '---','count',32,
        warn and HUD.config.rgb(cfg.heat_red) or {226,237,235},true) then return fallback end
    text(spec.label..(spec.zones.capacity and '' or (' / '..(capacity and tostring(capacity) or '--'))),'title',9,{183,211,210})
    text(capacity and '/ '..tostring(capacity) or '/ --','capacity',8,{183,211,210})
    -- Reserve source/unit stays reader-owned. Translate only known equivalent units.
    local unit=m.reserve_kind
    if unit==nil or (spec.key=='spear' and unit=='PACK') or (spec.key=='m90a' and unit=='ROUNDS') or
        (spec.key=='plas39' and unit=='MAGS') then unit=spec.reserve_label end
    text((reserve and string.format('%02d',reserve) or '--')..' '..unit,'reserve',8,{211,223,219},true)
    if spec.zones.compass then
        local heading=m.compass_heading
        local valid=type(heading)=='number' and heading==heading and math.abs(heading)<math.huge
        text(valid and string.format('BRG %03d',math.floor(heading%360+.5)%360) or 'BRG ---','compass',7,{105,211,207})
    end
    -- Keep existing mode/attachment child panels, positioned below this new parent.
    -- Spear's old reserve child is represented by its native readout zone instead.
    if spec.key~='spear' then
        local old=fallback[1];local dx=frame.x+frame.w/2-old.x-old.w/2;local dy=frame.y-old.y
        for _,v in ipairs(fallback) do if v.child then
            local copy={};for k,val in pairs(v) do copy[k]=val end
            copy.x=copy.x+dx;copy.y=copy.y+dy;out[#out+1]=copy
        end end
    end
    -- Shared shader/effect controls remain active; artwork owns its perimeter.
    local effects={};for k,v in pairs(cfg) do effects[k]=v end;effects.decoration='none'
    return HUD.layout.finish_custom_panel(out,m,s,opacity,effects,clock)
end
return M

