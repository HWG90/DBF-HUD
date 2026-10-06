-- Selected square instrument: chamber channels, reserve and one active mode.
-- Geometry is cached; only state selection and fitted readouts change per frame.
local M={version='square-v4',width=120,height=120}
local C={face={25,35,32},edge={100,114,105},line={60,81,67},ink={231,236,217},muted={145,162,149},ready={183,214,175},spent={211,175,118}}
local function rect(out,x,y,w,h,c,a)out[#out+1]={x=x,y=120-y-h,w=w,h=h,c=c,a=a or 1}end
local function ring(out,cx,cy,r,thickness,c)
 local step=1.2;local inner=math.max(0,r-thickness)
 for top=-r,r-.001,step do
  local height=math.min(step,r-top);local yy=top+height*.5
  local outer=math.sqrt(math.max(0,r*r-yy*yy));local hole=math.abs(yy)<inner and math.sqrt(math.max(0,inner*inner-yy*yy)) or 0
  if hole>0 then rect(out,cx-outer,cy+top,outer-hole,height,c);rect(out,cx+hole,cy+top,outer-hole,height,c)
  else rect(out,cx-outer,cy+top,outer*2,height,c)end
 end
end
local static={}
rect(static,0,0,120,120,C.face,.92)
for _,b in ipairs({{0,0,120,1},{0,119,120,1},{0,0,1,120},{119,0,1,120}})do rect(static,b[1],b[2],b[3],b[4],C.edge)end
for _,b in ipairs({{3,3,114,.5},{3,116.5,114,.5},{3,3,.5,114},{116.5,3,.5,114},{12,25,96,.5},{12,90,96,.5}})do rect(static,b[1],b[2],b[3],b[4],C.line)end
rect(static,63,96,47,18,{37,56,42})
for _,b in ipairs({{63,96,47,.6},{63,113.4,47,.6},{63,96,.6,18},{109.4,96,.6,18}})do rect(static,b[1],b[2],b[3],b[4],{137,169,132})end
local states={}
for _,key in ipairs({'READY','FIRED','OPEN','UNKNOWN'})do
 local shape={};local color=key=='READY' and C.ready or key=='FIRED' and C.spent or C.muted
 ring(shape,0,53,21,.5,C.line);ring(shape,0,53,18,1.3,color)
 if key=='READY' then ring(shape,0,53,6,6,color);ring(shape,0,53,2,2,C.face)
 elseif key=='FIRED' then
  ring(shape,0,53,6,1,C.line)
  for i=-8,8,1 do rect(shape,i-.6,53-i-.6,1.2,1.2,color)end
 elseif key=='OPEN' then rect(shape,-7,57.4,14,1.2,color);rect(shape,-.6,46,1.2,12,color)end
 states[key]=shape
end
local function finite(v)return type(v)=='number' and v==v and math.abs(v)<math.huge end
function M.compose(m,x,y,s,opacity,cfg,measure)
 if cfg.weapon_panel_overrides then local merged={};for k,v in pairs(cfg)do merged[k]=v end;for k,v in pairs(cfg.weapon_panel_overrides)do merged[k]=v end;cfg=merged end
 measure=measure or HUD.font.measure;local alpha=opacity*(cfg.text_opacity or 1)
 local out={{type='panel',x=x,y=y,w=120*s,h=120*s,c=C.face,a=0,frosted=false,neo_panel=true,atlas_frame=true,df_instrumentation=true,world_reference_width=240*s}}
 local function append(shape,dx,role)
  for _,q in ipairs(shape)do out[#out+1]={type='rect',x=x+(q.x+dx)*s,y=y+q.y*s,w=q.w*s,h=q.h*s,c=q.c,a=opacity*q.a*(role=='face' and (cfg.panel_opacity or 1) or 1),contrast_backing=true,df_instrumentation=true,render_role=role}end
 end
 append(static,0,'face')
 local function text(value,cx,cy,height,width,c)
  local font=cfg.font or 'departuremono';local l,b,r,t=measure(value,s,font,true)
  local size=s*math.min(width*s/math.max(.001,r-l),height*s/math.max(.001,t-b));l,b,r,t=measure(value,size,font,true)
  out[#out+1]={type='text',text=value,x=x+cx*s-(l+r)/2,y=y+(120-cy)*s-(b+t)/2,size=size,font=font,c=c or C.ink,a=alpha,mechanical_live=true,texture_readout=true,readout_zone={cx=x+cx*s,cy=y+(120-cy)*s,w=width*s,h=height*s},df_instrumentation=true}
 end
 text('DBS-2',60,14,9,75,C.muted)
 for side,cx in ipairs({33,87})do
  local known=finite(m.value)
  local key=m.df_ejector_open and 'OPEN' or not known and 'UNKNOWN' or ((m.df_shell_spent or {})[side] or m.value<3-side) and 'FIRED' or 'READY'
  append(states[key],cx,'chamber-'..side..'-'..key)
  if key=='UNKNOWN' then text('?',cx,53,14,15,C.muted)end
  text(side==1 and 'L' or 'R',cx,80,8,10,C.muted)
 end
 text(finite(m.reserve) and ('R'..math.max(0,math.floor(m.reserve))) or 'R--',34,105,16,46,C.ink)
 text(m.fire_mode=='SEMI' and 'SEMI' or m.fire_mode=='VOLLEY' and 'VOLLEY' or '--',86.5,105,9,43,C.ready)
 return out
end
return M
