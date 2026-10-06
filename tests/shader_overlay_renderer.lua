HUD={shader_catalog={{id='carbon',material='mods/dbf_hud/materials/lab_carbon'}}}
HUD.shader_layers=dofile('src/shader_layers.lua');HUD.scene_test={mount=function()return 0,0,0 end};HUD.world_style={prepare=function(v)return v end};HUD.projection=dofile('src/projection.lua');HUD.config={shader_animation_values=function()return 0,0 end}
HUD.native_font_data=dofile('src/native_font_data.lua')
HUD.config.texture_policy=dofile('src/config.lua').texture_policy
local M=dofile('src/screen_scene.lua');local made,freed,draws=0,{},{};local params={}
local sr={Application={worlds=function()return {'main','ui'}end,main_world=function()return 'main'end,can_get=function(_,name)return not name:find('_shader_layers',1,true)end},World={create_screen_gui=function()made=made+1;return made end,destroy_gui=function(_,g)assert(not freed[g]);freed[g]=true end},Gui={material=function(g,n)return {gui=g,name=n}end,triangle=function(g,...)draws[#draws+1]=g;return #draws end,destroy_triangle=function()end},Material={set_scalar=function()end,set_vector4=function(h,k,v)params[h.gui..':'..k]=v end},Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Vector4=function(...)return {...}end,Color=function(...)return {...}end}
local matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1};local p={matrix=matrix,x=0,y=10,z=0,resource_hex='0000000000000000'}
local commands={{type='panel',x=0,y=0,w=100,h=80,c={24,28,24},a=.8,frosted=false}}
local cfg={style_clock=2,shader_layers={{id=1,shader='carbon',enabled=true,scale=2,strength=1,animate=true,speed=2},{id=2,shader='carbon',enabled=true,scale=3,strength=2,animate=false,speed=1}}}
local r=M.new(sr,function()end);assert(r.draw(p,cfg,commands,matrix,1,1920,1080,.05),r.status)
assert(made==3,'two shader instances were not isolated')
assert(params['2:scissor_rect'][4]==4 and params['3:scissor_rect'][4]==2,'independent clocks not bound')
assert(params['2:atlas_scissor'][4]==1 and params['3:atlas_scissor'][4]==0)
r.release();assert(freed[1]and freed[2]and freed[3]);r.release()
print('PASS existing mapped materials only, isolated layer parameters, bounded GUI allocation and cleanup')
