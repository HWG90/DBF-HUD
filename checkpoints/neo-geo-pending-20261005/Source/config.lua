local M={}
M.fonts={'bigblue','hack','jetbrainsmono','firacode','iosevka'}
local listed={bigblue=true,hack=true,jetbrainsmono=true,firacode=true,iosevka=true}
for _,name in ipairs(HUD.native_font_data.order) do if name~='debug' and not listed[name] then M.fonts[#M.fonts+1]=name end end
M.styles={'standard','hologram','instrument','blueprint','retro'}
M.decorations={'none','outline','brackets','helldivers','double','deadeye'}
M.colors={'text_color','decoration_color','background_color','heat_white','heat_yellow','heat_red'}
-- Auto clearance in weapon-local metres; independent entries for each view.
-- Resource identity is stable across equip/respawn; never key by entity handle.
M.weapon_clearance={
    ['a8cffb316f0b5c5f']={ -- Autocannon: initial right-shoulder obstruction correction.
        right={x=.12,y=-.08,z=.10},
    },
}
M.defaults={appearance_follow_equipped=true,mechanical_art_enabled=true,texture_art_variant='faithful',texture_art_trial=true,theme_shader_animate=false,effect_shader_animate=false,theme_shader_speed=1,effect_shader_speed=1,theme_shader_scale=1,effect_shader_scale=1,render_sync_trial=true,theme_shader='auto',effect_shader='none',railgun_release_margin_ms=200,debug_hud_timing=false,senator_style="cylinder",weapon_panels={},effect_sweep_speed=.35,effect_sweep_density=3,effect_scanline_count=21,mg43_easter_egg=true,weapon_blacklist="",zoom_compensation=false,debug_sight_root_orientation=false,effect_scanlines=false,effect_flicker=false,effect_sweep=false,text_opacity=1,force_occlusion=false,style_3d='standard',fade_3d_unless_aiming=false,show_3d='aiming',keep_hud_upright=false,fp_auto_side='right',placement_mode='auto',decoration='none',debug_logging=false,weapon_screen_test=false,always_show_3d=false,occlusion_mode="gui_depth",hud_occlusion=true,text_color_alpha=255,heat_white_alpha=255,heat_yellow_alpha=255,heat_red_alpha=255,saturation=1.3,left_mount_x=0,left_mount_y=0,left_mount_z=0,fp_mount_x=0,fp_mount_y=0,fp_mount_z=0,scanline_strength=0.18,texture_refresh_hz=0,emissive_intensity=3,world_position_smooth=0.045,world_rotation_smooth=0.08,world_max_lag=0.12,follow=0.65,travel=55,settle=0.22,offset_x=62,offset_y=-5,scale=1,opacity=1,
    panel_opacity=0.8,flash_hz=2,frosted=true,pose_marker=false,world_probe=false,anchor_mode='world',weapon_offset_x=62,weapon_offset_y=30,weapon_settle=0.10,weapon_lag=40,mount_x=0,mount_y=0,mount_z=0,text_color='#C4CECA',decoration_color='#C4CECA',background_color='#202628',
    heat_white='#E5E7E2',heat_yellow='#E7C85C',heat_red='#E16D65',font='bigblue'}
M.limits={theme_shader_speed={.1,3},effect_shader_speed={.1,3},theme_shader_scale={.25,4},effect_shader_scale={.25,4},effect_sweep_speed={.05,2},effect_sweep_density={1,12},railgun_release_margin_ms={50,1000},effect_scanline_count={1,80},text_opacity={0,1},text_color_alpha={0,255},heat_white_alpha={0,255},heat_yellow_alpha={0,255},heat_red_alpha={0,255},saturation={0,2.5},left_mount_x={-2,2},left_mount_y={-2,2},left_mount_z={-2,2},fp_mount_x={-2,2},fp_mount_y={-2,2},fp_mount_z={-2,2},scanline_strength={0,0.6},texture_refresh_hz={0,120},emissive_intensity={0,10},world_position_smooth={0,0.5},world_rotation_smooth={0,0.5},world_max_lag={0,0.5},weapon_offset_x={-1920,1920},weapon_offset_y={-1080,1080},weapon_settle={0.04,1},weapon_lag={0,160},mount_x={-2,2},mount_y={-2,2},mount_z={-2,2},follow={0,1},travel={1,160},settle={0.04,1},offset_x={-1920,1920},offset_y={-1080,1080},
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
function M.new() local t={};for k,v in pairs(M.defaults) do t[k]=type(v)=='table' and {} or v end;return t end
HUD.shader_catalog={
{id='checker_fine',title="Fine checker dither",material='mods/dbf_hud/materials/lab_checker_fine',frozen=false},
{id='checker_coarse',title="Coarse VGA checker",material='mods/dbf_hud/materials/lab_checker_coarse',frozen=false},
{id='bayer',title="Ordered 4-level dither",material='mods/dbf_hud/materials/lab_bayer',frozen=false},
{id='diagonal_weave',title="Diagonal weave",material='mods/dbf_hud/materials/lab_diagonal_weave',frozen=false},
{id='dot_matrix',title="Dot matrix",material='mods/dbf_hud/materials/lab_dot_matrix',frozen=false},
{id='crt_scan',title="CRT scanlines",material='mods/dbf_hud/materials/lab_crt_scan',frozen=false},
{id='crt_phosphor',title="RGB phosphor mask",material='mods/dbf_hud/materials/lab_crt_phosphor',frozen=false},
{id='glass_sheen',title="Glass sheen",material='mods/dbf_hud/materials/lab_glass_sheen',frozen=false},
{id='brushed_steel',title="Brushed steel",material='mods/dbf_hud/materials/lab_brushed_steel',frozen=false},
{id='hammered_metal',title="Hammered metal",material='mods/dbf_hud/materials/lab_hammered_metal',frozen=false},
{id='ceramic',title="Ceramic enamel",material='mods/dbf_hud/materials/lab_ceramic',frozen=false},
{id='thermal',title="Thermal glow",material='mods/dbf_hud/materials/lab_thermal',frozen=false},
{id='warning_hatch',title="Warning hatch",material='mods/dbf_hud/materials/lab_warning_hatch',frozen=false},
{id='sweep',title="Scanner sweep",material='mods/dbf_hud/materials/lab_sweep',frozen=true},
{id='pulse',title="Warning pulse",material='mods/dbf_hud/materials/lab_pulse',frozen=true},
{id='circuit',title="Circuit traces",material='mods/dbf_hud/materials/lab_circuit',frozen=false},
{id='hex_cells',title="Hex-like cell lattice",material='mods/dbf_hud/materials/lab_hex_cells',frozen=false},
{id='ion_noise',title="Ion interference",material='mods/dbf_hud/materials/lab_ion_noise',frozen=true},
{id='heat_shimmer',title="Heat shimmer tint",material='mods/dbf_hud/materials/lab_heat_shimmer',frozen=true},
{id='blueprint',title="Blueprint cross grid",material='mods/dbf_hud/materials/lab_blueprint',frozen=false},
{id='carbon',title="Carbon weave",material='mods/dbf_hud/materials/lab_carbon',frozen=false},
{id='ribbed_alloy',title="Ribbed alloy",material='mods/dbf_hud/materials/lab_ribbed_alloy',frozen=false},
{id='oxidized_copper',title="Oxidized copper",material='mods/dbf_hud/materials/lab_oxidized_copper',frozen=false},
{id='etched_scale',title="Etched calibration",material='mods/dbf_hud/materials/lab_etched_scale',frozen=false},
{id='micro_mesh',title="Micro mesh",material='mods/dbf_hud/materials/lab_micro_mesh',frozen=false},
{id='triangular_grille',title="Triangular grille",material='mods/dbf_hud/materials/lab_triangular_grille',frozen=false},
{id='caution_dots',title="Caution dot tape",material='mods/dbf_hud/materials/lab_caution_dots',frozen=false},
{id='ceramic_cracks',title="Cracked ceramic",material='mods/dbf_hud/materials/lab_ceramic_cracks',frozen=false},
{id='iridescent',title="Iridescent coating",material='mods/dbf_hud/materials/lab_iridescent',frozen=false},
{id='amber_glass',title="Amber instrument glass",material='mods/dbf_hud/materials/lab_amber_glass',frozen=false},
{id='cobalt_glass',title="Cobalt instrument glass",material='mods/dbf_hud/materials/lab_cobalt_glass',frozen=false},
{id='frosted',title="Frosted diffusion",material='mods/dbf_hud/materials/lab_frosted',frozen=false},
{id='gunmetal',title="Gunmetal stipple",material='mods/dbf_hud/materials/lab_gunmetal',frozen=false},
{id='leather',title="Grip leather",material='mods/dbf_hud/materials/lab_leather',frozen=false},
{id='hazard_red',title="Red emergency hatch",material='mods/dbf_hud/materials/lab_hazard_red',frozen=false},
{id='rail_glints',title="Rail glints",material='mods/dbf_hud/materials/lab_rail_glints',frozen=false},
{id='energy_threads',title="Energy threads",material='mods/dbf_hud/materials/lab_energy_threads',frozen=false},
{id='grid_nodes',title="PCB nodes",material='mods/dbf_hud/materials/lab_grid_nodes',frozen=false},
{id='stipple_gradient',title="Stipple shading",material='mods/dbf_hud/materials/lab_stipple_gradient',frozen=false},
{id='prismatic',title="Prismatic facets",material='mods/dbf_hud/materials/lab_prismatic',frozen=false},
}
HUD.shader_ids={auto=true,none=true};for _,entry in ipairs(HUD.shader_catalog)do HUD.shader_ids[entry.id]=true end
M.panel_keys={mechanical_art_enabled=true,texture_art_variant=true,texture_art_trial=true,theme_shader_animate=true,effect_shader_animate=true,theme_shader_speed=true,effect_shader_speed=true,theme_shader_scale=true,effect_shader_scale=true,theme_shader=true,effect_shader=true,background_color=true,text_color=true,decoration_color=true,panel_opacity=true,text_opacity=true,decoration=true,frosted=true,effect_scanlines=true,effect_flicker=true,effect_sweep=true,effect_sweep_speed=true,effect_sweep_density=true,effect_scanline_count=true,style_3d=true,font=true}
function M.effective(config,resource)
 local out={};for k,v in pairs(config)do out[k]=v end
 local overrides=(config.weapon_panels or {})[resource or '']
 if overrides then for k,v in pairs(overrides)do out[k]=v end;out.weapon_panel_overrides=overrides end
 return out
end
function M.set_panel(config,resource,values)
 assert(type(resource)=='string' and resource:match('^%x+$') and #resource==16,'Equip a verified weapon first')
 local panels={};for id,profile in pairs(config.weapon_panels or {})do panels[id]=profile end
 if values==false then panels[resource]=nil else
  local profile={};for k,v in pairs(panels[resource] or {})do profile[k]=v end
  for k,v in pairs(values)do assert(M.panel_keys[k],'Not a panel appearance setting: '..tostring(k));if k=='font' and v==false then profile[k]=nil else profile[k]=v end end
  panels[resource]=profile
 end
 M.apply(config,{weapon_panels=panels})
end
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
    if flattened.mechanical_art_enabled~=nil then
        assert(type(flattened.mechanical_art_enabled)=='boolean','legacy artwork setting must be boolean')
        if flattened.texture_art_trial==nil then flattened.texture_art_trial=flattened.mechanical_art_enabled end
        flattened.mechanical_art_enabled=nil
    end
    local clean={}
    for k,v in pairs(flattened) do
        assert(M.defaults[k]~=nil,'unknown setting: '..tostring(k))
        local limits=M.limits[k]
        if k=='weapon_panels' then
            assert(type(v)=='table','Weapon panels must be a table');local validated={}
            for id,profile in pairs(v)do
                assert(type(id)=='string' and #id==16 and id:match('^%x+$'),'Invalid weapon panel identity')
                assert(type(profile)=='table','Invalid weapon panel settings')
                for key in pairs(profile)do assert(M.panel_keys[key],'Invalid weapon panel setting: '..tostring(key))end
                local migrated={};for key,value in pairs(profile)do if key~='mechanical_art_enabled' then migrated[key]=value end end
                if profile.mechanical_art_enabled~=nil then assert(type(profile.mechanical_art_enabled)=='boolean','legacy artwork setting must be boolean');if migrated.texture_art_trial==nil then migrated.texture_art_trial=profile.mechanical_art_enabled end end
                local scratch=M.new();M.apply(scratch,migrated);local result={}
                for key in pairs(migrated)do result[key]=scratch[key]end;validated[id]=result
            end
            v=validated
        elseif limits then assert(type(v)=='number' and v==v and v>=limits[1] and v<=limits[2],'invalid setting: '..k)
        elseif (k=='appearance_follow_equipped' or k=='texture_art_trial' or k=='theme_shader_animate' or k=='effect_shader_animate' or k=='render_sync_trial' or k=='debug_hud_timing' or k=='mg43_easter_egg' or k=='zoom_compensation' or k=='debug_sight_root_orientation' or k=='effect_scanlines' or k=='effect_flicker' or k=='effect_sweep' or k=='force_occlusion' or k=='fade_3d_unless_aiming' or k=='keep_hud_upright' or k=='debug_logging' or k=='always_show_3d' or k=='weapon_screen_test' or k=='hud_occlusion' or k=='frosted' or k=='pose_marker' or k=='world_probe') then assert(type(v)=='boolean','setting must be boolean')
        elseif k=='theme_shader' or k=='effect_shader' then assert(type(v)=='string' and HUD.shader_ids[v],'Unknown HUD shader')
        elseif k=='texture_art_variant' then assert(v=='faithful' or v=='realistic' or v=='study' or v=='original','invalid texture artwork variant')
        elseif k=='senator_style' then assert(v=='cylinder' or v=='upright','invalid Senator appearance')
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
    for k in pairs(M.defaults) do if not archived[k] and k~='weapon_panels' and k~='occlusion_mode' and k~='hud_occlusion' and k~='show_3d' and k~='always_show_3d' and k~='placement_mode' and not k:match('^left_mount_') and not k:match('^fp_mount_') and not k:match('^mount_') then keys[#keys+1]=k end end
    table.sort(keys)
    local out={'-- DBF-HUD tuning. Active settings below; camera placement is unchanged.','return {','    -- Active display, palette, placement and diagnostics.'}
    local function value(v)return type(v)=='string' and string.format('%q',v) or tostring(v)end
    for _,k in ipairs(keys) do out[#out+1]='    '..k..' = '..value(config[k])..',' end
    out[#out+1]='    weapon_panels = {'
    local weapons={};for id in pairs(config.weapon_panels or {})do weapons[#weapons+1]=id end;table.sort(weapons)
    for _,id in ipairs(weapons)do
        out[#out+1]='        ['..string.format('%q',id)..'] = {'
        local members={};for k in pairs(config.weapon_panels[id])do members[#members+1]=k end;table.sort(members)
        for _,k in ipairs(members)do out[#out+1]='            '..k..' = '..value(config.weapon_panels[id][k])..',' end
        out[#out+1]='        },'
    end
    out[#out+1]='    },'
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
function M.shader_animation_values(c,role,clock)
    local key=role=='effect' and 'effect_shader' or 'theme_shader'
    local speed=tonumber(c[key..'_speed']) or 1
    if speed~=speed then speed=1 end;speed=math.max(.1,math.min(3,speed))
    local time=tonumber(clock) or 0
    if time~=time or time==math.huge or time==-math.huge then time=0 end
    return math.max(0,time)*speed,c[key..'_animate']==true and 1 or 0
end
return M

