local scene=dofile('src/screen_scene.lua')
local base={type='texture',x=10,y=20,w=100,h=200,a=.8,c={255,255,255},texture_material='same',texture_resource='base',
    texture_layers={{texture='shell',rect={.2,.3,.4,.5},alpha=.5,tint={200,100,50}},
        {texture='hidden',visible=false},{texture='empty',alpha=0}}}
local out=scene.expand_texture_layers({base})
assert(#out==2 and out[1].texture_resource=='base' and out[2].texture_resource=='shell')
assert(out[2].x==30 and out[2].y==80 and out[2].w==40 and out[2].h==100)
assert(out[2].a==.4 and out[2].c[1]==200 and out[2].texture_layer>out[1].texture_layer)
assert(out[1].texture_slot~=out[2].texture_slot and out[1].texture_material==out[2].texture_material)
assert(base.texture_slot==nil and base.texture_layers~=nil)
local commands={};for i=1,scene.max_texture_images+1 do commands[i]=base end
assert(not pcall(scene.expand_texture_layers,commands))
base.texture_layers={{rect={0,0,-1,1}}};assert(not pcall(scene.expand_texture_layers,{base}))
base.texture_layers={{tint={255,0,0/0}}};assert(not pcall(scene.expand_texture_layers,{base}))
base.texture_layers={{order=math.huge}};assert(not pcall(scene.expand_texture_layers,{base}))
print('texture layers: ordering, geometry, tint, alpha, hidden images, material isolation and limits passed')

-- Exercise actual renderer ownership with two images sharing a material name.
HUD={shader_catalog={},scene_test={mount=function()return 0,0,0 end},
 world_style={prepare=function(v)return v end},projection=dofile('src/projection.lua'),
 texture_theme={material=function(name)return name end}}
HUD.native_font_data=dofile('src/native_font_data.lua')
HUD.config=dofile('src/config.lua')
local made,freed,removed=0,{},0
local bindings,draws={},{}
local sr={Application={worlds=function()return {'main','ui'}end,main_world=function()return 'main'end,can_get=function()return true end},
 World={create_screen_gui=function()made=made+1;return made end,destroy_gui=function(_,g)assert(not freed[g]);freed[g]=true end},
 Gui={material=function(g,name)return {gui=g,name=name}end,
 triangle=function(g,...)draws[#draws+1]=g;return #draws end,destroy_triangle=function()removed=removed+1 end},
 Material={set_texture=function(handle,_,resource)bindings[handle.gui]=resource end,set_scalar=function()end,set_vector4=function()end},
 Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end}
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
local p={matrix=matrix,x=0,y=1,z=0,attach_point='root',resource_hex='test'}
base.texture_layers={{texture='shell',alpha=.5}}
local renderer=scene.new(sr,function()end)
base.atlas_rect={0,0,2,1}
assert(not renderer.draw(p,{}, {base},matrix,1,1920,1080,.05))
assert(made==0 and #draws==0 and removed==0,'invalid atlas touched native ownership')
base.atlas_rect=nil
assert(renderer.draw(p,{}, {base},matrix,1,1920,1080,.05),renderer.status)
assert(made==3 and bindings[2]=='base' and bindings[3]=='shell','shared material binding leaked between layers')
local first_draws=#draws;assert(first_draws>0)
local too_many={};for i=1,scene.max_texture_images+1 do too_many[i]=base end
assert(not renderer.draw(p,{},too_many,matrix,1,1920,1080,.05))
assert(made==3 and #draws==first_draws and removed==0,'command rejection cleared healthy HUD primitives')
base.texture_layers[1].visible=false
assert(renderer.draw(p,{}, {base},matrix,1,1920,1080,.05),renderer.status)
assert(made==3 and removed==first_draws,'hidden layer retained old primitives or recreated native GUI')
renderer.release();assert(freed[1] and freed[2] and freed[3],'layer GUI leaked on release')
renderer.release();assert(removed==first_draws,'release repeated native primitive destruction')
print('texture renderer: independent material bindings, hidden-layer clearing, GUI reuse and release passed')

local native_fail=scene.new(sr,function()end)
local original_triangle=sr.Gui.triangle
sr.Gui.triangle=function()error('synthetic native submission failure')end
assert(not native_fail.draw(p,{}, {base},matrix,1,1920,1080,.05))
sr.Gui.triangle=original_triangle
local draws_before=#draws
assert(not native_fail.draw(p,{}, {base},matrix,1,1920,1080,.05) and #draws==draws_before,'native failure quarantine was removed')
print('PASS pure command rejection preserves native GUI and next valid draw; native submission failure remains quarantined')

HUD.native_font_data=dofile('src/native_font_data.lua')
HUD.native_font_uv=dofile('src/native_font_uv.lua')
HUD.font=dofile('src/font.lua')
HUD.config=dofile('src/config.lua')
local atlas=dofile('src/df_neogeo_atlas.lua')
local atlas_commands=atlas.compose({value=2,reserve=34,fire_mode='SEMI'},0,0,1,1,{font='bigblue',panel_opacity=.5,text_opacity=.8},HUD.font.measure)
HUD.layout=dofile('src/layout.lua')
HUD.world_style=dofile('src/world_style.lua')
HUD.bespoke_texture_panel=dofile('src/bespoke_texture_panel.lua')
local atlas_renderer=scene.new(sr,function()end)
local malformed={};for _,v in ipairs(atlas_commands)do local q={};for k,value in pairs(v)do q[k]=value end;if q.type=='text'then q.readout_zone=nil end;malformed[#malformed+1]=q end
local made_before,drawn_before=made,#draws
assert(not atlas_renderer.draw(p,{},malformed,matrix,1,1920,1080,.05))
assert(made==made_before and #draws==drawn_before,'missing readout zone reached native rendering')
assert(atlas_renderer.draw(p,{},atlas_commands,matrix,1,1920,1080,.05),atlas_renderer.status)
for _,font in ipairs({'bigblue','hack','jetbrainsmono'})do
    for _,style in ipairs({'standard','hologram','instrument','blueprint','retro'})do
        local cfg={font=font,style_3d=style,scale=.75,panel_opacity=.35,text_opacity=.7,text_color='#DDEEFF',background_color='#FF6A18'}
        local commands=atlas.compose({value=1,reserve=17,fire_mode='VOLLEY',df_shell_spent={true,false},compass_heading=123},0,0,1,.9,cfg,HUD.font.measure)
        assert(atlas_renderer.draw(p,cfg,commands,matrix,1,1920,1080,.05),font..'/'..style..': '..atlas_renderer.status)
    end
end
atlas_renderer.release()
print('PASS option matrix: three fonts, five visual styles, scale, text/backing opacity and colors through actual styling')
print('PASS seven-image atlas, live-style text and reserve geometry through full native-renderer mock')
