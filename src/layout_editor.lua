-- Live per-weapon placement editor; rendering and profile storage remain separate.
local M={}
local node_names={
    ['1245b39c']='standard_pistol',
    ['12cda115']='hellpod_interact_node',
    ['15c8ade4']='IK_right',
    ['16092557']='g_mg_LOD1',
    ['175f53c9']='g_reciever_LOD4',
    ['1a26b734']='g_reciever_LOD3',
    ['1d667f2e']='shadow_mesh',
    ['1e307614']='g_body_shadow_LOD2',
    ['1f8155c7']='g_reciever',
    ['27a837b4']='g_reciever_shadow_LOD2',
    ['315cd161']='game_mesh',
    ['32188af1']='bolt_carrier',
    ['3e2c3cb2']='g_mg_LOD2',
    ['450a8e24']='g_reciever_shadow',
    ['4a182741']='StingrayEntityRoot',
    ['4c3a8f75']='g_body',
    ['4cc67131']='c_bodycollisionbot',
    ['51c77b11']='g_body_shadow',
    ['58c66627']='c_bodycollisiontop',
    ['6685da74']='bipod_swivel',
    ['670a7fdd']='feed_arm',
    ['67c94e4b']='IK_left',
    ['71b4f330']='g_body_shadow_LOD1',
    ['754fe6c2']='bolthandle',
    ['789b7d63']='ejector',
    ['7950e36e']='attach_underbarrel',
    ['7a3790c2']='g_body_shadow_LOD3',
    ['7f30e61c']='FbxAxisSystem_ConvertNode',
    ['8144a2c2']='pivot',
    ['817d30f2']='g_mg_shadow_LOD1',
    ['839f1a10']='g_body_LOD2',
    ['83c9fe1a']='g_mg_shadow',
    ['8f998342']='g_mg_shadow_LOD3',
    ['93d8a8f2']='l_bipod',
    ['975cebbd']='skeleton',
    ['97fcfe68']='g_mg_shadow_LOD2',
    ['98deb5de']='topcover',
    ['9b115563']='boss',
    ['9f15b85a']='g_body_LOD1',
    ['a3d491d1']='collision',
    ['ade50005']='fire_selector',
    ['b1f3aa0a']='attach_paintjob',
    ['b34be51e']='g_mg_LOD3',
    ['b41f604d']='g_reciever_LOD1',
    ['b4afc5cb']='c_reciever',
    ['bbb52fb1']='g_body_LOD4',
    ['bdae5555']='g_mg',
    ['bdc96a7f']='r_bipod',
    ['c372217f']='g_reciever_shadow_LOD1',
    ['c489b14a']='ejection_cover',
    ['c4a1d881']='g_reciever_shadow_LOD3',
    ['c5a432d3']='barrel_handle',
    ['d5a0518b']='g_body_LOD3',
    ['d69497c1']='g_reciever_LOD2',
    ['d7901849']='bolthandle_pivot',
    ['da874826']='g_mg_LOD4',
    ['dc0a2993']='ejector_socket',
    ['e50d157f']='cog',
    ['e81e9a8c']='assault_rifle',
    ['e994e9e9']='machinegun',
    ['faeed71d']='attach_ammo',
    ['fd2aac63']='feed_plate',

    ['0844391a']='slide',
    ['23569738']='attach_mag_2',
    ['2c8ece2b']='muzzle',
    ['4d25685a']='attach_optic',
    ['527c9c73']='sight',
    ['57520abf']='attach_muzzle',
    ['5be474d2']='c_grip',
    ['866cc914']='barrel',
    ['b232fef2']='eject',
    ['b298a52a']='attach_weapon',
    ['b78d5aa4']='trigger',
    ['bccf91e5']='root',
    ['c03596c1']='hammer',
    ['c0978950']='c_scope',
    ['ca03689c']='bolt',
    ['e7f88e90']='attach_mag',
}
function M.new(hud,backend,log)
    local e={active=false,view='right',status='Equip a weapon, then enable editing'}
    local original
    local function copy(t)local out={};for k,v in pairs(t or {})do out[k]=v end;return out end
    local function screen()return hud.config.anchor_mode=='weapon' or hud.config.anchor_mode=='crosshair' end
    local function view_key(first)
        if screen() then return 'screen_'..hud.config.anchor_mode..'_'..(first and 'first' or 'third') end
        return (first and not e.shared) and ('first_'..hud.config.fp_auto_side) or 'right'
    end
    function e.bind()
        local pose=hud.weapon_pose;local key=pose and pose.resource_hex
        if not key or #key~=16 or not key:match('^%x+$') then e.status='No equipped weapon';e.active=false;return false end
        e.resource=key;e.name=(HUD.weapon_names or {})[key] or 'Unknown weapon';e.active=true;e.shared=false;e.view=view_key(hud.first_person)
        original={};for view,offset in pairs(hud.weapon_clearance[key] or {}) do original[view]=copy(offset) end
        e.status='Editing equipped weapon';return true
    end
    function e.values()
        local t=e.resource and hud.weapon_clearance[e.resource] or {}
        t=(t or {})[e.view] or {};local unit=screen() and .001 or .0254;return (t.x or 0)/unit,(t.y or 0)/unit,(t.z or 0)/unit
    end
    function e.set_view(first)e.view=view_key(first) end
    function e.scale()
        local views=e.resource and hud.weapon_clearance[e.resource] or {};return ((views or {})[e.view] or {}).scale or 1
    end
    function e.rotation(axis)
        axis=axis or 'rotation'
        local views=e.resource and hud.weapon_clearance[e.resource] or {}
        return ((views or {})[e.view] or {})[axis] or 0
    end
    function e.rotate(delta,axis)
        axis=axis or 'rotation'
        if not e.active or screen() then return false end
        e.set_view(hud.first_person)
        local views=hud.weapon_clearance[e.resource] or {};hud.weapon_clearance[e.resource]=views
        views[e.view]=views[e.view] or {}
        views[e.view][axis]=(e.rotation(axis)+delta+180)%360-180
        e.status='Rotation preview updated; save to keep it';return true
    end
    function e.set_scale(value)
        if not e.active then return false end
        assert(type(value)=='number' and value==value and value>=.05 and value<=3,'invalid editor scale')
        local views=hud.weapon_clearance[e.resource] or {};hud.weapon_clearance[e.resource]=views
        views[e.view]=views[e.view] or {};views[e.view].scale=value;e.status='Scale preview updated; save to keep it';return true
    end
    function e.set(axis,inches)
        if not e.active then return false end
        assert(axis=='x' or axis=='y' or axis=='z','invalid editor axis')
        assert(type(inches)=='number' and inches==inches and math.abs(inches)<=(screen() and 2000 or 72),'invalid editor position')
        local views=hud.weapon_clearance[e.resource] or {};hud.weapon_clearance[e.resource]=views
        views[e.view]=views[e.view] or {};views[e.view][axis]=inches*(screen() and .001 or .0254)
        hud.auto_mounts={};e.status='Preview updated; use Save layout to keep it';return true
    end
    function e.move(axis,amount)
        if screen() then
            local x,y,z=e.values();return e.set(axis,({x=x,y=y,z=z})[axis]+amount)
        end
        -- Translate camera directions into the saved attachment-local coordinates.
        -- Panel rotation changes its face, never the editor's movement directions.
        local camera=hud.editor_camera_matrix
        local pose=hud.weapon_pose
        local m=pose and pose.matrix
        if pose and not hud.config.debug_sight_root_orientation and pose.attach_point~='root'
            and pose.sight and pose.sight.matrix then m=pose.sight.matrix end
        if not camera or not m then e.status='Camera unavailable; movement paused';return false end
        local column=({x=1,y=5,z=9})[axis]
        assert(column,'invalid editor axis')
        local x,y,z=e.values()
        for j,item in ipairs({{'x',x},{'y',y},{'z',z}}) do
            local base=1+(j-1)*4
            local delta=m[base]*camera[column]+m[base+1]*camera[column+1]+m[base+2]*camera[column+2]
            e.set(item[1],math.max(-72,math.min(72,item[2]+delta*amount)))
        end
        return true
    end
    function e.save()
        if not e.active or not backend.write_weapon_offsets then e.status='Layout writer unavailable';return false end
        local ok,result=pcall(function()return backend.write_weapon_offsets(HUD.weapon_offsets.serialize(hud.weapon_clearance))end)
        e.status=ok and ('Saved: '..e.name..' ('..(e.view=='right' and (e.shared and 'shared views' or 'third person') or 'first person')..')') or ('Save failed: '..tostring(result))
        if ok then
            local x,y,z=e.values()
            log(string.format('LAYOUT_EDITOR SAVE confirmed name=%s weapon=%s view=%s x=%.3f y=%.3f z=%.3f inches; all profiles written',e.name,e.resource,e.view,x,y,z))
        else log('LAYOUT_EDITOR '..e.status) end
        return ok
    end
    function e.zero_position()
        if not e.active then return false end
        e.set_view(hud.first_person)
        e.set('x',0);e.set('y',0);e.set('z',0)
        e.set_scale(1)
        e.status='Position zeroed and scale reset to 1 for current weapon/view; F7 saves'
        log('LAYOUT_EDITOR '..e.status)
        return true
    end
    function e.reset()
        if not e.active then return false end
        local restored={};for view,offset in pairs(original)do restored[view]=copy(offset)end
        hud.weapon_clearance[e.resource]=restored;hud.auto_mounts={};e.status='Original position restored; save to keep it';return true
    end
    function e.points()
        local list={{value='root',label='Weapon root (default)'},{value='node:4d25685a',label='Attach optic'}}
        for _,node in ipairs((hud.weapon_pose or {}).anchors or {}) do
            list[#list+1]={value='node:'..node.hash,label=(node_names[node.hash] or 'Unnamed')..' [node '..node.index..']'}
        end
        list[#list+1]={value='sight',label='Sight (legacy)'}
        return list
    end
    function e.cycle(direction)
        if not e.active or screen() then return false end
        -- Selecting a bone explicitly opts this camera view out of shared mounting.
        e.shared=false;e.set_view(hud.first_person)
        local views=hud.weapon_clearance[e.resource] or {};hud.weapon_clearance[e.resource]=views
        local offset=views[e.view] or {};views[e.view]=offset
        local list=e.points();local current=1
        local default_point='root'
        for i,item in ipairs(list)do if item.value==(offset.attach_point or default_point)then current=i;break end end
        local item=list[(current-1+direction)%#list+1];offset.attach_point=item.value
        e.point_label=item.label;hud.auto_mounts={};e.status='Attach: '..item.label..'; save to keep it';return true
    end
    local held={};local repeats={};local notice_until=0;local next_input_probe=0
    function e.tick(dt)
        if not backend.editor_key then return end
        local now=hud.clock or 0
        if hud.config.debug_logging and backend.editor_input_diagnostic and now<60 and now>=next_input_probe then
            backend.editor_input_diagnostic(e.active);next_input_probe=now+2
        end
        local function pressed(code)
            local down=backend.editor_key(code);local edge=down and not held[code];held[code]=down;return edge
        end
        if pressed(116) and backend.editor_key(17) then -- Ctrl+F5: configuration only
            local ok,message=hud.reload_settings()
            e.status=ok and message or ('Reload failed: '..tostring(message))
            notice_until=now+4;log('LAYOUT_EDITOR '..e.status)
        end
        if pressed(117) then -- F6
            if e.active then e.active=false;e.status='Editor closed; unsaved changes remain in preview' else e.bind() end
            notice_until=now+4;log('LAYOUT_EDITOR '..e.status)
        end
        if pressed(118) and e.active then e.save();notice_until=now+4 end -- F7
        if pressed(119) and e.active then e.reset();notice_until=now+4 end -- F8
        if pressed(120) and e.active then e.zero_position();notice_until=now+4 end -- F9
        if pressed(219) and e.active then e.cycle(-1) end -- [
        if pressed(221) and e.active then e.cycle(1) end -- ]
        if pressed(188) and e.active then e.rotate(-(backend.editor_key(16) and 5 or 45),backend.editor_key(17) and 'pitch' or (backend.editor_key(18) and 'yaw' or 'rotation')) end -- comma
        if pressed(190) and e.active then e.rotate(backend.editor_key(16) and 5 or 45,backend.editor_key(17) and 'pitch' or (backend.editor_key(18) and 'yaw' or 'rotation')) end -- period
        if pressed(189) and e.active then e.set_scale(math.max(.05,e.scale()-(backend.editor_key(16) and .01 or .05))) end -- -
        if pressed(187) and e.active then e.set_scale(math.min(3,e.scale()+(backend.editor_key(16) and .01 or .05))) end -- = / +
        if e.active then
            local pose=hud.weapon_pose
            if not pose or pose.resource_hex~=e.resource then e.active=false;e.status='Weapon changed; editor closed';notice_until=now+4;return end
            local active_view=hud.first_person and ('first_'..hud.config.fp_auto_side) or 'right'
            local views=hud.weapon_clearance[e.resource] or {}
            e.shared=false
            e.set_view(hud.first_person)
            local step=screen() and (backend.editor_key(16) and .25 or (backend.editor_key(17) and 20 or 5)) or (backend.editor_key(16) and .03125 or (backend.editor_key(17) and 2 or .5))
            for _,binding in ipairs({{37,'x',-1},{39,'x',1},{38,'z',1},{40,'z',-1},{33,'y',1},{34,'y',-1}}) do
                local key,axis,sign=binding[1],binding[2],binding[3];local down=backend.editor_key(key)
                if down and (not repeats[key] or now>=repeats[key]) then
                    local x,y,z=e.values();local value=({x=x,y=y,z=z})[axis]
                    if not screen() or axis~='y' then local limit=screen() and 2000 or 72;e.move(axis,step*sign) end
                    repeats[key]=now+(held[key] and .08 or .3)
                elseif not down then repeats[key]=nil end
                held[key]=down
            end
        end
        e.notice_visible=e.active or now<notice_until
    end
    function e.overlay(w,h,font)
        if not e.notice_visible then return {} end
        local x,y,z=e.values();local s=h/1080
        local offset=(hud.weapon_clearance[e.resource] or {})[e.view] or {}
        local point=offset.attach_point or 'root';local point_label=point
        for _,item in ipairs(e.points()) do if item.value==point then point_label=item.label;break end end
        local label=e.active and string.format('EDIT %s | %s | %s | X %.2f Y %.2f Z %.2f in | SCALE %.0f%%',e.name,e.view=='right' and (e.shared and 'SHARED' or 'THIRD') or 'FIRST',point_label,x,y,z,e.scale()*100) or e.status
        if e.active and not screen() then label=label..string.format(' | ROLL %.0f PITCH %.0f YAW %.0f deg',e.rotation(),e.rotation('pitch'),e.rotation('yaw')) end
        if e.active and screen() then label=string.format('EDIT %s | %s | X %.0f Y %.0f px | SCALE %.0f%%',e.name,e.view,x,z,e.scale()*100) end
        return {{type='text',text=label,font=font,x=32*s,y=h-160*s,size=18*s,c={255,255,255},a=1},
            {type='text',text=e.status,font=font,x=32*s,y=h-135*s,size=16*s,c=e.status:match('^Saved:') and {100,255,160} or {255,255,255},a=1},
            {type='text',text='Ctrl+F5 reload settings | F6 edit  F7 save  F8 restore  F9 zero position | Arrows move  PgUp/PgDn depth | [ / ] bone | - / + scale | , / . roll | Ctrl+,/. pitch | Alt+,/. yaw | Shift fine',font=font,x=32*s,y=h-185*s,size=13*s,c={255,255,255},a=1}}
    end
    return e
end
return M
