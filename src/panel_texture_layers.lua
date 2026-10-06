-- Image layers use current reader-owned state. No texture uploads on firing.
local M={}
local function count(n)
 return type(n)=='number' and n==n and n>=0 and n<=100000 and n%1==0 and n or nil
end
function M.prepare(definitions,model,available)
 if not definitions then return nil end
 assert(type(definitions)=='table' and #definitions<=7,'at most seven panel overlays')
 local result={}
 for _,definition in ipairs(definitions)do
  assert(type(definition.texture)=='string' and type(definition.material)=='string','overlay image and material required')
  -- Fall back as a whole if any image is missing, including currently hidden ones.
  if not available('texture',definition.texture) or not available('material',definition.material)then return nil end
  local layer={};for key,value in pairs(definition)do layer[key]=value end
  local state=definition.state
  if state then
   assert(type(state)=='table' and state.kind=='loaded_shell','unsupported panel image state')
   assert(count(state.slot) and state.slot>=1 and state.slot<=7,'invalid loaded shell slot')
   local loaded=count(model.value)
   -- Slot 1 empties first on the Double Freedom; slot 2 remains at one round.
   local threshold=state.threshold or state.slot
   assert(count(threshold) and threshold>=1,'invalid loaded shell threshold')
   layer.visible=definition.visible~=false and loaded~=nil and loaded>=threshold
  end
  layer.state=nil;result[#result+1]=layer
 end
 return result
end
function M.double_freedom(shell,rects)
 assert(type(shell)=='table' and type(rects)=='table' and #rects==2,'two shell positions required')
 local result={}
 for side=1,2 do
  result[side]={texture=shell.texture,material=shell.material,rect=rects[side],
   theme=shell.theme,atlas_rect=shell.atlas_rect,state={kind='loaded_shell',slot=side,threshold=3-side}}
 end
 return result
end
return M
