-- Vertical Simple review candidate. Texture-free; top-left coordinates.
local M={width=64,height=86}
local function number(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
function M.compose(m,x,y,w,h,alpha,cfg,measure)
 m=m or {};cfg=cfg or {};x=x or 0;y=y or 0;w=w or 64;h=h or 86;alpha=alpha or 1
 local q={};local fg=cfg.text_color or {224,225,208};local accent=cfg.accent_color or {206,191,130};local bg=cfg.backing_color or {27,34,36}
 local function rect(a,b,c,d,color,opacity)q[#q+1]={type='rect',x=x+a*w/64,y=y+b*h/86,w=c*w/64,h=d*h/86,c=color,a=alpha*opacity}end
 local fs=math.max(.5,math.min(1.5,tonumber(cfg.font_scale)or 1))
 local function text(a,b,size,str,maxw,color)
  str=tostring(str);size=size*fs;local tw=measure and measure(str,size)or #str*size*.6
  if tw>maxw then size=size*maxw/tw end
  q[#q+1]={type='text',x=x+a*w/64,y=y+b*h/86,size=size*h/86,text=str,c=color or fg,a=alpha,font=cfg.font or 'bigblue'}
 end
 local opacity=math.max(0,math.min(1,tonumber(cfg.backing_opacity)or .22))
 if opacity>0 then rect(2,1,60,84,bg,opacity);rect(0,3,2,80,bg,opacity);rect(62,3,2,80,bg,opacity)end
 rect(5,15,54,.35,accent,.65)
 text(5,5,3.8,m.short_name or m.weapon_name or 'WEAPON',54,accent)
 local count=type(m.value_readout)=='string'and m.value_readout or number(m.value)and tostring(math.max(0,m.value))or number(m.feed_rounds)and tostring(math.max(0,m.feed_rounds))or '--'
 text(5,21,16,count,cfg.ammo_semantics=='double_freedom'and 34 or 54)
 text(5,40,4.5,m.capacity_readout or cfg.ammo_semantics=='backpack_feed'and 'FEED' or number(m.capacity)and '/ '..m.capacity or '/ --',54)
 if cfg.ammo_semantics=='double_freedom' then
  for side=1,2 do
   local state=m.shell_states and m.shell_states[side]or 'unknown'
   local color=state=='spent'and {164,113,69}or accent
   local op=state=='loaded'and 1 or state=='spent'and .42 or state=='unloaded'and .10 or .20
   rect(46,23+(side-1)*8,10,4,color,op)
  end
 end
 local reserve='RES --'
 if type(m.reserve_readout)=='string'then reserve=m.reserve_readout
 elseif number(m.reserve_magazines)then reserve=string.format('%d MAGS',m.reserve_magazines)
 elseif number(m.reserve_shells)then reserve=string.format('%d SHELLS',m.reserve_shells)
 elseif number(m.reserve_rounds)then reserve=string.format('%d RDS',m.reserve_rounds)
 elseif cfg.ammo_semantics=='backpack_feed'then reserve='BACKPACK'
 elseif cfg.ammo_semantics=='expendable'then reserve=number(m.spare_units)and string.format('%d SPARE UNITS',m.spare_units)or 'SPARE --'end
 text(5,50,5.5,reserve,54)
 text(5,62,5.8,cfg.ammo_semantics=='expendable'and 'SINGLE USE'or m.fire_mode or '--',54,accent)
 local state=m.ammo_name or m.chamber_status or m.reload_status
 if state then text(5,75,3.6,state,54)end
 return q
end
return M