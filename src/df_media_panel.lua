-- Designer receiver-shaped Double Freedom: static frame, Lua state/readouts.
local M={width=128,height=96,texture='mods/dbf_hud/textures/df_media_receiver_frame',material='mods/dbf_hud/materials/mechanical_72170a55a1f37ff1'}
local C={face={25,27,26},steel={159,163,155},gold={150,133,92},rim={179,175,155},ink={191,193,180},ready={213,202,155},fired={62,30,26},unknown={101,106,101}}
local outline={{6,24},{6,19},{18,10},{35,10},{39,4},{50,4},{53,13},{75,13},{78,4},{89,4},{93,10},{110,10},{122,19},{122,66},{111,75},{109,83},{102,89},{89,89},{86,85},{42,85},{39,89},{25,89},{18,83},{16,75},{6,66}}
local static={}
local function box(out,x,y,w,h,c,a,role)out[#out+1]={type='rect',x=x,y=96-y-h,w=w,h=h,c=c,a=a or 1,render_role=role}end
local function segment(out,a,b,width,c)
 local dx,dy=b[1]-a[1],b[2]-a[2];local length=math.sqrt(dx*dx+dy*dy);local nx,ny=-dy/length*width/2,dx/length*width/2
 out[#out+1]={type='rect',x=math.min(a[1],b[1])-width,y=96-math.max(a[2],b[2])-width,w=math.abs(dx)+2*width,h=math.abs(dy)+2*width,c=c,a=1,quad={{a[1]+nx,96-a[2]-ny},{b[1]+nx,96-b[2]-ny},{b[1]-nx,96-b[2]+ny},{a[1]-nx,96-a[2]+ny}}}
end
local function ring(out,cx,cy,r,width,c)
 for i=0,31 do local a=i*math.pi/16;local b=(i+1)*math.pi/16;segment(out,{cx+r*math.cos(a),cy+r*math.sin(a)},{cx+r*math.cos(b),cy+r*math.sin(b)},width,c)end
end
local function disc(out,cx,cy,r,c,a)
 for top=-r,r-.001,1 do local h=math.min(1,r-top);local yy=top+h/2;local half=math.sqrt(math.max(0,r*r-yy*yy));box(out,cx-half,cy+top,half*2,h,c,a)end
end
-- Raster spans fill a concave receiver outline without unsupported polygon APIs.
for y=4,89 do local hits={};local scan=y+.5
 for i,p in ipairs(outline)do local q=outline[i%#outline+1];if (p[2]<=scan and q[2]>scan)or(q[2]<=scan and p[2]>scan)then hits[#hits+1]=p[1]+(scan-p[2])*(q[1]-p[1])/(q[2]-p[2])end end
 table.sort(hits);for i=1,#hits,2 do box(static,hits[i],y,hits[i+1]-hits[i],1,C.face,.92)end
end
for i,p in ipairs(outline)do segment(static,p,outline[i%#outline+1],.8,C.steel)end
for _,cx in ipairs({42,87})do disc(static,cx,43,22,{15,17,17},.95);ring(static,cx,43,22,.7,C.steel);ring(static,cx,43,20.5,.8,C.gold)end
box(static,24,76,80,.6,C.steel);box(static,64,77,.5,8,C.gold)
function M.ready(resource)return resource(M.texture)~=nil end
local function finite(x)return type(x)=='number'and x==x and math.abs(x)<math.huge end
function M.compose(m,x,y,s,opacity,cfg,measure,primitive)
 measure=measure or HUD.font.measure;local own=cfg.weapon_panel_overrides or {};local face=own.background_color and HUD.config.rgb(own.background_color)or C.face;local trim=own.decoration_color and HUD.config.rgb(own.decoration_color)or C.gold;local ink=own.text_color and HUD.config.rgb(own.text_color)or C.ink;local out={{type='panel',x=x,y=y,w=128*s,h=96*s,c=face,a=0,frosted=false,mechanical_art=true,df_media=true,world_reference_width=256*s,shader_mask={{.1,.22,.8,.49}}}}
 local function append(shape)
  for _,v in ipairs(shape)do local q={};for k,value in pairs(v)do q[k]=value end;q.x=x+v.x*s;q.y=y+v.y*s;q.w=v.w*s;q.h=v.h*s;q.a=v.a*opacity;q.df_media=true;q.contrast_backing=true;if v.c==C.face then q.c=face elseif v.c==C.gold or v.c==C.steel then q.c=trim end
   if v.quad then q.quad={};for i,p in ipairs(v.quad)do q.quad[i]={x+p[1]*s,y+p[2]*s}end end;out[#out+1]=q
  end
 end
 if primitive then append(static)else out[#out+1]={type='texture',x=x,y=y,w=128*s,h=96*s,c={255,255,255},a=opacity*(cfg.panel_opacity or 1)*.88,texture_material=M.material,texture_resource=M.texture,texture_theme=false,texture_layer=49,df_media=true}end
 local function text(value,cx,cy,height,width,c)
  local font=cfg.font or 'departuremono';local l,b,r,t=measure(value,s,font,true);local size=s*math.min(width*s/math.max(.001,r-l),height*s/math.max(.001,t-b));l,b,r,t=measure(value,size,font,true)
  out[#out+1]={type='text',text=value,x=x+cx*s-(l+r)/2,y=y+(96-cy)*s-(b+t)/2,size=size,font=font,c=own.text_color and ink or c or ink,a=opacity*(cfg.text_opacity or 1),texture_readout=true,readout_zone={cx=x+cx*s,cy=y+(96-cy)*s,w=width*s,h=height*s},df_media=true}
 end
 text('DBS-2',64,20,5,29,C.steel)
 for side,cx in ipairs({42,87})do
  local known=finite(m.value);local unavailable=known and ((m.df_shell_spent or {})[side]or m.value<3-side);local shape={}
  if m.df_ejector_open then ring(shape,cx,43,5,.6,C.unknown)
  elseif not known then text('?',cx,43,8,9,C.unknown)
  elseif unavailable then disc(shape,cx,43,5,C.fired,1)
  else disc(shape,cx,43,7,C.ready,.12);disc(shape,cx,43,5.8,C.ready,1);disc(shape,cx,43,4.4,{222,215,183},1)end
  append(shape)
 end
 text(m.fire_mode=='SEMI'and 'SEMI'or m.fire_mode=='VOLLEY'and 'VOLLEY'or '--',42,82,7,32,C.gold)
 text(finite(m.reserve)and tostring(math.max(0,math.floor(m.reserve)))or '--',89,81,10,25)
 text('RES',108,82,4,13,C.steel)
 return out
end
return M
