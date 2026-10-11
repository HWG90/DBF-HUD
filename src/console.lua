-- Console setters use the same HUD configuration and tuning persistence as MCM.
return function(hud,project)
    local function copy(value)
        if type(value)~='table'then return value end
        local result={};for key,item in pairs(value)do result[key]=copy(item)end;return result
    end
    local function commit(values)
        local before=copy(hud.config)
        local configured,problem=pcall(hud.configure,values)
        if not configured then pcall(hud.configure,before);return false,tostring(problem)end
        local called,ok,why=pcall(hud.save_tuning)
        if not called or not ok then pcall(hud.configure,before);return false,tostring(called and why or ok)end
        return true
    end
    local settings={}
    for key,value in pairs(hud.config)do
        if type(value)=='number' or type(value)=='boolean' or type(value)=='string' then
            local field=key
            settings[field]={type=type(value),get=function()return hud.config[field]end,set=function(next_value)return commit({[field]=next_value})end}
        end
    end
    return project.expose('dbfhud',{
        global={opacity={type='number',min=0,max=100,
            get=function()return hud.config.panel_opacity*100 end,
            set=function(percent)
                local opacity=percent/100
                local panels=copy(hud.config.weapon_panels or {})
                for _,panel in pairs(panels)do if type(panel)=='table'then panel.panel_opacity=opacity;panel.third_person_opacity=opacity end end
                local ok,why=commit({panel_opacity=opacity,third_person_opacity=opacity,weapon_panels=panels})
                if not ok then return false,why end
                return true,string.format('All weapon panel backgrounds: %.3g%%',percent)
            end}},
        settings=settings,
        reload_settings={call=function()return hud.reload_settings()end},
    })
end
