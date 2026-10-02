-- External weapon profile loading and validation, independent of rendering.
local M={}
function M.load(backend,log)
    local profiles_loaded
    profiles_loaded=HUD.config.weapon_clearance
    if backend.read_weapon_offsets then
        local ok,profiles=pcall(function()
            local values=backend.read_weapon_offsets();if not values then return nil end
            assert(type(values)=='table','weapon offsets must return a table')
            for resource,views in pairs(values) do
                assert(type(resource)=='string' and #resource==16 and resource:match('^%x+$'),'invalid weapon resource')
                assert(type(views)=='table','weapon views must be a table')
                for view,offset in pairs(views) do
                    assert(view=='right' or view=='left' or view=='first_left' or view=='first_right' or view=='screen_weapon_first' or view=='screen_weapon_third' or view=='screen_crosshair_first' or view=='screen_crosshair_third','invalid weapon view')
                    assert(type(offset)=='table','weapon offset must be a table')
                    for axis,value in pairs(offset) do
                        if axis=='rotation' or axis=='pitch' or axis=='yaw' then
                            assert(type(value)=='number' and value==value and math.abs(value)<=180,'invalid weapon rotation')
                        elseif axis=='scale' then
                            assert(type(value)=='number' and value==value and value>=.25 and value<=3,'invalid weapon scale')
                        elseif axis=='attach_point' or axis=='root_from' then
                            assert(value=='sight' or value=='root' or (type(value)=='string' and value:match('^node:%x%x%x%x%x%x%x%x$')),'invalid attach point')
                        else
                        assert(axis=='x' or axis=='y' or axis=='z','invalid offset axis')
                        assert(type(value)=='number' and value==value and math.abs(value)<=2,'offset must be within two metres')
                        end
                    end
                end
            end
            return values
        end)
        if ok and profiles then profiles_loaded=profiles end
        if not ok then log('WEAPON_OFFSETS rejected: '..tostring(profiles)) end
    end
    return profiles_loaded
end
-- Convert only after the original attachment has been sampled in this view.
-- Root-oriented rendering permits exact translation without changing Euler angles.
function M.convert_root(offset,p,first,config)
    if not offset or not offset.root_from then return false end
    if not config.debug_sight_root_orientation then return false,'root orientation required' end
    if not p.sight and p.anchor_status~='selected node absent' then return false,'attachment read unavailable' end
    local sight=p.sight
    local base=first and {x=.12,y=.45,z=.01} or {x=.16,y=.10,z=.04}
    local old=sight and base or (first and {x=-.12,y=.35,z=.22} or {x=.18,y=.05,z=.10})
    local scale=config.scale or 1
    local converted={}
    for _,axis in ipairs({'x','y','z'}) do
        local anchor=sight and sight[axis] or 0
        local divisor=axis=='y' and 1 or scale
        local value=(offset[axis] or 0)+old[axis]-base[axis]+anchor/divisor
        if value~=value or math.abs(value)>2 then return false,'converted offset out of bounds' end
        converted[axis]=value
    end
    for axis,value in pairs(converted) do offset[axis]=value end
    offset.attach_point='root';offset.root_from=nil
    return true
end
function M.serialize(profiles)
    local keys={};for key in pairs(profiles) do keys[#keys+1]=key end;table.sort(keys)
    local lines={'-- Saved by DBF-HUD Layout Editor. 3D: weapon-local metres. Screen profiles: reference pixels divided by 1000.','return {'}
    for _,key in ipairs(keys) do
        assert(type(key)=='string' and #key==16 and key:match('^%x+$'),'invalid weapon resource')
        local parts={}
        for _,view in ipairs({'right','left','first_left','first_right','screen_weapon_first','screen_weapon_third','screen_crosshair_first','screen_crosshair_third'}) do
            local offset=profiles[key][view]
            if offset then
                local axes={}
                for _,axis in ipairs({'rotation','pitch','yaw'}) do
                    local value=offset[axis]
                    if value~=nil then
                        assert(type(value)=='number' and value==value and math.abs(value)<=180,'invalid weapon rotation')
                        axes[#axes+1]=axis..' = '..string.format('%.9f',value)
                    end
                end
                if offset.scale then
                    assert(type(offset.scale)=='number' and offset.scale>=.25 and offset.scale<=3,'invalid weapon scale')
                    axes[#axes+1]='scale = '..string.format('%.9f',offset.scale)
                end
                for _,field in ipairs({'attach_point','root_from'}) do
                if offset[field] then
                    local point=offset[field]
                    assert(point=='sight' or point=='root' or point:match('^node:%x%x%x%x%x%x%x%x$'),'invalid attach point')
                    axes[#axes+1]=field..' = '..string.format('%q',point)
                end
                end
                for _,axis in ipairs({'x','y','z'}) do
                    local value=offset[axis]
                    if value~=nil then
                        assert(type(value)=='number' and value==value and math.abs(value)<=2,'invalid weapon offset')
                        axes[#axes+1]=axis..' = '..string.format('%.9f',value)
                    end
                end
                parts[#parts+1]=view..' = { '..table.concat(axes,', ')..' }'
            end
        end
        lines[#lines+1]="    ['"..key.."'] = { "..table.concat(parts,', ')..' },'
    end
    lines[#lines+1]='}';return table.concat(lines,'\n')..'\n'
end
return M
