-- Native resource selection; no rectangle glyph renderer.
local M={}
local frame_cache,frame_clock
local availability=setmetatable({},{__mode='k'})
function M.begin_frame(clock) frame_cache={};frame_clock=clock end
function M.end_frame() frame_cache=nil;frame_clock=nil end
function M.resolve(sr,name,depth)
    local key=(name or 'bigblue')..(depth and ':depth' or ':clear')
    if frame_cache and frame_cache[key] then return unpack(frame_cache[key],1,3) end
    local function result(font,material,face)
        if frame_cache then frame_cache[key]={font,material,face} end
        return font,material,face
    end
    local face=HUD.native_font_data.faces[name or 'bigblue']
    local app=sr and sr.Application
    local function available(kind,resource)
        if not app or type(app.can_get)~='function' then return false end
        -- Resource registration is not animation. Recheck positive availability
        -- at 4 Hz; a new font/material or provider is still queried immediately.
        -- Misses are not retained, so newly uploaded fonts appear next frame.
        local entries=frame_clock and availability[app]
        if frame_clock and (not entries or entries.provider~=app.can_get)then
            entries={provider=app.can_get};availability[app]=entries
        end
        local id=kind..':'..resource;local entry=entries and entries[id]
        if entry and frame_clock>=entry.at and frame_clock<entry.expires then return true end
        local ok,value=pcall(app.can_get,kind,resource)
        if entries then entries[id]=ok and value==true and {at=frame_clock,expires=frame_clock+.25}or nil end
        return ok and value==true
    end
    if face then
        local material=depth and face.depth or face.clear
        if available('font',face.font) and available('material',material) then return result(face.font,material,face) end
    end
    if name=='hack' and depth and available('font','mods/dbf_hud/fonts/hack_regular_test') and available('material','mods/dbf_hud/materials/hack_regular_test') then
        return result('mods/dbf_hud/fonts/hack_regular_test','mods/dbf_hud/materials/hack_regular_test',face)
    end
    local debug='core/performance_hud/debug'
    local material=depth and 'mods/dbf_hud/materials/native_font_depth_loader_control' or debug
    if depth and not available('material',material) then return result(nil,nil,nil) end
    return result(debug,material,nil)
end
return M
