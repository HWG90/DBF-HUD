-- Ordered alpha overlays using the existing mapped native shader materials.
-- No new shader-library bytecode is generated or installed.
local M={maximum=4,scales={.5,1,2,4},strengths={.25,.5,.75,1},blends={'replace','multiply','add'}}
local available={}
local ids={};for i,e in ipairs(HUD.shader_catalog)do ids[e.id]=i end
function M.validate(rows)
 assert(type(rows)=='table' and #rows<=M.maximum,'At most four shader layers')
 local out,seen={},{}
 for k in pairs(rows)do assert(type(k)=='number' and k%1==0 and k>=1 and k<=#rows,'Shader layers must be a dense list')end
 for i,r in ipairs(rows)do
  assert(type(r)=='table' and ids[r.shader],'Unknown layer shader')
  assert(type(r.id)=='number' and r.id%1==0 and r.id>0 and r.id<1000000 and not seen[r.id],'Invalid layer identity');seen[r.id]=true
  assert(r.enabled==nil or type(r.enabled)=='boolean','Invalid layer enabled')
  local q={id=r.id,shader=r.shader,scale=r.scale or 2,strength=r.strength or 4,blend=r.blend or 1,enabled=r.enabled~=false,animate=r.animate==true,speed=r.speed or 1,opacity=r.opacity,pattern_size=r.pattern_size}
  for _,k in ipairs({'scale','strength','blend'})do assert(type(q[k])=='number' and q[k]%1==0 and q[k]>=1 and q[k]<=(k=='blend' and 3 or 4),'Invalid layer '..k)end
  assert(q.pattern_size==nil or(type(q.pattern_size)=='number'and q.pattern_size==q.pattern_size and q.pattern_size>=.25 and q.pattern_size<=4),'Invalid pattern size')
  assert(q.opacity==nil or (type(q.opacity)=='number' and q.opacity==q.opacity and q.opacity>=.01 and q.opacity<=1),'Invalid layer opacity')
  assert(r.animate==nil or type(r.animate)=='boolean','Invalid layer animation');assert(type(q.speed)=='number' and q.speed==q.speed and q.speed>=.1 and q.speed<=3,'Invalid layer speed')
  out[i]=q
 end
 return out
end
function M.effective(c)
 if c.shader_layers~=nil then local rows=M.validate(c.shader_layers);for _,r in ipairs(rows)do r.pattern_size=r.pattern_size or M.scales[r.scale];if r.opacity==nil then r.opacity=math.max(.01,math.min(1,M.strengths[r.strength]*(c.panel_opacity or 1)))end end;return rows end
 -- Legacy material path remains exact until the list is edited.
 local out={};for _,key in ipairs({'theme_shader','effect_shader'})do if ids[c[key]]then out[#out+1]={id=#out+1,shader=c[key],scale=2,strength=4,blend=1,opacity=math.max(.01,math.min(1,c.panel_opacity or 1))}end end
 return out
end
function M.edit(c,action,id,value)
 local rows=M.effective(c);local index
 for i,r in ipairs(rows)do if r.id==id then index=i end end
 if action=='add' then
  assert(#rows<M.maximum,'Four shader layers maximum');local next_id=c.shader_layer_serial or 0
  for _,r in ipairs(rows)do next_id=math.max(next_id,r.id)end
  next_id=next_id+1;rows[#rows+1]={id=next_id,shader='crt_scan',scale=2,strength=1,blend=1,animate=false,speed=1,opacity=.25,pattern_size=1}
  return {shader_layers=M.validate(rows),shader_layer_serial=next_id}
 end
 assert(index,'Shader layer was removed; refresh the menu')
 if action=='remove'then table.remove(rows,index)
 elseif action=='up' or action=='down'then local target=index+(action=='up' and -1 or 1);if target>=1 and target<=#rows then rows[index],rows[target]=rows[target],rows[index]end
 else rows[index][action]=value end
 return {shader_layers=M.validate(rows)}
end
function M.status(c,can_get)
 local rows=M.effective(c);local active,ready=0,0
 for _,r in ipairs(rows)do if r.enabled~=false then active=active+1;for _,e in ipairs(HUD.shader_catalog)do if e.id==r.shader and can_get('material',e.material:gsub('/lab_','/mapped_'))==true then ready=ready+1 end end end end
 return #rows..' shader layers ('..active..' enabled, '..ready..' materials available); alpha overlays, 3D only'
end

return M
