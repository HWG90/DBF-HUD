-- Fixed label images copied from the chosen native font. Changing values keep
-- native glyphs; nothing is composed, uploaded or retained on a camera move.
local M={}
function M.prepare(commands,can_get,max_images)
 local data=HUD.native_label_data
 if not data or not(commands[1]and commands[1].split_hud)or type(can_get)~='function'then return commands end
 local slots=0;for _,v in ipairs(commands)do if v.type=='texture'then slots=math.max(slots,v.texture_slot or slots+1)end end
 if slots>=max_images or not can_get('material',data.material)then return commands end
 local available,changed,out={},0,{}
 for i,v in ipairs(commands)do
  local face=v.type=='text'and data.faces[v.font or'bigblue']
  local label=face and face.labels[v.text]
  if label and slots<max_images and not v.last_digit_color and not v.numeric_display and not v.fuel_endpoint and(v.a or 1)>0 then
   local ready=available[face]
   if ready==nil then ready=can_get('texture',face.resource)==true;available[face]=ready end
   if ready then
    local q={};for k,value in pairs(v)do q[k]=value end
    local b,s=label.box,v.size/face.em
    q.type='texture';q.x=v.x+b[1]*s;q.y=v.y+b[2]*s;q.w=(b[3]-b[1])*s;q.h=(b[4]-b[2])*s
    slots=slots+1;q.texture_slot=slots;q.texture_resource=face.resource;q.texture_material=data.material
    q.atlas_rect=label.uv;q.texture_theme=false;q.texture_layer=51;q.native_label=true
    out[i]=q;changed=changed+1
   else out[i]=v end
  else out[i]=v end
 end
 if changed>0 then out.native_label_count=changed;return out end
 return commands
end
return M
