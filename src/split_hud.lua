-- Split Study 08 in the existing HUD Texture compositor. Authored top-left units.
local A=HUD.split_hud_assets
local M={width=320,height=161,assets=A,empty_flash_hz=2,
 dynamic_coverage='mods/dbf_hud/textures/split_hud_dynamic_coverage_v1',
 dynamic_face='mods/dbf_hud/textures/split_hud_dynamic_face_v1',
 dynamic_soft='mods/dbf_hud/textures/split_hud_dynamic_soft_v1'}
local WHITE,GOLD,NAVY,RED={245,246,240},{233,196,93},{9,27,53},{255,87,80}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function count(v)return finite(v)and v>=0 and v<=100000 and math.floor(v)or nil end
local function fraction(v)return finite(v)and v>=0 and v<=1 and v or nil end
local function color(v,fallback)
 if type(v)=='table'and finite(v[1])and finite(v[2])and finite(v[3])then return v end
 if type(v)=='string'and v:match('^#?%x%x%x%x%x%x$')then return HUD.config.rgb(v)end
 return fallback
end
function M.supported(id)return type(id)=='string'and HUD.weapon_names and HUD.weapon_names[id]~=nil end
function M.selected(c)return c and c.texture_art_trial~=false and c.texture_art_variant=='split'and c.hud_presentation~='practical'and not c.force_all_hud_texture_off end
function M.assets_ready(resource,can_get)
 if type(resource)~='function'or(can_get and can_get('material',A.material)~=true)then return false end
 for _,name in ipairs({A.face,A.atlas,A.coverage,A.hard_coverage})do local r=resource(name);if r==nil or r==false then return false end end
 return true
