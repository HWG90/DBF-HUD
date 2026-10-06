HUD={};for _,n in ipairs(DBF_BUNDLE_MODULES)do if n~='bundled_defaults'then HUD[n]=dofile('src/'..n..'.lua')end end
local C=HUD.config;local cfg=C.new();local count=0
for id,spec in pairs(HUD.ballistic_family.specs)do
 count=count+1;assert(id~='72170a55a1f37ff1' and not spec.conditional and spec.research_status=='individual_weapon_page_checked')
 local m=HUD.model.normalize({resource_hex=id,kind='magazine',rounds=25,capacity=30,reserve=5,reserve_kind='MAGS',fire_mode='SEMI'});m.compass_heading=270
 local out=HUD.ballistic_family.compose(m,0,0,1,1,cfg,function()return 'ready'end)
 assert(out and out[1].w==148 and out[1].h>182 and out[2].coverage_mask and out[3].texture_resource:find(id,1,true))
 for _,v in ipairs(out)do if v.type=='rect'then assert(v.w>0 and v.h>0)end end
end
assert(count==52 and not HUD.ballistic_family.specs['72170a55a1f37ff1'])
C.apply(cfg,{texture_art_trial=true,texture_art_variant='faithful',decoration='outline',style_3d='hologram',effect_scanlines=true,shader_layers={{id=1,shader='crt_scan',opacity=.37,pattern_size=1.03125}}})
assert(cfg.decoration=='none' and cfg.style_3d=='standard' and not cfg.effect_scanlines and cfg.shader_layers[1].opacity==.37)
C.set_panel(cfg,'5fecab819f96a3e8',{texture_art_trial=false,decoration='outline',style_3d='hologram'});assert(cfg.weapon_panels['5fecab819f96a3e8'].style_3d=='hologram')
C.set_panel(cfg,'5fecab819f96a3e8',{texture_art_trial=true});assert(cfg.weapon_panels['5fecab819f96a3e8'].style_3d=='standard' and cfg.weapon_panels['5fecab819f96a3e8'].decoration=='none')
local saved=C.serialize(cfg);local restored=C.new();C.apply(restored,assert(loadstring(saved))());assert(restored.shader_layers[1].pattern_size==1.03125)
local frame={type='panel',x=0,y=0,w=200,h=220}
local art={type='texture',x=10,y=20,w=120,h=160,c={255,255,255},a=.8,texture_resource='image',texture_material='test/alpha',atlas_rect={0,0,1,1}}
local layers={{id=1,shader='crt_scan',opacity=.01,scale=2,pattern_size=1.03125}}
local out=HUD.screen_scene.expand_shader_layers({frame,art},{shader_layers=layers},function()return true end,'test')
assert(#out==3 and out[3].type=='texture' and out[3].shader_alpha_masked and out[3].x==10 and out[3].w==120 and out[3].a==.01)
local other={};for k,v in pairs(art)do other[k]=v end;other.texture_material='test/unsupported'
out=HUD.screen_scene.expand_shader_layers({frame,other},{shader_layers=layers},function()return false end,'unsupported');assert(#out==2 and HUD.screen_scene.shader_layer_status.unsupported)
for _,id in ipairs({'5fecab819f96a3e8','72170a55a1f37ff1'})do
 local simple=HUD.view_presentation.compose({resource_hex=id,value=2,capacity=2,reserve=31,reserve_kind='ROUNDS',fire_mode='SEMI',df_shell_spent={false,false}},0,0,1,1,C.new())
 assert(simple[1].w==64 and simple[1].h==86 and #simple<=14);for _,v in ipairs(simple)do assert(v.type~='texture')end
end
print('PASS52 filtered bindings, DF Fancy exclusion, texture-style resets/persistence, shader source-alpha carrier bounds/no rectangular fallback, fine pattern persistence and vertical Simple includingDF')
