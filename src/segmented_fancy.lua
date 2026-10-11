-- Approved primary HUD Texture artwork. Cached face/digit textures, native labels.
-- Bottom-left output coordinates; unavailable artwork returns nil for the owner.
-- Composition has no intrinsic perimeter decoration or special renderer flags.
local M={width=174,height=304,empty_flash_hz=2,specs=HUD.segmented_primary_specs,
 face='mods/dbf_hud/textures/segmented_fancy_face_v4',atlas='mods/dbf_hud/textures/segmented_fancy_atlas_v4',
 full_white='mods/dbf_hud/textures/primary_full_white_v1',
 edge_masks={[4]='mods/dbf_hud/textures/primary_edge_mask_v1_04',[8]='mods/dbf_hud/textures/primary_edge_mask_v1_08',[12]='mods/dbf_hud/textures/primary_edge_mask_v1_12'},
 material='mods/dbf_hud/materials/adjudicator_tall_v1'}
local WHITE={245,246,240};local GOLD={233,196,93};local NAVY={9,27,53};local MUTED={40,69,104};local RED={255,87,80}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.edge_softness(value)return HUD.edge_mask.settings({panel_edge_softness=value}).width end
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function count(v)return finite(v)and v>=0 and v<=100000 and math.floor(v)or nil end
local function fraction(v)return finite(v)and v>=0 and v<=1 and v or nil end
local function color(v,fallback)
 if type(v)=='table'and finite(v[1])and finite(v[2])and finite(v[3])then return {clamp(v[1],0,255),clamp(v[2],0,255),clamp(v[3],0,255)}end
 if type(v)=='string'then local h=v:gsub('^#','');if #h==6 and h:match('^%x+$')then return {tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)}end end
 return fallback
end
local face_uv={32/256,32/512,174/256,304/512}
local solid_uv={988/1024,16/512,16/1024,16/512}
local gauge_uv={16/1024,192/512,160/1024,7/512}
local loaded_ghost_uv={256/1024,256/512,154/1024,78/512}
local mode_active_uv={448/1024,256/512,49/1024,22/512}
local function digit_uv(column)return {(8+80*column)/1024,8/512,72/1024,118/512}end
function M.ready(id,cfg)return M.specs[id]~=nil and(not cfg or(cfg.presentation_view~='third' and cfg.hud_presentation~='practical'))end
function M.assets_ready(resource,can_get)
 if type(resource)~='function'or(can_get~=nil and(type(can_get)~='function'or can_get('material',M.material)~=true))then return false end
 local face,atlas=resource(M.face),resource(M.atlas)
 return face~=nil and face~=false and atlas~=nil and atlas~=false
end
function M.readouts(m,spec)
 local heat=m.kind=='heat';local infinite=m.kind=='infinite'
 local loaded=not infinite and count(m.value)or nil;local capacity=count(m.capacity);local reserve=count(m.reserve)
 local empty=not heat and not infinite and loaded==0
 local q=spec.charge_field and fraction(m[spec.charge_field])or nil
 local progress=not infinite and fraction(m.fraction)or nil
 local low=not heat and not infinite and not empty and loaded~=nil and capacity~=nil and capacity>0 and loaded/capacity<=.2
 local label=heat and 'HEAT'or infinite and 'ARC'or m.label=='FUEL'and 'FUEL'or 'LOAD'
 local status=loaded==nil and not infinite and 'NO DATA'or empty and (m.state=='SPENT'and 'SPENT'or 'EMPTY')or low and 'LOW AMMO'or ''
 if m.reloading==true or m.df_ejector_open==true then status='RELOADING'
 elseif q and(q>0 or m.charge_ready)then status=(m.charge_ready or q>=1)and 'CHARGED'or('CHARGE '..math.floor(q*100+.5)..'%');progress=q
 elseif heat and m.state and m.state~='READY'then status=m.state
 elseif infinite and m.state and m.state~='READY'then status=m.state
 elseif m.chamber_bonus==1 and loaded and capacity and loaded==capacity+1 then status='CHAMBERED +1' end
 return {loaded=loaded,capacity=capacity,reserve=reserve,unit=type(m.reserve_kind)=='string'and m.reserve_kind or 'RES',heat=heat,infinite=infinite,empty=empty,low=low,label=label,status=status,progress=progress,charge=q,mode=m.ammo_mode or m.fire_mode or m.safety_mode or '--'}
