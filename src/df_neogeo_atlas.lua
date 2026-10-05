local M={}
local base='mods/dbf_hud/textures/'
local material='mods/dbf_hud/materials/mechanical_72170a55a1f37ff1'
local resources={shells=base..'df_neogeo_shell_states_v2',backing=base..'df_neogeo_backing_preview_v2',rim=base..'df_neogeo_rim_neutral'}
-- The runtime and renderer share these resource identities.
function M.ready(resource)
 for _,name in pairs(resources)do if not resource(name)then return false end end
 return true
end
local regions={loaded={0,0,1/3,1},spent={1/3,0,1/3,1},empty={2/3,0,1/3,1}}
function M.compose(m,x,y,s,opacity,cfg,measure)
 measure=measure or HUD.font.measure
 local ta=opacity*(cfg.text_opacity or 1)
 local pa=opacity*(cfg.panel_opacity or 1)
 local ink=HUD.config.rgb(cfg.text_color or '#FFFFFF')
 local glow=HUD.config.rgb(cfg.background_color or '#FFFFFF')
 local font=cfg.font or 'bigblue'
 local out={{type='panel',x=x,y=y,w=160*s,h=124*s,c={0,0,0},a=0,frosted=false,mechanical_art=true,atlas_frame=true}}
 local function image(name,uv,dx,dy,w,h,a,c,role)
  out[#out+1]={type='texture',x=x+dx*s,y=y+dy*s,w=w*s,h=h*s,a=a,c=c,texture_material=material,texture_resource=assert(resources[name],'unknown atlas image role'),atlas_rect=uv,texture_layer=49+(#out-1)*.1,mechanical_art=true,texture_theme=role~='state',render_role=role}
 end
 image('backing',{200/1536,60/1024,1136/1536,880/1024},0,0,160,124,pa,glow,'backing')
 local spent=m.df_shell_spent or {}
 for side=1,2 do
  local key=m.df_ejector_open and 'empty' or spent[side] and 'spent' or 'loaded'
  local alpha=m.df_ejector_open and 1 or spent[side] and .42 or 1
  if m.value==nil and not m.df_ejector_open then alpha=.2 end
  local dx=side==1 and 14.5 or 86.5
  image('rim',nil,dx-1,35.5,61,61,pa*alpha,glow,'rim')
  image('shells',regions[key],dx,36.5,59,59,opacity*alpha,{255,255,255},'state')
 end
 local function text(value,cx,cy,height,width,a,c,fixed)
  local l,b,r,t=measure(value,s,font)
  local size=fixed or s*math.min(width*s/math.max(.001,r-l),height*s/math.max(.001,t-b))
  l,b,r,t=measure(value,size,font)
  out[#out+1]={type='text',text=value,x=x+cx*s-(l+r)/2,y=y+cy*s-(b+t)/2,size=size,font=font,c=c or ink,a=a or ta,mechanical_live=true,texture_readout=true,readout_zone={cx=x+cx*s,cy=y+cy*s,w=width*s,h=height*s},render_role='readout'}
  return (r-l)/s
 end
 text('DBS-2',80,111,7.5,62)
 text('DOUBLE FREEDOM',80,101,4.6,88)
 local mode_size=math.huge
 for _,label in ipairs({'SEMI','VOLLEY'})do
  local l,b,r,t=measure(label,s,font)
  mode_size=math.min(mode_size,s*math.min(42*s/math.max(.001,r-l),10*s/math.max(.001,t-b)))
 end
 local sw=text('SEMI',55,30,10,42,ta*(m.fire_mode=='SEMI' and 1 or .3),ink,mode_size)
 local vw=text('VOLLEY',105,30,10,42,ta*(m.fire_mode=='VOLLEY' and 1 or .3),ink,mode_size)
 text('>',(m.fire_mode=='VOLLEY' and 105-vw/2 or 55-sw/2)-5,30,8,6,ta,glow)
 text(type(m.reserve)=='number' and string.format('%03d SHELLS',math.max(0,math.floor(m.reserve))) or '--- SHELLS',80,20,6,78)
 for i=0,5 do
  local on=type(m.reserve)=='number' and i<math.ceil(math.max(0,math.min(1,m.reserve/40))*6)
  out[#out+1]={type='rect',x=x+(60+i*7)*s,y=y+8*s,w=5*s,h=3*s,c=glow,a=ta*(on and 1 or .2),contrast_backing=true,render_role='readout'}
 end
 return out
end
return M
