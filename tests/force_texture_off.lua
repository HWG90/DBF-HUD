HUD={}
for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end end
local cfg=HUD.config.new();local df='72170a55a1f37ff1'
HUD.config.set_panel(cfg,df,{texture_art_trial=true,texture_art_variant='faithful'})
HUD.config.apply(cfg,{force_all_hud_texture_off=true})
local saved=HUD.config.serialize(cfg)
-- Reproduce the late renderer merge that previously defeated the global override.
for _,view in ipairs({'first','third','preview'})do
 local render=HUD.config.effective(cfg,df);render.presentation_view=view
 for k,v in pairs(render.weapon_panel_overrides)do render[k]=v end
 assert(render.texture_art_trial==true,'regression setup no longer reproduces late weapon merge')
 render=HUD.config.texture_policy(render)
 assert(render.texture_art_trial==false and render.mechanical_art_enabled==false and render.texture_art_variant=='original')
 local original={{type='panel',x=0,y=0,w=192,h=72,c={20,26,29},a=1}}
 local commands,used=HUD.mechanical_art.compose(original,{resource_hex=df},0,0,1,1,render,0,HUD.font.measure,function()return true end,function()return 'available'end)
 assert(commands==original and not used)
 assert(HUD.bespoke_texture_panel.compose(original,{resource_hex=df},0,0,1,1,render,0,HUD.font.measure,function()return true end)==original)
end
assert(HUD.config.serialize(cfg)==saved,'force-off changed saved per-weapon art')
HUD.config.apply(cfg,{force_all_hud_texture_off=false});assert(HUD.config.effective(cfg,df).texture_art_trial==true)
-- The final projected renderer also applies the policy before texture substitution.
local calls=0;HUD.world_style.prepare=function(v)return v end;HUD.texture_art.prepare=function(v)calls=calls+1;return v end
local p={matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},x=0,y=10,z=0,resource_hex=df}
local commands={{type='panel',x=0,y=0,w=192,h=72,c={20,26,29},a=1}}
local render=HUD.config.effective(cfg,df);render.shader_layers={}
HUD.screen_scene.prepare_commands(commands,p,render,function()return true end);assert(calls==1)
render.force_all_hud_texture_off=true
HUD.screen_scene.prepare_commands(commands,p,render,function()return true end);assert(calls==1,'projected renderer ignored force texture off')
assert(render.texture_art_trial==true,'render policy mutated caller settings')
local practical=HUD.view_presentation.compose({value=2,reserve=31,fire_mode='SEMI'},0,0,1,1,render)
for _,v in ipairs(practical)do assert(v.type~='texture')end
print('PASS late per-weapon merge regression, first/third/preview policy, mechanical/bespoke suppression, final projected texture gate, reversible saved choices and functional practical readouts')
