-- Pure WorldGUI geometry scaling, frame fitting and visual presets.
local M={}
function M.prepare(commands,p,c)
                    local f=commands[1];local scale=240*(c.scale or 1)/f.w
                    if c.placement_mode=='auto' and p.first_person then scale=scale*.5 end;local centered={}
                    for _,command in ipairs(commands) do
                        local v={};for k,value in pairs(command) do v[k]=value end
                        v.x=(v.x-f.x-f.w/2)*scale;v.y=(v.y-f.y-f.h/2)*scale
                        if v.w then v.w=v.w*scale end
                        if v.h then v.h=v.h*scale end
                        if v.size then v.size=v.size*scale end
                        centered[#centered+1]=v
                    end
                    -- Pixel glyphs quantize after world scaling; fit their actual bounds.
                    if HUD.font.supported(c.font) then
                        local panel=centered[1]
                        local left,bottom,right,top=panel.x,panel.y,panel.x+panel.w,panel.y+panel.h
                        local padding=math.max(1,8*2*(c.scale or 1)*scale)
                        for _,v in ipairs(centered) do
                            if v.type=='text' and not v.child then
                                local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
                                left=math.min(left,v.x+a-padding);bottom=math.min(bottom,v.y+b-padding)
                                right=math.max(right,v.x+e+padding);top=math.max(top,v.y+f+padding)
                            end
                        end
                        for _,v in ipairs(centered) do
                            if v.decoration and not v.child then
                                v.x=left+(v.x-panel.x)*(right-left)/panel.w
                                v.y=bottom+(v.y-panel.y)*(top-bottom)/panel.h
                                v.w=v.w*(right-left)/panel.w
                                v.h=v.h*(top-bottom)/panel.h
                            end
                        end
                        panel.x,panel.y,panel.w,panel.h=left,bottom,right-left,top-bottom
                    end
                    -- World glyph scaling and frame fitting may change the final
                    -- bounds after screen-layout centering. Align actual glyphs here.
                    local panel=centered[1];local middle=panel.x+panel.w/2
                    local bar_left,bar_right=math.huge,-math.huge
                    for _,v in ipairs(centered) do
                        if v.heat_label then
                            local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
                            if not e then a,e=0,#v.text*v.size*.6 end
                            local pad=8*2*(c.scale or 1)*scale
                            if v.heat_label=='percent' then
                                local pa,pb,pe=HUD.font.measure(v.heat_prefix,v.size,v.font,true)
                                local slot_width=0
                                for digit=0,9 do local da,db,de=HUD.font.measure(tostring(digit),v.size,v.font,true);slot_width=math.max(slot_width,(de or v.size*.6)-(da or 0)) end
                                v.x=panel.x+pad+(pe or #v.heat_prefix*v.size*.6)+(v.heat_digit_slot or 0)*slot_width
                            else v.x=v.heat_label=='left' and panel.x+pad-a or panel.x+panel.w-pad-e end
                        elseif v.center_in_frame then
                            local a,b,e,f
                            if HUD.font.supported(v.font) then a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true) end
                            if not e then a,e=0,#v.text*v.size*.6 end
                            v.x=middle-(a+e)/2
                        elseif v.center_bar then
                            bar_left=math.min(bar_left,v.x);bar_right=math.max(bar_right,v.x+v.w)
                        end
                    end
                    if bar_left<math.huge then
                        local shift=middle-(bar_left+bar_right)/2
                        for _,v in ipairs(centered) do if v.center_bar then v.x=v.x+shift end end
                    end
                    local heading;local icon_left,icon_right=math.huge,-math.huge
                    for _,v in ipairs(centered) do
                        if v.mode_count then heading=v end
                        if v.mode_icon then icon_left=math.min(icon_left,v.x);icon_right=math.max(icon_right,v.x+v.w) end
                    end
                    if heading and icon_left<math.huge then
                        local a,b,e,f
                        if HUD.font.supported(heading.font) then a,b,e,f=HUD.font.measure(heading.text,heading.size,heading.font,true) end
                        if not e then a,e=0,#heading.text*heading.size*.6 end
                        local gap=(heading.mode_gap or 8)*scale;local width=e-a+gap+icon_right-icon_left
                        local start=middle-width/2;heading.x=start-a
                        local shift=start+e-a+gap-icon_left
                        for _,v in ipairs(centered) do if v.mode_icon then v.x=v.x+shift end end
                    end
                    local fuel_left,fuel_right=math.huge,-math.huge
                    for _,v in ipairs(centered) do
                        if v.fuel_group then
                            local a,e=0,v.w or 0
                            if v.type=='text' then
                                local b,f
                                a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
                                if not e then a,e=0,#v.text*v.size*.6 end
                            end
                            fuel_left=math.min(fuel_left,v.x+a);fuel_right=math.max(fuel_right,v.x+e)
                        end
                    end
                    if fuel_left<math.huge then
                        local shift=middle-(fuel_left+fuel_right)/2
                        for _,v in ipairs(centered) do if v.fuel_group then v.x=v.x+shift end end
                    end
                    local child_panel,child_text
                    for _,v in ipairs(centered) do
                        if v.child and not v.heat_child and v.type=='panel' then child_panel=v end
                        if v.child and not v.heat_child and v.type=='text' then child_text=v end
                    end
                    if child_panel and child_text then
                        local old={x=child_panel.x,y=child_panel.y,w=child_panel.w,h=child_panel.h}
                        local a,b,e,f
                        if HUD.font.supported(child_text.font) then a,b,e,f=HUD.font.measure(child_text.text,child_text.size,child_text.font,true) end
                        if not e then a,b,e,f=0,-child_text.size*.2,#child_text.text*child_text.size*.6,child_text.size*.8 end
                        local pad=4*2*(c.scale or 1)*scale
                        local width,height=panel.w,f-b+2*pad
                        child_panel.x=middle-width/2;child_panel.y=panel.y-2*2*(c.scale or 1)*scale-height
                        child_panel.w,child_panel.h=width,height
                        child_text.x=middle-(a+e)/2;child_text.y=child_panel.y+pad-b
                        for _,v in ipairs(centered) do
                            if v.child and not v.heat_child and v.decoration then
                                v.x=child_panel.x+(v.x-old.x)*width/old.w
                                v.y=child_panel.y+(v.y-old.y)*height/old.h
                                v.w=v.w*width/old.w;v.h=v.h*height/old.h
                            end
                        end
                    end
                    for _,v in ipairs(centered) do
                        if v.heat_overlay then
                            local inset=2*(c.scale or 1)*scale
                            v.x,v.y=panel.x+inset,panel.y+inset
                            v.w=math.max(0,panel.w-2*inset)*v.heat_fraction
                            v.h=math.max(0,panel.h-2*inset)
                        end
                    end
                    if c.style_3d=='hologram' then
                        local panel=centered[1];local clock=c.style_clock or 0
                        local flicker=.96+.025*math.sin(clock*17)+.015*math.sin(clock*31)
                        for _,v in ipairs(centered) do v.a=v.a*flicker end
                        panel.a=panel.a*.18
                        if child_panel then child_panel.a=child_panel.a*.18 end
                        local ink=HUD.config.rgb(c.text_color)
                        local strength=c.visibility_alpha or (commands[2] and commands[2].a) or 1
                        local frames={panel}
                        if child_panel then frames[#frames+1]=child_panel end
                        for _,frame in ipairs(frames) do
                            local thickness=math.max(.3,frame.w/500)
                            for _,edge in ipairs({{frame.x,frame.y,frame.w,thickness},{frame.x,frame.y+frame.h-thickness,frame.w,thickness}}) do
                                centered[#centered+1]={type='rect',x=edge[1],y=edge[2],w=edge[3],h=edge[4],c=ink,a=.18*strength}
                            end
                            centered[#centered+1]={type='rect',x=frame.x,y=frame.y+(clock*.35%1)*(frame.h-thickness),w=frame.w,h=thickness,c=ink,a=.10*strength}
                        end
                    end
    if c.style_3d=='instrument' or c.style_3d=='blueprint' or c.style_3d=='retro' then
        local blueprint,retro=c.style_3d=='blueprint',c.style_3d=='retro'
        local accent=retro and HUD.config.rgb(c.text_color) or blueprint and {92,194,230} or {235,175,70}
        local frames={};for _,v in ipairs(centered) do if v.type=='panel' then frames[#frames+1]=v end end
        for _,frame in ipairs(frames) do
            if not retro and c.background_color=='#202628' then frame.c=blueprint and {12,28,42} or {35,28,17} end
            local t=math.max(.45,frame.w/180)
            local function line(x,y,w,h,alpha)
                centered[#centered+1]={type='rect',x=x,y=y,w=w,h=h,c=accent,a=alpha*(c.visibility_alpha or 1)}
            end
            if retro then
                for k=1,21 do line(frame.x,frame.y+frame.h*k/22,frame.w,t*.5,.14) end
            elseif blueprint then
                for k=1,7 do line(frame.x+frame.w*k/8,frame.y,t*.4,frame.h,.09) end
                for k=1,3 do line(frame.x,frame.y+frame.h*k/4,frame.w,t*.4,.09) end
            end
        end
    end
    HUD.layout.fuel_marker(centered,function(t,size,font)return HUD.font.measure(t,size,font,true)end)
    return centered
end
return M
