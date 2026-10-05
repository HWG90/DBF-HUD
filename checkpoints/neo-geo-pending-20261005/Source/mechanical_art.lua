-- Static texture skin; reader/model and safety logic remain owned by DBF-HUD.
local M={layouts=HUD.mechanical_layouts,status={},enabled=true}
local available={}
local function copy(v)local q={};for k,a in pairs(v)do q[k]=a end;return q end
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function rect_bounds(list,predicate)
 local l,b,r,t=math.huge,math.huge,-math.huge,-math.huge
 for _,v in ipairs(list)do if v.w and v.h and predicate(v)then l=math.min(l,v.x);b=math.min(b,v.y);r=math.max(r,v.x+v.w);t=math.max(t,v.y+v.h)end end
 if r>l and t>b then return {l,b,r-l,t-b}end
end
function M.compose(original,m,x,y,s,opacity,cfg,clock,measure,can_get)
 local id=m.resource_hex;local a=M.layouts[id]
 if not M.enabled or not a or m.snow_party or m.mg43_flash or cfg.mechanical_art_enabled==false or cfg.texture_art_trial==false or (cfg.texture_art_variant and cfg.texture_art_variant~='faithful') then return original,false end
 if id=='8d3d52a3b2f19402'and m.cylinder_slots and cfg.senator_style~='upright' then
  M.status[id]='Existing native cylinder retained; mechanical skin available for upright view'
  return original,false
 end
 local material='mods/dbf_hud/materials/mechanical_'..id
 local texture='mods/dbf_hud/textures/mechanical_'..id
 -- Missing resources must leave the complete original HUD operational.
 if available[id]==nil then
  available[id]=can_get('material',material)==true and can_get('texture',texture)==true
 end
 if not available[id]then M.status[id]='Assets pending game restart';return original,false end
 local box=a.box or a.source_box;local w,h=box[3]*s,box[4]*s;local left,bottom=x+box[1]*s,y+box[2]*s
 -- The zero-alpha frame supplies existing projection/effect bookkeeping without
 -- filling transparent corners. Artwork and native readouts share its transform.
 local out={{type='panel',x=left,y=bottom,w=w,h=h,c={0,0,0},a=0,frosted=false,mechanical_art=true},
  {type='texture',x=left,y=bottom,w=w,h=h,c={255,255,255},a=opacity*(cfg.panel_opacity or 1),texture_material=material,texture_resource=texture,texture_layer=49,mechanical_art=true}}
 local zones=a.zones;local ink=HUD.config.rgb(cfg.text_color or '#D8DFC9')
 local warning=m.warning and HUD.config.rgb(cfg.heat_red or '#E16D65')or ink
 local function bounds(z)return left+z[1]*w,bottom+(1-z[2]-z[4])*h,z[3]*w,z[4]*h end
 if cfg.theme_shader and cfg.theme_shader~='auto'and cfg.theme_shader~='none'then
  local z=zones.count or zones.gauge
  if z then local lx,ly,zw,zh=bounds(z);out[#out+1]={type='panel',x=lx,y=ly,w=zw,h=zh,c=HUD.config.rgb(cfg.background_color or '#202628'),a=opacity*(cfg.panel_opacity or 1),frosted=false,mechanical_live=true,mechanical_theme=true}end
 end
 local function text(value,z,color,source)
  if not z or value==nil then return end
  value=tostring(value);local lx,ly,zw,zh=bounds(z);local size=zh/.75
  local font=(source and source.font)or cfg.font or 'bigblue'
  local function metrics(q)return HUD.font.measure(value,q,font)end
  local ba,bb,br,bt=metrics(size);local tw,th=br-ba,bt-bb
  if tw>zw or th>zh then size=size*math.min(zw/math.max(.001,tw),zh/math.max(.001,th));ba,bb,br,bt=metrics(size)end
  local q=source and copy(source)or {type='text'}
  q.x=lx+(zw-(br-ba))/2-ba;q.y=ly+(zh-(bt-bb))/2-bb;q.size=size;q.text=value;q.font=font;q.c=color or (source and source.c)or ink
  q.a=source and (source.a or opacity)or opacity*(cfg.text_opacity or 1);q.mechanical_live=true;q.bounds=nil
  q.center_in_frame=nil;q.mode_count=nil;q.mode_gap=nil;q.heat_label=nil;q.heat_prefix=nil;q.heat_digit_slot=nil
  out[#out+1]=q
 end
 local function bar(z,fraction,color,segments)
  if not z then return end
  local lx,ly,zw,zh=bounds(z)
  if not finite(fraction)then return end
  fraction=math.max(0,math.min(1,fraction));segments=segments or 1
  for i=0,segments-1 do
   local part=math.max(0,math.min(1,fraction*segments-i))
   if part>0 then out[#out+1]={type='rect',x=lx+i*zw/segments,y=ly,w=zw/segments*part*(segments>1 and .83 or 1),h=zh,c=color,a=.9*opacity,mechanical_live=true}end
  end
 end
 local count,reserve,capacity,mode,status,selector,aux,charge_label,reading,rifle,grenade
 local count_size=-1
 for _,v in ipairs(original)do if v.type=='text'then
  local t=tostring(v.text or '')
  if (v.numeric_display or t:match('^%d+$')or t:match('^[-]+$'))and (v.size or 0)>count_size and not t:find('%a')then count=v;count_size=v.size or 0 end
  if v.heat_label or t:match('^HEAT:')or t:match('^FUEL:')or t:match('^GAS:')or t:match('^THERMAL:')then reading=reading or v end
  if t:find('MAGS')or t:find('BELTS')or t:find('TANKS')or t:find('HTSNKS')or t:find('SHELLS')or t:find('BATTERIES')or t:find('RCKTS')or t:find('WARHEAD')and t:find('%d')or t:find('POWER PACKS')or t:find('CNSTRS')or t:find('SPEARS')or t:find(' SHOTS')then reserve=v end
  if t:match('^/ ')then capacity=v end
  if v.child and not v.charge_meter and not v.loyalist_charge_meter and not v.fold_child then mode=v end
  if t=='LOADED'or t=='EMPTY'or t=='SPENT'or t:find('SPEAR ')then status=v end
  if t:find('MODE ')or t=='RIFLE'or t=='GL'then selector=v end
  if v.one_two_selector then if t=='RIFLE'then rifle=v elseif t=='GL'then grenade=v end end
  if t=='READY'or t=='CHARGING'or t=='--'and v.size/s<10 then charge_label=v end
  if id=='3575aabc5f1f9326' and not v.child and (t=='AUTO'or t=='SEMI'or t=='BURST')then aux=v end
 end end
 if zones.reading then
  local prefix=m.kind=='heat' and (id=='35a61296619cc47e' and (m.quasar_charge_verified and (m.state=='VENT' and 'COOLDOWN' or 'CHARGE')or 'THERMAL')or m.state=='VENT' and 'VENT'or 'HEAT')or m.label or 'FUEL'
  text(prefix..': '..(finite(m.value) and string.format('%03d',m.value)or tostring(m.value or '--'))..(m.kind=='heat'and '%'or ''),zones.reading,warning,reading)
 else
  local format=a.count_digits==2 and '%02d'or '%03d'
  text(finite(m.value)and string.format(format,m.value)or tostring(m.value or '--'),zones.count,count and count.c or warning,count)
 end
 if zones.reserve then text(reserve and reserve.text or (finite(m.reserve) and string.format('%03d ',m.reserve)or '-- ')..(m.reserve_kind or 'RES'),zones.reserve,nil,reserve)end
 if zones.capacity then text(capacity and capacity.text or '/ '..(m.capacity and tostring(m.capacity)or '--'),zones.capacity,nil,capacity)end
 text(mode and mode.text,zones.mode,nil,mode)
 text(status and status.text,zones.status,nil,status)
 text(aux and aux.text,zones.aux_mode,nil,aux)
 if zones.selector then
  if rifle and grenade then
   local z=zones.selector
   text(rifle.text,{z[1],z[2],z[3]*.48,z[4]},nil,rifle)
   text(grenade.text,{z[1]+z[3]*.52,z[2],z[3]*.48,z[4]},nil,grenade)
  else
   local label=id=='a8cffb316f0b5c5f' and ('AC-8 / '..(m.ammo_mode or 'MODE --'))or selector and selector.text
   text(label,zones.selector,nil,selector)
  end
 end
 local bar_ink=m.kind=='heat'and HUD.config.rgb(HUD.layout.heat_color(m.fraction or 0,clock,cfg))or m.warning and warning or (a.family=='plasma'and {74,210,238}or {231,187,66})
 local continuous=m.kind=='heat' or a.family=='fuel'and id~='8a307bd1811a5fe9'
 if continuous and zones.gauge and finite(m.fraction)then
  local z=zones.gauge;local bands=m.kind=='heat'and {{0,.65,cfg.heat_white},{.65,.85,cfg.heat_yellow},{.85,1,cfg.heat_red}}or {{0,.15,cfg.heat_red},{.15,.35,cfg.heat_yellow},{.35,1,cfg.heat_white}}
  for _,b in ipairs(bands)do bar({z[1]+z[3]*b[1],z[2],z[3]*(b[2]-b[1]),z[4]},(m.fraction-b[1])/(b[2]-b[1]),HUD.config.rgb(b[3]),1)end
  local lx,ly,zw,zh=bounds(z)
  for i=0,20 do local loaded=i/20<=m.fraction;local tick=i%5==0 and .34 or .18
   for _,dy in ipairs({0,1-tick})do out[#out+1]={type='rect',x=lx+zw*i/20,y=ly+zh*dy,w=math.max(.3*s,zw*.0025),h=zh*tick,c=loaded and {18,23,24}or {113,126,129},a=.8*opacity,mechanical_live=true}end
  end
 else bar(zones.gauge,m.fraction,bar_ink,math.max(1,math.min(45,m.capacity or 16)))end
 -- Keep unknown charge unknown; do not infer readiness from ammunition.
 local q=id=='e8d5f49ad7780e54'and m.epoch_charge_fraction or id=='aa69a60d74a3ec54'and m.loyalist_charge_fraction or id=='fb3a19078694708a'and m.purifier_charge_fraction
 local full=id=='e8d5f49ad7780e54' and finite(q) and q>=1-1e-6
 if a.occupancy_mask then
  out[2].mechanical_uv_mask=a.occupancy_mask;out[2].mechanical_intensity=finite(m.value)and (m.value>0 and 1 or 0)or .2
 elseif a.capacitor_mask then
  out[2].mechanical_uv_mask=a.capacitor_mask;out[2].mechanical_intensity=finite(q)and (.3+.7*q)or .3
 elseif a.melta_mask then
  out[2].mechanical_uv_mask=a.melta_mask;out[2].mechanical_intensity=finite(m.melta_charge_level)and math.max(0,math.min(1,m.melta_charge_level/10))or .5
 end
 local charge_ink=full and {255,32,32}or {74,210,238}
 local before=#out;bar(zones.charge,q,charge_ink)
 if full then for i=before+1,#out do out[i].a=out[i].a*(.35+.65*(.5+.5*math.cos((clock or 0)*math.pi*8)))end end
 text(charge_label and charge_label.text or (finite(q)and (q>=1-1e-6 and 'READY'or string.format('%02d%%',q*100))or '--'),zones.charge_label,charge_ink,charge_label)
 local function remap(predicate,z)
  if not z then return end
  local source=rect_bounds(original,predicate);if not source then return end
  local lx,ly,zw,zh=bounds(z)
  for _,v in ipairs(original)do if predicate(v)then
   local q=copy(v);q.x=lx+(v.x-source[1])*zw/source[3];q.y=ly+(v.y-source[2])*zh/source[4]
   if v.w then q.w=v.w*zw/source[3];q.h=v.h*zh/source[4]end
   if v.size then q.size=v.size*math.min(zw/source[3],zh/source[4])end
   q.mechanical_live=true;out[#out+1]=q
  end end
 end
 remap(function(v)return v.compass_piece==true end,zones.compass)
 if zones.compass then for _,v in ipairs(original)do if v.type=='text'and not v.child and v.size/s<20 and v.text~=reserve and tostring(v.text):match('^[NEWS]+$')then text(v.text,{zones.compass[1],zones.compass[2]-.04,zones.compass[3],.055},nil,v)end end end
 remap(function(v)return v.mode_icon==true end,zones.icon)
 remap(function(v)return v.shotgun_shell_art==true or v.barrel_indicator~=nil end,zones.shells)
 if mode and not zones.mode then
  local b=rect_bounds(original,function(v)return v.child and not v.charge_meter and not v.loyalist_charge_meter and not v.fold_child end)
  if b then for _,v in ipairs(original)do if v.child and not v.charge_meter and not v.loyalist_charge_meter and not v.fold_child then
   local q=copy(v);q.x=q.x+(left+w/2-b[1]-b[3]/2);q.y=q.y+(bottom-2*s-b[2]-b[4]);out[#out+1]=q
  end end end
 end
 -- Retain the existing safety timer, charge warnings, child modes, foldouts and effects.
 -- Charge controls without an internal new-art zone remain complete native child panels.
 for _,v in ipairs(original)do
  if (v.charge_meter or v.loyalist_charge_meter)and not zones.charge or v.fold_child then out[#out+1]=v
  elseif v.effect_shader_band or v.df_effect_sweep or v.scanline_layer then
   local q=copy(v);q.x=left+(v.x-x-box[1]*s);q.y=bottom+(v.y-y-box[2]*s);out[#out+1]=q
  end
 end
 M.status[id]='Mechanical live texture; native readouts active'
 return out,true
end
function M.world_prepare(commands,p,c)
 local frame=commands[1];local factor=240*(c.scale or 1)/(frame.world_reference_width or frame.w)
 if c.placement_mode=='auto'and p.first_person then factor=factor*.5 end
 local out={}
 for _,v in ipairs(commands)do
  local q=copy(v);q.x=(v.x-frame.x-frame.w/2)*factor;q.y=(v.y-frame.y-frame.h/2)*factor
  if v.w then q.w=v.w*factor;q.h=v.h*factor end
  if v.size then q.size=v.size*factor end
  if v.effect_band then q.effect_band=v.effect_band*factor end
  if v.df_effect_frame then local b=v.df_effect_frame;q.df_effect_frame={x=(b.x-frame.x-frame.w/2)*factor,y=(b.y-frame.y-frame.h/2)*factor,w=b.w*factor,h=b.h*factor}end
  if v.quad then q.quad={};for i,a in ipairs(v.quad)do q.quad[i]={(a[1]-frame.x-frame.w/2)*factor,(a[2]-frame.y-frame.h/2)*factor}end end
  out[#out+1]=q
 end
 return out
end
return M

