-- Exact Designer texture atlas; state selection/readouts remain Lua.
local M={}
local spec={["version"]=1,["authority"]="../concept-board.png; existing df-media/frame.png derived from that board",["format"]="straight RGBA8; RGB and alpha preserved, no gamma/color conversion",["files"]={["df_media_frame_v1"]={["width"]=1448,["height"]=1086,["rgba_bytes"]=6290112,["file"]="df_media_frame_v1_f98db39401c5dfd3a32483d902b0211e1882edb4a53b979780d4187995223729.rgba",["sha256"]="f98db39401c5dfd3a32483d902b0211e1882edb4a53b979780d4187995223729",["png"]="frame.png"},["df_media_cores_v1"]={["width"]=528,["height"]=1584,["rgba_bytes"]=3345408,["file"]="df_media_cores_v1_c29789ffcb7bdd3db8ee569406587974c798d1acabe08d2d8e70edcb0403f104.rgba",["sha256"]="c29789ffcb7bdd3db8ee569406587974c798d1acabe08d2d8e70edcb0403f104",["png"]="cores-atlas.png"}},["frame"]={["resource"]="mods/dbf_hud/textures/df_media_frame_v1",["pixels"]={51,46,1373,982},["uv"]={0.03522099447513812,0.0423572744014733,0.9482044198895028,0.9042357274401474},["logical_size"]={128,91.54843408594319}},["cores"]={["resource"]="mods/dbf_hud/textures/df_media_cores_v1",["regions"]={["loaded"]={["pixels"]={8,8,512,512},["uv"]={0.015151515151515152,0.005050505050505051,0.9696969696969697,0.32323232323232326},["source_crop"]={288,107,512,512}},["unavailable"]={["pixels"]={8,536,512,512},["uv"]={0.015151515151515152,0.3383838383838384,0.9696969696969697,0.32323232323232326},["source_crop"]={828,105,512,512}},["unknown"]={["pixels"]={8,1064,512,512},["uv"]={0.015151515151515152,0.6717171717171717,0.9696969696969697,0.32323232323232326},["source_crop"]={1374,105,512,512}}},["canonical_tile_size"]={512,512},["logical_draw_size"]={32,32},["centers_top_left_pixels"]={{436,492},{985,492}},["centers_top_left_logical"]={{35.892206846321926,41.579024034959936},{87.07356154406409,41.579024034959936}}},["readouts"]={["model"]={["center_top_left_pixels"]={724,203},["zone_pixels"]={530,178,388,50}},["mode"]={["center_top_left_pixels"]={488,865},["zone_pixels"]={295,806,386,118}},["reserve"]={["center_top_left_pixels"]={967,865},["zone_pixels"]={762,806,410,118}}},["all_coordinates_top_left"]=true,["baked_dynamic_text"]=false,["native_compositor_included"]=false,["installed"]=false}
M.frame='mods/dbf_hud/textures/df_media_frame_v1';M.cores='mods/dbf_hud/textures/df_media_cores_v1'
local material='mods/dbf_hud/materials/mechanical_72170a55a1f37ff1'
function M.ready(resource)return resource(M.frame)~=nil and resource(M.cores)~=nil end
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
function M.compose(m,x,y,s,opacity,cfg,measure)
 measure=measure or HUD.font.measure;local w,h=spec.frame.logical_size[1],spec.frame.logical_size[2]
 local out={{type='panel',x=x,y=y,w=w*s,h=h*s,c={22,23,22},a=0,frosted=false,mechanical_art=true,df_designer_texture=true,world_reference_width=256*s}}
 local function image(resource,uv,dx,dy,dw,dh,alpha,layer)
  out[#out+1]={type='texture',x=x+dx*s,y=y+(h-dy-dh)*s,w=dw*s,h=dh*s,c={255,255,255},a=opacity*alpha,texture_material=material,texture_resource=resource,atlas_rect=uv,texture_theme=false,texture_layer=layer,df_designer_texture=true}
 end
 image(M.frame,spec.frame.uv,0,0,w,h,cfg.panel_opacity or 1,49)
 for side,center in ipairs(spec.cores.centers_top_left_logical)do
  local state=not finite(m.value)and 'unknown'or ((m.df_shell_spent or {})[side]or m.value<3-side)and 'unavailable'or 'loaded'
  if m.df_ejector_open then state='unknown'end
  image(M.cores,spec.cores.regions[state].uv,center[1]-16,center[2]-16,32,32,1,49.1+side*.1)
 end
 local function text(value,zone,c)
  local scale=128/spec.frame.pixels[3];local z=zone.zone_pixels
  local cx=(z[1]+z[3]/2-spec.frame.pixels[1])*scale;local cy=(z[2]+z[4]/2-spec.frame.pixels[2])*scale;local zw,zh=z[3]*scale,z[4]*scale
  local font=cfg.font or 'departuremono';local l,b,r,t=measure(value,s,font,true);local size=s*math.min(zw*s/math.max(.001,r-l),zh*s/math.max(.001,t-b));l,b,r,t=measure(value,size,font,true)
  out[#out+1]={type='text',text=value,x=x+cx*s-(l+r)/2,y=y+(h-cy)*s-(b+t)/2,size=size,font=font,c=c,a=opacity*(cfg.text_opacity or 1),texture_readout=true,readout_zone={cx=x+cx*s,cy=y+(h-cy)*s,w=zw*s,h=zh*s},df_designer_texture=true}
 end
 local ink=cfg.weapon_panel_overrides and cfg.weapon_panel_overrides.text_color and HUD.config.rgb(cfg.weapon_panel_overrides.text_color)or {190,191,180}
 text('DBS-2',spec.readouts.model,{155,161,155});text(m.fire_mode=='SEMI'and 'SEMI'or m.fire_mode=='VOLLEY'and 'VOLLEY'or '--',spec.readouts.mode,{157,142,98})
 text((finite(m.reserve)and tostring(math.max(0,math.floor(m.reserve)))or '--')..' RES',spec.readouts.reserve,ink)
 return out
end
return M
