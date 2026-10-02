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
                        elseif axis=='attach_point' then
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
                if offset.attach_point then
                    local point=offset.attach_point
                    assert(point=='sight' or point=='root' or point:match('^node:%x%x%x%x%x%x%x%x$'),'invalid attach point')
                    axes[#axes+1]='attach_point = '..string.format('%q',point)
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
