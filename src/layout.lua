-- Renderer-independent HUD; geometry uses bottom-left coordinates.
local M={}
function M.heat_color(fraction,clock,cfg)
    if fraction>=0.95 then return math.floor((clock or 0)*cfg.flash_hz*2)%2==0 and cfg.heat_red or cfg.heat_yellow end
    if fraction>=0.86 then return cfg.heat_red end
    if fraction>=0.75 then return cfg.heat_yellow end
    return cfg.heat_white
end
function M.decorate(out,frame,scale,cfg,opacity)
    local left,bottom=frame.x,frame.y
    local right,top=left+frame.w,bottom+frame.h
    -- Decorations stay inside the measured panel perimeter, including at screen edges.
    -- Shared rectangle commands preserve direct WorldGUI depth and all screen renderers.
    local style=cfg.decoration or 'none'
    local w,h=right-left,top-bottom;local line=scale
    local neutral=HUD.config.rgb(cfg.text_color)
    local yellow=HUD.config.rgb(cfg.heat_yellow)
    local function border(dx,dy,bw,bh,color,strength)
        out[#out+1]={type='rect',decoration=true,x=left+dx,y=bottom+dy,w=bw,h=bh,
            c=color or neutral,a=opacity*(cfg.text_color_alpha or 255)/255*(strength or .7)}
    end
    local function outline(inset,strength)
        border(inset,inset,w-2*inset,line,nil,strength)
        border(inset,h-inset-line,w-2*inset,line,nil,strength)
        border(inset,inset,line,h-2*inset,nil,strength)
        border(w-inset-line,inset,line,h-2*inset,nil,strength)
    end
    local length=math.min(12*scale,w/4,h/4)
    if style=='outline' then outline(0,.55)
    elseif style=='brackets' then
        for _,cx in ipairs({0,w-length}) do for _,cy in ipairs({0,h-line}) do border(cx,cy,length,line) end end
        for _,cx in ipairs({0,w-line}) do for _,cy in ipairs({0,h-length}) do border(cx,cy,line,length) end end
    elseif style=='helldivers' then
        -- Native HUD-inspired open rails, pale angular corners and yellow highlights.
        border(0,0,line,h,nil,.35);border(w-line,0,line,h,nil,.35)
        border(0,0,length,line,nil,.9);border(0,h-line,length,line,nil,.9)
        border(w-length,0,length,line,nil,.9);border(w-length,h-line,length,line,nil,.9)
        border(0,0,line,length,nil,.9);border(w-line,h-length,line,length,nil,.9)
        border(0,h-2*line,length,2*line,yellow,.9)
        border(w-length,0,length,2*line,yellow,.9)
    elseif style=='double' then outline(0,.65);outline(3*scale,.25) end
