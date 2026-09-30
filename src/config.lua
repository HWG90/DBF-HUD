local M={}
M.colors={'text_color','background_color','heat_white','heat_yellow','heat_red'}
M.defaults={left_mount_x=-0.50,left_mount_y=0.25,left_mount_z=0.02,fp_mount_x=-0.18,fp_mount_y=0.20,fp_mount_z=-0.01,scanline_strength=0.18,texture_refresh_hz=0,emissive_intensity=3,world_position_smooth=0.045,world_rotation_smooth=0.08,world_max_lag=0.12,follow=0.65,travel=55,settle=0.22,offset_x=62,offset_y=-5,scale=1,opacity=0.92,
    panel_opacity=0.55,flash_hz=2,frosted=true,pose_marker=false,world_probe=false,anchor_mode='weapon',weapon_offset_x=62,weapon_offset_y=30,weapon_settle=0.10,weapon_lag=40,mount_x=0,mount_y=0,mount_z=0,text_color='#C4CECA',background_color='#202628',
    heat_white='#E5E7E2',heat_yellow='#E7C85C',heat_red='#E16D65',font='bigblue'}
M.limits={left_mount_x={-2,2},left_mount_y={-2,2},left_mount_z={-2,2},fp_mount_x={-2,2},fp_mount_y={-2,2},fp_mount_z={-2,2},scanline_strength={0,0.6},texture_refresh_hz={0,120},emissive_intensity={0,10},world_position_smooth={0,0.5},world_rotation_smooth={0,0.5},world_max_lag={0,0.5},weapon_offset_x={-1920,1920},weapon_offset_y={-1080,1080},weapon_settle={0.04,1},weapon_lag={0,160},mount_x={-2,2},mount_y={-2,2},mount_z={-2,2},follow={0,1},travel={1,160},settle={0.04,1},offset_x={-1920,1920},offset_y={-1080,1080},
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
