-- HD2-Addon: mods/dbf_hud/hud
local HUD={}
HUD.config=(function()
local M={}
M.colors={'text_color','background_color','heat_white','heat_yellow','heat_red'}
M.defaults={world_position_smooth=0.045,world_rotation_smooth=0.08,world_max_lag=0.12,follow=0.65,travel=55,settle=0.22,offset_x=62,offset_y=-5,scale=1,opacity=0.92,
    panel_opacity=0.55,flash_hz=2,frosted=true,pose_marker=false,world_probe=false,anchor_mode='weapon',weapon_offset_x=62,weapon_offset_y=30,weapon_settle=0.10,weapon_lag=40,mount_x=0,mount_y=0,mount_z=0,text_color='#C4CECA',background_color='#202628',
    heat_white='#E5E7E2',heat_yellow='#E7C85C',heat_red='#E16D65',font='bigblue'}
M.limits={world_position_smooth={0,0.5},world_rotation_smooth={0,0.5},world_max_lag={0,0.5},weapon_offset_x={-1920,1920},weapon_offset_y={-1080,1080},weapon_settle={0.04,1},weapon_lag={0,160},mount_x={-2,2},mount_y={-2,2},mount_z={-2,2},follow={0,1},travel={1,160},settle={0.04,1},offset_x={-1920,1920},offset_y={-1080,1080},
    scale={0.5,2},opacity={0.1,1},panel_opacity={0,1},flash_hz={0.5,3}}
function M.hex(v)
    assert(type(v)=='string','hex color must be a string')
    local h=v:gsub('^#','')
    assert(#h==6 and h:match('^%x+$'),'color needs six hex digits: #RRGGBB')
    return '#'..h:upper()
end
function M.rgb(v)
    v=M.hex(v);return {tonumber(v:sub(2,3),16),tonumber(v:sub(4,5),16),tonumber(v:sub(6,7),16)}
end
function M.new() local t={};for k,v in pairs(M.defaults) do t[k]=v end;return t end
function M.apply(config,values)
    assert(type(values)=='table','configuration must be a table')
    local clean={}
    for k,v in pairs(values) do
        assert(M.defaults[k]~=nil,'unknown setting: '..tostring(k))
        local limits=M.limits[k]
        if limits then assert(type(v)=='number' and v==v and v>=limits[1] and v<=limits[2],'invalid setting: '..k)
        elseif (k=='frosted' or k=='pose_marker' or k=='world_probe') then assert(type(v)=='boolean','frosted must be boolean')
        elseif k=='anchor_mode' then assert(v=='weapon' or v=='crosshair' or v=='world','invalid anchor mode')
        elseif k=='font' then assert(v=='bigblue' or v=='debug','font must be bigblue or debug')
        else v=M.hex(v) end
        clean[k]=v
    end
    for k,v in pairs(clean) do config[k]=v end
end
function M.serialize(config)
    local keys={};for k in pairs(M.defaults) do keys[#keys+1]=k end;table.sort(keys)
    local out={'-- DBF-HUD tuning. Loaded from the game installation root on startup.','return {'}
    for _,k in ipairs(keys) do local v=config[k];out[#out+1]='    '..k..' = '..(type(v)=='string' and string.format('%q',v) or tostring(v))..',' end
    out[#out+1]='}';return table.concat(out,'\n')..'\n'
end
return M

end)()
HUD.font_data=(function()
-- Generated from BigBlue Terminal (c) 2015 VileR / Nerd Fonts 3.5.1.
-- Glyph data: CC BY-SA 4.0; see licenses/BigBlueTerminal.

return {
    [32]={bounds={0,0,0,0},runs={}},
    [33]={bounds={2,0,6,9},runs={{3,8,2,1},{2,5,4,3},{3,3,2,2},{3,0,2,2}}},
    [34]={bounds={1,6,7,10},runs={{1,7,2,3},{5,7,2,3},{2,6,1,1},{5,6,1,1}}},
    [35]={bounds={0,0,7,9},runs={{1,7,2,2},{4,7,2,2},{0,6,7,1},{1,3,2,3},{4,3,2,3},{0,2,7,1},{1,0,2,2},{4,0,2,2}}},
    [36]={bounds={0,-1,7,10},runs={{3,8,2,2},{1,7,5,1},{0,5,2,2},{5,6,2,1},{1,4,5,1},{5,2,2,2},{0,2,2,1},{1,1,5,1},{3,-1,2,2}}},
    [37]={bounds={0,0,7,7},runs={{0,5,2,2},{6,6,1,1},{5,5,2,1},{4,4,2,1},{3,3,2,1},{2,2,2,1},{1,1,2,1},{5,0,2,2},{0,0,2,1}}},
    [38]={bounds={0,0,7,9},runs={{2,8,3,1},{1,6,2,2},{4,6,2,2},{2,5,3,1},{1,4,3,1},{5,4,2,1},{0,1,2,3},{3,3,3,1},{4,1,2,2},{1,0,3,1},{5,0,2,1}}},
    [39]={bounds={1,6,4,10},runs={{2,7,2,3},{1,6,2,1}}},
    [40]={bounds={2,0,6,9},runs={{4,8,2,1},{3,7,2,1},{2,2,2,5},{3,1,2,1},{4,0,2,1}}},
    [41]={bounds={2,0,6,9},runs={{2,8,2,1},{3,7,2,1},{4,2,2,5},{3,1,2,1},{2,0,2,1}}},
    [42]={bounds={0,2,8,7},runs={{1,6,2,1},{5,6,2,1},{2,5,4,1},{0,4,8,1},{2,3,4,1},{1,2,2,1},{5,2,2,1}}},
    [43]={bounds={1,2,7,7},runs={{3,5,2,2},{1,4,6,1},{3,2,2,2}}},
    [44]={bounds={2,-1,5,3},runs={{3,0,2,3},{2,-1,2,1}}},
    [45]={bounds={0,4,7,5},runs={{0,4,7,1}}},
    [46]={bounds={3,0,5,2},runs={{3,0,2,2}}},
    [47]={bounds={0,1,7,9},runs={{6,8,1,1},{5,7,2,1},{4,6,2,1},{3,5,2,1},{2,4,2,1},{1,3,2,1},{0,2,2,1},{0,1,1,1}}},
    [48]={bounds={0,0,7,9},runs={{2,8,3,1},{1,7,2,1},{4,7,2,1},{0,2,2,5},{5,2,2,5},{3,4,1,1},{1,1,2,1},{4,1,2,1},{2,0,3,1}}},
    [49]={bounds={1,0,7,9},runs={{3,8,2,1},{2,7,3,1},{1,6,4,1},{3,1,2,5},{1,0,6,1}}},
    [50]={bounds={0,0,7,9},runs={{1,8,5,1},{0,7,2,1},{5,6,2,2},{4,5,2,1},{3,4,2,1},{2,3,2,1},{1,2,2,1},{0,1,2,1},{5,1,2,1},{0,0,7,1}}},
    [51]={bounds={0,0,7,9},runs={{1,8,5,1},{0,7,2,1},{5,5,2,3},{2,4,4,1},{5,1,2,3},{0,1,2,1},{1,0,5,1}}},
    [52]={bounds={0,0,7,9},runs={{4,8,2,1},{3,7,3,1},{2,6,4,1},{1,5,2,1},{4,4,2,2},{0,4,2,1},{0,3,7,1},{4,1,2,2},{3,0,4,1}}},
    [53]={bounds={0,0,7,9},runs={{0,8,7,1},{0,5,2,3},{0,4,6,1},{5,1,2,3},{0,1,2,1},{1,0,5,1}}},
    [54]={bounds={0,0,7,9},runs={{2,8,3,1},{1,7,2,1},{0,5,2,2},{0,4,6,1},{0,1,2,3},{5,1,2,3},{1,0,5,1}}},
    [55]={bounds={0,0,7,9},runs={{0,8,7,1},{0,7,2,1},{5,6,2,2},{4,5,2,1},{3,4,2,1},{2,0,2,4}}},
    [56]={bounds={0,0,7,9},runs={{1,8,5,1},{0,5,2,3},{5,5,2,3},{1,4,5,1},{0,1,2,3},{5,1,2,3},{1,0,5,1}}},
    [57]={bounds={0,0,7,9},runs={{1,8,5,1},{0,5,2,3},{5,5,2,3},{1,4,6,1},{5,2,2,2},{4,1,2,1},{1,0,4,1}}},
    [58]={bounds={3,1,5,8},runs={{3,6,2,2},{3,1,2,2}}},
    [59]={bounds={2,0,5,8},runs={{3,6,2,2},{3,1,2,2},{2,0,2,1}}},
    [60]={bounds={0,0,6,9},runs={{4,8,2,1},{3,7,2,1},{2,6,2,1},{1,5,2,1},{0,4,2,1},{1,3,2,1},{2,2,2,1},{3,1,2,1},{4,0,2,1}}},
    [61]={bounds={1,2,7,6},runs={{1,5,6,1},{1,2,6,1}}},
    [62]={bounds={1,0,7,9},runs={{1,8,2,1},{2,7,2,1},{3,6,2,1},{4,5,2,1},{5,4,2,1},{4,3,2,1},{3,2,2,1},{2,1,2,1},{1,0,2,1}}},
    [63]={bounds={0,0,7,9},runs={{1,8,5,1},{0,6,2,2},{5,6,2,2},{4,5,2,1},{3,3,2,2},{3,0,2,2}}},
    [64]={bounds={0,0,7,9},runs={{1,8,5,1},{0,1,2,7},{5,6,2,2},{3,3,4,3},{3,2,3,1},{1,0,5,1}}},
    [65]={bounds={0,0,7,9},runs={{3,8,1,1},{2,7,3,1},{1,6,2,1},{4,6,2,1},{0,4,2,2},{5,4,2,2},{0,3,7,1},{0,0,2,3},{5,0,2,3}}},
    [66]={bounds={0,0,7,9},runs={{0,8,6,1},{1,5,2,3},{5,5,2,3},{1,4,5,1},{1,1,2,3},{5,1,2,3},{0,0,6,1}}},
    [67]={bounds={0,0,7,9},runs={{2,8,4,1},{1,7,2,1},{5,7,2,1},{0,2,2,5},{6,6,1,1},{6,2,1,1},{1,1,2,1},{5,1,2,1},{2,0,4,1}}},
    [68]={bounds={0,0,7,9},runs={{0,8,5,1},{1,1,2,7},{4,7,2,1},{5,2,2,5},{4,1,2,1},{0,0,5,1}}},
    [69]={bounds={0,0,7,9},runs={{0,8,7,1},{1,5,2,3},{5,7,2,1},{6,6,1,1},{4,5,1,1},{1,4,4,1},{1,1,2,3},{4,3,1,1},{6,2,1,1},{5,1,2,1},{0,0,7,1}}},
    [70]={bounds={0,0,7,9},runs={{0,8,7,1},{1,5,2,3},{5,7,2,1},{6,6,1,1},{4,5,1,1},{1,4,4,1},{1,1,2,3},{4,3,1,1},{0,0,4,1}}},
    [71]={bounds={0,0,7,9},runs={{2,8,4,1},{1,7,2,1},{5,7,2,1},{0,2,2,5},{6,6,1,1},{3,3,4,1},{5,1,2,2},{1,1,2,1},{2,0,3,1},{6,0,1,1}}},
    [72]={bounds={0,0,7,9},runs={{0,5,2,4},{5,5,2,4},{0,4,7,1},{0,0,2,4},{5,0,2,4}}},
    [73]={bounds={2,0,6,9},runs={{2,8,4,1},{3,1,2,7},{2,0,4,1}}},
    [74]={bounds={0,0,7,9},runs={{3,8,4,1},{4,1,2,7},{0,1,2,2},{1,0,4,1}}},
    [75]={bounds={0,0,7,9},runs={{0,8,3,1},{5,7,2,2},{1,5,2,3},{4,5,2,2},{1,4,4,1},{1,1,2,3},{4,2,2,2},{5,0,2,2},{0,0,3,1}}},
    [76]={bounds={0,0,7,9},runs={{0,8,4,1},{1,1,2,7},{6,2,1,1},{5,1,2,1},{0,0,7,1}}},
    [77]={bounds={0,0,7,9},runs={{0,8,2,1},{5,8,2,1},{0,7,3,1},{4,7,3,1},{0,5,7,2},{0,0,2,5},{3,4,1,1},{5,0,2,5}}},
    [78]={bounds={0,0,7,9},runs={{0,8,2,1},{5,6,2,3},{0,7,3,1},{0,6,4,1},{0,5,7,1},{0,0,2,5},{3,4,4,1},{4,3,3,1},{5,0,2,3}}},
    [79]={bounds={0,0,7,9},runs={{2,8,3,1},{1,7,2,1},{4,7,2,1},{0,2,2,5},{5,2,2,5},{1,1,2,1},{4,1,2,1},{2,0,3,1}}},
    [80]={bounds={0,0,7,9},runs={{0,8,6,1},{1,5,2,3},{5,5,2,3},{1,4,5,1},{1,1,2,3},{0,0,4,1}}},
    [81]={bounds={0,-1,7,9},runs={{1,8,5,1},{0,2,2,6},{5,3,2,5},{3,3,1,1},{3,2,4,1},{1,1,5,1},{4,0,2,1},{4,-1,3,1}}},
    [82]={bounds={0,0,7,9},runs={{0,8,6,1},{1,5,2,3},{5,5,2,3},{1,4,5,1},{1,1,2,3},{4,3,2,1},{5,0,2,3},{0,0,3,1}}},
    [83]={bounds={0,0,7,9},runs={{1,8,5,1},{0,6,2,2},{5,6,2,2},{1,5,2,1},{2,4,3,1},{4,3,2,1},{0,1,2,2},{5,1,2,2},{1,0,5,1}}},
    [84]={bounds={1,0,7,9},runs={{1,7,6,2},{1,6,1,1},{3,1,2,6},{6,6,1,1},{2,0,4,1}}},
    [85]={bounds={0,0,7,9},runs={{0,1,2,8},{5,1,2,8},{1,0,5,1}}},
    [86]={bounds={0,0,7,9},runs={{0,3,2,6},{5,3,2,6},{1,2,2,1},{4,2,2,1},{2,1,3,1},{3,0,1,1}}},
    [87]={bounds={0,0,7,9},runs={{0,3,2,6},{5,3,2,6},{3,3,1,2},{0,2,7,1},{1,1,5,1},{1,0,2,1},{4,0,2,1}}},
    [88]={bounds={0,0,7,9},runs={{0,7,2,2},{5,7,2,2},{1,6,2,1},{4,6,2,1},{2,3,3,3},{1,2,2,1},{4,2,2,1},{0,0,2,2},{5,0,2,2}}},
    [89]={bounds={1,0,7,9},runs={{1,5,2,4},{5,5,2,4},{2,4,4,1},{3,1,2,3},{2,0,4,1}}},
    [90]={bounds={0,0,7,9},runs={{0,8,7,1},{0,7,2,1},{5,7,2,1},{0,6,1,1},{4,6,2,1},{3,5,2,1},{2,4,2,1},{1,3,2,1},{0,1,2,2},{6,2,1,1},{5,1,2,1},{0,0,7,1}}},
    [91]={bounds={2,0,6,9},runs={{2,8,4,1},{2,1,2,7},{2,0,4,1}}},
    [92]={bounds={0,0,7,9},runs={{0,8,1,1},{0,7,2,1},{0,6,3,1},{1,5,3,1},{2,4,3,1},{3,3,3,1},{4,2,3,1},{5,1,2,1},{6,0,1,1}}},
    [93]={bounds={2,0,6,9},runs={{2,8,4,1},{4,1,2,7},{2,0,4,1}}},
    [94]={bounds={0,6,7,10},runs={{3,9,1,1},{2,8,3,1},{1,7,2,1},{4,7,2,1},{0,6,2,1},{5,6,2,1}}},
    [95]={bounds={0,-2,8,-1},runs={{0,-2,8,1}}},
    [96]={bounds={2,7,5,10},runs={{2,8,2,2},{3,7,2,1}}},
    [97]={bounds={0,0,7,6},runs={{1,5,4,1},{4,4,2,1},{1,3,5,1},{0,1,2,2},{4,1,2,2},{1,0,3,1},{5,0,2,1}}},
    [98]={bounds={0,0,7,9},runs={{0,8,3,1},{1,6,2,2},{1,5,4,1},{1,1,2,4},{4,4,2,1},{5,1,2,3},{1,0,5,1}}},
    [99]={bounds={0,0,7,6},runs={{1,5,5,1},{0,1,2,4},{5,4,2,1},{5,1,2,1},{1,0,5,1}}},
    [100]={bounds={0,0,7,9},runs={{3,8,3,1},{4,6,2,2},{2,5,4,1},{1,4,2,1},{4,1,2,4},{0,1,2,3},{1,0,3,1},{5,0,2,1}}},
    [101]={bounds={0,0,7,6},runs={{1,5,5,1},{0,4,2,1},{5,4,2,1},{0,3,7,1},{0,1,2,2},{5,1,2,1},{1,0,5,1}}},
    [102]={bounds={0,0,6,9},runs={{2,8,3,1},{1,5,2,3},{4,7,2,1},{5,6,1,1},{0,4,4,1},{1,1,2,3},{0,0,4,1}}},
    [103]={bounds={0,-2,7,6},runs={{1,5,3,1},{5,5,2,1},{0,2,2,3},{4,2,2,3},{1,1,5,1},{4,-1,2,2},{0,-1,2,1},{1,-2,4,1}}},
    [104]={bounds={0,0,7,9},runs={{0,8,3,1},{1,5,2,3},{4,5,2,1},{1,4,3,1},{5,0,2,5},{1,1,2,3},{0,0,3,1}}},
    [105]={bounds={2,0,6,9},runs={{3,7,2,2},{2,5,3,1},{3,1,2,4},{2,0,4,1}}},
    [106]={bounds={1,-2,7,9},runs={{5,7,2,2},{4,5,3,1},{5,-1,2,6},{1,-1,2,2},{2,-2,4,1}}},
    [107]={bounds={0,0,7,9},runs={{0,8,3,1},{1,4,2,4},{5,5,2,1},{4,4,2,1},{1,3,4,1},{1,1,2,2},{4,2,2,1},{5,0,2,2},{0,0,3,1}}},
    [108]={bounds={2,0,6,9},runs={{2,8,3,1},{3,1,2,7},{2,0,4,1}}},
    [109]={bounds={0,0,7,6},runs={{0,5,3,1},{4,5,2,1},{0,4,7,1},{0,0,2,4},{3,1,1,3},{5,0,2,4}}},
    [110]={bounds={0,0,7,6},runs={{0,5,2,1},{3,5,3,1},{1,0,2,5},{5,0,2,5}}},
    [111]={bounds={0,0,7,6},runs={{1,5,5,1},{0,1,2,4},{5,1,2,4},{1,0,5,1}}},
    [112]={bounds={0,-2,7,6},runs={{0,5,2,1},{3,5,3,1},{1,2,2,3},{5,2,2,3},{1,1,5,1},{1,-1,2,2},{0,-2,4,1}}},
    [113]={bounds={0,-2,7,6},runs={{1,5,3,1},{5,5,2,1},{0,2,2,3},{4,2,2,3},{1,1,5,1},{4,-1,2,2},{3,-2,4,1}}},
    [114]={bounds={0,0,7,6},runs={{0,5,2,1},{3,5,3,1},{1,4,3,1},{5,3,2,2},{1,1,2,3},{0,0,4,1}}},
    [115]={bounds={0,0,7,6},runs={{1,5,5,1},{0,4,2,1},{5,4,2,1},{1,3,3,1},{3,2,3,1},{0,1,2,1},{5,1,2,1},{1,0,5,1}}},
    [116]={bounds={0,0,7,9},runs={{3,8,1,1},{2,6,2,2},{0,5,6,1},{2,1,2,4},{5,1,2,1},{3,0,3,1}}},
    [117]={bounds={0,0,7,6},runs={{0,1,2,5},{4,1,2,5},{1,0,3,1},{5,0,2,1}}},
    [118]={bounds={1,0,7,6},runs={{1,2,2,4},{5,2,2,4},{2,1,4,1},{3,0,2,1}}},
    [119]={bounds={0,0,7,6},runs={{0,2,2,4},{5,2,2,4},{3,2,1,2},{0,1,7,1},{1,0,2,1},{4,0,2,1}}},
    [120]={bounds={0,0,7,6},runs={{0,5,2,1},{5,5,2,1},{1,4,2,1},{4,4,2,1},{2,2,3,2},{1,1,2,1},{4,1,2,1},{0,0,2,1},{5,0,2,1}}},
    [121]={bounds={0,-2,7,6},runs={{0,2,2,4},{5,2,2,4},{1,1,6,1},{5,0,2,1},{4,-1,2,1},{0,-2,5,1}}},
    [122]={bounds={0,0,7,6},runs={{0,5,7,1},{0,4,2,1},{4,4,2,1},{3,3,2,1},{2,2,2,1},{1,1,2,1},{5,1,2,1},{0,0,7,1}}},
    [123]={bounds={1,0,7,9},runs={{4,8,3,1},{3,5,2,3},{1,4,3,1},{3,1,2,3},{4,0,3,1}}},
    [124]={bounds={3,0,5,9},runs={{3,5,2,4},{3,0,2,4}}},
    [125]={bounds={1,0,7,9},runs={{1,8,3,1},{3,5,2,3},{4,4,3,1},{3,1,2,3},{1,0,3,1}}},
    [126]={bounds={0,7,7,9},runs={{1,8,3,1},{5,8,2,1},{0,7,2,1},{3,7,3,1}}},
}

end)()
HUD.font=(function()
-- Pixel glyph geometry: no native font calls, handle conversions or asset loading.
local M={}
function M.pixel(size) return math.max(1,math.floor(size/12+0.5)) end
function M.measure(text,size)
    local p=M.pixel(size);local left,bottom,right,top=0,0,0,0
    for i=1,#text do
        local g=HUD.font_data[text:byte(i)] or HUD.font_data[63]
        local b=g.bounds;local offset=(i-1)*8
        left=math.min(left,offset+b[1]);bottom=math.min(bottom,b[2])
        right=math.max(right,offset+b[3]);top=math.max(top,b[4])
    end
    return left*p,bottom*p,right*p,top*p
end
function M.draw(text,size,x,y,emit)
    local p=M.pixel(size)
    x=math.floor(x+0.5);y=math.floor(y+0.5)
    for i=1,#text do
        local g=HUD.font_data[text:byte(i)] or HUD.font_data[63]
        local offset=(i-1)*8*p
        for _,r in ipairs(g.runs) do emit(x+offset+r[1]*p,y+r[2]*p,r[3]*p,r[4]*p) end
    end
end
return M

end)()
HUD.motion=(function()
-- Exact critically damped spring; all coordinates are 1080p reference pixels.
local M = {}
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<1e8 end
function M.new() return {x=0,y=0,vx=0,vy=0,ready=false} end
function M.axis(x,v,target,dt,omega)
    local delta=x-target
    local j=v+omega*delta
    local e=math.exp(-omega*dt)
    return target+(delta+j*dt)*e,(v-omega*j*dt)*e
end
function M.step(s, target, dt, cfg)
    local x,y=0,0
    if target and finite(target.x) and finite(target.y) then
        x,y=target.x*cfg.follow,target.y*cfg.follow
    end
    local radius=math.sqrt(x*x+y*y)
    if radius>cfg.travel then x,y=x*cfg.travel/radius,y*cfg.travel/radius end
    if not finite(dt) or dt<0 then dt=0 end
    if not s.ready or dt>0.35 then s.x,s.y,s.vx,s.vy=x,y,0,0; s.ready=true end
    local omega=4.75/math.max(0.04,cfg.settle)
    s.x,s.vx=M.axis(s.x,s.vx,x,dt,omega)
    s.y,s.vy=M.axis(s.y,s.vy,y,dt,omega)
    -- Moving targets can retain momentum; enforce the hard travel envelope too.
    radius=math.sqrt(s.x*s.x+s.y*s.y)
    if radius>cfg.travel then
        s.x,s.y=s.x*cfg.travel/radius,s.y*cfg.travel/radius
        local outward=(s.vx*s.x+s.vy*s.y)/(cfg.travel*cfg.travel)
        if outward>0 then s.vx,s.vy=s.vx-outward*s.x,s.vy-outward*s.y end
    end
    return s.x,s.y
end
-- Limit lag relative to the moving weapon, never relative to screen center.
function M.attach(s,target,dt,cfg)
    if not finite(dt) or dt<0 then dt=0 end
    if not s.ready or dt>.35 then s.x,s.y,s.vx,s.vy=target.x,target.y,0,0;s.ready=true end
    local omega=4.75/cfg.weapon_settle
    s.x,s.vx=M.axis(s.x,s.vx,target.x,dt,omega)
    s.y,s.vy=M.axis(s.y,s.vy,target.y,dt,omega)
    local dx,dy=s.x-target.x,s.y-target.y;local d=math.sqrt(dx*dx+dy*dy)
    if d>cfg.weapon_lag then
        s.x,s.y=target.x+dx*cfg.weapon_lag/d,target.y+dy*cfg.weapon_lag/d
        s.vx,s.vy=0,0
    end
    return s.x,s.y
end
return M

end)()
HUD.model=(function()
-- Normalize providers into one presentation contract; unknown is never zero.
local M={}
local function count(x)
    if type(x)=='number' and x==x and x>=0 and x<=100000 then return math.floor(x) end
end
function M.normalize(raw)
    if not raw then return nil end
    local m={id=raw.id,unit_ref=raw.unit_ref,avatar_unit_ref=raw.avatar_unit_ref,resource_hex=raw.resource_hex,kind=raw.kind,reserve=count(raw.reserve),reserve_kind=raw.reserve_kind,
        alternate=raw.alternate, lowered=raw.lowered, label=raw.label or 'AMMO'}
    if raw.kind=='heat' then
        if type(raw.heat)~='number' or raw.heat~=raw.heat or raw.heat<0 or raw.heat>1 then return nil end
        m.value=math.floor(raw.heat*100+0.5); m.fraction=raw.heat
        m.label='HEAT'; m.suffix='%'
        m.state=raw.locked and 'VENT' or (raw.heat>=0.85 and 'HOT' or 'READY')
        m.warning=raw.locked or raw.heat>=0.85
    elseif raw.kind=='infinite' then
        m.value='--'; m.label='ENERGY'; m.state='READY'; m.fraction=1
    else
        m.value=count(raw.rounds)
        if not m.value then return nil end
        m.capacity=count(raw.capacity)
        if m.capacity and m.capacity>0 then m.fraction=math.min(1,m.value/m.capacity) end
        m.state=m.value==0 and (raw.reloadable==false and 'SPENT' or 'EMPTY') or 'READY'
        m.warning=m.value==0 or (m.fraction and m.fraction<=0.2) or false
    end
    return m
end
return M

end)()
HUD.layout=(function()
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
    local ink=HUD.config.rgb(heat and M.heat_color(m.fraction,clock,cfg) or
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
        for i=0,19 do
            local fill=math.max(0,math.min(1,m.fraction*20-i))
            rect(0,-8+i*2.35,9,1.75,ink,0.12)
            if fill>0 then rect(0,-8+i*2.35,9,1.75*fill,ink,0.95) end
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
    out[#out+1]={type='rect',x=left,y=top-scale,w=14*scale,h=scale,c=ink,a=.6*opacity}
    out[#out+1]={type='rect',x=right-14*scale,y=bottom,w=14*scale,h=scale,c=ink,a=.4*opacity}
    for _,c in ipairs(d) do out[#out+1]=c end
    return out
end
return M

end)()
HUD.memory=(function()
-- Private FFI symbols prevent collisions with other addons' declarations.
local M={}
function M.native()
    local ffi=require('ffi')
    pcall(ffi.cdef, [[
    void *dbf_hud_module(const char*) __asm__("GetModuleHandleA");
    void *dbf_hud_process(void) __asm__("GetCurrentProcess");
    int dbf_hud_read(void*,const void*,void*,size_t,size_t*) __asm__("ReadProcessMemory");
    unsigned long dbf_hud_filename(void*,char*,unsigned long) __asm__("GetModuleFileNameA");
    ]])
    local k=ffi.load('kernel32'); local process=k.dbf_hud_process()
    local buffer=ffi.new('uint8_t[4096]');local got=ffi.new('size_t[1]')
    local file,log_size;local log_attempted=false
    local backend={
        module=function(name) local p=k.dbf_hud_module(name); if p~=nil then return tonumber(ffi.cast('uintptr_t',p)) end end,
        read=function(address,size)
            if address<65536 or address+size>=2^47 or size<1 or size>4096 then return nil end
            got[0]=0
            if k.dbf_hud_read(process,ffi.cast('const void*',address),buffer,size,got)==0 or tonumber(got[0])~=size then return nil end
            return ffi.string(buffer,size)
        end
    }
    function backend.log(line)
        if not log_attempted then
            log_attempted=true
            local buf=ffi.new('char[4096]');local n=tonumber(k.dbf_hud_filename(nil,buf,4096))
            if n and n>0 and n<4096 then
                local exe=ffi.string(buf,n):gsub('\\','/')
                local root=exe:match('^(.*)/[Bb][Ii][Nn]/[^/]+$')
                if root then backend.log_path=root..'/DBF-HUD.log';file=io.open(backend.log_path,'w') end
            end
            log_size=0
        end
        if file and log_size<512*1024 then
            file:write(line..'\n');file:flush();log_size=log_size+#line+1
        end
    end
    local function tuning_path()
        local buf=ffi.new('char[4096]');local n=tonumber(k.dbf_hud_filename(nil,buf,4096))
        assert(n>0 and n<4096,'executable path unavailable')
        local root=ffi.string(buf,n):gsub('\\','/'):match('^(.*)/[Bb][Ii][Nn]/[^/]+$')
        assert(root,'game installation root unavailable')
        return root..'/DBF-HUD-tuning.lua'
    end
    function backend.read_tuning()
        local path=tuning_path();local f=io.open(path,'r')
        -- Compatibility: old settings are readable; writes use the new filename.
        if not f then path=path:gsub('DBF%-HUD%-tuning.lua$','AstraAmmo-tuning.lua');f=io.open(path,'r') end
        if not f then return nil end
        local body=f:read(65537);f:close();assert(#body<=65536,'tuning file too large')
        local chunk=assert(loadstring(body,'@'..path));setfenv(chunk,{})
        local values=chunk();assert(type(values)=='table','tuning file must return a table')
        return values
    end
    function backend.write_tuning(body)
        local path=tuning_path();local tmp=path..'.tmp'
        local f=assert(io.open(tmp,'w'));local ok,err=f:write(body);local closed,cerr=f:close()
        assert(ok and closed,err or cerr)
        -- Windows rename cannot replace an existing file; keep a recoverable backup.
        local previous=io.open(path,'r')
        if previous then previous:close();os.remove(path..'.bak');assert(os.rename(path,path..'.bak')) end
        local moved,why=os.rename(tmp,path)
        if not moved then os.rename(path..'.bak',path);error(why) end
        return path
    end
    function backend.close() if file then file:close();file=nil end end
    return backend
end
function M.new(backend)
    local r={reads=0,bytes=0}
    function r.reset() r.reads,r.bytes=0,0 end
    function r.read(a,n)
        assert(type(a)=='number' and a==a and a%1==0 and a>=65536 and a+n<2^47,'invalid address')
        assert(n>0 and n<=4096,'invalid read size')
        r.reads,r.bytes=r.reads+1,r.bytes+n
        assert(r.reads<=512 and r.bytes<=65536,'read budget exceeded')
        local s=backend.read(a,n); assert(s and #s==n,'unreadable memory');return s
    end
    function r.u(s,o)
        local a,b,c,d=s:byte(o+1,o+4);assert(d,'short uint32');return a+b*256+c*65536+d*16777216
    end
    function r.i(s,o) local v=r.u(s,o);return v>=2^31 and v-2^32 or v end
    function r.f(s,o)
        local v=r.u(s,o);local sign=v>=2^31 and -1 or 1
        local e=math.floor(v/2^23)%256;local m=v%2^23
        assert(e~=255,'nonfinite float')
        return sign*(e==0 and m*2^-149 or (1+m/2^23)*2^(e-127))
    end
    function r.p(a)
        local s=r.read(a,8);local p=r.u(s,0)+r.u(s,4)*2^32
        assert(p>=65536 and p<2^47,'invalid pointer');return p
    end
    function r.map(a,key,limit)
        local h=r.read(a,20);local n,empty,mult=r.u(h,8),r.u(h,12),r.u(h,16)
        if n==0 or key==empty or key==0xffffffff then return nil end
        assert(n<=limit and n>0,'invalid map capacity')
        local pow=n;while pow>1 and pow%2==0 do pow=pow/2 end
        assert(pow==1,'invalid map capacity')
        local p=r.p(a)
        -- Split multiplication keeps the low 32 bits exact under Lua doubles.
        local start=((key%65536)*(mult%65536)+((math.floor(key/65536)*(mult%65536)+(key%65536)*math.floor(mult/65536))%65536)*65536)%2^32
        for probe=0,math.min(n,128)-1 do
            local row=r.read(p+((start+probe)%n)*8,8);local k=r.u(row,0)
            if k==empty then return nil end
            if k==key then local index=r.u(row,4);if index~=0xffffffff then return index end;return nil end
        end
        error('map probe limit')
    end
    return r
end
return M

end)()
HUD.layouts=(function()
-- Reference facts: Reticle Ammo HUD 1.1.0, Steam 25327279 and September 24 PE.
-- No layout is guessed on unknown builds. Offsets relative to game.dll.
return {
    stamps={[0x6AA96B14]=0x4770000,[0x6AB3B43F]=0x4744000},
    player=0x3326468,owner=0x346BF98,inventory=0x3326738,driver=0x3326660,
    selector=0x3326420,magazine=0x3326648,rounds=0x3326CF0,heat=0x3326D48,
    entity_map=0xF1AEB0,unit_map=0xF22EC8,records=0xF32F18,
    deposit={0x33265F0,0x33265E8},resource={0x3326AA0,0x3326AA8,0x3326A98,0x3326AB0},
    static={magazine={0xF124A0,540,160},rounds={0xF12820,50,0x88},heat={0xF12CC8,58,0x250}},
    signatures={
        {0x607200,'488b0561f2d10283b88400000000'},
        {0x6066ed,'8b9410a8030000'},
        {0xfd9c93,'4c8b15fe224902'},
        {0xfd9cc5,'498b9ac82ef200'},
        {0xfd9d83,'498b9ab0aef100'},
        {0x9a83e0,'4c8b1551e39702'},
        {0x745db6,'488b1da308be02'},
        {0x744dc2,'4c8b0d271fbe02'},
        {0x744d02,'488b2d3f19be02'},
        {0x764efa,'4c8b15471ebc02'},
        {0x764f79,'8bc8498b4258488d1449807c9008000f94c0'}
    }
}

end)()
HUD.reader=(function()
local Memory,Layout=HUD.memory,HUD.layouts
local M={}
local function flag(v,b) return math.floor(v/b)%2==1 end
local function valid(v,limit) return v>=0 and v<=limit end
function M.new(backend)
    local r=Memory.new(backend);local base;local checked=false
    local self={status='starting'}
    local function global(name) return r.p(base+Layout[name]) end
    local function component(m,map,registry,id,record)
        local index=r.map(m+map,id,65536)
        if not index then return nil end
        assert(index<4096,'component index')
        assert(r.read(r.p(r.p(m+registry)+index*8),24)==record,'component identity')
        return index
    end
    local function entity(owner,id)
        if not id or id==0 or id==0xffffffff then return nil end
        local index=r.map(owner+Layout.entity_map,id,1048576)
        if not index then return nil end
        assert(index<1048576,'entity index')
        local rec=r.read(owner+Layout.records+index*24,24)
        assert(r.u(rec,8)==id,'entity identity');return rec,owner+Layout.records+index*24
    end
    local function config(kind,m,id,rec,owner)
        local spec=Layout.static[kind]
        if kind~='magazine' then
            local i=r.map(m+0x68,id,65536)
            if i then assert(i<4096,'override index');return r.read(r.p(m+0xa8)+i*spec[3],spec[3]) end
        end
        local p=r.p(owner+spec[1]);local n=spec[2];local key=rec:sub(1,8)
        local home=((r.u(rec,4)%n)*(2^32%n)+r.u(rec,0)%n)%n
        for probe=0,math.min(n,128)-1 do
            local row=r.read(p+((home+probe)%n)*16,16)
            if row:sub(1,8)==string.rep('\0',8) then return nil end
            if row:sub(1,8)==key then
                local i=r.u(row,8);assert(i<n and r.u(row,12)==0,'config index')
                return r.read(p+n*16+i*spec[3],spec[3])
            end
        end
        return nil
    end
    local function deposit(owner,id)
        local rec=entity(owner,id);if not rec then return nil end
        for _,off in ipairs(Layout.deposit) do
            local ok,v=pcall(function()
                local m=r.p(base+off);local i=component(m,0x20,0x38,id,rec)
                if not i then return nil end
                local c=r.i(r.read(r.p(m+0x50)+i*8,8),0)
                if valid(c,5000) then return c end
            end)
            if ok and v then return v end
        end
    end
    function self.validate()
        r.reset();base=backend.module('game.dll');assert(base,'game.dll not loaded')
        local dos=r.read(base,64);assert(dos:sub(1,2)=='MZ','DOS signature')
        local pe=r.u(dos,0x3c);assert(pe<0x100000,'PE offset')
        local header=r.read(base+pe,0x80)
        assert(header:sub(1,4)=='PE\0\0','PE signature')
        assert(Layout.stamps[r.u(header,8)]==r.u(header,0x50),'unsupported game build')
        for _,s in ipairs(Layout.signatures) do
            local bytes=s[2]:gsub('..',function(h) return string.char(tonumber(h,16)) end)
            assert(r.read(base+s[1],#bytes)==bytes,'layout signature mismatch')
        end
        checked=true;self.status='validated'
    end
    function self.snapshot()
        if not checked then self.validate() end
        r.reset()
        local pm=global('player');local n=r.read(pm+0x84,8)
        if r.u(n,0)==0 or r.u(n,4)==0 then return nil,'no local player' end
        local pl=r.read(r.p(pm+0xe8),24)
        assert(flag(pl:byte(21),1) and r.map(pm+0xd0,r.u(pl,8),64)==0,'local ownership')
        local unit=r.u(r.read(pm+0x3a8,4),0)
        if unit==0x7fff then return nil,'no avatar' end
        local owner=global('owner');local ai=r.map(owner+Layout.unit_map,unit,1048576)
        if not ai then return nil,'no avatar entity' end
        assert(ai<1048576,'avatar index')
        local avatar=r.read(owner+Layout.records+ai*24,24);local aid=r.u(avatar,8)
        assert(r.u(avatar,16)==unit and flag(avatar:byte(21),1),'avatar identity')
        local inv=global('inventory');local ii=component(inv,0x28,0x40,aid,avatar)
        if not ii then return nil,'no inventory' end
        assert(ii<r.u(r.read(inv+0x14,4),0),'inventory index')
        local inventory=r.read(r.p(inv+0x50)+ii*48,48);local slot=r.u(inventory,28)
        local offset=({[1]=0,[2]=4,[3]=8,[4]=16,[5]=16,[6]=12})[slot]
        local wid=offset and r.u(inventory,offset);local inventory_weapon=wid
        local lowered=false;local mounted=false
        local sm=global('selector');local si=r.map(sm+0x30,aid,1048576)
        if si then
            local live=r.u(r.read(sm+0x18,4),0);local cap=r.u(r.read(sm+0x10,4),0)
            assert(live<=cap and live<=262144 and si<live,'selector bounds')
            assert(r.read(r.p(r.p(sm+0x48)+si*8),24)==avatar,'selector identity')
            local at=r.p(sm+0x60)+si*0x1d0;local selected=r.u(r.read(at,4),0)
            -- Selector interpolation rates are NOT a reliable movement visibility signal.
            if selected~=0 and selected~=0xffffffff and selected~=aid then
                wid=selected;mounted=wid~=inventory_weapon
            end
        end
        local rec,record_address=entity(owner,wid);if not rec then return nil,'no selected weapon' end
        -- Known crash-prone reference resource: do not probe its components.
        if rec:sub(1,8)==string.char(0x56,0x89,0xb3,0xab,0x3b,0x7d,0xc2,0x11) then return nil,'excluded resource' end
        assert(mounted or flag(rec:byte(21),1),'weapon ownership')
        local driver=global('driver');local di=component(driver,0x28,0x40,wid,rec)
        if not di then return nil,'no weapon driver' end
        local flags=r.u(r.read(r.p(driver+0x50)+di*40,40),0)
        local result={id=wid,unit_ref=r.u(rec,16),avatar_unit_ref=unit,resource_hex=string.format('%08x%08x',r.u(rec,4),r.u(rec,0)),lowered=lowered,alternate=mounted,reloadable=flag(flags,0x40)}
        -- Diagnostic values only. +0x0C is not yet a verified engine/Lua handle.
        -- All bytes below were already read for ownership and ammo selection.
        result.binding={module_base=base,record=record_address,candidate=r.u(rec,12),
            avatar_id=aid,avatar_record=owner+Layout.records+ai*24,avatar_candidate=r.u(avatar,12)}
        local kind=flag(flags,0x80) and 'magazine' or flag(flags,0x100) and 'rounds' or flag(flags,0x200) and 'heat'
        if kind then
            local m=global(kind);local mag=kind=='magazine'
            local i=component(m,mag and 0x20 or 0x28,mag and 0x38 or 0x40,wid,rec)
            if not i then return nil,'ammo component missing' end
            local cfg=config(kind,m,wid,rec,owner);result.kind=kind
            if kind=='heat' then
                local rt=r.read(r.p(m+0x58)+i*12,12)
                if not cfg then return nil,'heat calibration missing' end
                local limit=r.f(cfg,0x60);local heat=r.f(rt,4)
                assert(limit>0 and limit<1e7 and heat>=-1 and heat<1e7,'heat range')
                result.heat=math.max(0,math.min(1,heat/limit));result.locked=rt:byte(9)==1
                local sinks=r.i(rt,0)
                if valid(sinks,1000) and r.u(cfg,0x5c)>0 then result.reserve=sinks;result.reserve_kind='SINKS' end
            else
                local st=r.read(r.p(m+(mag and 0x48 or 0x50))+i*(mag and 16 or 24),mag and 16 or 24)
                local rt=r.read(r.p(m+(mag and 0x50 or 0x58))+i*(mag and 12 or 20),mag and 12 or 20)
                local sel=mag and 0 or r.u(rt,4);assert(sel<=1,'magazine selection')
                local chambered=cfg and cfg:byte((mag and 0x9c or 0x68)+1)==1
                local chamber=chambered and r.u(st,mag and 8 or 16)>0 and 1 or 0
                result.rounds=r.i(st,mag and 0 or 4+sel*4)+chamber
                assert(valid(result.rounds,5001),'ammo range')
                if cfg then
                    local capacity=mag and r.u(cfg,0x88) or r.f(cfg,0x48+sel*4)
                    if valid(capacity,5000) and capacity>=1 then result.capacity=math.max(capacity,result.rounds) end
                end
                local reserve=r.i(rt,0)
                local reserve_max=cfg and r.u(cfg,mag and 0x94 or 0x50)
                if valid(reserve,100000) and (not reserve_max or reserve_max>0) then
                    result.reserve=reserve;result.reserve_kind=mag and 'MAGS' or 'ROUNDS'
                end
                -- Only a known spawned pair is used; arbitrary backpacks never become reserve.
                if cfg and reserve_max==0 and not mounted then
                    for off=12,24,4 do
                        local bid=r.u(inventory,off)
                        if bid==wid+1 then result.reserve=deposit(owner,bid);result.reserve_kind='PACK' end
                    end
                end
            end
        elseif flag(flags,0x400) then
            result.kind='resource'
            for _,off in ipairs(Layout.resource) do
                local ok,count=pcall(function()
                    local m=r.p(base+off);local i=component(m,0x20,0x38,wid,rec)
                    if not i then return nil end
                    local provider=r.u(r.read(r.p(m+0x48)+i*36,36),0)
                    return deposit(owner,provider)
                end)
                if ok and count then result.rounds=count;break end
            end
            if not result.rounds then return nil,'resource provider unavailable' end
        else return nil,'unsupported ammo component' end
        self.status='ok';return result
    end
    function self.poll()
        local ok,value,reason=pcall(self.snapshot)
        if not ok then self.status=tostring(value);return nil end
        self.status=reason or 'ok';return value
    end
    return self
end
return M

end)()
HUD.pose=(function()
-- Read-only selected-weapon root pose. Native code is inspected, never invoked.
-- See WEAPON_BINDING.md. Unknown implementations or recycled handles fail closed.
local M={}
local function unhex(s) return (s:gsub('..',function(h)return string.char(tonumber(h,16))end)) end
local pose_prefix=unhex('40534883ec204863da')
local pose_suffix=unhex('488bc84c8b0041ff90e8000000488bcb48c1e10648034828488bc14883c4205bc3')
local resolver_prefix=unhex('48895c24084889742410574883ec20488b35')
local resolver_body=unhex('8bc325ffff3f003b8698000000720433dbeb1c8bc8488b86a0000000c1eb16381c0175eb488b8688000000488b1cc8')
function M.new(backend)
    local r=HUD.memory.new(backend)
    local self={status='not sampled',samples=0}
    function self.snapshot(raw)
        assert(raw and raw.binding,'no weapon binding')
        local b=raw.binding;r.reset()
        -- The reader must validate the game build before returning this binding.
        local api=r.p(b.module_base+0x3326308);local unit_api=r.p(api+0x18)
        local getter=r.p(unit_api+0x90);local code=r.read(getter,48)
        assert(code:sub(1,9)==pose_prefix and code:byte(10)==0xe8 and code:sub(15,47)==pose_suffix,'unknown pose getter')
        local resolver=getter+14+r.i(code,10);code=r.read(resolver,116)
        assert(code:sub(1,18)==resolver_prefix and code:sub(0x26,0x54)==resolver_body,'unknown unit resolver')
        local registry=r.p(resolver+0x16+r.i(code,0x12))
        local cap=r.u(r.read(registry+0x98,4),0);assert(cap>0 and cap<=0x400000,'unit capacity')
        local index=b.candidate%0x400000;local generation=math.floor(b.candidate/0x400000)%256
        assert(index>0 and index<cap,'unit index')
        local array=r.p(registry+0x88);local generations=r.p(registry+0xa0)
        assert(r.read(generations+index,1):byte()==generation,'recycled unit')
        local object=r.p(array+index*8)
        assert(r.u(r.read(object+8,4),0)==b.candidate,'unit identity')
        local accessor=r.p(r.p(object)+0xe8)
        assert(r.read(accessor,5)==unhex('488d4160c3'),'unknown scene accessor')
        local nodes=r.u(r.read(object+0x70,4),0);assert(nodes>0 and nodes<=4096,'node count')
        local address=r.p(object+0x88);local bytes=r.read(address,64);local matrix={}
        for i=1,16 do matrix[i]=r.f(bytes,(i-1)*4) end
        for _,i in ipairs({4,8,12}) do assert(math.abs(matrix[i])<1e-5,'matrix affine row') end
        assert(math.abs(matrix[16]-1)<1e-5,'matrix homogeneous component')
        for _,k in ipairs({1,5,9}) do
            local norm=0;for j=0,2 do norm=norm+matrix[k+j]^2 end
            assert(math.abs(norm-1)<.05,'matrix axis scale')
        end
        for _,pair in ipairs({{1,5},{1,9},{5,9}}) do
            local dot=0;for j=0,2 do dot=dot+matrix[pair[1]+j]*matrix[pair[2]+j] end
            assert(math.abs(dot)<.05,'matrix axes')
        end
        for i=13,15 do assert(math.abs(matrix[i])<1e7,'matrix position') end
        -- Revalidate both ends after the read; no persistent entity/matrix pointer cache.
        local record=r.read(b.record,24)
        assert(r.u(record,8)==raw.id and r.u(record,12)==b.candidate and r.u(record,16)==raw.unit_ref,'weapon changed')
        assert(r.read(generations+index,1):byte()==generation and r.p(array+index*8)==object,'unit recycled during read')
        assert(r.u(r.read(object+8,4),0)==b.candidate and r.p(object+0x88)==address,'pose owner changed')
        return {id=raw.id,resource_hex=raw.resource_hex,candidate=b.candidate,node_count=nodes,
            matrix=matrix,x=matrix[13],y=matrix[14],z=matrix[15]}
    end
    function self.poll(raw)
        local ok,value=pcall(self.snapshot,raw)
        if not ok then self.status=tostring(value);return nil end
        self.status='verified root pose';self.samples=self.samples+1;return value
    end
    return self
end
return M

end)()
HUD.projection=(function()
-- Diagnostic world-to-screen projection. Reads data only; no engine calls.
-- Initial scope: perspective camera with identity local camera offset.
local M={}
local function unhex(s)return (s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
function M.project(m,x,y,z,fov,aspect,near)
    assert(fov>.05 and fov<3.1 and aspect>.1 and aspect<10,'projection dimensions')
    for i=1,16 do assert(type(m[i])=='number' and m[i]==m[i] and math.abs(m[i])<1e7,'camera matrix finite') end
    for _,k in ipairs({1,5,9}) do
        local n=m[k]^2+m[k+1]^2+m[k+2]^2;assert(math.abs(n-1)<.01,'camera axis scale')
    end
    for _,p in ipairs({{1,5},{1,9},{5,9}}) do
        local a,b=p[1],p[2];assert(math.abs(m[a]*m[b]+m[a+1]*m[b+1]+m[a+2]*m[b+2])<.01,'camera axes')
    end
    assert(math.abs(m[4])+math.abs(m[8])+math.abs(m[12])+math.abs(m[16]-1)<1e-5,'camera affine')
    local dx,dy,dz=x-m[13],y-m[14],z-m[15]
    local right=dx*m[1]+dy*m[2]+dz*m[3]
    local depth=dx*m[5]+dy*m[6]+dz*m[7]
    local up=dx*m[9]+dy*m[10]+dz*m[11]
    if depth<=math.max(near,.05) then return nil,'behind camera or near plane' end
    local t=math.tan(fov*.5)
    local nx,ny=.5+.5*right/(depth*t*aspect),.5+.5*up/(depth*t)
    if nx~=nx or ny~=ny or nx<0 or nx>1 or ny<0 or ny>1 then return nil,'outside viewport' end
    return {x=nx,y=ny,depth=depth},'projected weapon root'
end
function M.new(backend)
    local r=HUD.memory.new(backend);local self={status='not sampled'}
    function self.snapshot(base,pose,aspect)
        r.reset()
        local api=r.p(base+0x3326308);local camera_api=r.p(api+0x20)
        local getter=r.p(camera_api+0xf8)
        assert(r.read(getter,10)==unhex('48895c2408574883ec60'),'unknown projection wrapper')
        local call=r.read(getter+0x132,5);assert(call:byte()==0xe8,'unknown projection call')
        local impl=getter+0x137+r.i(call,1)
        assert(r.read(impl,16)==unhex('488bc448895808488968104889701857'),'unknown projection implementation')
        assert(r.read(impl+0x62,20)==unhex('488b471848c1e206418be948035028e80a951500'),'unknown camera scene layout')
        local state=r.p(base+0x346d560);local camera=r.p(state);local b=r.read(camera,160)
        local scene=r.p(camera+0x18);local index=r.u(b,0x20)
        assert(index<4096,'camera node index')
        assert(r.u(b,0x30)==1 and r.u(b,0x50)==0,'unsupported camera projection mode')
        local near,fov=r.f(b,0x28),r.f(b,0x34)
        assert(near>0 and near<10,'camera near plane')
        -- Nonidentity local offsets require a separately verified inverse transform.
        for _,o in ipairs({0x80,0x84,0x88,0x90,0x94,0x98,0x48,0x4c}) do
            assert(math.abs(r.f(b,o))<1e-6,'camera local offset unsupported')
        end
        assert(math.abs(math.abs(r.f(b,0x8c))-1)<1e-6,'camera local rotation unsupported')
        local array=r.p(scene+0x28);local data=r.read(array+index*64,64);local matrix={}
        for i=1,16 do matrix[i]=r.f(data,(i-1)*4) end
        assert(r.p(base+0x346d560)==state and r.p(state)==camera and r.p(camera+0x18)==scene
            and r.u(r.read(camera+0x20,4),0)==index and r.p(scene+0x28)==array,'camera changed during read')
        return M.project(matrix,pose.x,pose.y,pose.z,fov,aspect,near)
    end
    function self.poll(base,pose,aspect)
        if not base or not pose then self.status='no weapon pose';return nil end
        local ok,result,status=pcall(self.snapshot,base,pose,aspect)
        self.status=ok and status or tostring(result)
        return ok and result or nil
    end
    return self
end
return M

end)()
HUD.anchor=(function()
-- Read the native crosshair controller AFTER the game's update.
-- Layout independently traced from hud_crosshair -> native update -> screen XY.
-- Never invokes game functions or writes game memory.
local M={}
local SPEC={
    manager=0x346D538,camera=0x346D560,hud=0x24E340,crosshair=0x19AAF8,
    signatures={
        {0x12F53AF,'488b2d82811702'},
        {0x12F588F,'488d8d40e32400448bc60f28cee8af63ffffeb17'},
        {0x12EBDF4,'498d8ef8aa1900448bc30f28cfe85aa74c00'},
        {0x17B6718,'488b0521fcb6018b8830c50a00'},
        {0x17B6FF5,'f20f1008488b4424500f28c1f3410f118f88200000f30f5cce0fc6c055f3410f11878c200000'},
        {0x17B7050,'f30f594010498bcf8b542424f30f114583488b44245849898790200000'},
        {0x144C370,'488b81f00000004885c074130f1f4000488bc8488b80f00000004885c075f1488bc1c3'}
    }
}
M.spec=SPEC
function M.new(backend)
    local r=HUD.memory.new(backend)
    local base,validated,failed;local self={status='not sampled',samples=0}
    local function validate()
        r.reset();base=assert(backend.module('game.dll'),'game.dll not loaded')
        local d=r.read(base,64);assert(d:sub(1,2)=='MZ','DOS signature')
        local offset=r.u(d,0x3c);assert(offset<0x100000,'PE offset')
        local h=r.read(base+offset,0x80)
        assert(h:sub(1,4)=='PE\0\0' and HUD.layouts.stamps[r.u(h,8)]==r.u(h,0x50),'unsupported anchor build')
        for _,s in ipairs(SPEC.signatures) do
            local expected=s[2]:gsub('..',function(hex)return string.char(tonumber(hex,16))end)
            assert(r.read(base+s[1],#expected)==expected,string.format('anchor signature %X',s[1]))
        end
        validated=true
    end
    local function optional_pointer(a)
        local b=r.read(a,8);local p=r.u(b,0)+r.u(b,4)*2^32
        if p==0 then return nil end
        assert(p>=65536 and p<2^47,'anchor pointer');return p
    end
    local function snapshot()
        r.reset()
        local manager=r.p(base+SPEC.manager)
        local hud=manager+SPEC.hud
        if r.read(hud+0x58,1):byte(1)==0 or r.read(hud+0x21f5b0,1):byte(1)==0 then return nil,'native HUD inactive' end
        local control=hud+SPEC.crosshair
        local b=r.read(control+0x2080,24)
        local state=r.u(b,0)
        if state==1 then return nil,'native reticle hidden' end
        assert(state>=2 and state<=4,'invalid reticle state')
        local pixel_x,pixel_y=r.f(b,8),r.f(b,12)
        local dx,dy=r.f(b,16),r.f(b,20)
        -- This is the same bounded parent walk as native UI root lookup 144C370.
        local root=control;local visited={};local finished=false
        for _=1,32 do
            assert(not visited[root],'UI parent cycle');visited[root]=true
            local parent=optional_pointer(root+0xf0)
            if not parent then finished=true;break end
            root=parent
        end
        assert(finished,'UI parent depth')
        local size=r.read(root+0xc,8);local width,height=r.f(size,0),r.f(size,4)
        assert(width>=64 and width<=32768 and height>=64 and height<=32768,'UI root dimensions')
        local camera=r.p(base+SPEC.camera);local offset=r.read(camera+0xdc,8)
        local cx,cy=r.f(offset,0),r.f(offset,4)
        assert(math.abs(cx)<=1 and math.abs(cy)<=1,'camera screen offset')
        -- Native: local = (screen - 0.5*viewport*(1+camera_offset))/viewport * UI_size.
        -- Invert it to normalize without confusing render-scale pixels with output pixels.
        local nx,ny=0.5*(1+cx)+dx/width,0.5*(1+cy)+dy/height
        assert(nx>=-1 and nx<=2 and ny>=-1 and ny<=2,'reticle coordinates out of range')
        assert(math.abs(pixel_x)<=65536 and math.abs(pixel_y)<=65536,'screen position out of range')
        assert(r.p(base+SPEC.manager)==manager and r.u(r.read(control+0x2080,4),0)==state,'reticle changed during read')
        self.samples=self.samples+1;self.native_state=state
        self.pixel_x,self.pixel_y,self.dx,self.dy=pixel_x,pixel_y,dx,dy
        self.min_x=math.min(self.min_x or nx,nx);self.max_x=math.max(self.max_x or nx,nx)
        self.min_y=math.min(self.min_y or ny,ny);self.max_y=math.max(self.max_y or ny,ny)
        return {x=math.max(0,math.min(1,nx)),y=math.max(0,math.min(1,1-ny)),visible=true},'native crosshair'
    end
    function self.poll()
        if failed then return nil end
        if not validated then
            local ok,err=pcall(validate)
            if not ok then self.status=tostring(err);failed=not self.status:find('game.dll not loaded',1,true);return nil end
        end
        local ok,result,status=pcall(snapshot)
        self.status=ok and status or tostring(result)
        return ok and result or nil
    end
    return self
end
return M

end)()
HUD.view=(function()
local M={}
function M.new(sr)
    local gui,world;local ids={};local G,W,A=sr.Gui,sr.World,sr.Application
    local font='core/performance_hud/debug'
    local self={}
    local blur;local probe_frames=0
    local candidates={'content/ui/shared/material/gui_blur','content/ui/shared/material/blur_background'}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if v==w then return true end end
        return false
    end
    function self.clear()
        if gui and live(world) then
            for _,v in ipairs(ids) do pcall(G['destroy_'..v.type],gui,v.id) end
        end
        ids={}
    end
    function self.release()
        if gui and live(world) then self.clear();W.destroy_gui(world,gui) end
        gui,world,ids=nil,nil,{};blur=nil;probe_frames=0
    end
    local function ensure()
        if gui and not live(world) then gui,world,ids=nil,nil,{};blur=nil;probe_frames=0 end
        if not gui then
            local main=A.main_world()
            for _,v in pairs(A.worlds() or {}) do if v~=main then world=v;break end end
            world=world or main;if not world then return end
            gui=W.create_screen_gui(world,'scale',1,1)
        end
        return gui~=nil
    end
    function self.draw(commands)
        if not ensure() then return end
        self.clear()
        if not blur and probe_frames%120==0 and type(A.can_get)=='function' and type(G.bitmap)=='function' then
            for _,name in ipairs(candidates) do
                local ok,available=pcall(A.can_get,'material',name)
                if ok and available then blur=name;break end
            end
        end
        probe_frames=probe_frames+1
        for _,c in ipairs(commands) do
            local color=sr.Color(math.floor(c.a*255+0.5),c.c[1],c.c[2],c.c[3])
            local id
            local kind=c.type
            if c.type=='panel' then
                local drawn=false
                if c.frosted and blur then
                    local ok,bid=pcall(G.bitmap,gui,blur,sr.Vector3(c.x,c.y,48),sr.Vector2(c.w,c.h),sr.Color(255,255,255,255))
                    if ok and bid then ids[#ids+1]={type='bitmap',id=bid};drawn=true
                    else blur=nil;probe_frames=1 end
                end
                self.material_status=drawn and ('native frost: '..blur) or 'opaque panel (native frost unavailable or disabled)'
                -- No fake translucent fallback when the game's blur resource is unavailable.
                if not drawn then color=sr.Color(255,c.c[1],c.c[2],c.c[3]) end
                id=G.rect(gui,sr.Vector3(c.x,c.y,49),sr.Vector2(c.w,c.h),color);kind='rect'
            elseif c.type=='rect' then
                id=G.rect(gui,sr.Vector3(c.x,c.y,50),sr.Vector2(c.w,c.h),color)
            elseif c.font=='bigblue' then
                HUD.font.draw(c.text,c.size,c.x,c.y,function(x,y,w,h)
                    local rid=G.rect(gui,sr.Vector3(x,y,51),sr.Vector2(w,h),color)
                    if rid then ids[#ids+1]={type='rect',id=rid} end
                end)
            else
                id=G.text(gui,c.text,font,c.size,font,sr.Vector3(c.x,c.y,51),color)
            end
            if id then ids[#ids+1]={type=kind,id=id} end
        end
    end
    return self
end
return M

end)()
HUD.pose_motion=(function()
-- Frame-rate independent rigid-pose smoothing; no engine userdata retained.
local M={}
local function quaternion(m)
    local a,b,c=m[1],m[6],m[11];local x,y,z,w;local t=a+b+c
    if t>0 then
        local s=math.sqrt(t+1)*2;w=s/4;x=(m[7]-m[10])/s;y=(m[9]-m[3])/s;z=(m[2]-m[5])/s
    elseif a>b and a>c then
        local s=math.sqrt(1+a-b-c)*2;w=(m[7]-m[10])/s;x=s/4;y=(m[5]+m[2])/s;z=(m[9]+m[3])/s
    elseif b>c then
        local s=math.sqrt(1+b-a-c)*2;w=(m[9]-m[3])/s;x=(m[5]+m[2])/s;y=s/4;z=(m[10]+m[7])/s
    else
        local s=math.sqrt(1+c-a-b)*2;w=(m[2]-m[5])/s;x=(m[9]+m[3])/s;y=(m[10]+m[7])/s;z=s/4
    end
    local n=math.sqrt(x*x+y*y+z*z+w*w);return {x/n,y/n,z/n,w/n}
end
local function blend(a,b,t)
    local dot=0;for i=1,4 do dot=dot+a[i]*b[i]end
    local sign=dot<0 and -1 or 1;dot=math.min(1,math.abs(dot))
    local u,v=1-t,t
    if dot<.9995 then local angle=math.acos(dot);local den=math.sin(angle);u=math.sin((1-t)*angle)/den;v=math.sin(t*angle)/den end
    local q={};local n=0;for i=1,4 do q[i]=a[i]*u+b[i]*sign*v;n=n+q[i]^2 end
    n=math.sqrt(n);for i=1,4 do q[i]=q[i]/n end;return q
end
function M.step(s,m,x,y,z,key,dt,c)
    dt=type(dt)=='number' and dt==dt and dt>=0 and dt or 1/60
    local q=quaternion(m)
    local jump=s.x and (s.x-x)^2+(s.y-y)^2+(s.z-z)^2>4
    if not s.q or s.key~=key or dt>.35 or jump then
        s.x,s.y,s.z,s.q=x,y,z,q
    else
        local a=c.world_position_smooth==0 and 1 or 1-math.exp(-dt/c.world_position_smooth)
        s.x,s.y,s.z=s.x+(x-s.x)*a,s.y+(y-s.y)*a,s.z+(z-s.z)*a
        local dx,dy,dz=s.x-x,s.y-y,s.z-z;local d=math.sqrt(dx*dx+dy*dy+dz*dz)
        if d>c.world_max_lag then local k=c.world_max_lag/d;s.x,s.y,s.z=x+dx*k,y+dy*k,z+dz*k end
        local t=c.world_rotation_smooth==0 and 1 or 1-math.exp(-dt/c.world_rotation_smooth)
        s.q=blend(s.q,q,t)
    end
    s.key=key
    local a,b,c,d=s.q[1],s.q[2],s.q[3],s.q[4]
    return {1-2*(b*b+c*c),2*(a*b+c*d),2*(a*c-b*d),0,
        2*(a*b-c*d),1-2*(a*a+c*c),2*(b*c+a*d),0,
        2*(a*c+b*d),2*(b*c-a*d),1-2*(a*a+b*b),0,s.x,s.y,s.z,1}
end
return M

end)()
HUD.world_probe=(function()
-- Minimal world-space GUI experiment; only engine-returned world/GUI handles.
local M={}
function M.new(sr,log)
    local A,W,G=sr.Application,sr.World,sr.Gui
    local smooth={};local depth_fill;local blur;local gui,world;local failed=false;local first=true
    local self={status='not started'}
    local function identity(handle)
        -- LuaJIT %p bypasses the engine's generic '[Material]' __tostring.
        -- This identifies Lua userdata storage, not necessarily its native object.
        local ok,address=pcall(string.format,'%p',handle)
        return tostring(handle)..(ok and (' lua_address='..address) or '')
    end
    local function live(w)
        if not w then return false end
        for _,v in pairs(A.worlds() or {})do if v==w then return true end end
        return false
    end
    function self.release()
        if gui and live(world) then
            log('WORLD_GUI destroy begin');W.destroy_gui(world,gui);log('WORLD_GUI destroy complete')
        end
        gui,world=nil,nil;blur=nil;depth_fill=nil;smooth={}
    end
    local function draw(p,c,commands,dt)
        if (not c.world_probe and not commands) or not p then self.release();return end
        if not W.create_world_gui or not G.move or not sr.Matrix4x4 or not sr.Matrix4x4.from_axes then
            self.status='world GUI functions missing';return
        end
        if gui and not live(world) then gui,world=nil,nil;smooth={} end
        local main=A.main_world()
        if not live(main) then self.status='no live main world';return end
        if gui and main~=world then self.release() end
        local m=p.matrix
        local x,y,z=c.mount_x,c.mount_y,c.mount_z+.20
        local px=p.x+m[1]*x+m[5]*y+m[9]*z
        local py=p.y+m[2]*x+m[6]*y+m[10]*z
        local pz=p.z+m[3]*x+m[7]*y+m[11]*z
        m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
        px,py,pz=m[13],m[14],m[15]
        if first then log('WORLD_GUI matrix begin') end
        local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),
            sr.Vector3(m[5],m[6],m[7]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(px,py,pz))
        if not gui then
            world=main;log('WORLD_GUI create begin')
            gui=assert(W.create_world_gui(world,pose,1000,1000,'immediate'),'world GUI returned nil')
            log('WORLD_GUI create complete')
            local name='mods/dbf_hud/materials/depth_fill'
            if A.can_get and A.can_get('material',name) then depth_fill=name
            elseif A.can_get and A.can_get('material','mods/astra_ammo/materials/depth_fill') then
                depth_fill='mods/astra_ammo/materials/depth_fill' -- Previously deployed optional material.
            end
            log('WORLD_GUI depth material '..(depth_fill and 'available' or 'missing; install depth material addon'))
            -- One-time observation only: resolve the same material used by bitmap.
            -- Keep no native material handles across frames or GUI destruction.
            log('WORLD_GUI instance '..identity(gui)..' world '..identity(world))
            if type(G.material)=='function' and A.can_get then
                for _,material_name in ipairs({'content/ui/shared/material/gui_fill',
                    'mods/dbf_hud/materials/depth_fill','mods/dbf_hud/materials/depth_blur'}) do
                    if A.can_get('material',material_name) then
                        local ok,handle=pcall(G.material,gui,material_name)
                        log('WORLD_GUI material instance '..material_name..' '..(ok and identity(handle) or 'lookup failed'))
                    end
                end
            else log('WORLD_GUI material inspection unavailable') end
        else
            if first then log('WORLD_GUI move begin') end
            G.move(gui,pose)
        end
        if commands then
            -- Native screen frost renders white on the verified world-GUI path.
            -- Keep the user's frost preference for screen modes; omit it here.
            -- Bitmap takes the material as a required argument. This avoids relying
            -- on the game's optional rect material overload matching upstream.
            local function solid(x,y,w,h,layer,color)
                if depth_fill then
                    G.bitmap(gui,depth_fill,sr.Vector3(x,y,layer),sr.Vector2(w,h),color)
                else G.rect(gui,sr.Vector3(x,y,layer),sr.Vector2(w,h),color) end
            end
            for _,v in ipairs(commands) do
                local color=sr.Color(math.floor(v.a*255+.5),v.c[1],v.c[2],v.c[3])
                if v.type=='panel' then
                    -- Match the known-working hybrid background; leave experimental
                    -- depth fill on foreground primitives only during this comparison.
                    G.rect(gui,sr.Vector3(v.x,v.y,1),sr.Vector2(v.w,v.h),color)
                elseif v.type=='rect' then
                    solid(v.x,v.y,v.w,v.h,2,color)
                elseif v.font=='bigblue' then
                    HUD.font.draw(v.text,v.size,v.x,v.y,function(x,y,w,h)
                        solid(x,y,w,h,3,color)
                    end)
                else
                    local font='core/performance_hud/debug'
                    G.text(gui,v.text,font,v.size,font,sr.Vector3(v.x,v.y,3),color)
                end
            end
            if first then log('WORLD_GUI panel submitted: '..(depth_fill and 'explicit material bitmap path' or 'default rectangle path'));first=false end
            self.status='world panel; frost unavailable on this rendering path';return true
        end
        if first then log('WORLD_GUI rect begin') end
        G.rect(gui,sr.Vector3(0,0,0),sr.Vector2(240,140),sr.Color(255,45,52,55))
        G.rect(gui,sr.Vector3(0,0,1),sr.Vector2(12,140),sr.Color(255,231,200,92))
        if first then log('WORLD_GUI rect complete');first=false end
        self.status='world rectangle submitted'
    end
    function self.draw(p,c,commands,dt)
        if failed then return end
        local ok,err=pcall(draw,p,c,commands,dt)
        if not ok then
            failed=true;self.status=tostring(err);log('WORLD_GUI Lua failure: '..self.status)
            pcall(self.release)
        end
        return ok and err==true
    end
    return self
end
return M

end)()
HUD.offscreen_test=(function()
-- Isolated one-frame render test. Never renders from the update callback.
local M={}
function M.start(sr,log,globals,panel_provider)
    globals=globals or _G
    local self={};local active=true;local submitted=false
    local A,W,R,V,U,G=sr.Application,sr.World,sr.Renderer,sr.Viewport,sr.Unit,sr.Gui
    local world,viewport,target,camera,environment,gui
    local preview,preview_world
    local world_ready=false
    local source_ids={};local elapsed=0
    function self.tick(dt)
        elapsed=elapsed+(dt or 0)
        if panel_provider and active and world and gui and (not world_ready or elapsed>=0.1) then
            elapsed=0
            local commands=panel_provider()
            if commands then
                for _,id in ipairs(source_ids) do G.destroy_rect(gui,id) end
                source_ids={}
                local f=commands[1]
                assert(f.w>0 and f.h>0,'invalid panel bounds')
                self.aspect=f.w/f.h
                local sx,sy=512/f.w,256/f.h
                local function rect(x,y,w,h,c,a)
                    local id=G.rect(gui,sr.Vector3((x-f.x)*sx,(y-f.y)*sy,1),sr.Vector2(w*sx,h*sy),sr.Color(math.floor(255*(a or 1)),c[1],c[2],c[3]))
                    source_ids[#source_ids+1]=id
                end
                for _,c in ipairs(commands) do
                    if c.type=='text' then
                        HUD.font.draw(c.text,c.size,c.x,c.y,function(x,y,w,h)rect(x,y,w,h,c.c,c.a)end)
                    else rect(c.x,c.y,c.w,c.h,c.c,c.a) end
                end
                world_ready=false;submitted=false
            end
        end
        if active and world and not world_ready then
            world_ready=true
            if type(W.update)=='function' then
                if not panel_provider then log('OFFSCREEN private world update begin') end
                local ok,err=pcall(W.update,world,0)
                if not panel_provider or not ok then log(ok and 'OFFSCREEN private world update complete' or ('OFFSCREEN private world update failed '..tostring(err))) end
                if not ok then active=false end
            else log('OFFSCREEN private world update unavailable') end
        end
    end
    local bridge=rawget(globals,'HUDRenderBridge');local unsubscribe
    function self.release()
        active=false
        if unsubscribe then unsubscribe();unsubscribe=nil end
        local ok=true
        local function destroy(fn,...)
            if not ok then return end
            local done,err=pcall(fn,...);ok=done
            if not done then log('OFFSCREEN cleanup failed '..tostring(err)) end
        end
        if preview then
            local live=false
            for _,w in pairs(A.worlds() or {}) do if w==preview_world then live=true end end
            if live then destroy(W.destroy_gui,preview_world,preview) end
            if ok then preview=nil end
        end
        if gui then destroy(W.destroy_gui,world,gui);if ok then gui=nil end end
        if viewport then destroy(A.destroy_viewport,world,viewport);if ok then viewport=nil end end
        if environment then destroy(W.destroy_shading_environment,world,environment);if ok then environment=nil end end
        if world then destroy(A.release_world,world);if ok then world=nil end end
        if target then destroy(R.destroy_resource,target);if ok then target=nil end end
        if ok then log('OFFSCREEN cleanup complete') end
    end
    if not bridge or bridge.api~=1 or type(bridge.subscribe)~='function' then
        local loader=rawget(globals,'CowboyBingusModLoader')
        local state=loader and loader.modules and loader.modules['mods/holographic_utility_display/render_bridge']
        log('OFFSCREEN blocked: startup HUD render bridge required; loader='..tostring(state)..'; render='..type(rawget(globals,'render')))
        self.waiting_for_bridge=true
        return self
    end
    local ok,err=pcall(function()
        for _,pair in ipairs({{A,'new_world'},{A,'release_world'},{A,'create_viewport'},{A,'destroy_viewport'},
            {A,'render_world'},{A,'can_get'},{W,'spawn_unit'},{W,'create_screen_gui'},
            {W,'destroy_gui'},{W,'destroy_shading_environment'},
            {U,'camera'},{R,'create_resource'},{R,'destroy_resource'},{V,'set_output_render_target'},
            {G,'rect'}}) do assert(pair[1] and type(pair[1][pair[2]])=='function','missing '..pair[2]) end
        local name='core/units/camera'
        if not A.can_get('unit',name) then name='core/appkit/units/camera/camera' end
        if not A.can_get('unit',name) then
            for _,ns_name in ipairs({'Camera','World','Application'}) do
                local names={};local ns=sr[ns_name]
                if type(ns)=='table' then for key,value in pairs(ns) do
                    if type(key)=='string' and type(value)=='function' and
                        (ns_name=='Camera' or key:lower():find('camera',1,true)) then names[#names+1]=key end
                end end
                table.sort(names);log('OFFSCREEN CAMERA_API '..ns_name..' '..table.concat(names,' '))
            end
            for _,candidate in ipairs({'core/appkit/units/camera','content/markers/camera_marker',
                'core/editor_slave/stingray_editor/editor_camera'}) do
                log('OFFSCREEN CAMERA_RESOURCE '..candidate..' '..tostring(A.can_get('unit',candidate)))
            end
        end
        assert(A.can_get('unit',name),'camera resource unavailable: '..name)
        local environment_name='core/stingray_renderer/environments/midday/midday'
        local default_environment=type(W.create_default_shading_environment)=='function'
        if not default_environment then
            assert(type(W.create_shading_environment)=='function','missing create_shading_environment')
            assert(A.can_get('shading_environment',environment_name),'default environment resource unavailable')
        end
        log('OFFSCREEN setup begin')
        world=assert(A.new_world())
        if type(U.num_meshes)=='function' then
            for _,candidate in ipairs({'content/art_shared/meshes/plane_2x2m','content/art_shared/meshes/plane_primitive','content/env_ship/hologram/units/plane'}) do
                local available=A.can_get('unit',candidate)
                log('SURFACE unit '..candidate..' available='..tostring(available))
                if available then
                    local probe=assert(W.spawn_unit(world,candidate))
                    local count=U.num_meshes(probe)
                    log('SURFACE unit '..candidate..' meshes='..tostring(count))
                    if count==1 and type(U.mesh)=='function' and sr.Mesh and type(sr.Mesh.num_materials)=='function' then
                        local mesh=U.mesh(probe,1)
                        local slots=sr.Mesh.num_materials(mesh)
                        log('SURFACE first mesh material slots='..tostring(slots))
                        if slots==1 and type(sr.Mesh.material)=='function' then
                            local material=sr.Mesh.material(mesh,1)
                            local ffi=require('ffi')
                            log(string.format('SURFACE material pointer=0x%X',tonumber(ffi.cast('uintptr_t',material))))
                        end
                    end
                    -- Private world owns this probe; no scene attachment or material changes.
                end
            end
        end
        local unit=assert(W.spawn_unit(world,name))
        camera=assert(U.camera(unit,1),'camera unavailable')
        environment=assert(default_environment and W.create_default_shading_environment(world)
            or W.create_shading_environment(world,environment_name))
        viewport=assert(A.create_viewport(world,'offscreen_ui_weapon_screen'))
        target=assert(R.create_resource('render_target','R8G8B8A8',panel_provider and 512 or 64,panel_provider and 256 or 64))
        V.set_output_render_target(viewport,target)
        self.texture=target
        gui=assert(W.create_screen_gui(world,'scale',1,1))
        if not panel_provider then
        for i,color in ipairs({{230,60,60},{60,210,100},{60,110,230},{230,200,60}}) do
            G.rect(gui,sr.Vector3(((i-1)%2)*32,math.floor((i-1)/2)*32,1),sr.Vector2(32,32),
                sr.Color(255,color[1],color[2],color[3]))
        end
        end
        log('OFFSCREEN camera and source GUI ready')
    end)
    if not ok then log('OFFSCREEN setup stopped '..tostring(err));self.release();return self end
    unsubscribe=bridge.subscribe('dbf_hud.offscreen',function(...)
        if active and world_ready and not submitted then
            submitted=true
            if not preview then log('OFFSCREEN render callback entered') end
            local done,why=pcall(A.render_world,world,camera,viewport,environment)
            if not preview or not done then log(done and 'OFFSCREEN render submitted; pixels unverified' or ('OFFSCREEN render failed '..tostring(why))) end
            if done and not preview then
                local shown,reason=pcall(function()
                    log('OFFSCREEN preview preflight begin')
                    assert(type(G.material)=='function','Gui.material unavailable')
                    assert(sr.Material and type(sr.Material.set_resource)=='function','Material.set_resource unavailable')
                    assert(type(G.bitmap)=='function','Gui.bitmap unavailable')
                    assert(type(A.main_world)=='function','Application.main_world unavailable')
                    assert(A.can_get('material','content/ui/shared/material/gui_diffuse_map'),'preview material unavailable')
                    local main=assert(A.main_world())
                    preview_world=main
                    for _,candidate in pairs(A.worlds() or {}) do
                        if candidate~=main and candidate~=world then preview_world=candidate;break end
                    end
                    log('OFFSCREEN preview world '..(preview_world==main and 'main fallback' or 'HUD world'))
                    log('OFFSCREEN preview GUI create begin')
                    preview=assert(W.create_screen_gui(preview_world,'scale',1,1))
                    -- Independent control: visible geometry does not depend on the render target.
                    G.rect(preview,sr.Vector3(896,296,79),sr.Vector2(panel_provider and 392 or 200,panel_provider and 200 or 200),sr.Color(255,255,0,255))
                    G.rect(preview,sr.Vector3(panel_provider and 1300 or 1104,300,80),sr.Vector2(48,48),sr.Color(255,255,255,255))
                    log('OFFSCREEN placement control: magenta frame and white square')
                    log('OFFSCREEN preview material lookup begin')
                    for _,candidate in ipairs({'core/performance_hud/gui','content/ui/shared/material/gui_diffuse_map','content/ui/shared/material/gui_fill','content/ui/shared/material/gui_white_alpha'}) do
                        if A.can_get('material',candidate) then
                            local valid,result=pcall(function()
                                local ffi=require('ffi')
                                return string.format('0x%X',tonumber(ffi.cast('uintptr_t',G.material(preview,candidate))))
                            end)
                            log('OFFSCREEN material candidate '..candidate..' '..(valid and result or 'lookup failed'))
                        else log('OFFSCREEN material candidate '..candidate..' unavailable') end
                    end
                    local material=assert(G.material(preview,'content/ui/shared/material/gui_diffuse_map'))
                    log('OFFSCREEN material Lua type='..type(material)..'; target Lua type='..type(target))
                    local pointer_ok,pointers=pcall(function()
                        local ffi=require('ffi')
                        local mp=tonumber(ffi.cast('uintptr_t',material))
                        local tp=tonumber(ffi.cast('uintptr_t',target))
                        assert(mp and mp>=65536,'Gui.material returned a null or invalid native pointer')
                        assert(tp and tp>=65536,'render target returned a null or invalid native pointer')
                        return string.format('material=0x%X target=0x%X',mp,tp)
                    end)
                    assert(pointer_ok,pointers)
                    log('OFFSCREEN native pointer check '..pointers)
                    -- Native signature and diffuse_map slot verified; null handles rejected above.
                    log('OFFSCREEN verified texture binding begin')
                    sr.Material.set_resource(material,'diffuse_map',target)
                    log('OFFSCREEN preview bitmap draw begin')
                    G.bitmap(preview,'content/ui/shared/material/gui_diffuse_map',sr.Vector3(900,300,80),sr.Vector2(panel_provider and 384 or 192,192),sr.Color(255,255,255,255))
                    log('OFFSCREEN four-color preview placed above/right of native bottom-left HUD')
                end)
                if not shown then log('OFFSCREEN preview stopped '..tostring(reason)) end
            end
        end
    end)
    log('OFFSCREEN waiting for render callback')
    return self
end
return M

end)()
HUD.scene_test=(function()
-- Experimental scene-mesh carrier; uses only engine-owned handles.
local M={}
function M.new(sr,log)
    local A,W,U,Mesh=sr.Application,sr.World,sr.Unit,sr.Mesh
    local unit,world,bound;local failed=false;local smooth={}
    local self={}
    local function live(w)
        for _,v in pairs(A.worlds() or {}) do if w==v then return true end end
        return false
    end
    function self.release()
        if unit and live(world) then W.destroy_unit(world,unit) end
        unit,world,bound=nil,nil,nil;smooth={}
    end
    function self.draw(p,c,target,dt,aspect)
        if failed then return end
        if not p or not target then if unit then self.release() end;return end
        local ok,err=pcall(function()
            local main=A.main_world()
            if not live(main) then return end
            if unit and (world~=main or not live(world)) then self.release() end
            if not unit then
                local name='content/art_shared/meshes/plane_primitive'
                assert(A.can_get('unit',name),'plane unit unavailable')
                for _,fn in ipairs({'set_local_pose','set_local_scale','num_meshes','mesh'}) do assert(type(U[fn])=='function','missing Unit.'..fn) end
                assert(Mesh and type(Mesh.num_materials)=='function' and type(Mesh.material)=='function','mesh material API unavailable')
                world=main
                log('SCENE plane spawn begin')
                unit=assert(W.spawn_unit(world,name))
                assert(U.num_meshes(unit)==1,'unexpected mesh count')
                local mesh=U.mesh(unit,1)
                assert(Mesh.num_materials(mesh)==1,'unexpected material count')
                local material=Mesh.material(mesh,1)
                local ffi=require('ffi')
                assert(tonumber(ffi.cast('uintptr_t',material))>=65536,'invalid scene material')
                assert(tonumber(ffi.cast('uintptr_t',target))>=65536,'invalid panel texture')
                log('SCENE verified material texture bind begin')
                sr.Material.set_resource(material,'color_map',target)
                sr.Material.set_resource(material,'emissive_map',target)
                sr.Material.set_scalar(material,'use_color_map',1)
                sr.Material.set_scalar(material,'use_emissive_map',1)
                sr.Material.set_scalar(material,'emissive_intensity',1)
                sr.Material.set_vector3(material,'base_color',sr.Vector3(1,1,1))
                sr.Material.set_vector3(material,'emissive',sr.Vector3(1,1,1))
                bound=target
                log('SCENE plane texture bound')
            end
            assert(bound==target,'render target changed without scene retirement')
            local m=p.matrix
            local x,y,z=c.mount_x,c.mount_y,c.mount_z+0.2
            local px=p.x+m[1]*x+m[5]*y+m[9]*z
            local py=p.y+m[2]*x+m[6]*y+m[10]*z
            local pz=p.z+m[3]*x+m[7]*y+m[11]*z
            m=HUD.pose_motion.step(smooth,m,px,py,pz,tostring(p.id)..':'..tostring(p.candidate),dt,c)
            local pose=sr.Matrix4x4.from_axes(sr.Vector3(m[1],m[2],m[3]),sr.Vector3(m[9],m[10],m[11]),sr.Vector3(-m[5],-m[6],-m[7]),sr.Vector3(m[13],m[14],m[15]))
            U.set_local_pose(unit,1,pose)
            U.set_local_scale(unit,1,sr.Vector3(0.24,0.24,0.24/math.max(0.25,math.min(8,aspect or 2))))
        end)
        if not ok then failed=true;log('SCENE stopped '..tostring(err));self.release() end
    end
    return self
end
return M

end)()
HUD.menu=(function()
-- Optional ModOptionsMenu API 1 integration. Never bundles or patches its implementation.
local M={}
function M.new(hud)
    local api,attempted,retired,routes;local target=1;local self={status='Mod Options Menu not installed'}
    local prefix='dbf_hud_v3.'
    local sliders={
        {'world_position_smooth','3D position smoothing',0,0.5,0.005},{'world_rotation_smooth','3D rotation smoothing',0,0.5,0.005},{'world_max_lag','3D maximum position lag',0,0.5,0.01},
        {'weapon_offset_x','Weapon panel horizontal offset',-1920,1920,1},{'weapon_offset_y','Weapon panel vertical offset',-1080,1080,1},
        {'weapon_settle','Weapon settling time',0.04,1,0.01},{'weapon_lag','Maximum weapon lag',0,160,1},
        {'mount_x','Weapon local X',-2,2,0.01},{'mount_y','Weapon local Y',-2,2,0.01},{'mount_z','Weapon local Z',-2,2,0.01},
        {'offset_x','Horizontal position',-1920,1920,1},{'offset_y','Vertical position (up)',-1080,1080,1},
        {'scale','HUD scale',0.5,2,0.05},{'opacity','HUD opacity',0.1,1,0.01},
        {'panel_opacity','Panel tint',0,1,0.01},{'follow','Reticle follow',0,1,0.01},
        {'travel','Maximum travel',1,160,1},{'settle','Settling time',0.04,1,0.01},
        {'flash_hz','Overheat flash rate',0.5,3,0.5}}
    local function set(k,v) assert(api.set(prefix..k,v)) end
    function self.sync()
        if not api or not attempted or retired then return end
        for _,s in ipairs(sliders) do set(s[1],hud.config[s[1]]) end
        set('frosted',hud.config.frosted)
        set('anchor_mode_v2',hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2))
        set('pose_marker',hud.config.pose_marker)
        set('world_probe',hud.config.world_probe)
        set('font',hud.config.font=='bigblue' and 1 or 2)
        local hex=hud.config[HUD.config.colors[target]]:sub(2)
        for i=1,6 do set('hex'..i,tonumber(hex:sub(i,i),16)+1) end
    end
    function self.poll()
        if attempted or retired then return end
        api=rawget(_G,'ModOptionsMenu')
        if not api or api.api~=1 then return end
        for _,k in ipairs({'register_option','on_change','set'}) do if type(api[k])~='function' then return end end
        attempted=true
        -- Keep one dispatcher per option across reloads; retiring releases HUD closures.
        api.dbf_hud_routes=api.dbf_hud_routes or {}
        routes=api.dbf_hud_routes
        local function add(k,spec,callback)
            spec.mod='DBF-HUD'
            local id=prefix..k
            -- API 1 treats a changed default as a different registration. Reuse
            -- our stable option IDs when taking over from the boot addon too.
            local exists=routes[id] or (type(api.get)=='function' and api.get(id)~=nil)
            if not exists then local ok,err=api.register_option(id,spec);assert(ok,err) end
            if not routes[id] then
                local route={};routes[id]=route
                assert(api.on_change(id,function(v) if route.callback then route.callback(v) end end))
            end
            routes[id].owner=self;routes[id].callback=callback
        end
        local ok,err=pcall(function()
            for _,s in ipairs(sliders) do
                local k=s[1]
                add(k,{type='slider',label=s[2],min=s[3],max=s[4],step=s[5],default=hud.config[k]},function(v)
                    hud.configure({[k]=v});hud.save_tuning()
                end)
            end
            add('anchor_mode_v2',{type='choice',label='Attach HUD to',choices={'Weapon (hybrid)','Crosshair','Weapon (3D plane)'},
                default=hud.config.anchor_mode=='weapon' and 1 or (hud.config.anchor_mode=='world' and 3 or 2)},function(v)
                hud.configure({anchor_mode=v==1 and 'weapon' or (v==3 and 'world' or 'crosshair')});hud.save_tuning()
            end)
            add('world_probe',{type='toggle',label='Experimental 3D rectangle',default=hud.config.world_probe},function(v)
                hud.configure({world_probe=v});hud.save_tuning()
            end)
            add('pose_marker',{type='toggle',label='Show attachment marker',default=hud.config.pose_marker},function(v)
                hud.configure({pose_marker=v});hud.save_tuning()
            end)
            add('font',{type='choice',label='HUD font',choices={'BigBlue Terminal (pixel)','Original debug font'},
                default=hud.config.font=='bigblue' and 1 or 2},function(v)
                hud.configure({font=v==1 and 'bigblue' or 'debug'});hud.save_tuning()
            end)
            add('frosted',{type='toggle',label='Native frosted panel',default=hud.config.frosted},function(v)
                hud.configure({frosted=v});hud.save_tuning()
            end)
            add('color_target',{type='choice',label='Color to edit',default=1,
                choices={'Text / accents','Panel tint','Heat white','Heat yellow','Heat red'},
                description='Edit #RRGGBB using the six hexadecimal digit rows. Apply the target before editing its digits.'},function(v)
                target=v;self.sync()
            end)
            local digits={};for i=0,15 do digits[#digits+1]=string.format('%X',i) end
            for i=1,6 do
                local index=i
                add('hex'..i,{type='choice',label=({'Hex R high','Hex R low','Hex G high','Hex G low','Hex B high','Hex B low'})[i],
                    choices=digits,default=tonumber(hud.config.text_color:sub(i+1,i+1),16)+1},function(v)
                    local key=HUD.config.colors[target];local h=hud.config[key]:sub(2)
                    hud.configure({[key]='#'..h:sub(1,index-1)..string.format('%X',v-1)..h:sub(index+1)})
                    hud.save_tuning()
                end)
            end
            set('color_target',target);self.sync()
        end)
        self.status=ok and 'Options > Mods > DBF-HUD' or ('menu unavailable: '..tostring(err))
        if not ok then api=nil end
    end
    function self.retire()
        retired=true
        for _,route in pairs(routes or {}) do
            if route.owner==self then route.callback=nil;route.owner=nil end
        end
    end
    return self
end
return M

end)()
HUD.runtime=(function()
local M={}
function M.start(sr,backend,options)
    local managed=options and options.managed==true
    -- Compatibility: retire a previous-brand instance during live upgrade.
    local legacy=rawget(_G,'AstraAmmo');if legacy and legacy.retire then legacy.retire() end
    local old=rawget(_G,'DBFHUD');if old and old.retire then old.retire() end
    local self={version='0.3.36',status='starting',anchor_status='starting native anchor',clock=0,hidden=false}
    self.config=HUD.config.new()
    local attached=HUD.motion.new();local attachment_active=false
    local motion=HUD.motion.new();local reader=HUD.reader.new(backend);local view=HUD.view.new(sr)
    local native=HUD.anchor.new(backend);self.native_anchor=native
    local pose=HUD.pose.new(backend);local next_pose_log=0;local last_pose_status
    local original=rawget(_G,'update');local shutdown=rawget(_G,'shutdown')
    if not managed and type(original)~='function' then self.status='update callback missing';return self end
    local projection=HUD.projection.new(backend);local binding_base;local next_projection_log=0
    local latest_raw;local next_sample=0;local model;local anchor;local anchor_at=-10;local provider;local failures=0
    function self.texture_commands()
        if not model then return nil end
        local cfg={};for k,v in pairs(self.config) do cfg[k]=v end
        cfg.font='bigblue';cfg.frosted=false
        return HUD.layout.compose(model,0,0,2,1,cfg,self.clock)
    end
    local retired=false;local cleaned=false;local alpha=0;local last_id;local width,height
    local manual_until=-1;local anchor_source;local next_log=0;local last_log_status
    local last_binding
    local function log(line) if backend.log then pcall(backend.log,string.format('[%.3f] %s',self.clock,line)) end end
    local world_probe=HUD.world_probe.new(sr,log)
    log('START DBFHUD '..self.version..' native crosshair enabled; movement visibility filter removed')
    -- Availability check only: never invokes unverified world GUI functions.
    local capabilities={}
    for _,entry in ipairs({{'World','create_world_gui'},{'World','destroy_gui'},
        {'Gui','move'},{'Gui','rect'},{'Gui','bitmap'},
        {'Matrix4x4','from_axes'},{'Matrix4x4','from_quaternion_position'},
        {'Matrix4x4','identity'},{'Matrix4x4','set_translation'},
        {'Matrix4x4','set_x'},{'Matrix4x4','set_y'},{'Matrix4x4','set_z'}}) do
        local namespace=sr[entry[1]]
        local ok,value=pcall(function()return namespace and namespace[entry[2]]end)
        capabilities[#capabilities+1]=entry[1]..'.'..entry[2]..'='..(ok and type(value) or 'unavailable')
    end
    log('WORLD_GUI_CAPABILITIES '..table.concat(capabilities,' '))
    -- Inspect C binding entry points without invoking the bindings themselves.
    local jit_ok,jit_util=pcall(require,'jit.util')
    for _,entry in ipairs({{'Viewport','set_output_render_target'},
        {'Viewport','register_render_resource'},{'Application','create_viewport'},
        {'Application','render_world'},{'Renderer','update_texture_base64'},
        {'Mesh','material'},{'Gui','material'},{'Gui','bitmap'},{'Gui','update_bitmap'},{'Material','set_resource'}}) do
        local ok,address=pcall(function()
            assert(jit_ok,'jit.util unavailable')
            local ns=sr[entry[1]];local fn=ns and ns[entry[2]]
            assert(type(fn)=='function','binding unavailable')
            local info=jit_util.funcinfo(fn);assert(type(info.addr)=='number','no native entry')
            return string.format('0x%X',info.addr)
        end)
        log('SCREEN_BINDING '..entry[1]..'.'..entry[2]..' '..(ok and address or 'unavailable'))
    end
    -- Enumerate exposed names rather than guessing the game's custom bindings.
    for _,namespace in ipairs({'Viewport','Renderer','Material','Unit'}) do
        local ok,names=pcall(function()
            local ns=sr[namespace];local found={}
            if type(ns)~='table' then return {'namespace='..type(ns)} end
            for name,value in pairs(ns) do
                if type(name)=='string' and type(value)=='function' and
                    (namespace~='Unit' or name:find('material',1,true) or name:find('mesh',1,true)) then
                    found[#found+1]=name
                end
            end
            table.sort(found);return found
        end)
        log('SCREEN_API_NAMES '..namespace..' '..(ok and table.concat(names,' ') or 'unavailable'))
    end
    -- Lookup only: do not allocate resources or invoke rendering from update.
    local screen_apis={
        Renderer={'create_resource','destroy_resource'},
        Material={'set_resource','set_texture','set_scalar','set_vector4'},
        Application={'create_viewport','destroy_viewport','render_world','new_world','release_world'},
        Viewport={'set_render_targets','set_render_target','set_rect'},
        World={'spawn_unit','destroy_unit','create_screen_gui','destroy_gui'},
        Unit={'material','set_material','set_local_pose','set_local_scale'},
        Gui={'create_material','material','bitmap','bitmap_3d'}
    }
    for namespace,entries in pairs(screen_apis) do
        local result={}
        for _,name in ipairs(entries) do
            local ok,value=pcall(function()local ns=sr[namespace];return ns and ns[name]end)
            result[#result+1]=name..'='..(ok and type(value) or 'unavailable')
        end
        log('SCREEN_CAPABILITIES '..namespace..' '..table.concat(result,' '))
    end
    for _,resource in ipairs({
        {'unit','content/env_ship/hologram/units/plane'},
        {'unit','content/env_ship/hologram/units/hologram_cylinder'},
        {'material','content/fac_helldivers/equipment/primary_weapons/assault_rifle_nacho/materials/weapon_screen'}
    }) do
        local ok,available=pcall(function()return sr.Application.can_get(resource[1],resource[2])end)
        log('SCREEN_RESOURCE '..resource[1]..' '..resource[2]..' '..(ok and tostring(available) or 'lookup unavailable'))
    end
    -- Integration contract: normalized viewport coordinates, origin top-left.
    -- Only a verified adapter should supply the actual game's dynamic reticle.
    function self.push_anchor(x,y,visible)
        assert(type(x)=='number' and type(y)=='number' and x==x and y==y and x>=0 and x<=1 and y>=0 and y<=1,'invalid anchor')
        anchor={x=x,y=y,visible=visible~=false};anchor_at=self.clock
        manual_until=self.clock+0.15;anchor_source='external provider'
    end
    function self.set_anchor_provider(fn) assert(fn==nil or type(fn)=='function');provider=fn end
    local menu
    function self.configure(values)
        HUD.config.apply(self.config,values)
        if menu then menu.sync() end
    end
    function self.export_tuning() return HUD.config.serialize(self.config) end
    function self.save_tuning()
        if not backend.write_tuning then self.tuning_status='file writer unavailable';return false end
        local ok,result=pcall(backend.write_tuning,self.export_tuning())
        self.tuning_status=ok and ('saved '..result) or tostring(result)
        if not ok then log('TUNING '..self.tuning_status) end
        return ok,result
    end
    function self.reload_tuning()
        if not backend.read_tuning then return false end
        local ok,result=pcall(function()local values=backend.read_tuning();if values then self.configure(values) end;return values~=nil end)
        self.tuning_status=ok and (result and 'loaded tuning file' or 'defaults; no tuning file') or tostring(result)
        log('TUNING '..self.tuning_status);return ok and result
    end
    self.reload_tuning()
    menu=HUD.menu.new(self)
    function self.frame(dt)
        if retired then return end
        if type(dt)~='number' or dt~=dt or dt<0 or dt==math.huge then dt=1/60 end
        self.clock=self.clock+dt
        menu.poll();self.menu_status=menu.status
        if provider then
            local ok,x,y,visible=pcall(provider)
            if ok and x~=nil then local accepted=pcall(self.push_anchor,x,y,visible);if not accepted then self.anchor_status='invalid provider' end end
        end
        if self.clock>=next_sample then
            next_sample=self.clock+1/30
            local raw=reader.poll();latest_raw=raw;binding_base=raw and raw.binding and raw.binding.module_base;model=HUD.model.normalize(raw);self.status=reader.status
            if self.clock>=next_pose_log then
                if self.weapon_pose then
                    local p=self.weapon_pose;local m=p.matrix
                    log(string.format('POSE weapon=%d handle=0x%X nodes=%d position=%.4f,%.4f,%.4f axis_x=%.4f,%.4f,%.4f',
                        p.id,p.candidate,p.node_count,p.x,p.y,p.z,m[1],m[2],m[3]))
                elseif self.pose_status~=last_pose_status then log('POSE unavailable: '..self.pose_status) end
                last_pose_status=self.pose_status;next_pose_log=self.clock+1
            end
            if raw and raw.binding then
                local b=raw.binding
                local identity=string.format('weapon=%d native=%d candidate=0x%X record=0x%X resource=%s avatar=%d avatar_native=%d avatar_candidate=0x%X avatar_record=0x%X game_base=0x%X',
                    raw.id,raw.unit_ref,b.candidate,b.record,raw.resource_hex,b.avatar_id,raw.avatar_unit_ref,b.avatar_candidate,b.avatar_record,b.module_base)
                if identity~=last_binding then log('BINDING '..identity);last_binding=identity end
            elseif last_binding~=nil then
                log('BINDING unavailable: '..self.status);last_binding=nil
            end
            if model and model.id~=last_id then
                motion.ready=false;attached.ready=false;last_id=model.id
                if anchor_source=='native crosshair' then anchor=nil end
            end
        end
        -- Pose follows the render/update cadence; ammo discovery remains at 30 Hz.
        -- Holding pose samples caused stepped targets and lag-limit corrections.
        self.weapon_pose=latest_raw and pose.poll(latest_raw) or nil
        self.pose_status=latest_raw and pose.status or 'no weapon'
        local w,h=sr.Gui.resolution()
        -- Screen GUIs may render at output size while Gui.resolution reports render scale.
        if sr.Application and type(sr.Application.back_buffer_size)=='function' then
            local ok,bw,bh=pcall(sr.Application.back_buffer_size)
            if ok and type(bw)=='number' and type(bh)=='number' and bw>=320 and bh>=240 and bw<=32768 and bh<=32768 then w,h=bw,bh end
        end
        if type(w)~='number' or type(h)~='number' or w<=0 or h<=0 then view.clear();return end
        if w~=width or h~=height then motion.ready=false;attached.ready=false;width,height=w,h end
        if model and not provider and self.clock>=manual_until then
            local point=native.poll()
            if point then anchor=point;anchor_at=self.clock;anchor_source='native crosshair' end
        elseif not model then anchor=nil;motion.ready=false end
        local live=anchor and self.clock-anchor_at<0.15
        self.anchor_status=live and anchor_source or ('center fallback: '..native.status)
        local target=live and {x=(anchor.x-0.5)*w*1080/h,y=(0.5-anchor.y)*1080} or nil
        local point
        if self.weapon_pose and (self.config.anchor_mode=='weapon' or self.config.pose_marker) then
            local p=self.weapon_pose;local m=p.matrix;local c=self.config
            local mount={x=p.x+m[1]*c.mount_x+m[5]*c.mount_y+m[9]*c.mount_z,
                y=p.y+m[2]*c.mount_x+m[6]*c.mount_y+m[10]*c.mount_z,
                z=p.z+m[3]*c.mount_x+m[7]*c.mount_y+m[11]*c.mount_z}
            point=projection.poll(binding_base,mount,w/h)
        end
        self.projection_status=projection.status
        local use_weapon=self.config.anchor_mode=='weapon' and point~=nil and not provider and self.clock>=manual_until
        if use_weapon~=attachment_active then motion.ready=false;attached.ready=false;attachment_active=use_weapon end
        local x,y
        if use_weapon then
            x,y=HUD.motion.attach(attached,{x=(point.x-.5)*w*1080/h,y=(point.y-.5)*1080},dt,self.config)
            self.anchor_status='weapon attachment'
        else
            x,y=HUD.motion.step(motion,target,dt,self.config)
            self.attachment_status='reticle fallback: '..projection.status
        end
        -- Movement must not control alpha. Native reticle hiding only changes the anchor.
        local visible=model and not self.hidden and not (live and not anchor.visible)
        if sr.Window and sr.Window.show_cursor then
            local ok,cursor=pcall(sr.Window.show_cursor);if ok and cursor then visible=false end
        end
        local wanted=visible and 1 or 0
        alpha=wanted+(alpha-wanted)*math.exp(-math.min(dt,0.35)/(visible and 0.06 or 0.10))
        self.opacity=alpha;self.motion_x=x;self.motion_y=y
        local diagnostic=self.status..' | '..self.anchor_status..' | '..(view.material_status or 'material not sampled')..' | font: '..self.config.font
        if self.clock>=next_log then
            if diagnostic~=last_log_status or live then
                log(string.format('%s viewport=%dx%d state=%s pos=%.1f,%.1f samples=%d',diagnostic,w,h,
                    tostring(native.native_state),x,y,native.samples))
                last_log_status=diagnostic
            end
            next_log=self.clock+2
        end
        if self.scene_test_only then world_probe.draw(nil,self.config);view.clear();return end
        if not model or alpha<0.01 then world_probe.draw(nil,self.config);view.clear();return end
        if self.config.anchor_mode=='world' and self.weapon_pose then
            local world_config={};for k,v in pairs(self.config)do world_config[k]=v end;world_config.font='bigblue'
            local world_commands=HUD.layout.compose(model,0,0,2*self.config.scale,alpha*self.config.opacity,world_config,self.clock)
            local f=world_commands[1];local left,bottom=f.x,f.y
            for _,v in ipairs(world_commands) do v.x=v.x-left;v.y=v.y-bottom end
            if world_probe.draw(self.weapon_pose,self.config,world_commands,dt) then
                view.clear();self.anchor_status='weapon 3D plane';return
            end
        end
        local s=h/1080
        x=w/2+(x+(use_weapon and self.config.weapon_offset_x or self.config.offset_x))*s;y=h/2+(y+(use_weapon and self.config.weapon_offset_y or self.config.offset_y))*s
        local scale=s*self.config.scale
        local commands=HUD.layout.compose(model,x,y,scale,alpha*self.config.opacity,self.config,self.clock)
        local frame=commands[1];local margin=4*scale
        local dx=math.max(margin,math.min(w-margin-frame.w,frame.x))-frame.x
        local dy=math.max(margin,math.min(h-margin-frame.h,frame.y))-frame.y
        for _,c in ipairs(commands) do c.x=c.x+dx;c.y=c.y+dy end
        if self.config.pose_marker then
            self.projection_status=projection.status
            if self.clock>=next_projection_log then
                log(point and string.format('PROJECT x=%.4f y=%.4f depth=%.3f',point.x,point.y,point.depth)
                    or ('PROJECT unavailable: '..projection.status))
                next_projection_log=self.clock+2
            end
            if point then
                local px,py=point.x*w,point.y*h
                commands[#commands+1]={type='rect',x=px-7*s,y=py-1*s,w=14*s,h=2*s,a=alpha,c={229,231,226}}
                commands[#commands+1]={type='rect',x=px-1*s,y=py-7*s,w=2*s,h=14*s,a=alpha,c={229,231,226}}
            end
        end
        view.draw(commands)
        world_probe.draw(self.weapon_pose,self.config,nil,dt)
    end
    function self.tick(dt)
        if not retired then
            local ok,err=pcall(self.frame,dt)
            if not ok then self.status=tostring(err);failures=failures+1;log('ERROR '..self.status);pcall(view.clear)
                if failures>=10 then self.status='disabled: '..self.status;self.retire() end
            else failures=0 end
        end
    end
    local wrapper
    wrapper=function(...)
        -- frame dt belongs to update's arguments, not its return values.
        local dt=select(1,...)
        local function after(...)
            self.tick(dt)
            return ...
        end
        return after(original(...))
    end
    local shutdown_wrapper
    shutdown_wrapper=function(...)
        self.retire()
        if shutdown then return shutdown(...) end
    end
    function self.retire()
        if cleaned then return end
        cleaned=true
        retired=true;menu.retire();pcall(world_probe.release);pcall(view.release)
        if backend.close then pcall(backend.close) end
        if not managed then
            if rawget(_G,'update')==wrapper then rawset(_G,'update',original) end
            if rawget(_G,'shutdown')==shutdown_wrapper then rawset(_G,'shutdown',shutdown) end
        end
    end
    if not managed then
        rawset(_G,'update',wrapper);rawset(_G,'shutdown',shutdown_wrapper);rawset(_G,'DBFHUD',self)
    end
    return self
end
return M

end)()
local ok,result=pcall(function() return HUD.runtime.start(assert(rawget(_G,"stingray"),"stingray missing"),HUD.memory.native()) end)
if not ok then rawset(_G,"DBFHUD",{status=tostring(result),version="0.3.36"}) end
return rawget(_G,"DBFHUD")
