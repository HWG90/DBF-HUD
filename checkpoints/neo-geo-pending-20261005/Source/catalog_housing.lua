-- Shared physical instrument finish. Existing telemetry and meter geometry remain authoritative.
local M={protected={['e6d932be83729076']=true,['89c5493e08ca4207']=true,['52e4334e6a128caf']=true,['2e9d0bdc48b09e60']=true,['11c27d3babb38956']=true,['a8cffb316f0b5c5f']=true,['6cfcc7f8801a0266']=true,['3828e2051aa9e897']=true,['9f80d67a12a7e40f']=true,['84354339522c932d']=true,['5fecab819f96a3e8']=true,['0f83639ab8c86165']=true,['a6a735accb4a327f']=true,['14d5d4506056c7a4']=true,['5f3ec9bda2bd8553']=true,['4dbd74f49c8ffc13']=true,['0b882808c6f498e8']=true,['e5796355a8fd67e0']=true,['416d053372c4e433']=true,['b2b5e0d185605f9e']=true,['26e40437ea275296']=true,['2b28e17ffed05f7c']=true}}
-- Retired added artwork bays. Earlier weapon presentation remains authoritative.
M.enabled=false
function M.eligible(id) return M.enabled and not M.protected[id] end
function M.apply(out,m,s,cfg,opacity,style,fallback,measure)
 if not M.enabled then return out end
 if not M.eligible(m.resource_hex) then return out end
 local frame=out[1];if not frame or frame.type~='panel' then return out end
 -- Double Freedom: a retro shotgun status slab, rather than nested instrument frames.
 if m.resource_hex=='72170a55a1f37ff1' then
  frame.c={24,29,32};frame.machined_catalog=true;frame.doom_shotgun=true
  local result={frame}
  for i=2,#out do local d=out[i]
   if not d.decoration and not d.catalog_detail then result[#result+1]=d end
  end
  return result
 end

 local pale={177,198,208};local shade={12,19,23};local steel={49,64,73};local brass={211,171,92}
 local energy=style.family=='laser' or style.family=='arc' or style.family=='plasma'
 local fuel=style.family=='fuel'
 local accent=energy and (style.family=='plasma' and {168,131,238} or {100,220,238}) or fuel and {233,159,64} or brass
 local lo,hi,left,right=math.huge,-math.huge,math.huge,-math.huge
 for _,d in ipairs(out) do if d.catalog_heading then
  lo=math.min(lo,d.y);hi=math.max(hi,d.y+d.h);left=math.min(left,d.x);right=math.max(right,d.x+d.w)
 end end
 -- Heat/fuel gauges retain their native full-height meter, gaining a separate hardware bay above it.
 if lo==math.huge then
  local icon=HUD.munition_art.icon(style,m,HUD.fire_icons[fallback])
  if icon and #icon.runs>0 then
   local il,ib,ir,it=math.huge,math.huge,-math.huge,-math.huge
   for _,run in ipairs(icon.runs) do il=math.min(il,run[1]);ib=math.min(ib,run[2]);ir=math.max(ir,run[1]+run[3]);it=math.max(it,run[2]+run[4]) end
   local old_top=frame.y+frame.h
   local factor=math.min(36*s/(it-ib),(frame.w-30*s)/(ir-il))
   local px=frame.x+frame.w/2-(il+ir)*factor/2
   lo=old_top+8*s;hi=lo+(it-ib)*factor;left=px+il*factor;right=px+ir*factor
   for _,run in ipairs(icon.runs) do
    out[#out+1]={type='rect',catalog_heading=true,x=px+run[1]*factor,y=lo+(run[2]-ib)*factor,w=run[3]*factor,h=run[4]*factor,c=run[5] or accent,a=opacity}
   end
   frame.h=hi-frame.y+10*s
  end
 end
 local layers={};local function r(x,y,w,h,c,a)
  if w<=0 or h<=0 then return end
  layers[#layers+1]={type='rect',x=x,y=y,w=w,h=h,c=c,a=(a or 1)*opacity,machined_detail=true}
 end
 local x,y,w,h=frame.x,frame.y,frame.w,frame.h
 frame.machined_catalog=true
 -- Double steel rails, shadow channel, stepped corner plates and screw recesses.
 for _,inset in ipairs({1,3}) do
  local q=inset*s;local color=inset==1 and pale or steel
  r(x+q,y+q,w-2*q,.6*s,color,.6);r(x+q,y+h-q-.6*s,w-2*q,.6*s,color,.6)
  r(x+q,y+q,.6*s,h-2*q,color,.6);r(x+w-q-.6*s,y+q,.6*s,h-2*q,color,.6)
 end
 for _,dx in ipairs({5,w/s-12}) do for _,dy in ipairs({5,h/s-11}) do
  r(x+dx*s,y+dy*s,7*s,5*s,shade,.9);r(x+(dx+2)*s,y+(dy+1)*s,3*s,3*s,steel)
  r(x+(dx+2.5)*s,y+(dy+2)*s,2*s,.5*s,pale,.8)
 end end
 if lo<math.huge then
  local bay_y=lo-3*s;local bay_h=hi-lo+6*s
  r(x+11*s,bay_y,s,bay_h,pale,.35);r(x+w-12*s,bay_y,s,bay_h,pale,.35)
  r(x+11*s,bay_y,w-22*s,.6*s,pale,.35);r(x+11*s,bay_y+bay_h-.6*s,w-22*s,.6*s,pale,.35)
  -- Different machined hardware for projectile racks, energy coils, fuel valves and tool clamps.
  for _,edge in ipairs({x+13*s,x+w-18*s}) do
   if energy then
    for k=0,3 do r(edge,bay_y+(3+k*math.max(1,(bay_h/s-8)/4))*s,4*s,2*s,accent,.6) end
   elseif fuel then
    r(edge,bay_y+4*s,3*s,bay_h-8*s,steel);r(edge-s,bay_y+bay_h/2,5*s,2*s,accent)
   elseif style.family=='tool' or style.family=='medical' then
    r(edge,bay_y+4*s,4*s,3*s,pale,.65);r(edge,bay_y+bay_h-7*s,4*s,3*s,pale,.65)
   else
    for k=0,3 do r(edge,bay_y+(3+k*math.max(1,(bay_h/s-8)/4))*s,3*s,s,pale,.45) end
   end
  end
 end
 local single=m.capacity==1 and (m.kind=='magazine' or m.kind=='rounds') and not m.energy_icon and style.family~='tool'
 local result={frame};for _,v in ipairs(layers) do result[#result+1]=v end
 for i=2,#out do local d=out[i]
  if single and d.catalog_heading and m.value==0 then
   -- Empty ammunition bay keeps its brackets but contains no projectile.
  elseif single and d.center_bar then
  else
   if single and d.type=='text' and d.size>=20*s and not d.child and not d.heat_label then
    local state=m.value>0 and 'LOADED' or 'EMPTY';local size=10*s
    local a,b,e,f=0,-size*.2,#state*size*.6,size*.8
    if measure then a,b,e,f=measure(state,size) end
    d.text=state;d.size=size;d.x=x+w/2-(a+e)/2;d.c=m.value>0 and accent or {238,111,87}
    d.numeric_display=nil;d.mode_count=nil;d.mode_gap=nil;d.last_digit_color=nil;d.center_in_frame=nil
   end
   result[#result+1]=d
  end
 end
 return result
end
return M

