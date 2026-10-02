-- Renderer-independent HUD; geometry uses bottom-left coordinates.
local M={}
function M.fuel_marker(commands,measure)
    local edge=-math.huge;local marker
    for i=#commands,1,-1 do
        local v=commands[i]
        if v.fuel_marker_piece then table.remove(commands,i)
        elseif v.fuel_fill then edge=math.max(edge,v.x+v.w)
        elseif v.fuel_endpoint then marker=v end
    end
    if not marker then return end
    local a,b,e,f=measure('F',marker.size,marker.font)
    local w,h=e-a,f-b;local stroke=math.max(w*.22,marker.size*.08)
    for _,run in ipairs({{0,0,stroke,h},{0,h-stroke,w,stroke},{0,h*.5,w*.75,stroke}}) do
        local x,y=marker.x+a+run[1],marker.y+b+run[2]
        local cut=math.max(0,math.min(run[3],edge-x))
        for _,part in ipairs({{x,cut,{0,0,0}},{x+cut,run[3]-cut,{255,255,255}}}) do
            if part[2]>0 then commands[#commands+1]={type='rect',fuel_marker_piece=true,x=part[1],y=y,w=part[2],h=run[4],c=part[3],a=marker.a} end
        end
    end
end
function M.heat_color(fraction,clock,cfg)
    if fraction>=0.95 then return math.floor((clock or 0)*cfg.flash_hz*2)%2==0 and cfg.heat_red or cfg.heat_yellow end
    if fraction>=0.85 then return cfg.heat_red end
    if fraction>=0.65 then return cfg.heat_yellow end
    return cfg.heat_white
end
function M.decorate(out,frame,scale,cfg,opacity)
    local left,bottom=frame.x,frame.y
    local right,top=left+frame.w,bottom+frame.h
    -- Decorations stay inside the measured panel perimeter, including at screen edges.
    -- Shared rectangle commands preserve direct WorldGUI depth and all screen renderers.
    local style=cfg.decoration or 'none'
    local w,h=right-left,top-bottom;local line=scale
    local neutral=HUD.config.rgb(cfg.decoration_color or cfg.text_color)
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
        -- Native HUD-inspired open rails and angular corners in the HUD text color.
        border(0,0,line,h,nil,.35);border(w-line,0,line,h,nil,.35)
        border(0,0,length,line,nil,.9);border(0,h-line,length,line,nil,.9)
        border(w-length,0,length,line,nil,.9);border(w-length,h-line,length,line,nil,.9)
        for _,cx in ipairs({0,w-line}) do
            for _,cy in ipairs({0,h-length}) do border(cx,cy,line,length,nil,.9) end
        end
        for _,cx in ipairs({0,w-length}) do
            for _,cy in ipairs({0,h-2*line}) do border(cx,cy,length,2*line,nil,.9) end
        end
    elseif style=='double' then outline(0,.65);outline(3*scale,.25)
    end
end
function M.compose(m,x,y,scale,opacity,cfg,clock,measure)
    if m.snow_party then
        local function rainbow(phase)
            local t=(clock or 0)*3+phase
            return {math.floor(128+127*math.sin(t)),math.floor(128+127*math.sin(t+2.094)),math.floor(128+127*math.sin(t+4.189))}
        end
        local color=rainbow(0);local out={{type='panel',x=x-55*scale,y=y-55*scale,w=110*scale,h=125*scale,c=color,a=.5*opacity,frosted=false}}
        for row=0,47 do
            local dy=row-23.5;local half=math.sqrt(math.max(0,24*24-dy*dy))
            out[#out+1]={type='rect',x=x-half*scale,y=y+dy*scale,w=2*half*scale,h=scale,c={235,247,255},a=opacity}
        end
        for _,r in ipairs({{-55,-55,110,2},{-55,68,110,2},{-55,-55,2,125},{53,-55,2,125}})do
            out[#out+1]={type='rect',x=x+r[1]*scale,y=y+r[2]*scale,w=r[3]*scale,h=r[4]*scale,c=rainbow(math.pi),a=opacity}
        end
        out[#out+1]={type='text',x=x-40*scale,y=y-40*scale,text='SNOWBALL',size=12*scale,font=cfg.font,c={255,255,255},a=opacity}
        return out
    end

    cfg=cfg or HUD.config.defaults
    local pixel=HUD.font.supported(cfg.font)
    if pixel and not measure then measure=function(text,size)return HUD.font.measure(text,size,cfg.font)end end
    local d={};local heat=m.kind=='heat';local fuel=m.label=='FUEL' or m.label=='GAS'
    local vent=heat and m.state=='VENT'
    if vent then opacity=opacity*(0.25+0.75*(0.5+0.5*math.cos((clock or 0)*math.pi*4))) end
    local heat_ink=vent and cfg.heat_red or M.heat_color(m.fraction or 0,clock,cfg)
    local key='text_color'
    if heat then
        if vent then key='heat_red'
        elseif m.fraction>=.95 then key=math.floor((clock or 0)*cfg.flash_hz*2)%2==0 and 'heat_red' or 'heat_yellow'
        elseif m.fraction>=.85 then key='heat_red'
        elseif m.fraction>=.65 then key='heat_yellow'
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
        if size>=20 and m.charge_ready and m.resource_hex=='fb3a19078694708a' then
            c={0,255,255};reminder=.35+.65*(.5+.5*math.cos((clock or 0)*math.pi*2*cfg.flash_hz))
        end
        d[#d+1]={type='text',numeric_display=tostring(t):match('^%d%d%d')~=nil,text=tostring(t),font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=c,a=(pixel and 1 or (a or 1))*opacity*ink_alpha*reminder}
    end
    local number=type(m.value)=='number' and string.format('%03d',m.value) or m.value
    if m.resource_hex=='3828e2051aa9e897' then number=tostring(m.value) end
    local number_top,label_top=0,0
    if pixel then
        local a,b,c,nt=measure(number,36*scale)
        local e,f,g,lt=measure('HEAT SINKS',12*scale)
        number_top=nt/scale;label_top=lt/scale
    end
    if heat or fuel then
        local percent=fuel and tostring(number) or string.format('%03d%%',m.value)
        local label=(fuel and (m.label..': ') or vent and 'VENT: ' or 'HEAT: ')..percent
        local reserve=fuel and (m.reserve and string.format('%03d TANKS',m.reserve) or '-- TANKS') or (m.reserve and string.format('%03d:HTSNKS',m.reserve) or '--:HTSNKS')
        local size=16*scale
        local function width(t)
            if measure then local a,b,e,f=measure(t,size);if e then return (e-a)/scale end end
            return #t*16*.6
        end
        local digit_width=0
        for digit=0,9 do digit_width=math.max(digit_width,width(tostring(digit))) end
        local label_width=heat and (width('HEAT: ')+3*digit_width+width('%')) or width(label)
        local bar_width=math.max(160,label_width+width(reserve)+20)
        local fraction=math.max(0,math.min(1,m.fraction or 0))
        local zones=fuel and {{0,.15,cfg.heat_red},{.15,.35,cfg.heat_yellow},{.35,1,cfg.heat_white}} or {{0,.65,cfg.heat_white},{.65,.85,cfg.heat_yellow},{.85,1,cfg.heat_red}}
        for _,zone in ipairs(vent and {} or zones) do
            local start,finish,color=zone[1],zone[2],HUD.config.rgb(zone[3])
            rect(start*bar_width,0,(finish-start)*bar_width,38,color,(fuel and finish<=.35 or not fuel and start>0) and .25 or .1)
            d[#d].heat_background=true;d[#d].fuel_background=fuel or nil
            local amount=math.max(0,math.min(fraction,finish)-start)
            if amount>0 then
                rect(start*bar_width,0,amount*bar_width,38,color,1)
                d[#d].heat_fill=true;d[#d].fuel_fill=fuel or nil
            end
        end
        -- Fine dark scanlines add texture without reducing the fill strength.
        if not vent then
            if heat and fraction>=.95 then
                local danger=math.floor((clock or 0)*16)%2==0 and {255,20,35} or {255,255,255}
                rect(.95*bar_width,0,.05*bar_width,38,danger,1)
                d[#d].heat_danger=true
            end
            -- Fine staggered marks avoid stretching low-resolution asset pixels.
            for row=0,7 do
                for column=0,23 do
                    local dx=(column+.25+(row%2)*.5)*bar_width/24
                    rect(dx,3+row*4.5,bar_width/96,.55,{0,0,0},.16)
                    d[#d].heat_texture=true
                end
            end
        end
        if not vent then
            -- Instrument-style rails and calibration marks stay within the gauge.
            local function gauge_detail(dx,dy,w,h,color,alpha)
                rect(dx,dy,w,h,color,alpha);d[#d].heat_detail=true
            end
            local pale=HUD.config.rgb(cfg.heat_white)
            gauge_detail(0,0,bar_width,1,pale,.65)
            gauge_detail(0,37,bar_width,1,pale,.65)
            gauge_detail(0,0,1,38,pale,.65)
            gauge_detail(bar_width-1,0,1,38,pale,.65)
            for i=1,9 do
                if i~=5 then
                    gauge_detail(i*bar_width/10,1,1.4,6,{0,0,0},.55)
                    gauge_detail(i*bar_width/10,31,1.4,6,{0,0,0},.55)
                end
            end
            for _,position in ipairs({.5,.75}) do
                gauge_detail(position*bar_width-1,1,2,13,{0,0,0},.65)
                gauge_detail(position*bar_width-1,24,2,13,{0,0,0},.65)
            end
            for i=1,99 do
                if i%10~=0 and i~=75 then
                    gauge_detail(i*bar_width/100,1,.6,3,{0,0,0},.4)
                    gauge_detail(i*bar_width/100,34,.6,3,{0,0,0},.4)
                end
            end
            for _,boundary in ipairs(fuel and {.15,.35} or {.65,.85}) do
                gauge_detail(boundary*bar_width-.5,1,1,36,{0,0,0},.5)
            end
        end
        local prefix=fuel and (m.label..': ') or vent and 'VENT: ' or 'HEAT: '
        local white={255,255,255}
        text(prefix,0,44,8,white,.9);d[#d].size=size;d[#d].heat_label='left'
        if heat then
            local leading=m.value<10 and 2 or (m.value<100 and 1 or 0)
            for slot=0,3 do
                text(percent:sub(slot+1,slot+1),width(prefix)+slot*digit_width,44,8,ink,slot<leading and .3 or .9)
                local command=d[#d];command.size=size;command.heat_label='percent';command.heat_prefix=prefix;command.heat_digit_slot=slot
                -- Pixel-style text otherwise overrides per-command alpha.
                if pixel and slot<leading then command.a=command.a/3 end
            end
        else
            text(percent,width(prefix),44,8,ink,.9);d[#d].size=size;d[#d].heat_label='percent';d[#d].heat_prefix=prefix
        end
        text(reserve,bar_width-width(reserve),-18,8,white,.9);d[#d].size=size;d[#d].heat_label='right'
        if fuel then
            local icon=HUD.fire_icons[m.label] or HUD.fire_icons.FUEL;local factor=14/math.max(icon.w,icon.h)
            for _,run in ipairs(icon.runs) do
                rect(bar_width-14+run[1]*factor,44+run[2]*factor,run[3]*factor,run[4]*factor,{255,255,255},.9)
                d[#d].fuel_flame=true
            end
            text('E',0,-3,8,{255,255,255},1);d[#d].heat_label='left';d[#d].y=y+3*scale
            text('F',bar_width-8,-3,8,{0,0,0},1);d[#d].heat_label='right';d[#d].y=y+3*scale;d[#d].fuel_endpoint=true
        end
        if vent then
            text('OVERHEAT',0,8,32,ink,1)
            local warning=d[#d]
            local warning_size=bar_width/(8*.6)
            if measure then
                local a,b,e=measure('OVERHEAT',warning_size*scale)
                if e and e>a then warning_size=warning_size*bar_width*scale/(e-a) end
            end
            warning.size=warning_size*scale
            warning.overheat_warning=true
        end

    elseif m.resource_hex=='5f3ec9bda2bd8553' then
        local icon=HUD.fire_icons.HAMMER;local factor=1.5
        local charged=(tonumber(m.value) or 0)>0
        local color=charged and ink or {255,55,55}
        local alpha=charged and 1 or (.35+.65*(.5+.5*math.sin((clock or 0)*6)))
        for _,run in ipairs(icon.runs) do
            rect(run[1]*factor,5+run[2]*factor,run[3]*factor,run[4]*factor,color,alpha)
            d[#d].hammer_indicator=true
        end
        text(m.reserve and (string.format('%03d',m.reserve)..' CHARGES') or '-- CHARGES',0,-19,9,ink,.8)
    elseif m.resource_hex=='72170a55a1f37ff1' then
        local icon=HUD.fire_icons.BARREL_SHELL;local factor=36/icon.h
        for barrel=1,2 do
            local alpha=(tonumber(m.value) or 0)>=(3-barrel) and .95 or .18
            rect((barrel-1)*20+3*factor,5+11*factor,6*factor,14*factor,{65,145,235},alpha*.4)
            d[#d].barrel_indicator=barrel
            for _,run in ipairs(icon.runs)do
                local shell_color=run[2]<9 and {218,172,78} or {65,145,235}
                rect((barrel-1)*20+run[1]*factor,5+run[2]*factor,run[3]*factor,run[4]*factor,shell_color,alpha)
                d[#d].barrel_indicator=barrel
            end
        end
        text(m.reserve and (string.format('%03d',m.reserve)..' '..(m.reserve_kind or 'SHELLS')) or '-- SHELLS',0,-19,9,ink,.8)
    else
        local cannon_mode=(m.ammo_mode=='APHET' or m.ammo_mode=='FLAK') and m.resource_hex~='26e40437ea275296'
        local heading=cannon_mode and m.ammo_mode or m.label
        local heading_y=pixel and math.max(42,5+number_top+3) or 42
        if m.resource_hex=='4dbd74f49c8ffc13' and m.compass_heading then
            -- Fixed-width compass window; only the heading strip moves.
            local labels={[0]='N',[90]='E',[180]='S',[270]='W'}
            for tick=0,345,15 do
                local delta=(tick-m.compass_heading+180)%360-180
                local tx=38+delta*.8
                if tx>=2 and tx<=74 then
                    rect(tx,heading_y,1,labels[tick] and 5 or 3,ink,.7);d[#d].compass_piece=true
                    if labels[tick] and tx>=7 and tx<=69 then
                        text(labels[tick],tx-4,heading_y+7,8,ink,.9);d[#d].compass_piece=true
                    end
                end
            end
            rect(37,heading_y-4,3,3,{255,210,70},1);d[#d].compass_piece=true
        else
            text(heading..(m.chamber_bonus==1 and ' +1' or ''),0,heading_y,8,ink,0.72)
        end
        if cannon_mode then d[#d].size=(pixel and 18 or 12)*scale end
        text(number,0,5,32,ink)
        local fire_icon=HUD.fire_icons[m.energy_icon or m.ammo_icon or m.fire_mode]
        if fire_icon and (not m.ammo_mode or m.ammo_mode=='HEAT' or m.ammo_mode=='HE' or m.resource_hex=='26e40437ea275296') then
            d[#d].mode_count=true;d[#d].mode_gap=2
            local edge=#number*(pixel and 36 or 32)*.6
            if measure then local a,b,c=measure(number,(pixel and 36 or 32)*scale);if c then edge=c/scale end end
            -- Fit both dimensions: wide single/burst icons must not be
            -- enlarged merely to match the square auto icon's height.
            local factor=24*(fire_icon.scale or 1)/math.max(fire_icon.w,fire_icon.h)
            local bottom,top=0,32
            if measure then local a,b,c,e=measure(number,(pixel and 36 or 32)*scale);if e then bottom,top=b/scale,e/scale end end
            if m.fire_mode=='AUTO' and not m.ammo_icon and not m.energy_icon then
                factor=(top-bottom)/fire_icon.h
            end
            local icon_y=5+(bottom+top-fire_icon.h*factor)/2
            local icon_gap=2
            if fire_icon==HUD.fire_icons.SHELL or fire_icon==HUD.fire_icons.DOUBLE_SHELL then
                for _,offset in ipairs(fire_icon==HUD.fire_icons.DOUBLE_SHELL and {0,15} or {0}) do
                    rect(edge+icon_gap+(offset+3)*factor,icon_y+11*factor,6*factor,14*factor,{65,145,235},.36)
                    d[#d].mode_icon=true
                end
            end
            for _,run in ipairs(fire_icon.runs) do
                local color=run[5] or ink
                if fire_icon==HUD.fire_icons.SHELL or fire_icon==HUD.fire_icons.DOUBLE_SHELL then color=run[2]<9 and {218,172,78} or {65,145,235} end
                rect(edge+icon_gap+run[1]*factor,icon_y+run[2]*factor,run[3]*factor,run[4]*factor,color,.9)
                d[#d].mode_icon=true
            end
        end
        if cannon_mode then d[#d].mode_count=true;d[#d].mode_gap=2 end
        if cannon_mode then
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
        local reserve=m.reserve and (string.format('%03d',m.reserve)..' '..(m.reserve_kind or 'RES')) or '-- RES'
        local footer=m.state~='READY' and m.state or reserve
        if m.resource_hex=='3828e2051aa9e897' then footer=reserve end
        text(footer,0,pixel and math.min(-19,-7-label_top) or -19,9,ink,0.8)
    end
    local spear_reserve
    for i=#d,1,-1 do if d[i].spear_reserve then spear_reserve=d[i];table.remove(d,i) end end
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
    if m.resource_hex=='4dbd74f49c8ffc13' and m.compass_heading then
        -- Reserve the compass lettering envelope even when no cardinal is visible.
        local a,b,e,f
        if measure then a,b,e,f=measure('N',(pixel and 12 or 8)*scale) end
        if not f then b,f=-(pixel and 12 or 8)*scale*.2,(pixel and 12 or 8)*scale*.8 end
        local heading_y=pixel and math.max(42,5+number_top+3) or 42
        left=math.min(left,x);right=math.max(right,x+76*scale)
        bottom=math.min(bottom,y+(heading_y-4)*scale)
        top=math.max(top,y+(heading_y+7)*scale+f)
    end
    local pad=8*scale
    local has_mode_icon=false
    for _,command in ipairs(d) do if command.mode_icon then has_mode_icon=true;break end end
    local horizontal_pad=has_mode_icon and 16*scale or pad
    left,bottom,right,top=left-horizontal_pad,bottom-pad,right+horizontal_pad,top+pad
    do
        local center=(left+right)/2
        local bar_left,bar_right=math.huge,-math.huge
        for _,v in ipairs(d) do if v.type=='rect' and not v.mode_icon and not v.heat_vertical and not v.compass_piece then bar_left=math.min(bar_left,v.x);bar_right=math.max(bar_right,v.x+v.w) end end
        for _,c in ipairs(d) do
            if c.type=='text' and not c.compass_piece then
                c.center_in_frame=true
                local a,b,e,f
                if measure then a,b,e,f=measure(c.text,c.size) end
                if not e then a,e=0,#c.text*c.size*.6 end
                if c.heat_label then
                    c.center_in_frame=nil
                    if c.heat_label=='percent' then
                        local prefix_width=#c.heat_prefix*c.size*.6
                        if measure then local pa,pb,pe=measure(c.heat_prefix,c.size);if pe then prefix_width=pe end end
                        local slot_width=c.size*.6
                        if c.heat_digit_slot and measure then
                            slot_width=0
                            for digit=0,9 do local da,db,de=measure(tostring(digit),c.size);slot_width=math.max(slot_width,(de or c.size*.6)-(da or 0)) end
                        end
                        c.x=left+pad+prefix_width+(c.heat_digit_slot or 0)*slot_width
                    else c.x=c.heat_label=='left' and left+pad-a or right-pad-e end
                else c.x=center-(a+e)/2 end
            elseif c.type=='rect' and not c.mode_icon and not c.heat_vertical and not c.compass_piece then
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
        local gap=2*scale;local width=e-a+gap+icon_edge-icon_left
        local start=(left+right-width)/2
        h.x=start-a
        local shift=start+e-a+gap-icon_left
        for _,c in ipairs(d) do if c.mode_icon then c.x=c.x+shift end end
    end
    local out={{type='panel',x=left,y=bottom,w=right-left,h=top-bottom,
        c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}}
    if fuel then
        -- Center the bar and flame as one group without moving the fill
        -- independently of its background as fuel decreases.
        local start=(left+right)/2-54*scale
        for _,c in ipairs(d) do
            if c.fuel_group then
                c.center_bar=nil
                c.center_in_frame=nil
                if c.fuel_dx then c.x=start+c.fuel_dx
                else c.x=start end
            end
        end
    end
    for _,c in ipairs(d) do out[#out+1]=c end
    M.decorate(out,out[1],scale,cfg,opacity)
    if spear_reserve then
        local size=spear_reserve.size;local a,b,e,f=0,-size*.2,#spear_reserve.text*size*.6,size*.8
        if measure then a,b,e,f=measure(spear_reserve.text,size) end
        local ch=f-b+16*scale
        local child={type='panel',child=true,fold_child=true,x=left,y=bottom-2*scale-ch,w=right-left,h=ch,c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity}
        spear_reserve.child=true;spear_reserve.fold_child=true;spear_reserve.center_in_frame=true
        spear_reserve.x=(left+right-a-e)/2;spear_reserve.y=child.y+8*scale-b
        local group={child,spear_reserve};M.decorate(group,child,scale,cfg,opacity)
        for _,v in ipairs(group) do v.child=true;v.fold_child=true;out[#out+1]=v end
    end

    local child_label=m.safety_mode or m.fire_mode
    if m.rpm then child_label=(child_label and (child_label..'  ') or '')..tostring(m.rpm)..' RPM' end
    if m.rpm or child_label=='SAFE' or child_label=='UNSAFE' or child_label=='AUTO' or child_label=='SEMI' or child_label=='BURST' or child_label=='ALT' or child_label=='VOLLEY' then
        local size=(pixel and 12 or 8)*scale
        local a,b,e,f
        if measure then a,b,e,f=measure(child_label,size) end
        if not e then a,b,e,f=0,-size*.2,#child_label*size*.6,size*.8 end
        local cw,ch=right-left,f-b+8*scale
        local child={type='panel',child=true,x=(left+right-cw)/2,y=bottom-2*scale-ch,w=cw,h=ch,
            c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}
        local group={child,{type='text',child=true,text=child_label,font=cfg.font,
            x=child.x+cw/2-(a+e)/2,y=child.y+4*scale-b,size=size,c=ink,a=opacity*ink_alpha}}
        M.decorate(group,child,scale,cfg,opacity)
        for _,command in ipairs(group) do command.child=true;out[#out+1]=command end
    end
    if fuel then
        local fill_right=-math.huge
        for _,command in ipairs(out) do
            if command.fuel_fill then fill_right=math.max(fill_right,command.x+command.w) end
        end
        for _,command in ipairs(out) do
            if command.type=='text' and command.text=='F' then
                local bearing=0
                if measure then bearing=select(1,measure(command.text,command.size)) or 0 end
                command.c=fill_right>command.x+bearing and {0,0,0} or {255,255,255}
            end
        end
    end
    -- Charge metadata is supplied only after the native signal is verified.
    if m.safety_mode and type(m.charge_fraction)=='number' then
        local fraction=math.max(0,math.min(1,m.charge_fraction))
        local parent=out[1];local low=parent.y
        for _,c in ipairs(out) do if c.child and c.type=='panel' then low=math.min(low,c.y) end end
        local x=parent.x+parent.w+2*scale;local height=parent.y+parent.h-low;local width=12*scale
        local flash=m.charge_warning and math.floor((clock or 0)*8)%2==0
        local yellow=HUD.config.rgb(cfg.heat_yellow);local red=HUD.config.rgb(cfg.heat_red)
        local panel={type='panel',charge_meter=true,x=x,y=low,w=width,h=height,c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity}
        out[#out+1]=panel
        local zones={{0,.65,{255,255,255}},{.65,.70,{0,255,0}},{.70,.85,yellow},{.85,1,red}}
        for _,zone in ipairs(zones) do
            local color=flash and yellow or zone[3]
            out[#out+1]={type='rect',charge_meter=true,x=x,y=low+height*zone[1],w=width,h=height*(zone[2]-zone[1]),c=color,a=opacity*.25}
            local filled=math.max(0,math.min(fraction,zone[2])-zone[1])
            if filled>0 then out[#out+1]={type='rect',charge_meter=true,x=x,y=low+height*zone[1],w=width,h=height*filled,c=color,a=opacity} end
        end
        for i=1,39 do
            out[#out+1]={type='rect',charge_meter=true,x=x,y=low+height*i/40,w=width,h=.3*scale,c={0,0,0},a=opacity*.25}
        end
        for i=1,19 do
            out[#out+1]={type='rect',charge_meter=true,x=x,y=low+height*i/20,w=(i%5==0 and 6 or 3)*scale,h=.6*scale,c={0,0,0},a=opacity*.65}
        end
        M.decorate(out,panel,scale,cfg,opacity)
    end
    if vent then
        local red=HUD.config.rgb(cfg.heat_red)
        for _,command in ipairs(out) do command.c=red end
    end
    if fuel then M.fuel_marker(out,measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end) end
    -- Optional effects share the composed panel and its visibility fade in every mode.
    if cfg.effect_flicker then
        local strength=.94+.04*math.sin((clock or 0)*17)+.02*math.sin((clock or 0)*31)
        for _,v in ipairs(out) do v.a=v.a*strength;if v.frost_a then v.frost_a=v.frost_a*strength end end
    end
    if cfg.effect_scanlines or cfg.effect_sweep then
        local frames={};for _,v in ipairs(out)do if v.type=='panel' then frames[#frames+1]=v end end
        local ink=HUD.config.rgb(cfg.text_color)
        for _,frame in ipairs(frames)do
            local thickness=math.max(.3,scale*.35)
            if cfg.effect_scanlines then
                for k=1,21 do out[#out+1]={type='rect',x=frame.x,y=frame.y+frame.h*k/22,w=frame.w,h=thickness,c=ink,a=.12*opacity} end
            end
            if cfg.effect_sweep then
                local band=math.min(frame.h,thickness*2)
                for k=0,2 do
                    out[#out+1]={type='rect',x=frame.x,y=frame.y+(((clock or 0)*.35+k/3)%1)*(frame.h-band),w=frame.w,h=band,c=ink,a=.2*opacity}
                end
            end
        end
    end
    for _,command in ipairs(out)do if command.type=='text' then command.a=command.a*(cfg.text_opacity or 1) end end
    return out
end
return M
