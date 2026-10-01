-- Native resource selection; no rectangle glyph renderer.
local M={}
function M.resolve(sr,name,depth)
    local face=HUD.native_font_data.faces[name or 'bigblue']
    local app=sr and sr.Application
    local function available(kind,resource)
        if not app or type(app.can_get)~='function' then return false end
        local ok,value=pcall(app.can_get,kind,resource);return ok and value==true
    end
    if face then
        local material=depth and face.depth or face.clear
        if available('font',face.font) and available('material',material) then return face.font,material,face end
    end
    if name=='hack' and depth and available('font','mods/dbf_hud/fonts/hack_regular_test') and available('material','mods/dbf_hud/materials/hack_regular_test') then
        return 'mods/dbf_hud/fonts/hack_regular_test','mods/dbf_hud/materials/hack_regular_test',face
    end
    local debug='core/performance_hud/debug'
    local material=depth and 'mods/dbf_hud/materials/native_font_depth_loader_control' or debug
    if depth and not available('material',material) then return nil end
    return debug,material,nil
end
return M
