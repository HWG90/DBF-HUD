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
                    assert(view=='right' or view=='left' or view=='first_left' or view=='first_right','invalid weapon view')
                    assert(type(offset)=='table','weapon offset must be a table')
                    for axis,value in pairs(offset) do
                        assert(axis=='x' or axis=='y' or axis=='z','invalid offset axis')
                        assert(type(value)=='number' and value==value and math.abs(value)<=2,'offset must be within two metres')
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
return M
