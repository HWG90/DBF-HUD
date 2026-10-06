local M={}
local root='mods/dbf_hud/'
function M.compose(m,asset,x,y,w,h,alpha)
 local q={type='texture',x=x,y=y,w=w,h=h,a=alpha*.72,c={255,255,255},texture_theme=false,texture_material=root..'materials/mechanical_72170a55a1f37ff1',texture_resource=root..'textures/df_emitted_loaded',texture_layers={}}
 local spent=m.df_shell_spent or {};local left,right=spent[1]==true,spent[2]==true
 if left or right then
  q.mechanical_uv_mask=left and right and {.163,.264,.673,.397}or left and {.163,.264,.300,.397}or {.536,.264,.300,.397};q.mechanical_intensity=.35
  for side=1,2 do if spent[side]then q.texture_layers[#q.texture_layers+1]={material=root..'materials/mechanical_72170a55a1f37ff1',texture=root..'textures/df_emitted_stencil',atlas_rect={.75,.75,.0234375,.1875},rect={side==1 and .304 or .680,.5175,.014,.019},alpha=1,theme=false}end end
 end
 return q
end
function M.reserve_commands(m,x,y,w,h,alpha)
 local reserve=type(m.reserve)=='number'and math.max(0,math.min(999,math.floor(m.reserve)))or 1000
 local heading=type(m.compass_heading)=='number'and math.floor(m.compass_heading+.5)%360 or 360
 local packed=reserve+1001*(m.fire_mode=='VOLLEY'and 1 or 0)+2002*heading
 return {{type='texture',x=x,y=y,w=w,h=h,a=alpha,c={255,255,255},texture_theme=false,texture_material=root..'materials/df_emitted_readouts',texture_resource=root..'textures/df_emitted_stencil',mechanical_uv_mask={0,0,1,1},mechanical_intensity=packed,mechanical_live=true}}
end
return M