end
function M.compose(m,x,y,s,opacity,cfg,clock,resource,can_get)
 cfg=cfg or {};if not m or not M.ready(m.resource_hex,cfg)or not M.assets_ready(resource,can_get)then return nil end
 x=x or 0;y=y or 0;s=s or 1;opacity=clamp(finite(opacity)and opacity or 1,0,1);clock=finite(clock)and clock or 0
 assert(finite(x)and finite(y)and finite(s)and s>0,'invalid segmented geometry')
 local spec=M.specs[m.resource_hex];local r=M.readouts(m,spec)
 local white=color(cfg.text_color,WHITE);local gold=color(cfg.decoration_color,GOLD);local bg=color(cfg.background_color,NAVY)
 local red=color(cfg.heat_red,RED);local low=color(cfg.heat_yellow,gold)
 local fg=opacity*clamp(finite(cfg.text_opacity)and cfg.text_opacity or 1,0,1)*clamp(finite(cfg.text_color_alpha)and cfg.text_color_alpha/255 or 1,0,1)
 local backing=clamp(finite(cfg.panel_opacity)and cfg.panel_opacity or .25,0,1)
 local out={{type='panel',x=x,y=y,w=M.width*s,h=M.height*s,c=bg,a=0,frosted=false,atlas_frame=true,mechanical_art=true,hud_texture_primary=true,world_reference_width=M.width*s}}
 local function image(texture,uv,a,b,w,h,c,alpha,role,layer,lit,leading,character,column)
  out[#out+1]={type='texture',x=x+(a-18)*s,y=y+(M.height-(b-25)-h)*s,w=w*s,h=h*s,c=c,a=alpha,
   texture_material=M.material,texture_resource=texture,atlas_rect=uv,texture_layer=layer,mechanical_art=true,
   coverage_mask=role=='backing' or nil,render_role=role=='backing' and 'backing' or 'artwork',
   segmented_role=role,segment_lit=lit,leading_zero=leading,digit_character=character,atlas_column=column}
 end
 local white_ready=resource(M.full_white)
 local edge_resource=M.edge_softness(cfg.panel_edge_softness)>0 and HUD.edge_mask.resource
 local edge_ready=edge_resource and resource(edge_resource)
 if edge_ready~=nil and edge_ready~=false then out[1].edge_mask_resource=edge_resource;out[1].edge_mask_material=M.material end
 image(edge_ready~=nil and edge_ready~=false and edge_resource or white_ready~=nil and white_ready~=false and M.full_white or M.atlas,
  (edge_ready~=nil and edge_ready~=false or white_ready~=nil and white_ready~=false)and {0,0,1,1} or solid_uv,
  18,25,M.width,M.height,bg,opacity*backing,'backing',49)
 image(M.face,face_uv,18,25,M.width,M.height,gold,fg,'face',49.01)
 local font=cfg.font or 'bigblue';local font_scale=clamp(finite(cfg.font_scale)and cfg.font_scale or 1,.5,1.5)
 local function measure(str,size)
  if HUD.font and HUD.font.measure then return HUD.font.measure(str,size,font,true)end
  return 0,0,#str*size*.6,size
 end
 -- Labels use the approved SVG baselines; texture cells remain top-left boxes.
 local function text(a,b,w,h,size,str,c,role,align,alpha,lit,top_aligned)
  str=tostring(str);size=size*font_scale*s
  local l,bottom,right,top=measure(str,size);size=size*math.min(1,w*s/math.max(.001,right-l),h*s/math.max(.001,top-bottom))
  l,bottom,right,top=measure(str,size)
  local tx=x+(a-18)*s-l;if align=='right'then tx=x+(a-18+w)*s-right
  elseif align=='center'then tx=x+(a-18+w/2)*s-(l+right)/2 end
  local ty=y+(M.height-(b-25))*s-(top_aligned and top or 0)
  out[#out+1]={type='text',x=tx,y=ty,text=str,size=size,font=font,c=c,a=fg*(alpha or 1),
   texture_readout=true,render_role='readout',readout_key=role,
   readout_zone={cx=tx+(l+right)/2,cy=ty+(bottom+top)/2,w=math.max(.001,right-l),h=math.max(.001,top-bottom)},
   segmented_role=role,font_scale_applied=true,segment_lit=lit}
 end
 local pulse=1
 if r.empty and cfg.reduced_motion~=true and math.floor(clock*M.empty_flash_hz*2)%2==1 then pulse=.22 end
 local ink=r.empty and red or r.low and low or r.heat and m.warning and red or white
 local function digits(value,slots,a,b,w,h,c,role)
  local raw=value~=nil and tostring(value)or string.rep('-',slots);local str=value~=nil and string.rep('0',math.max(0,slots-#raw))..raw or raw
  -- Exceptional wide values remain exact without exceeding the renderer's 24 images.
  if #str>slots then text(a,b+h,w,h,h*.8,raw,c,role,'right',role=='loaded'and pulse or 1,true);return end
  local n=#str;local full=n*72+(n-1)*7;local scale=math.min(w/full,h/118);local start=a+(w-full*scale)/2;local leading=value~=nil and n-#raw or 0
  if role=='loaded'then image(M.atlas,loaded_ghost_uv,a,b,w,h,MUTED,fg*.18,role..'_ghost',49.02,false,false,'888',11)end
  for i=1,n do
   local character=str:sub(i,i);local column=tonumber(character)or 10;local lead=i<=leading;local base=start+(i-1)*79*scale
   if role~='loaded'then image(M.atlas,digit_uv(11),base,b,72*scale,118*scale,MUTED,fg*.18,role..'_ghost',49.02,false,lead,'8',11)end
   local alpha=lead and .14 or 1;if role=='loaded'then alpha=alpha*pulse end
   local cell=c
   if role=='loaded'and i==n and m.chamber_bonus==1 and r.loaded and r.capacity and r.loaded==r.capacity+1 then cell=gold end
   image(M.atlas,digit_uv(column),base,b,72*scale,118*scale,cell,fg*alpha,role,49.03,true,lead,character,column)
  end
 end
 text(25,44,52,10,10,spec.code,gold,'identity')
 text(80,44,104,10,9,spec.name,white,'name','right')
 text(25,67,160,9,9,r.label,gold,'loaded_label')
 digits(r.loaded,3,28,87,154,78,ink,'loaded')
 image(M.atlas,solid_uv,25,184,3,14,gold,fg*(r.status~=''and 1 or .15),'status_indicator',49.03)
 text(34,194,151,10,9,r.status,gold,'status')
 text(25,218,100,11,10,r.heat and 'UNIT'or r.infinite and 'SUPPLY'or 'CAP',gold,'capacity_label')
 if r.heat then text(136,228,49,22,16,'%',gold,'capacity','right')
 elseif r.infinite then text(136,228,49,22,14,'--',gold,'capacity','right')
 else digits(r.capacity,3,136,206,49,22,gold,'capacity')end
 local progress=r.progress
 image(M.atlas,gauge_uv,25,231,160,7,MUTED,fg*.35,'gauge_inactive',49.02)
 if progress and progress>0 then image(M.atlas,{gauge_uv[1],gauge_uv[2],gauge_uv[3]*progress,gauge_uv[4]},25,231,160*progress,7,gold,fg,'gauge',49.03,true)end
 text(25,260,105,10,9,'RESERVE',gold,'reserve_label')
 text(25,278,100,12,10,r.unit,white,'reserve_unit')
 digits(r.reserve,2,132,250,53,33,white,'reserve')
 text(25,296,160,9,9,'MODE',gold,'mode_label')
 local selected=false
 for i,mode in ipairs({'AUTO','BURST','SEMI'})do
  local on=r.mode==mode;selected=selected or on
  text(25+(i-1)*55,313,48,12,9,mode,on and gold or MUTED,'mode','center',on and 1 or .55)
  out[#out].mode_active=on
  if on then
   -- Outline at x25/y301 and underline at y321 share one cached image.
   image(M.atlas,mode_active_uv,24.5+(i-1)*55,300.5,49,22,gold,fg,'mode_underline',49.03)
   out[#out].mode_active=true
  end
 end
 -- A native mode outside the visual bank stays explicit; nothing is selected.
 if not selected then text(80,296,104,9,9,r.mode,gold,'mode','right');out[#out].mode_active=false end
 return out
end
return M