end
function M.compose(m,x,y,scale,opacity,cfg,clock,measure)
    cfg=cfg or HUD.config.defaults
    local pixel=HUD.font.supported(cfg.font)
    if pixel and not measure then measure=function(text,size)return HUD.font.measure(text,size,cfg.font)end end
    local d={};local heat=m.kind=='heat'
    local vent=heat and m.state=='VENT'
    if vent then opacity=opacity*(0.25+0.75*(0.5+0.5*math.cos((clock or 0)*math.pi*4))) end
    local heat_ink=vent and cfg.heat_red or M.heat_color(m.fraction or 0,clock,cfg)
    local key='text_color'
    if heat then
        if vent then key='heat_red'
        elseif m.fraction>=.95 then key=math.floor((clock or 0)*cfg.flash_hz*2)%2==0 and 'heat_red' or 'heat_yellow'
        elseif m.fraction>=.86 then key='heat_red'
        elseif m.fraction>=.75 then key='heat_yellow'
        else key='heat_white' end
    elseif m.warning then key=m.value==0 and 'heat_red' or 'heat_yellow' end
    local ink=HUD.config.rgb(cfg[key])
    local ink_alpha=(cfg[key..'_alpha'] or 255)/255
    local function rect(dx,dy,w,h,c,a,kind)
        d[#d+1]={type=kind or 'rect',x=x+dx*scale,y=y+dy*scale,w=w*scale,h=h*scale,c=c,a=(a or 1)*opacity*ink_alpha,frosted=cfg.frosted}
    end
    local function text(t,dx,dy,size,c,a)
        if pixel then size=t=='%' and 24 or (size>=20 and 36 or 12) end
        local reminder=m.reload_reminder and size>=20 and (0.35+0.65*(0.5+0.5*math.cos((clock or 0)*math.pi*2*cfg.flash_hz))) or 1
        d[#d+1]={type='text',text=tostring(t),font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=c,a=(pixel and 1 or (a or 1))*opacity*ink_alpha*reminder}
    end
    local number=type(m.value)=='number' and string.format('%02d',m.value) or m.value
    local number_top,label_top=0,0
    if pixel then
        local a,b,c,nt=measure(number,36*scale)
        local e,f,g,lt=measure('HEAT SINKS',12*scale)
        number_top=nt/scale;label_top=lt/scale
    end
    if heat then
        text('HEAT',0,pixel and math.max(42,5+number_top+3) or 42,10,ink,.85)
        text(number..'%',0,5,32,ink)
        for i=0,19 do
            local fill=math.max(0,math.min(1,m.fraction*20-i))
            rect(i*5,-3,3.5,3,ink,.12)
            if fill>0 then rect(i*5,-3,3.5*fill,3,ink,.95) end
        end
        local footer=m.fraction>=.95 and 'OVERHEAT' or (m.state=='VENT' and 'VENT' or
            (m.reserve and string.format('%02d SINKS',m.reserve) or '-- SINKS'))
        text(footer,0,pixel and math.min(-19,-7-label_top) or -19,9,ink,.9)
    else
        local heading=(m.ammo_mode=='APHET' or m.ammo_mode=='FLAK') and m.ammo_mode or m.label
        local heading_y=pixel and math.max(42,5+number_top+3) or 42
        text(heading..(m.chamber_bonus==1 and ' +1' or ''),0,heading_y,8,ink,0.72)
        if m.ammo_mode=='APHET' or m.ammo_mode=='FLAK' then d[#d].size=(pixel and 18 or 12)*scale end
        text(number,0,5,32,ink)
        local fire_icon=HUD.fire_icons[m.energy_icon or m.ammo_icon or m.fire_mode]
        if fire_icon and not m.ammo_mode then
            d[#d].mode_count=true
            local edge=#number*(pixel and 36 or 32)*.6
            if measure then local a,b,c=measure(number,(pixel and 36 or 32)*scale);if c then edge=c/scale end end
            -- Fit both dimensions: wide single/burst icons must not be
            -- enlarged merely to match the square auto icon's height.
            local factor=24/math.max(fire_icon.w,fire_icon.h)
            local bottom,top=0,32
            if measure then local a,b,c,e=measure(number,(pixel and 36 or 32)*scale);if e then bottom,top=b/scale,e/scale end end
            if m.fire_mode=='AUTO' and not m.ammo_icon and not m.energy_icon then
                factor=(top-bottom)/fire_icon.h
            end
            local icon_y=5+(bottom+top-fire_icon.h*factor)/2
            for _,run in ipairs(fire_icon.runs) do
                rect(edge+8+run[1]*factor,icon_y+run[2]*factor,run[3]*factor,run[4]*factor,ink,.9)
                d[#d].mode_icon=true
            end
        end
        if m.ammo_mode=='APHET' or m.ammo_mode=='FLAK' then d[#d].mode_count=true end
        if m.ammo_mode=='APHET' or m.ammo_mode=='FLAK' then
            local edge=#number*(pixel and 36 or 32)*.6
            if measure then local a,b,c=measure(number,(pixel and 36 or 32)*scale);if c then edge=c/scale end end
            local ix,iy=edge+8,5
            -- Large pictogram shares the main count row.
            local function mode_rect(dx,dy,w,h)
                rect(ix+dx*1.8,iy+dy*1.8,w*1.8,h*1.8,ink,.9)
                d[#d].mode_icon=true
            end
            -- Compact cartridge / airburst pictograms use the same depth-aware
            -- primitives as the HUD; native icon materials are not depth-validated.
            if m.ammo_mode=='APHET' then
                mode_rect(5,0,6,12);mode_rect(6,12,4,3);mode_rect(7,15,2,2)
                mode_rect(4,0,8,2)
            else
                mode_rect(6,6,4,4)
                for _,p in ipairs({{7,13},{7,0},{0,7},{13,7},{2,2},{12,12},{2,12},{12,2}}) do
                    mode_rect(p[1],p[2],2,2)
                end
            end
        end
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
    if heat then
        local icon=HUD.fire_icons[m.energy_icon or m.ammo_icon or m.fire_mode]
        if icon then
            local command
            for _,v in ipairs(d) do if v.type=='text' and v.text==number..'%' then command=v end end
            command.mode_count=true
            local a,b,e,f=0,0,#command.text*command.size*.6,command.size
            if measure then a,b,e,f=measure(command.text,command.size) end
            local factor=24/math.max(icon.w,icon.h)
            local iy=5+(b/scale+f/scale-icon.h*factor)/2
            for _,run in ipairs(icon.runs) do
                rect(e/scale+8+run[1]*factor,iy+run[2]*factor,run[3]*factor,run[4]*factor,ink,.9)
                d[#d].mode_icon=true
            end
        end
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
    do
        local center=(left+right)/2
        local bar_left,bar_right=math.huge,-math.huge
        for _,v in ipairs(d) do if v.type=='rect' and not v.mode_icon then bar_left=math.min(bar_left,v.x);bar_right=math.max(bar_right,v.x+v.w) end end
        for _,c in ipairs(d) do
            if c.type=='text' then
                c.center_in_frame=true
                local a,b,e,f
                if measure then a,b,e,f=measure(c.text,c.size) end
                if not e then a,e=0,#c.text*c.size*.6 end
                c.x=center-(a+e)/2
            elseif c.type=='rect' and not c.mode_icon then
                c.center_bar=true
                -- Ammo bar retains its own cell spacing, centered as a group.
                c.x=c.x+center-(bar_left+bar_right)/2
            end
        end
    end
    local icon_right,icon_top=-math.huge,-math.huge
    for _,c in ipairs(d) do
        if c.mode_icon then icon_right=math.max(icon_right,c.x+c.w);icon_top=math.max(icon_top,c.y+c.h) end
    end
    if icon_right>-math.huge then
        local dx,dy=right-pad-icon_right,0
        for _,c in ipairs(d) do if c.mode_icon then c.x=c.x+dx;c.y=c.y+dy end end
    end
    local heading_command;local icon_left,icon_edge=math.huge,-math.huge
    for _,c in ipairs(d) do
        if c.mode_count then heading_command=c end
        if c.mode_icon then icon_left=math.min(icon_left,c.x);icon_edge=math.max(icon_edge,c.x+c.w) end
    end
    if heading_command and icon_left<math.huge then
        local h=heading_command;local a,b,e,f
        if measure then a,b,e,f=measure(h.text,h.size) end
        if not e then a,e=0,#h.text*h.size*.6 end
        local gap=8*scale;local width=e-a+gap+icon_edge-icon_left
        local start=(left+right-width)/2
        h.x=start-a
        local shift=start+e-a+gap-icon_left
        for _,c in ipairs(d) do if c.mode_icon then c.x=c.x+shift end end
    end
    local out={{type='panel',x=left,y=bottom,w=right-left,h=top-bottom,
        c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}}
    for _,c in ipairs(d) do out[#out+1]=c end
    M.decorate(out,out[1],scale,cfg,opacity)
    if m.fire_mode=='AUTO' or m.fire_mode=='SEMI' or m.fire_mode=='BURST' or m.fire_mode=='ALT' then
        local size=(pixel and 12 or 8)*scale
        local a,b,e,f
        if measure then a,b,e,f=measure(m.fire_mode,size) end
        if not e then a,b,e,f=0,-size*.2,#m.fire_mode*size*.6,size*.8 end
        local cw,ch=right-left,f-b+8*scale
        local child={type='panel',child=true,x=(left+right-cw)/2,y=bottom-2*scale-ch,w=cw,h=ch,
            c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}
        local group={child,{type='text',child=true,text=m.fire_mode,font=cfg.font,
            x=child.x+cw/2-(a+e)/2,y=child.y+4*scale-b,size=size,c=ink,a=opacity*ink_alpha}}
        M.decorate(group,child,scale,cfg,opacity)
        for _,command in ipairs(group) do command.child=true;out[#out+1]=command end
    end
    return out
end
return M
