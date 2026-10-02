local M={}
M.fonts={'bigblue','hack','jetbrainsmono','firacode','iosevka'}
local listed={bigblue=true,hack=true,jetbrainsmono=true,firacode=true,iosevka=true}
for _,name in ipairs(HUD.native_font_data.order) do if name~='debug' and not listed[name] then M.fonts[#M.fonts+1]=name end end
M.styles={'standard','hologram','instrument','blueprint','retro'}
M.decorations={'none','outline','brackets','helldivers','double'}
M.colors={'text_color','decoration_color','background_color','heat_white','heat_yellow','heat_red'}
-- Auto clearance in weapon-local metres; independent entries for each view.
-- Resource identity is stable across equip/respawn; never key by entity handle.
M.weapon_clearance={
    ['a8cffb316f0b5c5f']={ -- Autocannon: initial right-shoulder obstruction correction.
        right={x=.12,y=-.08,z=.10},
    },
}
M.defaults={weapon_blacklist="",debug_sight_root_orientation=false,effect_scanlines=false,effect_flicker=false,effect_sweep=false,text_opacity=1,force_occlusion=false,style_3d='standard',fade_3d_unless_aiming=false,show_3d='aiming',keep_hud_upright=false,fp_auto_side='right',placement_mode='auto',decoration='none',debug_logging=false,weapon_screen_test=false,always_show_3d=false,occlusion_mode="gui_depth",hud_occlusion=true,text_color_alpha=255,heat_white_alpha=255,heat_yellow_alpha=255,heat_red_alpha=255,saturation=1.3,left_mount_x=0,left_mount_y=0,left_mount_z=0,fp_mount_x=0,fp_mount_y=0,fp_mount_z=0,scanline_strength=0.18,texture_refresh_hz=0,emissive_intensity=3,world_position_smooth=0.045,world_rotation_smooth=0.08,world_max_lag=0.12,follow=0.65,travel=55,settle=0.22,offset_x=62,offset_y=-5,scale=1,opacity=1,
    panel_opacity=0.55,flash_hz=2,frosted=true,pose_marker=false,world_probe=false,anchor_mode='world',weapon_offset_x=62,weapon_offset_y=30,weapon_settle=0.10,weapon_lag=40,mount_x=0,mount_y=0,mount_z=0,text_color='#C4CECA',decoration_color='#C4CECA',background_color='#202628',
    heat_white='#E5E7E2',heat_yellow='#E7C85C',heat_red='#E16D65',font='bigblue'}
M.limits={text_opacity={0,1},text_color_alpha={0,255},heat_white_alpha={0,255},heat_yellow_alpha={0,255},heat_red_alpha={0,255},saturation={0,2.5},left_mount_x={-2,2},left_mount_y={-2,2},left_mount_z={-2,2},fp_mount_x={-2,2},fp_mount_y={-2,2},fp_mount_z={-2,2},scanline_strength={0,0.6},texture_refresh_hz={0,120},emissive_intensity={0,10},world_position_smooth={0,0.5},world_rotation_smooth={0,0.5},world_max_lag={0,0.5},weapon_offset_x={-1920,1920},weapon_offset_y={-1080,1080},weapon_settle={0.04,1},weapon_lag={0,160},mount_x={-2,2},mount_y={-2,2},mount_z={-2,2},follow={0,1},travel={1,160},settle={0.04,1},offset_x={-1920,1920},offset_y={-1080,1080},
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
function M.is_blacklisted(config,resource)
    if not resource then return false end
    for key in (config.weapon_blacklist or ''):gmatch('[^,]+') do if key==resource then return true end end
    return false
end
function M.blacklist_value(config,resource,hidden)
    assert(type(resource)=='string' and #resource==16 and resource:match('^%x+$'),'Invalid weapon resource')
    local keys,seen={},{}
    for key in (config.weapon_blacklist or ''):gmatch('[^,]+') do
        if key~=resource and not seen[key] then keys[#keys+1]=key;seen[key]=true end
    end
    if hidden then keys[#keys+1]=resource end
    table.sort(keys);return table.concat(keys,',')
end
function M.apply(config,values)
    assert(type(values)=='table','configuration must be a table')
    local flattened={}
    for k,v in pairs(values) do
        if M.archived[k] then
            assert(type(v)=='table','archived group must be a table')
            for name,value in pairs(v) do
                assert(M.archived[k][name],'unknown archived setting: '..tostring(name))
                assert(values[name]==nil and flattened[name]==nil,'duplicate setting: '..name)
                flattened[name]=value
            end
        else
            assert(flattened[k]==nil,'duplicate setting: '..tostring(k));flattened[k]=v
        end
    end
    local clean={}
    for k,v in pairs(flattened) do
        assert(M.defaults[k]~=nil,'unknown setting: '..tostring(k))
        local limits=M.limits[k]
        if limits then assert(type(v)=='number' and v==v and v>=limits[1] and v<=limits[2],'invalid setting: '..k)
        elseif (k=='debug_sight_root_orientation' or k=='effect_scanlines' or k=='effect_flicker' or k=='effect_sweep' or k=='force_occlusion' or k=='fade_3d_unless_aiming' or k=='keep_hud_upright' or k=='debug_logging' or k=='always_show_3d' or k=='weapon_screen_test' or k=='hud_occlusion' or k=='frosted' or k=='pose_marker' or k=='world_probe') then assert(type(v)=='boolean','setting must be boolean')
        elseif k=='style_3d' then assert(v=='standard' or v=='hologram' or v=='instrument' or v=='blueprint' or v=='retro','invalid 3D style')
        elseif k=='show_3d' then assert(v=='occluded' or v=='always' or v=='aiming','invalid 3D visibility')
        elseif k=='occlusion_mode' then assert(v=='mesh' or v=='gui' or v=='gui_depth','invalid occlusion mode')
        elseif k=='weapon_blacklist' then
            assert(type(v)=='string' and #v<=8192 and (v=='' or v:match('^[%x,]+$')),'Invalid weapon blacklist')
            local keys={}
            for key in v:gmatch('[^,]+') do assert(#key==16,'Invalid blacklisted weapon');keys[#keys+1]=key end
            assert(table.concat(keys,',')==v,'Invalid blacklist separators')
        elseif k=='fp_auto_side' then assert(v=='left' or v=='right','invalid first-person side')
        elseif k=='placement_mode' then assert(v=='manual' or v=='auto','invalid placement mode')
        elseif k=='anchor_mode' then assert(v=='weapon' or v=='crosshair' or v=='world','invalid anchor mode')
        elseif k=='decoration' then local found=false;for _,name in ipairs(M.decorations) do if v==name then found=true end end;assert(found,'unknown decoration')
        elseif k=='font' then assert(v=='debug' or HUD.native_font_data.faces[v],'unknown HUD font')
        else v=M.hex(v) end
        -- Retired global opacity is accepted for old presets but no longer dims the HUD.
        clean[k]=k=='opacity' and 1 or (k=='fp_auto_side' and 'right' or v)
    end
    if clean.hud_occlusion~=nil and clean.occlusion_mode==nil then clean.occlusion_mode=clean.hud_occlusion and 'gui_depth' or 'gui' end
    -- Migrate retired mesh selection to the verified direct WorldGUI path.
    if clean.occlusion_mode=='mesh' then clean.occlusion_mode='gui_depth' end
    if clean.show_3d==nil and clean.always_show_3d~=nil then clean.show_3d=clean.always_show_3d and 'always' or 'occluded' end
    if clean.show_3d then clean.always_show_3d=clean.show_3d=='always' end
    if clean.always_show_3d~=nil then clean.occlusion_mode=clean.always_show_3d and 'gui' or 'gui_depth' end
    if clean.occlusion_mode then clean.hud_occlusion=clean.occlusion_mode~='gui';clean.always_show_3d=clean.occlusion_mode=='gui' end
    for k,v in pairs(clean) do config[k]=v end
end
M.archived={archived_mesh={weapon_screen_test=true,saturation=true,scanline_strength=true,texture_refresh_hz=true,emissive_intensity=true},research={pose_marker=true,world_probe=true}}
function M.serialize(config)
    local keys={};local archived={}
    for _,group in pairs(M.archived) do for k in pairs(group) do archived[k]=true end end
    for k in pairs(M.defaults) do if not archived[k] and k~='occlusion_mode' and k~='hud_occlusion' and k~='show_3d' and k~='always_show_3d' and k~='placement_mode' and not k:match('^left_mount_') and not k:match('^fp_mount_') and not k:match('^mount_') then keys[#keys+1]=k end end
    table.sort(keys)
    local out={'-- DBF-HUD tuning. Active settings below; camera placement is unchanged.','return {','    -- Active display, palette, placement and diagnostics.'}
    local function value(v)return type(v)=='string' and string.format('%q',v) or tostring(v)end
    for _,k in ipairs(keys) do out[#out+1]='    '..k..' = '..value(config[k])..',' end
    for _,name in ipairs({'archived_mesh','research'}) do
        out[#out+1]='    -- Retained settings; mesh is disabled. Research markers require debug_logging.'
        out[#out+1]='    '..name..' = {'
        local members={};for k in pairs(M.archived[name]) do members[#members+1]=k end;table.sort(members)
        for _,k in ipairs(members) do out[#out+1]='        '..k..' = '..value(config[k])..',' end
        out[#out+1]='    },'
    end
    out[#out+1]='}';return table.concat(out,'\n')..'\n'
end

if HUD.bundled_defaults then
    M.apply(M.defaults,HUD.bundled_defaults.settings)
    M.weapon_clearance=HUD.bundled_defaults.layouts
end
return M
