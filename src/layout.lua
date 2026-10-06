-- Renderer-independent HUD; geometry uses bottom-left coordinates.
local M={}
-- SAFE cap verified in live charge capture 20261003-215227. This is not an UNSAFE deadline.
-- Epoch live cycles 20261003: normalized value reaches 1, holds, and resets on firing.
function M.epoch_charge(raw)
    if type(raw)~='number' or raw~=raw or raw<0 or raw>1 then return nil end
    return {fraction=raw,ready=raw>=1-1e-6}
end
function M.railgun_charge(mode,raw,timer,reaction_ms,age,frame_delay)
    if type(raw)~='number' or raw~=raw or raw<0 or raw>1 then return nil end
    if mode=='SAFE' then
        return {fraction=math.min(1,raw/.7),ready=raw>=.7-1e-6}
    elseif mode=='UNSAFE' then
        local result={fraction=raw,ready=false}
        -- Native verified formula and 3s branch; timer validity is checked independently.
        if type(timer)=='number' and timer==timer and timer>=0 and timer<=3 and
            type(age)=='number' and age>=0 and age<=.15 then
            local expected=.7*math.min(1,timer/.5)+.3*math.max(0,math.min(1,(timer-.5)/2.5))
            if math.abs(expected-raw)<=.0001 and timer>0 then
                local reaction=tonumber(reaction_ms) or 200
                if reaction~=reaction then reaction=200 end
                reaction=math.max(50,math.min(1000,reaction))/1000
                local frame=math.max(1/120,math.min(.25,tonumber(frame_delay) or 1/60))
                result.remaining=math.max(0,3-timer-age)
                result.margin=reaction+1/30+2*frame+.005
                result.release=result.remaining<=result.margin
                result.limit=result.remaining<=0
            end
        end
        return result
    end
