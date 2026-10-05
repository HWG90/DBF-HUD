local M={scope={['006e44327bb953fe']=true,['02eecd0b1fa49630']=true,['03e67a19b07c6523']=true,['05d8d8c073b9d502']=true,['05e4e5c2db6e44a2']=true,['076dd5d4f4360204']=true,['0807aea5217e4767']=true,['186ea95de7306b1a']=true,['1a437158e1b8d2a1']=true,['1abbff60d26ba391']=true,['25aa2fd4643cf4ee']=true,['27ee1ed8f6fb6356']=true,['295beb26dc4f8ff1']=true,['30061f91af477f5e']=true,['3575aabc5f1f9326']=true,['35a61296619cc47e']=true,['3c86e871923f3970']=true,['41eac4a03987faa0']=true,['43a58cb89cfa197c']=true,['43cb1033961a2276']=true,['46183b50961d1328']=true,['4ba41b6f9f405cc2']=true,['4c786785c79d44e7']=true,['4d58c77087b774c5']=true,['4e310b1fe4c52b52']=true,['4f749e2ee26f532d']=true,['52071f49263415e4']=true,['52cdbfbaca3cb397']=true,['5990123d142b16cb']=true,['5ebaea70c0d060b9']=true,['708ea298c82093d0']=true,['75816077c139c850']=true,['7617642765ac38c7']=true,['7b75e5132ffd4ca6']=true,['80f1a156d9fa1e36']=true,['8645f167b3c813a2']=true,['88c2d09ad85a7c9f']=true,['8d3d52a3b2f19402']=true,['90ddc374f4e3d756']=true,['94bd931b5fb4ee95']=true,['9571ca51f0daf35b']=true,['968211c0033dce64']=true,['96de9cd50f7306e6']=true,['9b75217d8312dd67']=true,['9eb160830321bfd6']=true,['a7ee1ebf58fcdf1f']=true,['a8a91eb54892b6b2']=true,['a955c4ea6f6d4203']=true,['aa69a60d74a3ec54']=true,['b0f1b354ba1d38d8']=true,['b16c9d490aa59b77']=true,['b6aff2195568767f']=true,['bc29613666df696b']=true,['be70ee0d8d44028e']=true,['bf4cfd2aeabfb5a4']=true,['c12a34f375bd5a87']=true,['c780bcd79547da0f']=true,['c85f576d5e086147']=true,['cc786f6491fe7e65']=true,['cdf28be026bb7d84']=true,['ce063aa33d95a812']=true,['cf5f176e0e322be1']=true,['cf8934ff6567a42d']=true,['d323de60855898ac']=true,['d54b9505c0f72873']=true,['d6b1fb05b9109353']=true,['dbb6c961c59fadc1']=true,['dcd1c835407ef7ba']=true,['de18775fa447a9bf']=true,['e3b6aedd07fcb464']=true,['e8d5f49ad7780e54']=true,['e91f569c2ad8af01']=true,['eea5e3cef1e12c14']=true,['f0338468dcdb6a6c']=true,['f49227a0630a3f7f']=true,['f992ce97577c8a7f']=true,['fb3a19078694708a']=true,['fcd8a6e67eac635a']=true,['fe3b29b2cfa63f9b']=true}}
M.enabled=false
-- Presentation-only proposal; deployment approval was revoked. Readers, state tracking and accepted panels remain authoritative.
function M.eligible(id) return M.scope[id]==true end
local steel,silver,brass={24,31,36},{198,210,218},{218,172,78}
local icons={rifle='RIFLE_SEMI',precision='AMENDMENT_CARTRIDGE',sidearm='SIDEARM_CARTRIDGE',compact='SIDEARM_CARTRIDGE',belt='LINKED_BELT',shotgun='BARREL_SHELL',explosive='GL_GRENADE',rocket='MISSILE_SIDE',laser='ENERGY_CELL',plasma='PLASMA',arc='ARC_EMBLEM',dart='BOLT',tool='TOOL_BLADE',medical='STIM_DART'}
function M.compose(original,m,scale,cfg,opacity,style,measure,decorate)
 local first=original[1];if not first or first.type~='panel' then return original end
 local x,y=first.x,first.y
 local out={}
 local function rect(dx,dy,w,h,c,a)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=w*scale,h=h*scale,c=c,a=opacity*(a or 1)}
 end
 local function text(t,dx,dy,size,c,label)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=t:match('^%d%d%d')~=nil,weapon_label=label or nil}
 end
 local name=style.model or style.name
 local function heading(w,h)
  local size=math.min(10,(w-18)*1.5/#name)
  text(name,9,h-16,size,brass,true);rect(8,h-21,w-16,1,brass,.65)
 end
 -- Keep all native heat/charge and programmable-ammunition controls in their existing arrangement.
 local special=m.kind=='heat' or m.chamber_bonus or m.ammo_mode or m.safety_mode or m.charge_fraction~=nil or m.charge_ready or (m.kind=='infinite' and style.family~='tool')
 if special then
  for _,v in ipairs(original) do if not v.decoration then
   if v.type=='panel' then v.c=steel end
   out[#out+1]=v
  end end
  first.shared_suite=true;first.weapon_theme=style.family
  first.h=first.h+24*scale
  heading(first.w/scale,first.h/scale)
  for _,v in ipairs(out) do if v.type=='panel' then decorate(out,v,scale,cfg,opacity) end end
  return out
 end
 local w,h=150,100
 out={{type='panel',shared_suite=true,weapon_theme=style.family,x=x,y=y,w=w*scale,h=h*scale,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted}}
 heading(w,h)
 local color=HUD.config.rgb(cfg[m.warning and (m.value==0 and 'heat_red' or 'heat_yellow') or 'text_color'])
 local melee=style.family=='tool' and m.kind=='infinite'
 local single=m.capacity==1 and (m.kind=='rounds' or m.kind=='magazine')
 text(melee and 'READY' or single and (m.value>0 and 'LOADED' or 'EMPTY') or type(m.value)=='number' and string.format('%03d',m.value) or tostring(m.value),10,(single or melee) and 49 or 40,(single or melee) and 12 or 36,color)
 local key=m.ammo_icon or icons[style.family]
 if style.family=='rifle' or style.family=='precision' then key=(m.fire_mode=='AUTO' or m.fire_mode=='BURST') and 'RIFLE_AUTO' or 'AMENDMENT_CARTRIDGE' end
 if style.family=='tool' then local n=name:lower();key=n:find('hatchet',1,true) and 'TOOL_HATCHET' or n:find('flag',1,true) and 'TOOL_FLAG' or n:find('c4',1,true) and 'TOOL_PACK' or n:find('stun',1,true) and 'TOOL_BATON' or 'TOOL_BLADE' end
 local icon=HUD.fire_icons[key] or HUD.fire_icons[icons[style.family]] or HUD.fire_icons.BULLET
 if icon then
  local factor=math.min(38/icon.w,38/icon.h);local ix=115-icon.w*factor/2;local iy=54-icon.h*factor/2
  for _,r in ipairs(icon.runs) do
   local c=r[5] or brass
   if style.family=='shotgun' then c=r[2]<9 and brass or {65,145,235} end
   rect(ix+r[1]*factor,iy+r[2]*factor,r[3]*factor,r[4]*factor,c,m.value==0 and .18 or 1);out[#out].mode_icon=true
  end
 end
 local fill=math.max(0,math.min(1,m.fraction or 0))
 if not melee then for i=0,14 do rect(10+i*8.6,28,6.6,3,i<math.ceil(fill*15) and brass or silver,i<math.ceil(fill*15) and 1 or .18) end end
 local reserve=melee and 'TOOL' or m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'RESERVE') or '-- '..(m.reserve_kind or 'RESERVE')
 text(reserve,10,13,math.min(12,130*1.5/#reserve),silver);rect(8,8,w-16,1,silver,.25)
 decorate(out,out[1],scale,cfg,opacity)
 local children={}
 for _,v in ipairs(original) do if v.child and not v.decoration then children[#children+1]=v end end
 local child=children[1]
 if child and child.type=='panel' then
  local dx=x+w*scale/2-(child.x+child.w/2);local dy=y-2*scale-child.h-child.y
  for _,v in ipairs(children) do v.x=v.x+dx;v.y=v.y+dy;v.c=v.type=='panel' and steel or silver;out[#out+1]=v end
  child.x=x;child.w=w*scale
  local group={};decorate(group,child,scale,cfg,opacity)
  for _,v in ipairs(group) do v.child=true;out[#out+1]=v end
 end
 return out
end
return M
