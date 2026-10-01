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
                            if v.type=='text' then
                                local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
                                left=math.min(left,v.x+a-padding);bottom=math.min(bottom,v.y+b-padding)
                                right=math.max(right,v.x+e+padding);top=math.max(top,v.y+f+padding)
                            end
                        end
                        for _,v in ipairs(centered) do
                            if v.decoration then
                                v.x=left+(v.x-panel.x)*(right-left)/panel.w
                                v.y=bottom+(v.y-panel.y)*(top-bottom)/panel.h
                                v.w=v.w*(right-left)/panel.w
                                v.h=v.h*(top-bottom)/panel.h
                            end
                        end
                        panel.x,panel.y,panel.w,panel.h=left,bottom,right-left,top-bottom
                    end
                    if c.style_3d=='hologram' then
                        local panel=centered[1];local clock=c.style_clock or 0
                        local flicker=.96+.025*math.sin(clock*17)+.015*math.sin(clock*31)
                        for _,v in ipairs(centered) do v.a=v.a*flicker end
                        panel.a=panel.a*.18
                        local ink=HUD.config.rgb(c.text_color)
                        local strength=commands[2] and commands[2].a or 1
                        local thickness=math.max(.3,panel.w/500)
                        for _,edge in ipairs({{panel.x,panel.y,panel.w,thickness},{panel.x,panel.y+panel.h-thickness,panel.w,thickness}}) do
                            centered[#centered+1]={type='rect',x=edge[1],y=edge[2],w=edge[3],h=edge[4],c=ink,a=.18*strength}
                        end
                        centered[#centered+1]={type='rect',x=panel.x,y=panel.y+(clock*.35%1)*(panel.h-thickness),w=panel.w,h=thickness,c=ink,a=.10*strength}
                    end
    return centered
end
return M
