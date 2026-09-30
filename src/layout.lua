-- Renderer-independent HUD; geometry uses bottom-left coordinates.
local M={}
function M.heat_color(fraction,clock,cfg)
    if fraction>=0.95 then return math.floor((clock or 0)*cfg.flash_hz*2)%2==0 and cfg.heat_red or cfg.heat_yellow end
    if fraction>=0.86 then return cfg.heat_red end
    if fraction>=0.75 then return cfg.heat_yellow end
    return cfg.heat_white
end
function M.compose(m,x,y,scale,opacity,cfg,clock,measure)
    cfg=cfg or HUD.config.defaults
    local pixel=cfg.font=='bigblue'
    if pixel and not measure then measure=HUD.font.measure end
    local d={};local heat=m.kind=='heat'
    local vent=heat and m.state=='VENT'
    if vent then opacity=opacity*(0.25+0.75*(0.5+0.5*math.cos((clock or 0)*math.pi*4))) end
    local heat_ink=vent and cfg.heat_red or M.heat_color(m.fraction or 0,clock,cfg)
    local ink=HUD.config.rgb(heat and heat_ink or
        (m.warning and (m.value==0 and cfg.heat_red or cfg.heat_yellow) or cfg.text_color))
    local function rect(dx,dy,w,h,c,a,kind)
        d[#d+1]={type=kind or 'rect',x=x+dx*scale,y=y+dy*scale,w=w*scale,h=h*scale,c=c,a=(a or 1)*opacity,frosted=cfg.frosted}
    end
    local function text(t,dx,dy,size,c,a)
        if pixel then size=t=='%' and 24 or (size>=20 and 36 or 12) end
        d[#d+1]={type='text',text=tostring(t),font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=c,a=(pixel and 1 or (a or 1))*opacity}
    end
    local number=type(m.value)=='number' and string.format('%02d',m.value) or m.value
    local number_top,label_top=0,0
    if pixel then
        local a,b,c,nt=measure(number,36*scale)
        local e,f,g,lt=measure('HEAT SINKS',12*scale)
        number_top=nt/scale;label_top=lt/scale
    end
    if heat then
        -- Twenty cells fill from the base upward, including the partially filled cell.
        local pitch,cell=pixel and 2.5 or 2.35,pixel and 2 or 1.75
        for i=0,19 do
            local fill=math.max(0,math.min(1,m.fraction*20-i))
            rect(0,-8+i*pitch,9,cell,ink,0.12)
            if fill>0 then rect(0,-8+i*pitch,9,cell*fill,ink,0.95) end
        end
        text('HEAT',18,pixel and math.max(34,5+number_top+3) or 34,10,ink,0.85)
        local size=pixel and 36 or 30
        local edge=#number*size*0.6
        if measure then local a,b,c,e=measure(number,size*scale);if c then edge=c/scale end end
        text(number,18,5,size,ink);text('%',18+edge+4,5,pixel and 24 or 20,ink,0.85)
        local footer=m.fraction>=0.95 and 'OVERHEAT' or (m.state=='VENT' and 'VENT' or
            (m.reserve and string.format('%02d SINKS',m.reserve) or '-- SINKS'))
        text(footer,18,pixel and math.min(-9,1-label_top) or -9,9,ink,0.9)
    else
        text(m.label,0,pixel and math.max(42,5+number_top+3) or 42,8,ink,0.72)
        text(number,0,5,32,ink)
        if m.suffix then
            local edge=60
            if pixel then local a,b,c=measure(number,36*scale);edge=c/scale end
            text(m.suffix,edge+4,11,12,ink,0.7)
        end
        for i=0,11 do rect(i*6.5,-3,4.5,3,ink,m.fraction and i/12<m.fraction and 0.92 or 0.14) end
        local reserve=m.reserve and (string.format('%02d',m.reserve)..' '..(m.reserve_kind or 'RES')) or '-- RES'
        local footer=m.state~='READY' and m.state or reserve
        text(footer,0,pixel and math.min(-19,-7-label_top) or -19,9,ink,0.8)
    end
    -- Measure content first. Frame, frost and accents share these same bounds.
    local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
    for _,c in ipairs(d) do
        local x0,y0,x1,y1=c.x,c.y,c.x+(c.w or 0),c.y+(c.h or 0)
        if c.type=='text' then
            local a,b,e,f
            if measure then a,b,e,f=measure(c.text,c.size) end
            if not e then a,b,e,f=0,-c.size*.2,#c.text*c.size*.6,c.size*.8 end
            x0,y0,x1,y1=c.x+a,c.y+b,c.x+e,c.y+f
        end
        left,bottom,right,top=math.min(left,x0),math.min(bottom,y0),math.max(right,x1),math.max(top,y1)
    end
    local pad=8*scale
    left,bottom,right,top=left-pad,bottom-pad,right+pad,top+pad
    local out={{type='panel',x=left,y=bottom,w=right-left,h=top-bottom,
        c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}}
    for _,c in ipairs(d) do out[#out+1]=c end
    return out
end
return M