end
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
        out[#out+1]={type='rect',decoration=true,charge_meter=frame.charge_meter,x=left+dx,y=bottom+dy,w=bw,h=bh,
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
    elseif style=='deadeye' then
        -- Original R-6 receiver perimeter: silver rails and four inset brass squares.
        local silver,brass={198,210,218},{218,172,78}
        border(0,0,w,line,silver,.55);border(0,h-line,w,line,silver,.55)
        border(0,0,line,h,silver,.55);border(w-line,0,line,h,silver,.55)
        local inset=math.min(4*scale,w/8,h/8)
        local size=math.min(3*scale,w/10,h/5)
        for _,dx in ipairs({inset,w-inset-size}) do
            for _,dy in ipairs({inset,h-inset-size}) do border(dx,dy,size,size,brass,.75) end
        end
    end
end
function M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    local frames={};for _,v in ipairs(out)do if v.type=='panel' then frames[#frames+1]=v end end
    if cfg.decoration and cfg.decoration~='none' then
        -- Replace only the built-in outer perimeter; retain interior approved art.
        local kept={}
        for _,v in ipairs(out)do
            local perimeter=false
            if v.type=='rect' then for _,f in ipairs(frames)do
                local eps=scale*.00001
                local horizontal=math.abs(v.x-f.x+scale)<eps and math.abs(v.w-f.w-2*scale)<eps and (math.abs(v.y-f.y+scale)<eps or math.abs(v.y+v.h-f.y-f.h-scale)<eps)
                local vertical=math.abs(v.y-f.y+scale)<eps and math.abs(v.h-f.h-2*scale)<eps and (math.abs(v.x-f.x+scale)<eps or math.abs(v.x+v.w-f.x-f.w-scale)<eps)
                perimeter=perimeter or horizontal or vertical
            end end
            if not perimeter then kept[#kept+1]=v end
        end
        out=kept
        for _,frame in ipairs(frames)do
            local group={};M.decorate(group,frame,scale,cfg,opacity)
            for _,v in ipairs(group)do v.child=frame.child;out[#out+1]=v end
        end
    end
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
                local count=cfg.effect_scanline_count or 21
                for k=1,count do out[#out+1]={type='rect',x=frame.x,y=frame.y+frame.h*k/(count+1),w=frame.w,h=thickness,c=ink,a=.12*opacity,effect_shader_band=true,effect_owner=frame,child=frame.child,fold_child=frame.fold_child,df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,df_effect_fraction=k/(count+1)} end
            end
            if cfg.effect_sweep then
                local band=math.min(frame.h,thickness*2)
                local sweep_count=math.max(1,math.min(12,math.floor(cfg.effect_sweep_density or 3)))
                local spacing=math.max(.001,out[1].h/sweep_count)
                local speed=(cfg.effect_sweep_speed or .35)*out[1].h
                local offset=((clock or 0)*speed)%spacing
                for k=-1,math.ceil(frame.h/spacing)do
                    local low=offset+k*spacing;local bottom=math.max(0,low);local top=math.min(frame.h,low+band)
                    if top>bottom then
                        out[#out+1]={type='rect',x=frame.x,y=frame.y+bottom,w=frame.w,h=top-bottom,c=ink,a=.2*opacity,
                            df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,
                            df_effect_fraction=bottom/math.max(.001,frame.h-band),df_effect_sweep=true,effect_band=band,effect_clock=clock or 0,effect_owner=frame,child=frame.child,fold_child=frame.fold_child}
                    end
                end
            end
        end
    end
    return out
end
function M.scorcher_step(state,m,now)
    if not m or m.resource_hex~='eea5e3cef1e12c14' or type(m.value)~='number' then
        state.id=nil;state.value=nil;state.until_time=nil;return
    end
    if state.id~=m.id then state.id=m.id;state.value=m.value;state.until_time=nil end
    if state.value and state.value-m.value==1 then state.until_time=now+.10 end
    state.value=m.value
    m.scorcher_flash=math.max(0,math.min(1,((state.until_time or now)-now)/.10))
end
M.ultimatum_panel=(function()
-- Offline GP-20 Ultimatum proposal; no installed runtime or settings changes.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=144,118
 local steel,olive,brass,ice,shadow,red={116,132,119},{26,34,27},{235,190,65},{230,237,222},{9,14,11},{239,97,69}
 local function r(dx,dy,rw,rh,c,a,tag)
  out[#out+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel' and cfg.frosted or nil,ultimatum_detail=tag}
 end
 local function t(text,dx,dy,size,c,center)
  local a,b,e,f=measure(text,size*s);local xx=x+dx*s
  if center then xx=xx-(a+e)/2 end
  out[#out+1]={type='text',text=text,x=xx,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,numeric_display=text:match('^%d+$')~=nil}
 end
 r(1,1,w-2,h-2,olive,cfg.panel_opacity,'panel')
 for _,v in ipairs({{0,0,w,1},{0,h-1,w,1},{0,0,1,h},{w-1,0,1,h}})do r(v[1],v[2],v[3],v[4],steel,.65,'perimeter')end
 t('GP-20',8,105,9,ice);t('ULTIMATUM',86,105,9,brass,true)
 r(7,100,w-14,1,brass,.6)
 -- Reference-matched wide dark casing, yellow collar, white nose and yellow tip.
 r(9,35,1,59,steel,.3);r(50,35,1,59,steel,.3)
 for _,dy in ipairs({39,89})do
  r(10,dy,8,2,{59,68,67},.9);r(42,dy,8,2,{59,68,67},.9)
 end
 -- Neck and attachment flange under a broad, gently curved payload body.
 r(22,36,16,8,{74,82,85},1);r(23,37,3,7,{135,146,148},.8)
 r(18,42,24,3,{91,102,105},1);r(19,44,22,.7,{185,195,193},.8)
 for i=0,27 do
  local half=17.5-math.max(0,4-i)*.75-math.max(0,i-23)*.3
  r(30-half,45+i,half*2,1,{63,71,77},1,'cartridge')
  r(30-half+1,45+i,2,1,{106,119,124},.8)
  r(30+half-3,45+i,2,1,{34,41,47},1)
 end
 r(13,50,34,.7,{160,173,174},.65);r(13,52,34,.5,{26,33,38},1)
 r(13,69,34,.8,{155,170,173},.6);r(13,71,34,.6,{25,33,39},1)
 -- Yellow collar has its own shaded rim, as on the reference.
 r(13,73,34,6,{234,193,19},1);r(14,73,3,6,{250,216,56},1)
 r(43,73,3,6,{163,133,13},1);r(14,78,32,.6,{255,231,106},.9)
 -- White curved nose reduces toward a rounded yellow center cap.
 for i=0,8 do
  local half=17-i*.9
  r(30-half,79+i,half*2,1,{225-i*3,230-i*3,225-i*2},1,'nose-cap')
  r(30-half+1,79+i,2,1,{247,248,235},.8)
  r(30+half-2,79+i,1,1,{158,168,164},.9)
 end
 for i=0,4 do
  local half=math.sqrt(math.max(0,1-(i/5)^2))*7
  r(30-half,86+i,half*2,1,{232-i*8,193-i*7,20},1,'yellow-tip')
 end
 -- Upright equilateral explosion-hazard triangle, fixed identification artwork.
 for i=0,10 do
  local half=(10.5-i)/math.sqrt(3)
  r(30-half,56+i,half*2,1,{230,184,27},.95)
 end
 local mark={44,51,55}
 for _,v in ipairs({{28.5,58,3,2},{27,59,2,1},{31,59,2,1},{29,60,1,2},{27,61,1,1},{31,61,1,1},{26,57,1,1},{33,57,1,1},{29,63,1,1}})do r(v[1],v[2],v[3],v[4],mark,1)end
 -- Recessed count bezel and fine fasteners frame the instrument, not its digits.
 r(56,45,77,37,{8,15,11},.6)
 r(57,80,75,.6,steel,.4);r(57,46,75,.6,steel,.3)
 for _,dx in ipairs({5,137})do for _,dy in ipairs({5,112})do
  r(dx,dy,2,2,{42,54,43},1);r(dx+.4,dy+.8,1.2,.4,steel,.7)
 end end
 local valid=type(m.value)=='number' and m.value>=0 and m.value%1==0
 local loaded=valid and m.value>0
 t(valid and string.format('%02d',m.value) or '--',94,53,34,loaded and ice or red,true)
 t('PAYLOAD',94,86,7,steel,true)
 t(m.capacity and ('/ '..tostring(m.capacity)) or '/ --',125,51,8,steel,true)
 r(58,44,74,1,steel,.3)
 t(valid and (loaded and 'LOADED' or 'EMPTY') or 'UNKNOWN',94,31,8,loaded and brass or red,true)
 r(7,25,w-14,1,steel,.35)
 local reserve=type(m.reserve)=='number' and string.format('%03d',m.reserve) or '---'
 local label=reserve..' WARHEAD'
 local size=8;local a,b,e,f=measure(label,size*s)
 if e-a>124*s then size=size*124*s/(e-a) end
 t(label,w/2,11,size,ice,true)
 -- Sparse static corner safety markings; no extra animated geometry.
 for _,dx in ipairs({5,134})do for i=0,2 do r(dx,87+i*3,5,1,brass,.6)end end
 return out
end

end)()
M.leveller_panel=(function()
-- Offline EAT-411 Leveller proposal; no installed runtime or settings changes.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=144,118
 local steel,olive,brass,ice,shadow,red={116,132,119},{26,34,27},{235,190,65},{230,237,222},{9,14,11},{239,97,69}
 local function r(dx,dy,rw,rh,c,a,tag)
  out[#out+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel' and cfg.frosted or nil,ultimatum_detail=tag}
 end
 local function t(text,dx,dy,size,c,center)
  local a,b,e,f=measure(text,size*s);local xx=x+dx*s
  if center then xx=xx-(a+e)/2 end
  out[#out+1]={type='text',text=text,x=xx,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,numeric_display=text:match('^%d+$')~=nil}
 end
 r(1,1,w-2,h-2,olive,cfg.panel_opacity,'panel')
 for _,v in ipairs({{0,0,w,1},{0,h-1,w,1},{0,0,1,h},{w-1,0,1,h}})do r(v[1],v[2],v[3],v[4],steel,.65,'perimeter')end
 t('EAT-411',8,105,8,ice);t('LEVELLER',96,105,9,brass,true)
 r(7,100,w-14,1,brass,.6)
 -- Reference-shaped detachable warhead: silver casing, yellow band, rear fins.
 r(9,34,1,60,steel,.3);r(50,34,1,60,steel,.3)
 r(24,35,12,8,{73,83,89},1,'coupling')
 r(23,36,14,2,{155,166,169},1);r(24,42,12,1,ice,.65)
 -- Four rear stabilizers surround the reduced rear shroud.
 for _,v in ipairs({{14,43,5,15},{41,43,5,15},{19,40,5,7},{36,40,5,7}})do
  r(v[1],v[2],v[3],v[4],{120,131,136},1,'rear-fin')
  r(v[1],v[2]+v[4]-1,v[3],.7,{208,216,215},.8)
 end
 r(18,44,24,15,{105,119,127},1);r(19,45,3,13,{171,185,190},.8)
 r(38,45,3,13,{58,72,82},1)
 for _,dx in ipairs({23,35})do r(dx,45,2,13,{49,62,72},1);r(dx+1,45,.6,13,{190,204,207},.7)end
 -- Broad cylindrical silver body with shaded curvature and seam rings.
 for i=0,16 do
  local half=16-math.max(0,i-13)*.5
  r(30-half,59+i,half*2,1,{137,150,156},1,'warhead-body')
  r(30-half+1,59+i,3,1,{208,219,220},.85)
  r(30+half-4,59+i,3,1,{79,96,107},1)
 end
 for _,dy in ipairs({58,60,73,75})do r(15,dy,30,.6,{39,54,66},.9)end
 r(15,76,30,5,{238,190,29},1,'yellow-band')
 r(16,76,3,5,{255,222,86},.9);r(40,76,4,5,{173,126,15},1)
 -- Short rounded nose with a yellow center cap.
 for i=0,8 do
  local half=15-i*1.05
  r(30-half,81+i,half*2,1,{197-i*3,209-i*3,210-i*3},1,'silver-nose')
  r(30-half+1,81+i,2,1,{239,243,234},.8)
 end
 for i=0,3 do
  local half=math.sqrt(math.max(0,1-(i/4)^2))*5
  r(30-half,88+i,half*2,1,{221-i*9,179-i*9,25},1,'yellow-tip')
 end
 for _,dy in ipairs({39,89})do r(10,dy,6,1,steel,.4);r(44,dy,6,1,steel,.4)end
 -- Accepted Ultimatum equilateral explosion-hazard marking.
 for i=0,8 do
  local half=(8.5-i)/math.sqrt(3)
  r(30-half,62+i,half*2,1,{230,184,27},.95)
 end
 local mark={44,51,55}
 for _,v in ipairs({{29,64,2,2},{27.5,65,1.5,1},{31,65,1.5,1},{29.5,66,1,2},{27.5,67,1,1},{31.5,67,1,1},{26.5,63,1,1},{33,63,1,1}})do r(v[1],v[2],v[3],v[4],mark,1)end
 -- Recessed count bezel and fine fasteners frame the instrument, not its digits.
 r(56,45,77,37,{8,15,11},.6)
 r(57,80,75,.6,steel,.4);r(57,46,75,.6,steel,.3)
 for _,dx in ipairs({5,137})do for _,dy in ipairs({5,112})do
  r(dx,dy,2,2,{42,54,43},1);r(dx+.4,dy+.8,1.2,.4,steel,.7)
 end end
 local valid=type(m.value)=='number' and m.value>=0 and m.value%1==0
 local loaded=valid and m.value>0
 t(valid and string.format('%02d',m.value) or '--',94,53,34,loaded and ice or red,true)
 t('WARHEAD',94,86,7,steel,true)
 t(m.capacity and ('/ '..tostring(m.capacity)) or '/ --',125,51,8,steel,true)
 r(58,44,74,1,steel,.3)
 t(valid and (loaded and 'LOADED' or 'EMPTY') or 'UNKNOWN',94,31,8,loaded and brass or red,true)
 r(7,25,w-14,1,steel,.35)
 local reserve=type(m.reserve)=='number' and string.format('%03d',m.reserve) or '---'
 local label=type(m.reserve)=='number' and (reserve..' WARHEAD') or 'SINGLE USE'
 local size=8;local a,b,e,f=measure(label,size*s)
 if e-a>124*s then size=size*124*s/(e-a) end
 t(label,w/2,11,size,ice,true)
 -- Sparse static corner safety markings; no extra animated geometry.
 for _,dx in ipairs({5,134})do for i=0,2 do r(dx,87+i*3,5,1,brass,.6)end end
 return out
end

end)()
M.breacher_panel=(function()
-- P-34 Breacher reference-led break-open receiver proposal; offline only.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=158,112
 local dark,steel,edge,ice,yellow={27,31,34},{86,95,100},{145,155,160},{226,233,235},{240,193,28}
 local function r(dx,dy,rw,rh,c,a,tag)
  out[#out+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel' and cfg.frosted or nil}
 end
 local function t(text,dx,dy,size,c,center)
  local a,b,e,f=measure(text,size*s);local xx=x+dx*s
  if center then xx=xx-(a+e)/2 end
  out[#out+1]={type='text',text=text,x=xx,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,numeric_display=text:match('^%d+$')~=nil}
 end
 r(1,1,w-2,h-2,dark,cfg.panel_opacity,'panel')
 -- Asymmetric receiver perimeter, with a wide top designation plate.
 r(0,0,w,1,edge,.5);r(0,h-1,w,1,edge,.55);r(0,0,1,h,edge,.4);r(w-1,0,1,h,edge,.4)
 r(5,95,w-10,12,{50,57,61},.8);r(6,95,w-12,1,yellow,.85)
 t('P-34',10,98,8,ice);t('BREACHER',100,98,10,yellow,true)
 -- Long yellow nose and grooved gray casing from the supplied ammunition reference.
 local projectile_start=#out+1
 r(17,67,16,19,steel,1);r(18,68,2,17,edge,.9)
 for _,dx in ipairs({21,25,29})do r(dx,69,.8,15,{41,49,55},1);r(dx+.8,69,.5,15,edge,.5)end
 r(15,85,20,3,{170,181,184},1);r(17,82,16,2,yellow,.95)
 r(16,63,18,4,{177,135,16},1);r(17,66,16,.7,{255,221,75},.8)
 r(17,54,16,9,{135,146,149},1);r(18,55,2,7,{199,207,204},.8)
 r(17,51,16,3,{177,135,16},1)
 r(17,34,16,17,yellow,1);r(18,35,2,15,{255,221,67},.85);r(30,35,2,15,{158,115,8},1)
 for i=0,8 do local half=1.2+i*.8;r(25-half,26+i,half*2,1,{225-i*3,175-i*2,18},1)end
 r(22,25,6,1,{178,131,14},1)
 for i=projectile_start,#out do local v=out[i];v.x=x+50*s-(v.x-x)-v.w;v.y=y+113*s-(v.y-y)-v.h end
 -- Open breech rails and steel receiver housing; count is the receiver instrument.
 r(45,27,103,58,{16,22,26},.8)
 r(45,79,103,6,{113,125,133},.9);r(46,84,101,.7,ice,.6)
 r(45,27,103,6,{83,95,104},.9);r(46,32,101,.7,edge,.6)
 r(143,34,5,44,{113,125,133},.9);r(146,35,1,42,ice,.4)
 for i=0,3 do r(49+i*5,37,2,8,steel,.6)end
 r(43,28,8,8,steel,1);r(45,30,4,4,edge,.9);r(46,31,2,2,dark,1)
 local valid=type(m.value)=='number' and m.value>=0 and m.value%1==0
 t(valid and string.format('%02d',m.value) or '--',100,45,35,valid and m.value==0 and {238,105,72} or ice,true)
 t('AMMO',100,74,6,edge,true)
 t(m.capacity and ('/ '..tostring(m.capacity)) or '/ --',133,43,8,edge,true)
 -- Three recessed inspection ports echo the angled breech block in the reference.
 for _,dx in ipairs({68,97,126})do r(dx,86,6,5,steel,.9);r(dx+1,87,4,3,{18,25,29},1);r(dx+2,87,2,.6,edge,.6)end
 r(7,18,w-14,.7,edge,.35)
 local reserve=type(m.reserve)=='number' and string.format('%03d',m.reserve) or '---'
 local label=reserve..' SHELLS'
 local size=8;local a,b,e,f=measure(label,size*s);if e-a>138*s then size=size*138*s/(e-a)end
 t(label,w/2,7,size,ice,true)
 return out
end

end)()
M.hotshot_panel=(function()
-- R/40-K Hot-Shot / accepted Warhammer family proposal; preview only.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=144,116
 local steel,rim,ice={24,29,33},{148,159,165},{225,234,235}
 local copper,gold,bone,red,shadow={205,124,59},{185,143,63},{222,211,169},{130,37,29},{9,15,18}
 local flash=math.max(0,math.min(1,m.bolt_shot_flash or 0))
 local orange={247,151,54}
 local function r(dx,dy,rw,rh,c,a,tag)out[#out+1]={type=tag=='panel'and'panel'or'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel'and cfg.frosted or nil}end
 local function text(t,dy,size,c)local a,b,e,f=measure(t,size*s);out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w*s-a-e)/2,y=y+dy*s,size=size*s,c=c,a=opacity,numeric_display=t:match('^%d+$')~=nil}end
 r(0,0,w,h,steel,cfg.panel_opacity,'panel')
 r(0,0,w,1,rim,.65);r(0,h-1,w,1,rim,.65);r(0,0,1,h,rim,.65);r(w-1,0,1,h,rim,.65)
 for _,dx in ipairs({4,w-7})do for _,dy in ipairs({4,h-7})do r(dx,dy,3,3,shadow);r(dx+.5,dy+1.2,2,.5,rim)end end
 text('R/40-K HOT-SHOT',101,9,copper)
 for _,dx in ipairs({18,112})do r(dx,109,14,3,{63,58,44},.95);r(dx,112,14,1,gold,.8)end
 r(8,94,128,1,copper,.65)
 -- The accepted Melta winged skull: brass feathers, bone face, dark sockets.
 r(68,91,8,6,bone);r(69,97,6,1,gold)
 r(69,94,2,1,shadow);r(73,94,2,1,shadow);r(71,91,2,2,shadow)
 for k=0,3 do r(53+k*3,95-k,13-k*3,1,gold,.85);r(78,95-k,13-k*3,1,gold,.85)end
 -- Detailed Imperialis: central skull and paired stepped feathered wings.
 -- Static merged rectangles; transparent gaps remain between the feather rows.
 local wing_dark,wing_light={101,78,36},{230,200,122}
 local function feather(side,dx,dy,width,height)
  local px=side<0 and dx or 144-dx-width
  r(px,dy,width,height,gold,.95)
  r(px,dy,width,.65,wing_dark,.9)
  r(px,dy+height-.65,width,.65,wing_light,.9)
 end
 for _,side in ipairs({-1,1})do
  feather(side,23,82,39,3)
  feather(side,28,78,34,3)
  feather(side,33,74,29,3)
  feather(side,38,70,24,3)
  feather(side,43,66,19,3)
  for k=0,4 do
   local dx=23+k*5;local dy=82-k*4
   local px=side<0 and dx or 144-dx-2
   r(px,dy,2,3,{162,123,55},1)
  end
  local px=side<0 and 59 or 82
  r(px,69,3,13,{137,103,48},.9)
 end
 -- Sculpted bone cranium, recessed orbital sockets, nasal notch and individual teeth.
 r(65,83,14,3,bone,1);r(63,78,18,6,bone,1);r(64,73,16,5,bone,1)
 r(66,69,12,5,{192,176,132},1);r(67,66,10,4,bone,1)
 r(65,81,14,1,{247,234,193},.9);r(64,78,1,4,{247,234,193},.8)
 r(79,75,1,7,{130,114,76},.85)
 r(65,75,5,4,shadow,1);r(74,75,5,4,shadow,1)
 r(66,78,4,1,{93,79,52},1);r(74,78,4,1,{93,79,52},1)
 r(70,71,4,3,shadow,1);r(71,74,2,2,shadow,1)
 r(65,72,3,1,{128,111,75},.9);r(76,72,3,1,{128,111,75},.9)
 for dx=68,76,2 do r(dx,66,1,3,shadow,.9);r(dx+1,66,1,.5,{255,237,188},.7)end
 r(69,64,6,1,gold,.8)
 -- The same paired parchment tabs and red wax seals as Melta.
 for _,dx in ipairs({5,135})do
  r(dx,42,4,13,bone,.9);r(dx+1,44,1,8,{111,99,72},.7)
  r(dx-1,54,6,5,red);r(dx,55,4,3,{192,61,40},.8)
 end
 text(m.kind=='heat' and (m.state=='VENT' and 'COOLDOWN' or 'HEAT') or 'ENERGY',53,8,rim)
 local n=tonumber(m.value);text(n and string.format('%03d',n)or'---',24,32,m.warning and {245,111,63}or ice)
 local cap=m.kind~='heat' and tonumber(m.capacity) or nil
 if cap and cap>=1 and cap<=24 and cap%1==0 then local gap=3;local pw=(120-(cap-1)*gap)/cap
  for k=0,cap-1 do r(12+k*(pw+gap),19,pw,2,k<(n or 0)and orange or rim,k<(n or 0)and 1 or .18)end
 end
 r(9,15,126,.5,rim,.25)
 local reserve=type(m.reserve)=='number'and string.format('%03d',m.reserve)or'---'
 text(reserve..' POWER PACKS',5,8,rim)
 return out
end

end)()
M.sg8_panel=(function()
-- SG-8 Punisher tube-fed receiver proposal; offline only.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=158,112
 local dark,steel,edge,ice,yellow={27,31,34},{86,95,100},{145,155,160},{226,233,235},{240,193,28}
 local function r(dx,dy,rw,rh,c,a,tag)
  out[#out+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel' and cfg.frosted or nil}
 end
 local function t(text,dx,dy,size,c,center)
  local a,b,e,f=measure(text,size*s);local xx=x+dx*s
  if center then xx=xx-(a+e)/2 end
  out[#out+1]={type='text',text=text,x=xx,y=y+dy*s,size=size*s,font=cfg.font,c=c,a=opacity,numeric_display=text:match('^%d+$')~=nil}
 end
 r(1,1,w-2,h-2,dark,cfg.panel_opacity,'panel')
 -- Asymmetric receiver perimeter, with a wide top designation plate.
 r(0,0,w,1,edge,.5);r(0,h-1,w,1,edge,.55);r(0,0,1,h,edge,.4);r(w-1,0,1,h,edge,.4)
 r(5,95,w-10,12,{50,57,61},.8);r(6,95,w-12,1,yellow,.85)
 t('SG-8',10,98,8,ice);t('PUNISHER',100,98,10,yellow,true)
 -- High-detail shell: folded crimp, molded hull, shallow ribs and brass head.
 r(17,39,16,42,{147,51,40},1,'shell-hull')
 r(18,40,2,40,{219,96,66},.85);r(30,40,2,40,{93,31,27},1)
 for _,dx in ipairs({21,24,27})do r(dx,42,.65,37,{106,34,29},.9);r(dx+.7,43,.4,36,{209,83,58},.45)end
 r(18,81,14,2,{126,46,37},1);r(19,82,12,.7,{223,111,84},.7)
 r(21,81,8,1,{62,30,27},.8);r(23,79,4,2,{86,29,26},.8)
 for _,dx in ipairs({19,23,27,31})do r(dx,80,1,2,{193,83,58},.75)end
 r(17,32,16,7,{179,136,49},1);r(18,33,2,5,{242,205,112},.85)
 r(30,33,2,5,{112,82,28},1)
 r(15,30,20,2,{201,157,63},1);r(16,31,18,.5,{255,222,142},.9)
 r(17,33,16,.7,{101,75,31},.85);r(17,38,16,.6,{248,208,104},.8)
 -- Two slim retaining brackets frame the shell without a filled backing.
 r(12,31,1,52,edge,.35);r(37,31,1,52,edge,.35)
 r(12,31,4,.6,edge,.6);r(34,31,4,.6,edge,.6)
 r(12,82,4,.6,edge,.6);r(34,82,4,.6,edge,.6)
 -- Receiver window and tubular magazine seam, with native count as primary readout.
 r(45,27,103,58,{16,22,26},.8)
 r(45,79,103,6,{113,125,133},.9);r(46,84,101,.7,ice,.6)
 r(45,27,103,6,{83,95,104},.9);r(46,32,101,.7,edge,.6)
 r(143,34,5,44,{113,125,133},.9);r(146,35,1,42,ice,.4)
 for i=0,3 do r(49+i*5,37,2,8,steel,.6)end
 r(43,28,8,8,steel,1);r(45,30,4,4,edge,.9);r(46,31,2,2,dark,1)
 local valid=type(m.value)=='number' and m.value>=0 and m.value%1==0
 t(valid and string.format('%02d',m.value) or '--',100,45,35,valid and m.value==0 and {238,105,72} or ice,true)
 t('SHELLS',100,74,6,edge,true)
 t(m.capacity and ('/ '..tostring(m.capacity)) or '/ --',133,43,8,edge,true)
 -- Tubular magazine and six fine receiver ribs echo the pump-action housing.
 r(46,86,101,5,{79,91,98},.9);r(47,90,99,.6,ice,.45)
 for i=0,5 do r(52+i*15,86,2,5,{36,46,54},.8)end
 local cap=tonumber(m.capacity)
 if cap and cap>=1 and cap<=32 and cap%1==0 then
  local cols=math.min(cap,16);local pitch=90/cols
  for i=0,cap-1 do r(53+(i%cols)*pitch,35-math.floor(i/cols)*3,pitch-1.4,1.3,i<(tonumber(m.value) or 0) and yellow or edge,i<(tonumber(m.value) or 0) and .85 or .2)end
 end
 r(7,18,w-14,.7,edge,.35)
 local reserve=type(m.reserve)=='number' and string.format('%03d',m.reserve) or '---'
 local label=reserve..' SHELLS'
 local size=8;local a,b,e,f=measure(label,size*s);if e-a>138*s then size=size*138*s/(e-a)end
 t(label,w/2,7,size,ice,true)
 return out
end

end)()
M.loyalist_panel=(function()
-- PLAS-15 Loyalist redesign proposal; isolated preview, not installed.
return function(m,x,y,s,opacity,cfg,measure,clock)
 local d={};local w,h=144,118
 local loyalist=m.resource_hex=='aa69a60d74a3ec54';local purifier=m.resource_hex=='fb3a19078694708a'
 local epoch=m.resource_hex=='e8d5f49ad7780e54'
 local q=loyalist and m.loyalist_charge_fraction or epoch and m.epoch_charge_fraction or purifier and m.purifier_charge_fraction or nil
 local valid=type(q)=='number' and q==q and q>=0 and q<=1
 local glow=valid and q or (m.resource_hex=='eea5e3cef1e12c14' and (m.scorcher_flash or 0) or 0)
 local epoch_state=epoch and M.epoch_charge(q) or nil
 local full_warning=epoch_state and epoch_state.ready
 local charge_ink=full_warning and {255,32,32} or {74,210,238}
 local charge_alpha=full_warning and (.35+.65*(.5+.5*math.cos((clock or 0)*math.pi*8))) or .95
 local designation=loyalist and 'PLAS-15' or purifier and 'PLAS-101' or epoch and 'PLAS-45' or 'PLAS-1'
 local name=loyalist and 'LOYALIST' or purifier and 'PURIFIER' or epoch and 'EPOCH' or 'SCORCHER'
 local cyan,ice,steel,dark,yellow={74,210,238},{214,247,252},{120,143,154},{24,53,66},{246,205,96}
 local function rect(dx,dy,rw,rh,c,a,tag)
  d[#d+1]={type=tag=='panel' and 'panel' or 'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel' and cfg.frosted or nil,capacitor_glow=tag=='capacitor_glow'}
 end
 local function text(t,dx,dy,size,c,center)
  local a,b,e,f=measure(t,size*s);local xx=x+dx*s
  if center then xx=xx-(a+e)/2 end
  d[#d+1]={type='text',text=t,font=cfg.font,x=xx,y=y+dy*s,size=size*s,c=c,a=opacity}
 end
 rect(1,1,w-2,h-2,{13,23,30},cfg.panel_opacity,'panel')
 rect(0,0,w,1,steel,.55);rect(0,h-1,w,1,steel,.65);rect(0,0,1,h,steel,.45);rect(w-1,0,1,h,steel,.45)
 rect(6,108,3,4,cyan,1);text(designation,15,106,9,ice,false);text(name,w-6,107,7,steel,false)
 -- Right-align the name using the native font extent.
 local v=d[#d];local a,b,e,f=measure(v.text,v.size);v.x=x+(w-6)*s-e
 rect(7,101,w-14,1,cyan,.55)
 -- Selected ammunition remains the largest instrument; eight slots are exact rounds.
 text(string.format('%02d',tonumber(m.value) or 0),88,52,34,m.warning and yellow or ice,true)
 if purifier and valid and q>=1-1e-6 and m.charge_ready then local v=d[#d];v.c={0,255,255};v.a=v.a*(.35+.65*(.5+.5*math.cos((clock or 0)*math.pi*2*(cfg.flash_hz or 2)))) end
 text('/ '..tostring(m.capacity or '--'),123,51,8,steel,true)
 text('AMMO',88,87,7,steel,true)
 local cap=tonumber(m.capacity)
 if cap and cap>=1 and cap<=32 and cap%1==0 then
  local gap=cap==8 and 3 or 1.5;local pw=cap==8 and 7 or (83-(cap-1)*gap)/cap
  for i=0,cap-1 do rect(48+i*(pw+gap),82,pw,2,i<(tonumber(m.value) or 0) and cyan or steel,i<(tonumber(m.value) or 0) and .9 or .2) end
 end
 -- Native charge progressively illuminates the existing capacitor. Three inexpensive halo rectangles.
 rect(9,42,28,50,dark,.7)
 rect(9,42,2,50,steel,.55);rect(35,42,2,50,steel,.55)
 rect(14,46,18,42,{10,19,25},.9)
 rect(15,48,16,38,cyan,.09*glow,'capacitor_glow')
 rect(17,49,12,36,cyan,.16*glow,'capacitor_glow')
 rect(18,50,10,34,cyan,.23*glow,'capacitor_glow')
 rect(19,51,8,32,cyan,.12+.70*glow,'capacitor_glow')
 local core={math.floor(74+(214-74)*glow),math.floor(210+(247-210)*glow),math.floor(238+(252-238)*glow)}
 rect(21,51,4,32,core,.27+.73*glow,'capacitor_glow')
 for _,dy in ipairs({54,65,76}) do rect(13,dy,20,2,steel,.65) end
 rect(16,85,14,2,ice,.85);rect(16,46,14,2,ice,.85)
 text('PLASMA',23,32,6,steel,true)
 rect(45,42,86,1,steel,.3)
 local reserve=type(m.reserve)=='number' and tostring(m.reserve) or '--'
 text(reserve..' BATTERIES',88,29,7,steel,true)
 -- Existing native-calibrated charge is integrated into the bottom instrument strip.
 rect(7,25,w-14,1,steel,.35)
 text((loyalist or purifier or epoch) and 'CHARGE' or 'PLASMA',8,14,7,charge_ink,false)
 local label=valid and string.format('%03d%%',math.floor(q*100+.5)) or ((loyalist or epoch) and '--' or purifier and '--' or ((tonumber(m.value) or 0)>0 and 'READY' or 'EMPTY'))
 local a,b,e,f=measure(label,7*s);text(label,w-8-(e-a)/s,14,7,full_warning and charge_ink or valid and q>=.999 and ice or cyan,false)
 if loyalist or purifier or epoch then
  rect(8,6,w-16,4,dark,.85)
  if valid and q>0 then rect(8,6,(w-16)*q,4,charge_ink,charge_alpha);d[#d].epoch_full_warning=full_warning==true;d[#d].charge_meter=true end
 end
 if m.resource_hex=='eea5e3cef1e12c14' and (m.fire_mode=='AUTO' or m.fire_mode=='SEMI') then
  local cw,ch=48,16;local cx=(w-cw)/2
  rect(cx,-ch-2,cw,ch,{13,23,30},cfg.panel_opacity,'panel');d[#d].child=true
  text(m.fire_mode,w/2,-ch+2,8,ice,true);d[#d].child=true
 end
 return d
end

end)()
M.bolt_pistol_panel=(function()
-- P/40-K Bolt Pistol / Melta reliquary-family proposal; preview only.
return function(m,x,y,s,opacity,cfg,measure)
 local out={};local w,h=144,116
 local steel,rim,ice={24,29,33},{148,159,165},{225,234,235}
 local copper,gold,bone,red,shadow={205,124,59},{185,143,63},{222,211,169},{130,37,29},{9,15,18}
 local flash=math.max(0,math.min(1,m.bolt_shot_flash or 0))
 local orange={247,151,54}
 local function r(dx,dy,rw,rh,c,a,tag)out[#out+1]={type=tag=='panel'and'panel'or'rect',x=x+dx*s,y=y+dy*s,w=rw*s,h=rh*s,c=c,a=(a or 1)*opacity,frosted=tag=='panel'and cfg.frosted or nil}end
 local function text(t,dy,size,c)local a,b,e,f=measure(t,size*s);out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w*s-a-e)/2,y=y+dy*s,size=size*s,c=c,a=opacity,numeric_display=t:match('^%d+$')~=nil}end
 r(0,0,w,h,steel,cfg.panel_opacity,'panel')
 r(0,0,w,1,rim,.65);r(0,h-1,w,1,rim,.65);r(0,0,1,h,rim,.65);r(w-1,0,1,h,rim,.65)
 for _,dx in ipairs({4,w-7})do for _,dy in ipairs({4,h-7})do r(dx,dy,3,3,shadow);r(dx+.5,dy+1.2,2,.5,rim)end end
 text('P/40-K BOLT',101,10,copper)
 for _,dx in ipairs({18,112})do r(dx,109,14,3,{63,58,44},.95);r(dx,112,14,1,gold,.8)end
 r(8,94,128,1,copper,.65)
 -- The accepted Melta winged skull: brass feathers, bone face, dark sockets.
 r(68,91,8,6,bone);r(69,97,6,1,gold)
 r(69,94,2,1,shadow);r(73,94,2,1,shadow);r(71,91,2,2,shadow)
 for k=0,3 do r(53+k*3,95-k,13-k*3,1,gold,.85);r(78,95-k,13-k*3,1,gold,.85)end
 -- Heavy bolt cartridge in a recessed armor cradle; not a heat/charge instrument.
 r(28,65,7,20,{72,78,80});r(30,68,2,14,rim,.7)
 r(38,66,46,18,{92,64,35});r(40,68,42,14,copper,.8)
 r(41,79,41,2,bone,.7);r(41,68,41,2,gold,.8)
 r(48,68,3,13,{61,42,26},.65);r(72,68,3,13,{61,42,26},.65)
 r(84,67,7,16,red);r(86,68,2,14,{192,61,40},.8)
 r(92,68,8,14,rim);r(100,70,5,10,ice,.85);r(105,73,5,4,ice,.75)
 r(39,64,43,1,gold,.5)
 if flash>0 then r(38,66,53,18,orange,flash*.17);r(93,72,17,6,{255,225,157},flash*.7)end
 -- The same paired parchment tabs and red wax seals as Melta.
 for _,dx in ipairs({5,135})do
  r(dx,42,4,13,bone,.9);r(dx+1,44,1,8,{111,99,72},.7)
  r(dx-1,54,6,5,red);r(dx,55,4,3,{192,61,40},.8)
 end
 text('BOLTS',53,8,rim)
 local n=tonumber(m.value);text(n and string.format('%03d',n)or'---',24,32,m.warning and {245,111,63}or ice)
 local cap=tonumber(m.capacity)
 if cap and cap>=1 and cap<=24 and cap%1==0 then local gap=3;local pw=(120-(cap-1)*gap)/cap
  for k=0,cap-1 do r(12+k*(pw+gap),19,pw,2,k<(n or 0)and orange or rim,k<(n or 0)and 1 or .18)end
 end
 r(9,15,126,.5,rim,.25)
 local reserve=type(m.reserve)=='number'and string.format('%03d',m.reserve)or'---'
 text(reserve..' MAGS',5,9,rim)
 return out
end

end)()
function M.compose(m,x,y,scale,opacity,cfg,clock,measure)
    if m.resource_hex=='4ba41b6f9f405cc2' then
        return M.finish_custom_panel(HUD.sta11_panel(m,x,y,scale,opacity,cfg,measure),m,scale,opacity,cfg,clock)
    end
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
    if m.resource_hex=='9eb160830321bfd6' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        local out=M.ultimatum_panel(m,x,y,scale,opacity,cfg,extent)
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='7617642765ac38c7' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        if not M.leveller_draw_verified then
            M.leveller_draw_verified=true
            local f=io.open(((os.getenv('LOCALAPPDATA') or '.')..'/LLL/Helldivers2/Logs/Leveller-layout-checkpoint.log'),'a')
            if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ')..' APPROVED_LEVELLER_LAYOUT selected='..tostring(m.resource_hex)..'\n');f:close() end
        end
        local out=M.leveller_panel(m,x,y,scale,opacity,cfg,extent)
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='e91f569c2ad8af01' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        if not M.breacher_draw_verified then
            M.breacher_draw_verified=true
            local f=io.open(((os.getenv('LOCALAPPDATA') or '.')..'/LLL/Helldivers2/Logs/Breacher-layout-checkpoint.log'),'a')
            if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ')..' APPROVED_BREACHER_LAYOUT selected='..tostring(m.resource_hex)..'\n');f:close() end
        end
        local out=M.breacher_panel(m,x,y,scale,opacity,cfg,extent)
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='1abbff60d26ba391' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        if not M.hotshot_draw_verified then
            M.hotshot_draw_verified=true
            local f=io.open(((os.getenv('LOCALAPPDATA') or '.')..'/LLL/Helldivers2/Logs/HotShot-layout-checkpoint.log'),'a')
            if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ')..' APPROVED_HOTSHOT_LAYOUT selected='..tostring(m.resource_hex)..'\n');f:close() end
        end
        local out=M.hotshot_panel(m,x,y,scale,opacity,cfg,extent)
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='41eac4a03987faa0' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        if not M.sg8_draw_verified then
            M.sg8_draw_verified=true
            local f=io.open(((os.getenv('LOCALAPPDATA') or '.')..'/LLL/Helldivers2/Logs/SG8-layout-checkpoint.log'),'a')
            if f then f:write(os.date('!%Y-%m-%dT%H:%M:%SZ')..' APPROVED_SG8_LAYOUT selected='..tostring(m.resource_hex)..'\n');f:close() end
        end
        local out=M.sg8_panel(m,x,y,scale,opacity,cfg,extent)
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='dbb6c961c59fadc1' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        local out=M.bolt_pistol_panel(m,x,y,scale,opacity,cfg,extent)
        -- Bespoke panels also honor the selected shared decoration.
        local frames={};for _,v in ipairs(out) do if v.type=='panel' then frames[#frames+1]=v end end
        for _,frame in ipairs(frames) do
            local group={};M.decorate(group,frame,scale,cfg,opacity)
            for _,v in ipairs(group) do v.child=frame.child;out[#out+1]=v end
        end
        for _,v in ipairs(out)do if v.type=='text' then
            v.a=v.a*(cfg.text_opacity or 1)
            if v.numeric_display and m.chamber_bonus==1 then v.last_digit_color={255,221,0} end
        end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
    if m.resource_hex=='aa69a60d74a3ec54' or m.resource_hex=='eea5e3cef1e12c14' or m.resource_hex=='fb3a19078694708a' or m.resource_hex=='e8d5f49ad7780e54' then
        local extent=measure or function(t,size)return 0,-size*.2,#t*size*.6,size*.8 end
        local out=M.loyalist_panel(m,x,y,scale,opacity,cfg,extent,clock)
        -- Bespoke panels also honor the selected shared decoration.
        local frames={};for _,v in ipairs(out) do if v.type=='panel' then frames[#frames+1]=v end end
        for _,frame in ipairs(frames) do
            local group={};M.decorate(group,frame,scale,cfg,opacity)
            for _,v in ipairs(group) do v.child=frame.child;out[#out+1]=v end
        end
        for _,v in ipairs(out)do if v.type=='text' then v.a=v.a*(cfg.text_opacity or 1) end end
        return M.finish_custom_panel(out,m,scale,opacity,cfg,clock)
    end
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
        local label=(fuel and (m.label..': ') or m.resource_hex=='35a61296619cc47e' and (m.quasar_charge_verified and (vent and 'COOLDOWN: ' or 'CHARGE: ') or 'THERMAL: ') or vent and 'VENT: ' or 'HEAT: ')..percent
        local reserve=fuel and (m.reserve and string.format('%03d TANKS',m.reserve) or '-- TANKS') or (m.reserve and string.format('%03d:HTSNKS',m.reserve) or '--:HTSNKS')
        local size=16*scale
        local function width(t)
            if measure then local a,b,e,f=measure(t,size);if e then return (e-a)/scale end end
            return #t*16*.6
        end
        local digit_width=0
        for digit=0,9 do digit_width=math.max(digit_width,width(tostring(digit))) end
        local label_width=heat and (width(m.resource_hex=='35a61296619cc47e' and (m.quasar_charge_verified and (vent and 'COOLDOWN: ' or 'CHARGE: ') or 'THERMAL: ') or 'HEAT: ')+3*digit_width+width('%')) or width(label)
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
            if (heat and HUD.ammo_types.laser_weapons[m.resource_hex]==true) then
                for row=0,7 do
                    rect(0,3+row*4.5,bar_width,.35,{0,0,0},.08)
                    d[#d].heat_texture=true
                end
            else
            for row=0,7 do
                for column=0,23 do
                    local dx=(column+.25+(row%2)*.5)*bar_width/24
                    rect(dx,3+row*4.5,bar_width/96,.55,{0,0,0},.16)
                    d[#d].heat_texture=true
                end
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
            for i=((heat and HUD.ammo_types.laser_weapons[m.resource_hex]==true) and 5 or 1),99,((heat and HUD.ammo_types.laser_weapons[m.resource_hex]==true) and 5 or 1) do
                if i%10~=0 and i~=75 then
                    gauge_detail(i*bar_width/100,1,.6,3,{0,0,0},.4)
                    gauge_detail(i*bar_width/100,34,.6,3,{0,0,0},.4)
                end
            end
            for _,boundary in ipairs(fuel and {.15,.35} or {.65,.85}) do
                gauge_detail(boundary*bar_width-.5,1,1,36,{0,0,0},.5)
            end
        end
        local prefix=fuel and (m.label..': ') or m.resource_hex=='35a61296619cc47e' and (m.quasar_charge_verified and (vent and 'COOLDOWN: ' or 'CHARGE: ') or 'THERMAL: ') or vent and 'VENT: ' or 'HEAT: '
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
        if m.resource_hex~='35a61296619cc47e' then
        text(reserve,bar_width-width(reserve),-18,8,white,.9);d[#d].size=size;d[#d].heat_label='right'
        end
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

    elseif m.resource_hex=='5f3ec9bda2bd8553' or m.resource_hex=='14d5d4506056c7a4' then
        local missile=m.resource_hex=='14d5d4506056c7a4'
        local icon=missile and HUD.fire_icons.MISSILE_SIDE or HUD.fire_icons.HAMMER;local factor=missile and 1.25 or 1.5
        local charged=(tonumber(m.value) or 0)>0
        local color=charged and ink or {255,55,55}
        local alpha=charged and 1 or (.35+.65*(.5+.5*math.sin((clock or 0)*6)))
        for _,run in ipairs(icon.runs) do
            rect(run[1]*factor,5+run[2]*factor,run[3]*factor,run[4]*factor,charged and (run[5] or color) or color,alpha*(run[6] or 1))
            d[#d].hammer_indicator=true
        end
        if missile then
            local function centered(t,y,size,alpha)
                local width=#t*size*.6
                if measure then local a,b,c=measure(t,size*scale);if c then width=(c-(a or 0))/scale end end
                text(t,(icon.w*factor-width)/2,y,size,ink,alpha)
            end
            centered(m.reserve~=nil and string.format('%03d',m.reserve) or '--',-14,12,1)
            centered('MSL',-29,8,.8)
            centered(m.ammo_mode or 'GUIDANCE --',46,8,.9)
        else
            text(m.reserve and (string.format('%03d',m.reserve)..' CHARGES') or '-- CHARGES',0,-19,9,ink,.8)
        end
    elseif m.resource_hex=='72170a55a1f37ff1' then
        local icon=HUD.fire_icons.BARREL_SHELL;local factor=36/icon.h
        -- Rear-biased silhouette: broad brass base with only a short exposed hull.
        local function shell_y(y)
            return y<=9 and y*22/9 or 22+(y-9)*6/19
        end
        for barrel=1,2 do
            local alpha=(tonumber(m.value) or 0)>=(3-barrel) and .95 or .18
            rect((barrel-1)*20+3*factor,5+shell_y(11)*factor,6*factor,(shell_y(25)-shell_y(11))*factor,{65,145,235},alpha*.4)
            d[#d].barrel_indicator=barrel
            for _,run in ipairs(icon.runs)do
                local shell_color=run[2]<9 and {218,172,78} or {65,145,235}
                rect((barrel-1)*20+run[1]*factor,5+shell_y(run[2])*factor,run[3]*factor,(shell_y(run[2]+run[4])-shell_y(run[2]))*factor,shell_color,alpha)
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
            text(heading,0,heading_y,8,ink,0.72);d[#d].ammo_heading=true
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
            if fire_icon==HUD.fire_icons.SHELL or fire_icon==HUD.fire_icons.DOUBLE_SHELL or fire_icon==HUD.fire_icons.TRIPLE_SHELL then
                for _,offset in ipairs(fire_icon==HUD.fire_icons.TRIPLE_SHELL and {0,15,30} or fire_icon==HUD.fire_icons.DOUBLE_SHELL and {0,15} or {0}) do
                    rect(edge+icon_gap+(offset+3)*factor,icon_y+11*factor,6*factor,14*factor,{65,145,235},.36)
                    d[#d].mode_icon=true
                end
            end
            for _,run in ipairs(fire_icon.runs) do
                local color=run[5] or ink
                if fire_icon==HUD.fire_icons.SHELL or fire_icon==HUD.fire_icons.DOUBLE_SHELL or fire_icon==HUD.fire_icons.TRIPLE_SHELL then color=run[2]<9 and {218,172,78} or {65,145,235} end
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
    if m.resource_hex=='a8cffb316f0b5c5f' and (m.ammo_mode=='APHET' or m.ammo_mode=='FLAK') then
        -- Reserve both native label envelopes and the larger temporary mode pictogram.
        -- The final long-case heading replaces these pictograms; their widths must not size the box.
        local size=(pixel and 18 or 12)*scale
        local hy=(pixel and math.max(42,5+number_top+3) or 42)*scale
        for _,label in ipairs({'APHET','FLAK'}) do
            local a,b,e,f=0,-size*.2,#label*size*.6,size*.8
            if measure then a,b,e,f=measure(label,size) end
            left=math.min(left,x+a);right=math.max(right,x+e)
            bottom=math.min(bottom,y+hy+b);top=math.max(top,y+hy+f)
        end
        local edge=#number*(pixel and 36 or 32)*.6
        if measure then local a,b,e=measure(number,(pixel and 36 or 32)*scale);edge=e/scale end
        right=math.max(right,x+(edge+8+15*1.8)*scale)
        top=math.max(top,y+(5+17*1.8)*scale)
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
    if heading_command and icon_left<math.huge and m.resource_hex~='a8cffb316f0b5c5f' then
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

    if m.resource_hex=='aa69a60d74a3ec54' then
        local q=m.loyalist_charge_fraction
        local valid=type(q)=='number' and q==q and q>=0 and q<=1
        local cw,ch=right-left,22*scale
        local child={type='panel',child=true,loyalist_charge_meter=true,x=left,y=bottom-2*scale-ch,w=cw,h=ch,c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted}
        local label=valid and string.format('CHARGE %03d%%',math.floor(q*100+.5)) or 'CHARGE --'
        local size=7*scale;local a,b,ee,f=0,-size*.2,#label*size*.6,size*.8
        if measure then a,b,ee,f=measure(label,size) end
        local cyan={74,210,238};local group={child,
            {type='text',child=true,loyalist_charge_meter=true,text=label,font=cfg.font,x=child.x+(cw-a-ee)/2,y=child.y+3*scale-b,size=size,c=cyan,a=opacity*ink_alpha},
            {type='rect',child=true,loyalist_charge_meter=true,x=child.x+7*scale,y=child.y+14*scale,w=cw-14*scale,h=4*scale,c={24,64,86},a=.7*opacity}}
        if valid and q>0 then group[#group+1]={type='rect',child=true,loyalist_charge_meter=true,x=child.x+7*scale,y=child.y+14*scale,w=(cw-14*scale)*q,h=4*scale,c=cyan,a=opacity} end
        for _,command in ipairs(group) do out[#out+1]=command end
    end
    local epoch_charge=m.resource_hex=='e8d5f49ad7780e54' and M.epoch_charge(m.epoch_charge_fraction) or nil
    local railgun_charge=M.railgun_charge(m.safety_mode,m.charge_fraction,m.charge_seconds,
        cfg.railgun_release_margin_ms,m.charge_sample_clock and math.max(0,(clock or 0)-m.charge_sample_clock),m.charge_frame_delay)
    local child_label=m.safety_mode or m.fire_mode
    if railgun_charge and railgun_charge.ready then child_label='SAFE READY'
    elseif railgun_charge and railgun_charge.limit then child_label='LIMIT'
    elseif railgun_charge and railgun_charge.release then child_label='RELEASE'
    elseif railgun_charge and railgun_charge.remaining then child_label=string.format('UNSAFE %.2fs',railgun_charge.remaining) end
    local display_rpm=m.resource_hex~='35a61296619cc47e' and m.rpm or nil
    if display_rpm then child_label=(child_label and (child_label..'  ') or '')..tostring(display_rpm)..' RPM' end
    if display_rpm or m.safety_mode or child_label=='SAFE READY' or child_label=='SAFE' or child_label=='UNSAFE' or child_label=='AUTO' or child_label=='SEMI' or child_label=='BURST' or child_label=='ALT' or child_label=='VOLLEY' then
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
    -- Railgun: electromagnetic instrument styling, retaining charge warning zones.
    if m.resource_hex=='2e9d0bdc48b09e60' or m.ammo_icon=='RAILGUN' then
        local charcoal,cyan,ice={17,28,35},{68,211,232},{211,240,243}
        local frames={}
        local icon_top=-math.huge
        local kept={}
        for _,command in ipairs(out) do
            if command.mode_icon then icon_top=math.max(icon_top,command.y+command.h)
            elseif not (command.decoration and not command.child and not command.charge_meter) then kept[#kept+1]=command end
        end
        out=kept
        local frame=out[1]
        if icon_top>-math.huge and frame.type=='panel' then
            local factor=scale*.85
            local px=frame.x+(frame.w-36*factor)/2
            local old_top=frame.y+frame.h
            frame.h=frame.h+18*scale
            M.decorate(out,frame,scale,cfg,opacity)
            local py=old_top-5*scale
            for _,run in ipairs(HUD.fire_icons.RAILGUN_DISPLAY.runs) do
                out[#out+1]={type='rect',railgun_heading=true,x=px+run[1]*factor,y=py+run[2]*factor,w=run[3]*factor,h=run[4]*factor,c=run[5],a=opacity}
            end
            if m.safety_mode=='UNSAFE' then
                local phase=math.floor((clock or 0)*12)%3
                local function spark(dx,dy,w,h,bright)
                    out[#out+1]={type='rect',railgun_heading=true,railgun_arc=true,x=px+dx*factor,y=py+dy*factor,w=w*factor,h=h*factor,c=bright and {211,250,255} or cyan,a=opacity*(bright and .85 or .48)}
                end
                -- Short stepped arcs stay inside the reserved heading padding.
                for side=0,1 do
                    local start=side==0 and 3 or 22
                    local shift=phase-1
                    spark(start,13+shift*.4,4,.6,true)
                    spark(start+3,12.6+shift*.4,.7,1.5,false)
                    spark(start+3,14+shift*.4,4,.6,true)
                    spark(start+6,13.3+shift*.4,.7,1.3,false)
                    spark(start+6,13.3+shift*.4,4,.6,true)
                end
                spark(-2,4+phase,1,3,false);spark(-3,6+phase,2,.7,true)
                spark(37,3+phase,1,3,false);spark(36,5+phase,2,.7,true)
            end
        end
        for _,command in ipairs(out) do
            if not command.charge_meter then
                if command.type=='panel' then command.c=charcoal;frames[#frames+1]=command
                elseif command.type=='text' then
                    command.c=(command.text=='RELEASE' or command.text=='LIMIT') and {255,104,64} or (command.text=='SAFE READY' and {0,255,0} or ice)
                elseif command.type=='rect' and not command.railgun_heading then command.c=cyan end
            end
        end
        for _,frame in ipairs(frames) do
            if not frame.child then
                for _,side in ipairs({0,1}) do
                    local edge=frame.x+(side==0 and 3*scale or frame.w-4*scale)
                    for k=0,2 do
                        out[#out+1]={type='rect',x=edge,y=frame.y+frame.h-(5+k*3)*scale,w=scale,h=2*scale,c=cyan,a=.8*opacity}
                    end
                end
            end
        end
    end
    out=HUD.weapon_styles.apply(out,m,scale,cfg,opacity,measure,M.decorate,clock)
    if m.resource_hex=='8d3d52a3b2f19402' and m.cylinder_slots then
        local panel=cfg.anchor_mode=='world' and cfg.senator_style~='upright' and HUD.senator_panel or HUD.senator_panel.upright
        out=panel.compose(m,x,y,scale,opacity,cfg,measure)
    end
    -- Charge metadata is supplied only after the native signal is verified.
    if railgun_charge or epoch_charge then
        local fraction=(railgun_charge or epoch_charge).fraction
        local parent=out[1];local low=parent.y
        for _,c in ipairs(out) do if c.child and c.type=='panel' then low=math.min(low,c.y) end end
        local x=parent.x+parent.w+2*scale;local height=parent.y+parent.h-low;local width=12*scale
        local flash=railgun_charge and m.safety_mode=='UNSAFE' and (railgun_charge.remaining and railgun_charge.release or not railgun_charge.remaining and m.charge_warning) and math.floor((clock or 0)*8)%2==0
        local yellow=HUD.config.rgb(cfg.heat_yellow);local red=HUD.config.rgb(cfg.heat_red)
        local panel={type='panel',charge_meter=true,x=x,y=low,w=width,h=height,c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity}
        out[#out+1]=panel
        local zones=epoch_charge and {{0,1,{112,219,255}}}
            or m.safety_mode=='SAFE' and {{0,1,railgun_charge.ready and {0,255,0} or {255,255,255}}}
            or {{0,.70,{255,255,255}},{.70,.85,yellow},{.85,1,red}}
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
    -- Grenade Pistol: olive ordnance display with amber safety markings.
    if m.resource_hex=='52e4334e6a128caf' then
        local olive,amber,ivory={28,38,29},{242,183,54},{229,234,211}
        local frames={}
        local heading
        local kept={}
        for _,command in ipairs(out) do
            if command.type=='text' and command.text=='GRNDS' then heading=command
            elseif not command.mode_icon then kept[#kept+1]=command end
        end
        out=kept
        if heading then
            local factor=heading.size/12
            local frame
            for _,command in ipairs(out) do if command.type=='panel' then frame=command;break end end
            local shell_x=frame and (frame.x+(frame.w-32*factor)/2) or heading.x
            for _,run in ipairs(HUD.fire_icons.GRENADE_PISTOL_SHELL.runs) do
                out[#out+1]={type='rect',grenade_heading=true,x=shell_x+run[1]*factor,y=heading.y+run[2]*factor,w=run[3]*factor,h=run[4]*factor,c=run[5],a=opacity}
            end
        end
        for _,command in ipairs(out) do
            if command.type=='panel' then
                command.c=olive;frames[#frames+1]=command
            elseif command.type=='text' then
                command.c=ivory
                if command.text=='GRNDS' then command.text='GRNDS';command.c=amber end
            elseif command.type=='rect' and not command.mode_icon and not command.grenade_heading then
                command.c=amber
            end
        end
        for _,frame in ipairs(frames) do
            for k=0,3 do
                out[#out+1]={type='rect',x=frame.x+(3+k*4)*scale,y=frame.y+frame.h-3*scale,w=2*scale,h=1*scale,c=amber,a=.8*opacity}
            end
        end
    end
    -- Anti-Materiel Rifle: restrained precision instrument with a centered heavy cartridge.
    if m.resource_hex=='89c5493e08ca4207' and not (out[1] and out[1].amr_candidate) then
        local slate,silver,brass={22,29,34},{185,203,213},{209,165,82}
        local kept,heading={},nil
        for _,command in ipairs(out) do
            if command.type=='text' and command.text=='ROUNDS' then heading=command
            elseif not command.mode_icon then kept[#kept+1]=command end
        end
        out=kept
        local frame=out[1]
        for _,command in ipairs(out) do
            if command.type=='panel' then command.c=slate
            elseif command.type=='text' then command.c={224,231,235}
            elseif command.type=='rect' then command.c=command.decoration and silver or brass end
        end
        if heading then
            local factor=heading.size/12
            local px=frame.x+(frame.w-44*factor)/2
            for _,run in ipairs(HUD.fire_icons.AMR_CARTRIDGE.runs) do
                out[#out+1]={type='rect',amr_heading=true,x=px+run[1]*factor,y=heading.y+run[2]*factor,w=run[3]*factor,h=run[4]*factor,c=run[5],a=opacity}
            end
        end
        -- Small calibrated edge marks remain inside the main frame.
        for _,side in ipairs({0,1}) do
            for k=0,2 do
                out[#out+1]={type='rect',x=frame.x+(side==0 and 3*scale or frame.w-5*scale),y=frame.y+frame.h-(4+k*3)*scale,w=2*scale,h=.6*scale,c=brass,a=.65*opacity}
            end
        end
    end
    -- Deadeye trial: dedicated receiver display.
    if m.resource_hex=='e6d932be83729076' then
        local steel,silver,brass={24,31,36},{198,210,218},{218,172,78}
        local w,h=126,100
        out={{type='panel',x=x,y=y,w=w*scale,h=h*scale,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='precision'}}
        local function line(dx,dy,bw,bh,color,a)
            out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=bw*scale,h=bh*scale,c=color,a=(a or 1)*opacity}
        end
        local function caption(value,dx,dy,size,color)
            out[#out+1]={type='text',text=value,numeric_display=value:match('^%d%d%d$')~=nil,font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=color,a=opacity}
        end
        if cfg.decoration~='deadeye' then
            line(0,0,w,1,silver,.55);line(0,h-1,w,1,silver,.55)
            line(0,0,1,h,silver,.55);line(w-1,0,1,h,silver,.55)
        end
        line(8,79,110,1,brass,.65)
        caption('R-6 DEADEYE',9,84,12,brass)
        caption(number,10,40,36,ink)
        for _,r in ipairs(HUD.fire_icons.AMENDMENT_CARTRIDGE.runs) do
            line(96+r[1]*1.15,34+r[2]*1.3,r[3]*1.15,r[4]*1.3,r[5] or brass)
        end
        local fill=math.max(0,math.min(1,m.fraction or 0))
        for i=0,14 do line(10+i*7,28,5,3,i<math.ceil(fill*15) and brass or silver,i<math.ceil(fill*15) and 1 or .18) end
        caption(m.reserve and string.format('%03d SHELLS',m.reserve) or '-- SHELLS',10,13,12,silver)
        line(8,8,110,.7,silver,.25)
        if cfg.decoration~='deadeye' then
            for _,dx in ipairs({4,119}) do for _,dy in ipairs({4,93}) do line(dx,dy,3,3,brass,.75) end end
        end
    end
    -- Double Freedom shares Deadeye's receiver display grammar and two-shot capacity.
    if m.resource_hex=='72170a55a1f37ff1' then
        local w,h=120,112
        local reference=142
        if measure then
            for _,text in ipairs({'DOUBLE FREEDOM','DBS-2'}) do
                local a,b,e,t=measure(text,10*scale)
                w=math.max(w,(e-a)/scale+24)
                h=math.max(h,(text=='DBS-2' and 99 or 84)+t/scale+4)
            end
            local ra,rb,re=measure(m.reserve~=nil and string.format('%03d SHELLS',m.reserve) or '--- SHELLS',12*scale)
            w=math.max(w,(re-ra)/scale+24)
            local a,b,e=measure('DBS-2 DOUBLE FREEDOM',10*scale)
            reference=math.max(reference,5+e/scale+6,6+re/scale+6)
        end
        local shift=w/2-73
        local shared_child={}
        for _,v in ipairs(out) do if v.child and not v.decoration then shared_child[#shared_child+1]=v end end
        local steel,silver,brass={24,31,36},{198,210,218},{218,172,78}
        out={{type='panel',x=x,y=y,w=w*scale,h=h*scale,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='shotgun',world_reference_width=reference*scale}}
        local function line(dx,dy,pw,ph,color,a)
            out[#out+1]={type='rect',x=x+(dx+shift)*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=color,a=(a or 1)*opacity}
        end
        local function caption(value,dx,dy,size,color)
            out[#out+1]={type='text',text=value,numeric_display=value:match('^%d%d%d$')~=nil,font=cfg.font,x=x+(dx+shift)*scale,y=y+dy*scale,size=size*scale,c=color,a=opacity}
        end
        local function centered(value,dy,size,color,weapon)
            local a,b,e=0,0,#value*size*scale*.6
            if measure then a,b,e=measure(value,size*scale) end
            caption(value,(w*scale-a-e)/(2*scale)-shift,dy,size,color)
            out[#out].center_in_frame=true;out[#out].weapon_label=weapon or nil
        end
        line(81-w/2,79,w-16,1,brass,.65)
        centered('DBS-2',99,10,brass,true)
        centered('DOUBLE FREEDOM',84,10,brass,true)
        local shell=HUD.fire_icons.DOUBLE_FREEDOM_SHELL
        for barrel=1,2 do
            local loaded=m.fire_mode=='VOLLEY' and m.value>=2 or (m.fire_mode~='VOLLEY' and m.value>=(3-barrel))
            -- Match native SEMI order: left empties first; VOLLEY empties both.
            line(27+(barrel-1)*50,26,42,3,loaded and brass or silver,loaded and 1 or .18)
            out[#out].barrel_indicator=barrel;out[#out].shell_loaded=loaded
            local spent=not loaded and m.df_shell_spent and m.df_shell_spent[barrel]
            local symbol=spent and HUD.fire_icons.DOUBLE_FREEDOM_SPENT or shell
            for _,run in ipairs(symbol.runs) do
                local xs,origin,ry,rh=1.85,36.9,run[2],run[4]
                if cfg.double_freedom_proportions_preview~=false then
                    -- Short brass head: 27% brass, 73% blue; preserve total height and anchors.
                    xs,origin=1.75,37.5
                    if ry>=11 then ry,rh=8+(ry-11)*22/19,rh*22/19
                    else ry,rh=ry*8/11,rh*8/11 end
                end
                line(origin+(barrel-1)*50+run[1]*xs,32+ry*1.5,run[3]*xs,rh*1.5,
                    ((loaded or spent) and run[5] or silver),(loaded and .9 or spent and .55 or .18))
                out[#out].shotgun_shell_art=true;out[#out].shotgun_shell_barrel=barrel;out[#out].shell_spent=spent==true
            end
        end
        centered(m.reserve~=nil and string.format('%03d SHELLS',m.reserve) or '--- SHELLS',13,12,silver)
        line(81-w/2,8,w-16,.7,silver,.25)
        M.decorate(out,out[1],scale,cfg,opacity)
        local child=shared_child[1]
        if child and child.type=='panel' then
            local dx=x+w*scale/2-(child.x+child.w/2)
            local dy=y-2*scale-child.h-child.y
            for _,v in ipairs(shared_child) do v.x=v.x+dx;v.y=v.y+dy;v.c=v.type=='panel' and steel or silver end
            child.x=x;child.w=w*scale
            local group={};M.decorate(group,child,scale,cfg,opacity)
            for _,v in ipairs(group) do v.child=true;shared_child[#shared_child+1]=v end
            for _,v in ipairs(shared_child) do out[#out+1]=v end
        end
    end
    if vent then
        local red=HUD.config.rgb(cfg.heat_red)
        for _,command in ipairs(out) do if not command.scythe_heatsink then command.c=red end end
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
                local count=cfg.effect_scanline_count or 21
                for k=1,count do out[#out+1]={type='rect',x=frame.x,y=frame.y+frame.h*k/(count+1),w=frame.w,h=thickness,c=ink,a=.12*opacity,effect_shader_band=true,effect_owner=frame,child=frame.child,fold_child=frame.fold_child,df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,df_effect_fraction=k/(count+1)} end
            end
            if cfg.effect_sweep then
                local band=math.min(frame.h,thickness*2)
                local sweep_count=math.max(1,math.min(12,math.floor(cfg.effect_sweep_density or 3)))
                local spacing=math.max(.001,out[1].h/sweep_count)
                local speed=(cfg.effect_sweep_speed or .35)*out[1].h
                local offset=((clock or 0)*speed)%spacing
                for k=-1,math.ceil(frame.h/spacing)do
                    local low=offset+k*spacing;local bottom=math.max(0,low);local top=math.min(frame.h,low+band)
                    if top>bottom then
                        out[#out+1]={type='rect',x=frame.x,y=frame.y+bottom,w=frame.w,h=top-bottom,c=ink,a=.2*opacity,
                            df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,
                            df_effect_fraction=bottom/math.max(.001,frame.h-band),df_effect_sweep=true,effect_band=band,effect_clock=clock or 0,effect_owner=frame,child=frame.child,fold_child=frame.fold_child}
                    end
                end
            end
        end
    end
    -- One shared tag colors only the loaded count's final digit, including bespoke panels.
    for _,command in ipairs(out) do
        if command.type=='text' and command.text==number and command.size>=20*scale and not command.child then
            command.last_digit_color=m.chamber_bonus==1 and {255,221,0} or nil
        end
    end
    if cfg.decoration=='deadeye' then
        -- Apply once at final parent/child bounds, including bespoke and fuel panels.
        local panels={};for _,v in ipairs(out) do if v.type=='panel' then panels[#panels+1]=v end end
        local kept={}
        for _,v in ipairs(out) do
            local perimeter=false
            if v.type=='rect' then for _,f in ipairs(panels) do
                local eps=scale*.00001
                local horizontal=math.abs(v.x-f.x)<eps and math.abs(v.w-f.w)<eps and (math.abs(v.y-f.y)<eps or math.abs(v.y+v.h-f.y-f.h)<eps)
                local vertical=math.abs(v.y-f.y)<eps and math.abs(v.h-f.h)<eps and (math.abs(v.x-f.x)<eps or math.abs(v.x+v.w-f.x-f.w)<eps)
                perimeter=perimeter or horizontal or vertical
            end end
            if not v.decoration and not perimeter then kept[#kept+1]=v end
        end
        out=kept
        for _,f in ipairs(panels) do
            local group={};M.decorate(group,f,scale,cfg,opacity)
            for _,v in ipairs(group) do v.child=f.child;out[#out+1]=v end
        end
    end
    for _,command in ipairs(out)do if command.type=='text' then command.a=command.a*(cfg.text_opacity or 1) end end
    return out
end
-- Texture compositions replace primitive housing. Reapply the selected perimeter
-- on their final live frame, without tinting or changing the artwork pixels.
function M.decorate_textures(commands,scale,cfg,opacity)
    cfg=HUD.config.texture_policy(cfg)
    local textured=false
    for _,v in ipairs(commands)do if v.type=='texture' then textured=true;break end end
    if not textured then return commands end
    local out,panels={},{}
    for _,v in ipairs(commands)do
        if not v.decoration then out[#out+1]=v end
        if v.type=='panel' and not v.charge_meter then panels[#panels+1]=v end
    end
    for _,panel in ipairs(panels)do
        local decoration={};M.decorate(decoration,panel,scale,cfg,opacity)
        for _,v in ipairs(decoration)do v.child=panel.child;out[#out+1]=v end
    end
    return out
end
return M
