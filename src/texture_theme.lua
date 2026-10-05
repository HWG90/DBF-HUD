-- Texture-compatible theme materials preserve the artwork's binding and alpha.
local M={}
local ids,available={},{}
for _,entry in ipairs(HUD.shader_catalog or {})do ids[entry.id]=true end
function M.material(original,id,can_get)
 if not ids[id]then return original end
 local name=original..'_texture_theme_'..id
 if available[name]==nil then available[name]=can_get('material',name)==true end
 return available[name] and name or original
end
function M.parameters(enabled,scale,seconds,animated)
 scale=tonumber(scale)or 1;seconds=tonumber(seconds)or 0
 if scale~=scale then scale=1 end
 if seconds~=seconds or math.abs(seconds)==math.huge then seconds=0 end
 -- Exactly representable 24-bit word in the existing scalar uniform. Its low
 -- bit remains the depth toggle; UV .w fields retain live occupancy masks.
 local size=math.floor(math.max(.25,math.min(4,scale))*32+.5)
 local time=math.floor(math.max(0,seconds)*16)%16384
 return (enabled>.5 and 1 or 0)+size*2+time*512+(animated==1 and 8388608 or 0)
end
return M
