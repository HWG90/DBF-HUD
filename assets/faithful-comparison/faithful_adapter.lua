-- Reference adapter for faithful conversion handoff. No game API or deployment.
-- The renderer owner injects compiled material/texture names per fragment.
local M={}
local function near(a,b)return type(a)=='number'and type(b)=='number'and math.abs(a-b)<=1e-6*math.max(1,math.abs(a),math.abs(b))end
local function matches(current,expected,x,y,s,opacity,panel,policy)
 if current.type~='rect'or current.child or current.fold_child or current.quad then return false end
 for k,v in pairs(expected)do
  if k=='x'then if not near(current.x,x+v*s)then return false end
  elseif k=='y'then if not near(current.y,y+v*s)then return false end
  elseif k=='w'or k=='h'then if not near(current[k],v*s)then return false end
  elseif k=='a'then if not near(current.a,v*opacity*(policy=='panel'and panel or 1))then return false end
  elseif k=='c'then for i=1,3 do if not near(current.c[i],v[i])then return false end end
  elseif k=='texture_art_opacity'then if not near(current[k],v*opacity*(policy=='panel'and panel or 1))then return false end
  elseif k:sub(-10)=='_reference'then if type(current[k:sub(1,-11)])~='table'then return false end
  elseif current[k]~=v then return false end
 end
 -- A newly introduced runtime flag must not silently become part of frozen artwork.
 for k,v in pairs(current)do
  if k~='index'and k~='bounds'and expected[k]==nil and expected[k..'_reference']==nil then return false end
 end
 return true
end
function M.prepare(commands,spec,assets,x,y,s,opacity,cfg,available)
 if not spec or #spec.layers==0 or not near(opacity,1)or not near(cfg.panel_opacity or 1,1)then return commands end
 local used,starts={},{ }
 for _,fragment in ipairs(spec.layers)do
  local material=assets[fragment.asset]
  if not material or not available('material',material.material)or not available('texture',material.texture)then return commands end
  local start
  for i=1,#commands-#fragment.commands+1 do
   local ok=true
   for k,expected in ipairs(fragment.commands)do
    if used[i+k-1]or not matches(commands[i+k-1],expected,x,y,s,opacity,cfg.panel_opacity or 1,fragment.opacity)then ok=false;break end
   end
   if ok then start=i;break end
  end
  if not start then return commands end
  local b=fragment.origin
  starts[start]={type='texture',x=x+b[1]*s,y=y+b[2]*s,w=b[3]*s,h=b[4]*s,c={255,255,255},
   a=opacity*(fragment.opacity=='panel'and(cfg.panel_opacity or 1)or 1),texture_material=material.material,texture_resource=material.texture,
   texture_layer=50,faithful_fragment=fragment.asset}
  for i=start,start+#fragment.commands-1 do used[i]=true end
 end
 local out={}
 for i,v in ipairs(commands)do if starts[i]then out[#out+1]=starts[i]elseif not used[i]then out[#out+1]=v end end
 return out
end
return M