end
function M.readouts(m,cfg,clock)
 cfg=cfg or {};clock=finite(clock)and clock or finite(cfg.style_clock)and cfg.style_clock or 0
 local loaded,capacity,reserve=count(m.value),count(m.capacity),count(m.reserve)
 local heat,infinite=m.kind=='heat',m.kind=='infinite'
 local fuel=m.label=='FUEL'or m.label=='GAS';local unknown=loaded==nil and not infinite
 local charge,release,railgun
 if m.safety_mode then
  local now=clock or cfg.style_clock
  local age=finite(now)and finite(m.charge_sample_clock)and now-m.charge_sample_clock or nil
  local q=HUD.layout.railgun_charge(m.safety_mode,m.charge_fraction,m.charge_seconds,cfg.railgun_release_margin_ms,age,m.charge_frame_delay)
  if q then railgun=q;charge,release=q.fraction,q.release or q.limit end
 else charge=fraction(m.epoch_charge_fraction)or fraction(m.loyalist_charge_fraction)or fraction(m.purifier_charge_fraction)end
 local quasar=m.quasar_charge_verified==true
 local cooldown=quasar and(m.state=='VENT'or m.locked==true)
 if quasar and not cooldown then charge=fraction(m.fraction)end
 local active_charge=charge~=nil and(charge>0 or m.charge_ready==true or quasar)
 local level=m.melta_charge_level
 local active_level=finite(level)and level>=0 and level<=10 and level>0
 local empty=not heat and not infinite and loaded==0
 -- The normalizer owns weapon-specific thresholds (Autocannon: <=3 warning,
 -- <=5 reload reminder). Do not replace them with the generic 20% rule.
 local low=not heat and not infinite and loaded and loaded>0 and
  (type(m.warning)=='boolean'and m.warning or type(m.warning)~='boolean'and capacity and capacity>0 and loaded/capacity<=.2)
 local reminder=not heat and not infinite and loaded and loaded>0 and m.reload_reminder==true
 local label=heat and 'HEAT'or infinite and 'ENERGY'or fuel and m.label or
  ((m.reserve_kind=='SHELLS'or m.ammo_icon=='SHELL'or m.ammo_icon=='DOUBLE_SHELL')and 'SHELLS'or'ROUNDS')
 if not heat and not infinite and not fuel and capacity==1 then label='LOADED' end
 local value,suffix,sub=loaded,heat and '%'or nil,capacity and('/ '..capacity)or''
 local progress=fraction(m.fraction);local status='';local warning
 local counter_color,gauge_color,counter_pulse,gauge_pulse,status_pulse=nil,nil,1,1,1
 local animate=cfg.reduced_motion~=true
 local hz=finite(cfg.flash_hz)and math.max(.5,math.min(3,cfg.flash_hz))or 2
 local function pulse(rate,floor)return animate and floor+(1-floor)*(.5+.5*math.cos(clock*math.pi*2*rate))or 1 end
 if m.reloadable==false then sub='ONE SHOT' end
 if infinite then value=nil;sub='CONTINUOUS';unknown=false;progress=1 end
 if quasar then label=cooldown and 'COOLDOWN'or'CHARGE';reserve=nil end
 if active_charge and not unknown then
  value=math.floor(charge*100+.5);suffix='%';sub=quasar and ''or(tostring(loaded)..' LOADED');progress=charge;label='CHARGE'
  status=railgun and railgun.limit and 'LIMIT'or release and 'RELEASE'or
   railgun and railgun.ready and 'SAFE READY'or(m.charge_ready or charge>=1-1e-6)and'CHARGED'or charge>0 and'CHARGING'or''
  if railgun and railgun.remaining and not release then status=string.format('UNSAFE %.2fs',railgun.remaining)end
 elseif active_level and not unknown then
  value=math.floor(level);label='CHARGE LEVEL';suffix=nil;sub=tostring(loaded)..' LOADED';progress=nil;status='CHARGING'
 end
 if unknown then status='NO DATA';sub='';suffix=nil;progress=nil
 elseif cooldown then status='COOLING';suffix='%'
 elseif m.reloading==true or m.df_ejector_open==true then status='RELOADING'
 elseif empty then status=(m.state=='SPENT'or m.reloadable==false or m.recoilless_spent==true)and'SPENT'or'EMPTY';warning='red'
 elseif heat and not quasar then
  counter_color='heat_white'
  if m.state=='VENT'or m.locked==true then
   status='VENTING';warning='red';counter_color='heat_red';counter_pulse=pulse(2,.25);gauge_pulse=counter_pulse;status_pulse=counter_pulse
  elseif m.state=='HOT'or(progress and progress>=.85)then
   status='HOT';warning='red';counter_color='heat_red'
   if progress and progress>=.95 then
    counter_color=animate and math.floor(clock*hz*2)%2==1 and 'heat_yellow'or'heat_red'
    gauge_color=animate and math.floor(clock*16)%2==1 and 'heat_white'or'heat_red'
   end
  elseif progress and progress>=.65 then warning='gold';counter_color='heat_yellow'end
 elseif fuel and progress and progress<=.35 then
  status='LOW '..m.label;warning=progress<=.15 and'red'or'gold'
 elseif low and not active_charge and not active_level then status='LOW AMMO';warning='gold'
 elseif reminder then status='RELOAD ADVISED' end
 if not unknown and not empty then
  if reminder and not active_charge and not active_level then counter_pulse=pulse(hz,.35)end
  if railgun and m.safety_mode=='UNSAFE'and active_charge then
   if charge>=.85 then warning='red'elseif charge>=.7 then warning='gold'end
   if release or not railgun.remaining and m.charge_warning==true then
    warning='red';gauge_color=animate and math.floor(clock*8)%2==0 and'heat_yellow'or'heat_red'
    status_pulse=pulse(4,.35)
   end
  elseif railgun and railgun.ready then counter_color='heat_yellow'end
  if m.resource_hex=='fb3a19078694708a'and active_charge and charge>=1-1e-6 and m.charge_ready==true then
   counter_color='heat_yellow';counter_pulse=pulse(hz,.35)
  elseif m.resource_hex=='e8d5f49ad7780e54'and active_charge and charge>=1-1e-6 then
   warning='red';gauge_color='heat_red';gauge_pulse=pulse(4,.35);status_pulse=gauge_pulse
  end
 end
 if release then warning='red'end
 if empty then counter_color='heat_red'end
 if status==''and m.resource_hex=='11c27d3babb38956'and m.mg43_flash==true and cfg.mg43_easter_egg~=false then status='GET SOME!!!';status_pulse=pulse(hz,.35)end
 local heading=finite(m.compass_heading)and m.compass_heading%360 or nil
 if status==''and heading then
  local names={'N','NE','E','SE','S','SW','W','NW'}
  status=string.format('HDG %03d %s',math.floor(heading+.5)%360,names[math.floor((heading+22.5)/45)%8+1])
 end
 -- Count-driven indicators retain the existing state machines. These are
 -- observed loaded/spent states, not claims about physical casing occupancy.
 local slots
 if not unknown and m.resource_hex=='8d3d52a3b2f19402'and type(m.cylinder_slots)=='table'then
  local valid,total=true,0;slots={}
  for i=1,6 do local loaded_slot=m.cylinder_slots[i];if type(loaded_slot)~='boolean'then valid=false end
   total=total+(loaded_slot==true and 1 or 0)
   -- Upright Senator slot order differs from the rotating cylinder order;
   -- never borrow its spent-case latch to infer a physical chamber here.
   slots[i]={loaded=loaded_slot==true,spent=false,index=i}
  end
  if not valid or total~=loaded then slots=nil end
 elseif not unknown and m.resource_hex=='72170a55a1f37ff1'and loaded<=2 and type(m.df_shell_spent)=='table'then
  slots={};for i=1,2 do slots[i]={loaded=m.fire_mode=='VOLLEY'and loaded>=2 or m.fire_mode~='VOLLEY'and loaded>=3-i,
   spent=m.df_shell_spent[i]==true,index=i}end
 end
 local contexts={}
 local function context(kind,value)if type(value)=='string'and value~=''and value~='--'then contexts[#contexts+1]={kind=kind,value=value}end end
 context('AUTO',m.fire_mode)
 if finite(m.rpm)and m.rpm>=1 and m.rpm<=10000 and not quasar then context('RPM',math.floor(m.rpm+.5)..' RPM')end
 context('AMMO',m.ammo_mode);context('SAFE',m.safety_mode)
 if m.reloadable==false then context('SINGLE','SINGLE USE')end
 local name=HUD.weapon_names[m.resource_hex]or'WEAPON';local spec=HUD.segmented_primary_specs and HUD.segmented_primary_specs[m.resource_hex]
 local code=spec and spec.code or name:match('^%S+')or'WEAPON'
 -- The reader includes the chamber in loaded. Mark only its ones digit, and
 -- never apply the chamber tint to a replacement charge/heat readout.
 local chamber_digit=m.chamber_bonus==1 and loaded~=nil and capacity~=nil and loaded==capacity+1
  and not heat and not infinite and not active_charge and not active_level
 return {value=value,loaded=loaded,capacity=capacity,reserve=reserve,unit=m.reserve_kind,label=label,code=code,chamber_digit=chamber_digit,
  suffix=suffix,sub=sub,status=status,progress=progress,empty=empty,infinite=infinite,unknown=unknown,
  warning=warning,contexts=contexts,charge=active_charge and charge or nil,slots=slots,
  counter_color=counter_color,gauge_color=gauge_color,counter_pulse=counter_pulse,gauge_pulse=gauge_pulse,status_pulse=status_pulse,compass_heading=heading}
end
-- A key describes visible layout, not camera motion or shader animation time.
-- Callers own the returned commands and must not mutate them after caching.
function M.same_layout(a,b)
 if a==b then return true end
 if type(a)~='table'or type(b)~='table'then return false end
 for k,v in pairs(a)do if not M.same_layout(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end
 return true
end
function M.layout_key(m,c,opacity,clock,resource)
 if not M.selected(c)or not M.supported(m.resource_hex)then return nil end
 local settings={};for k,v in pairs(c)do if k~='style_clock'then settings[k]=v end end
 local images={}
 for _,name in ipairs({A.face,A.atlas,A.coverage,A.hard_coverage,M.dynamic_coverage,M.dynamic_face,M.dynamic_soft})do
  images[#images+1]=resource(name)or false
 end
 local r=M.readouts(m,c,clock)
 -- Only the formatted heading is drawn; sub-degree aim changes do not alter it.
 r.compass_heading=nil
 return {weapon=m.resource_hex,settings=settings,readouts=r,
  empty_phase=r.empty and math.floor(clock*4)%2 or 0,opacity=opacity,images=images}
end
function M.compose(m,x,y,s,opacity,cfg,clock,resource,can_get)
 if not m or not M.selected(cfg)or not M.supported(m.resource_hex)or not M.assets_ready(resource,can_get)then return nil end
 local r=M.readouts(m,cfg,clock);local inspect=cfg.split_readout_view=='inspect'
 local width,height=inspect and 410 or 320,inspect and 178 or 161
 if #r.contexts>4 then height=math.max(height,(inspect and 46 or 61)+(#r.contexts-1)*(inspect and 29 or 23)+25)end
 local white,gold,navy,red=color(cfg.text_color,WHITE),color(cfg.decoration_color,GOLD),color(cfg.background_color,NAVY),color(cfg.heat_red,RED)
 local yellow,heat_white=color(cfg.heat_yellow,gold),color(cfg.heat_white,white)
 local function signal(key,fallback)return key=='heat_red'and red or key=='heat_yellow'and yellow or key=='heat_white'and heat_white or fallback end
 local ink=signal(r.counter_color,r.warning=='red'and red or r.warning=='gold'and yellow or white)
 local fg=opacity*(cfg.text_opacity or 1)*(cfg.text_color_alpha or 255)/255
 local depth=finite(cfg.panel_spatial_depth)and math.max(0,math.min(32,cfg.panel_spatial_depth))or 16
 local depths={main=depth*s,reserve=-depth*.5*s,context=depth*1.8*s,status=0}
 local dynamic=resource(M.dynamic_coverage);local soft=resource(M.dynamic_soft)
 local coverage=dynamic and M.dynamic_coverage or(cfg.panel_edge_softness==0 and A.hard_coverage or A.coverage)
 local frame={type='panel',x=x,y=y,w=width*s,h=height*s,a=0,c={0,0,0},frosted=false,atlas_frame=true,
  split_hud=true,hud_texture_split=true,hud_texture_primary=true,world_reference_width=240*s/A.gameplay_scale,
  edge_mask_resource=soft and M.dynamic_soft or nil,edge_mask_material=A.material,
  edge_mask_box={x=x,y=y+(height-161)*s,w=320*s,h=161*s},spatial_plane='main',spatial_depth=depths.main}
 local out={frame}
 local function image(texture,uv,a,b,w,h,c,alpha,role,plane,layer)
  local q={type='texture',x=x+a*s,y=y+(height-b-h)*s,w=w*s,h=h*s,c=c,a=alpha,
   texture_material=A.material,texture_resource=texture,atlas_rect=uv,texture_theme=false,texture_layer=layer or 50,
   split_role=role,spatial_plane=plane or'main',spatial_depth=depths[plane or'main']}
  out[#out+1]=q;return q
 end
 -- Separate integer layers: native GUI sorting must not collapse fractional
 -- backing/foreground depths and blend the backing over individual digits.
 local carrier=image(coverage,A.full_uv,0,0,320,161,navy,opacity*(cfg.panel_opacity or.35),'backing','main',40)
 carrier.coverage_mask=true;carrier.texture_theme=nil;carrier.render_role='backing'
 local font=cfg.font or'hack';local font_scale=cfg.font_scale or 1
 local function text(a,b,str,size,c,role,plane,align,maxw)
  str=tostring(str);size=size*s*font_scale
  local l,bt,rr,tt=HUD.font.measure(str,size,font,true)
  if maxw and rr-l>maxw*s then size=size*maxw*s/(rr-l);l,bt,rr,tt=HUD.font.measure(str,size,font,true)end
  local tx=x+a*s;if align=='right'then tx=tx-rr elseif align=='center'then tx=tx-(l+rr)/2 end
  local ty=y+(height-b)*s
  out[#out+1]={type='text',x=tx,y=ty,text=str,size=size,font=font,c=c,a=fg,texture_readout=true,
   font_scale_applied=true,render_role='readout',readout_key=role,split_role=role,
   readout_zone={cx=tx+(l+rr)/2,cy=ty+(bt+tt)/2,w=math.max(.001,rr-l),h=math.max(.001,tt-bt)},
   spatial_plane=plane or'main',spatial_depth=depths[plane or'main']}
  return out[#out]
 end
 text(87,16,r.code,10,gold,'identity','main','left',140)
 text(87,43,r.label,11.5,gold,'unit','main','left',134)
 local pulse=r.empty and cfg.reduced_motion~=true and math.floor((clock or 0)*4)%2==1 and.22 or r.counter_pulse
 if r.infinite then
  local b=A.infinity_outline;local q=image(A.atlas,b.uv,88,61,b.w,b.h,NAVY,fg,'loaded','main',49);q.outline=true
  local a=A.infinity;image(A.atlas,a.uv,88,61,a.w,a.h,white,fg,'loaded')
 else
  local raw=r.value and tostring(r.value)or'--';local str=r.value and string.rep('0',math.max(0,2-#raw))..raw or raw
  if #str>3 then
   local q=text(88,101,raw,48,ink,'loaded','main','left',134);q.a=fg*pulse;q.last_digit_color=r.chamber_digit and gold or nil
  else for i=1,#str do
   local ch=str:sub(i,i);local column=tonumber(ch)or 10;local quiet=r.value~=nil and i<=#str-#raw
   local a=88+(i-1)*76*48/118
   local cell=r.chamber_digit and i==#str and gold or ink
   local q=image(A.atlas,A.digit_uv(column,quiet),a,53,72*48/118,48,cell,fg*pulse,'loaded');q.digit_character=ch;q.leading_zero=quiet
   q=image(A.atlas,quiet and A.quiet_zero_outline_uv or A.outline_uv(column),a,53,72*48/118,48,NAVY,fg*pulse,'loaded','main',49);q.outline=true;q.digit_character=ch
  end end
 end
 local digit_count=r.value and math.max(2,#tostring(r.value))or 2
 if r.suffix then text(88+(digit_count*76-5)*48/118+5,97,r.suffix,14,ink,'suffix')end
 text(222,122,r.sub,11,white,'capacity','main','right',134)
 local gauge=A.sprites.gauge;image(A.atlas,gauge.uv,87,109.5,136,10,white,fg,'gauge_inactive','main',49)
 if r.slots then
  local pitch=134/#r.slots
  for _,slot in ipairs(r.slots)do
   local q=image(A.atlas,A.sprites.solid.uv,88+(slot.index-1)*pitch,109.5,pitch-3,3,
    slot.loaded and gold or slot.spent and red or white,fg*(slot.loaded and 1 or slot.spent and.55 or.18),'gauge')
   q.ammo_slot=slot.index;q.slot_loaded=slot.loaded;q.slot_observed_spent=slot.spent;q.count_driven_slot=true
  end
 elseif r.progress and r.progress>0 then image(A.atlas,A.sprites.solid.uv,88,109.5,134*r.progress,3,signal(r.gauge_color,r.warning=='red'and red or gold),fg*r.gauge_pulse,'gauge')end
 if r.reserve~=nil then
  local sprite=A.sprites.reserve_connector;image(A.atlas,sprite.uv,61,78.5,12,3,gold,fg,'reserve','reserve')
  local icon=A.icons[r.unit]or A.icons[r.unit=='ROUNDS'and'SHELLS'or r.unit=='CANISTERS'and'TANKS'or'UNKNOWN']
  image(A.atlas,icon.uv,10-2*.9,48-2*.9,18*.9,18*.9,gold,fg,'reserve','reserve')
  text(29,71,r.reserve,29,white,'reserve','reserve','left',45)
  text(10,87,r.unit or'RES',11.5,white,'reserve','reserve','left',67)
 end
 local keys={AUTO='FIRE SELECT',RPM='FIRE RATE',AMMO='AMMUNITION',SAFE='SAFETY',SINGLE='SUPPLY'}
 for i,c in ipairs(r.contexts)do
  local baseline=(inspect and 46 or 61)+(i-1)*(inspect and 29 or 23)
  local node=inspect and A.inspect_context_nodes[c.kind]or A.context_nodes[c.kind]
  image(A.atlas,node.uv,node.box[1],baseline-(inspect and 13 or 13),node.box[3],node.box[4],gold,fg,'context','context').context_kind=c.kind
  if inspect then text(286,baseline-10,keys[c.kind],8.5,{147,170,189},'context','context','left',120)end
  if not inspect and #c.value>9 then
   local a,b=c.value:match('^(%S+)%s+(.+)$')
   text(264,baseline,a or c.value,11.5,gold,'context','context','left',55)
   if b then text(264,baseline+12,b,11.5,gold,'context','context','left',55)end
  else text(inspect and 286 or 264,baseline+(inspect and 3 or 0),c.value,11.5,gold,'context','context','left',inspect and 120 or 55)end
  out[#out].context_kind=c.kind
 end
 if r.status~=''then
  local c=r.warning=='red'and red or gold
  image(A.atlas,A.sprites.solid.uv,87,141,166,18,navy,fg*.58,'status','status',40)
  image(A.atlas,A.sprites.solid.uv,85.5,141,3,18,c,fg*r.status_pulse,'status','status')
  text(97,153.5,r.status,11.5,c,'status','status','left',153).a=fg*r.status_pulse
 end
 frame.split_decor_resource=resource(M.dynamic_face)and M.dynamic_face or A.face
 frame.split_scale=s
 out=HUD.layout.decorate_textures(out,s,cfg,opacity)
 return out
end
function M.decorate(out,frame,cfg,opacity)
 local s=frame.split_scale;local h=frame.h
 out[#out+1]={type='texture',x=frame.x,y=frame.y+h-161*s,w=320*s,h=161*s,c=color(cfg.decoration_color,GOLD),
  a=opacity*(cfg.text_color_alpha or 255)/255,texture_material=A.material,texture_resource=frame.split_decor_resource,
  atlas_rect=A.full_uv,texture_theme=false,texture_layer=49.2,decoration=true,split_role='decoration',
  spatial_plane='main',spatial_depth=frame.spatial_depth}
end
return M
