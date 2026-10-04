HUD={}
for _,name in ipairs({'native_font_data','native_font_uv','native_font','config','font','motion','ammo_types','model','fire_icons','munition_art','mg_easter','df_shell_state','recoilless_state','senator_state','senator_panel','doom_easter','melta_panel','speargun_panel','recoilless_panel','catalog_housing','shared_suite','weapon_styles','layout','memory','layouts','reader','pose','camera_mode','projection','camera_state','anchor','view','pose_motion','world_probe','depth_marker','offscreen_test','world_style','archived_mesh','scene_test','screen_scene','placement','weapon_names','weapon_offsets','layout_editor','menu','runtime'})do HUD[name]=assert(loadfile('src/'..name..'.lua'))() end
local c=HUD.config.new();assert(c.theme_shader_scale==1 and c.effect_shader_scale==1 and c.panel_opacity==.8)
HUD.config.apply(c,{theme_shader_scale=.25,effect_shader_scale=4})
assert(c.theme_shader_scale==.25 and c.effect_shader_scale==4)
assert(not pcall(HUD.config.apply,c,{theme_shader_scale=0}))
assert(not pcall(HUD.config.apply,c,{effect_shader_scale=0/0}))
HUD.config.apply(c,{weapon_panels={['a6a735accb4a327f']={theme_shader_scale=.5,effect_shader_scale=2,panel_opacity=.8}}})
local w=HUD.config.effective(c,'a6a735accb4a327f');assert(w.theme_shader_scale==.5 and w.effect_shader_scale==2 and c.theme_shader_scale==.25)
local camera={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};local samples=0
for _,fov in ipairs({.3,.7,1.2,1.57})do for _,aspect in ipairs({1,1.777,2.4,3})do for j=1,50 do
 local x,y,z=-.2+j*.008,.25+j*.03,.3
 local ux,uy,uz=.2,.03,.01;local vx,vy,vz=.01,.02,-.12
 local rows={HUD.projection.panel_inverse(camera,fov,aspect,x,y,z,ux,uy,uz,vx,vy,vz)};assert(rows[1])
 local u,v=(j%7)/6,(j%5)/4
 local px,py,pz=x+u*ux+v*vx,y+u*uy+v*vy,z+u*uz+v*vz
 local tx,ty=.5+px/(2*py*math.tan(fov/2)*aspect),.5-pz/(2*py*math.tan(fov/2))
 local d=rows[7]*tx+rows[8]*ty+rows[9]
 assert(math.abs((rows[1]*tx+rows[2]*ty+rows[3])/d-u)<1e-8)
 assert(math.abs((rows[4]*tx+rows[5]*ty+rows[6])/d-v)<1e-8);samples=samples+1
end end end
assert(not HUD.projection.panel_inverse(camera,1.2,1.777,0,1,0,0,0,0,0,0,0))
print('PASS independent pattern scales, bounds, inheritance, opacity and '..samples..' planar projection cases')
-- Count composed commands, not GPU draw calls or measured performance.
for _,spec in ipairs({{'Leveller','7617642765ac38c7'},{'Breacher','e91f569c2ad8af01'},{'Punisher','41eac4a03987faa0'},{'Hot Shot','1abbff60d26ba391'},{'Ultimatum','9eb160830321bfd6'}})do
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=spec[2],kind='magazine',rounds=8,capacity=16,reserve=4,fire_mode='AUTO'}))
 local value,reserve=m.value,m.reserve
 local original=io.open;io.open=function(path,...)if tostring(path):find('checkpoint.log',1,true)then return nil end;return original(path,...)end
 local out=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0);io.open=original
 assert(m.value==value and m.reserve==reserve)
 local rectangles,text=0,0
 for _,v in ipairs(out)do if v.type=='rect' or v.type=='panel' then rectangles=rectangles+1 elseif v.type=='text' then text=text+1 end end
 print(string.format('COMMAND_COUNT %s rectangles=%d text_runs=%d minimum_art_triangles=%d',spec[1],rectangles,text,rectangles*2))
end
