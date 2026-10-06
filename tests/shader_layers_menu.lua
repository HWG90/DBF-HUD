HUD={}
for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end end
local core=dofile('../DBF-MCM/src/core.lua');local errors={};DBFMCM=core.new(nil,function(e)if e:lower():find('failed',1,true)then errors[#errors+1]=e end end)
local weapon='72170a55a1f37ff1';local h={config=HUD.config.new(),appearance_revision=0}
h.appearance_weapon=function()return weapon end;h.equipped_resource=function()return weapon end
h.panel_settings=function(id)return HUD.config.effective(h.config,id or weapon)end
h.configure_panel=function(v,id)HUD.config.set_panel(h.config,id or weapon,v);h.appearance_revision=h.appearance_revision+1 end
h.configure=function(v)HUD.config.apply(h.config,v)end;h.save_tuning=function()return true end
h.faithful_status=function()return 'test'end
local menu=HUD.menu.new(h);menu.poll();menu.poll()
local mod=assert(DBFMCM.mods.dbf_hud_fonts);local handle=mod.handle
assert(mod.controls.weapon_shader_add and not mod.controls.weapon_theme_shader)
assert(mod.values.hud_presentation==1)
assert(handle.set('hud_presentation',2));assert(h.config.hud_presentation=='practical')
assert(handle.set('hud_presentation',3));assert(h.config.hud_presentation=='weapon_specific')
assert(handle.set('hud_presentation',1));assert(h.config.hud_presentation=='automatic')
assert(mod.controls.hud_presentation.label=='HUD presentation')
assert(mod.controls.hud_presentation.choices[1]=='Automatic' and mod.controls.hud_presentation.choices[2]=='Simple' and mod.controls.hud_presentation.choices[3]=='Fancy')
assert(handle.set('third_person_scale',.65));assert(h.config.third_person_scale==.65)
assert(handle.set('third_person_opacity',.8));assert(h.config.third_person_opacity==.8)
assert(handle.set('weapon_texture_art_trial',true));menu.poll()
assert(mod.controls.weapon_decoration.disabled and mod.controls.weapon_style_3d.disabled)
assert(h.panel_settings().decoration=='none' and h.panel_settings().style_3d=='standard')
assert(handle.set('weapon_texture_art_trial',false));menu.poll()
assert(handle.set('weapon_decoration',2));assert(h.panel_settings().decoration==HUD.config.decorations[2])
assert(handle.set('weapon_style_3d',2));assert(h.panel_settings().style_3d==HUD.config.styles[2])
assert(handle.set('hud_presentation',2));menu.poll();assert(mod.controls.weapon_decoration.disabled and mod.controls.weapon_style_3d.disabled)
assert(handle.set('hud_presentation',3));menu.poll();assert(not mod.controls.weapon_decoration.disabled and not mod.controls.weapon_style_3d.disabled)
h.configure({anchor_mode='weapon'});menu.poll();assert(not mod.controls.weapon_decoration.disabled and mod.controls.weapon_style_3d.disabled)
h.configure({anchor_mode='world',hud_presentation='automatic'});menu.poll()
assert(not mod.controls.weapon_shader_layer_1_shader)
assert(handle.activate('weapon_shader_add'));assert(mod.controls.weapon_shader_layer_1_shader)
assert(handle.activate('weapon_shader_add'));assert(mod.controls.weapon_shader_layer_2_shader)
assert(handle.set('weapon_shader_layer_1_pattern_size',1.03125));assert(h.panel_settings().shader_layers[1].pattern_size==1.03125)
assert(handle.set('weapon_shader_layer_1_opacity',.01));assert(h.panel_settings().shader_layers[1].opacity==.01)
assert(handle.set('weapon_shader_layer_1_opacity',1));assert(h.panel_settings().shader_layers[1].opacity==1)
assert(mod.controls.weapon_shader_layer_1_opacity.min==.01 and mod.controls.weapon_shader_layer_1_opacity.max==1)
assert(handle.set('weapon_font_scale',1.2));assert(math.abs(h.panel_settings().font_scale-1.2)<1e-9)
local saved=HUD.config.serialize(h.config);local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(saved))());assert(math.abs(HUD.config.effective(restored,weapon).font_scale-1.2)<1e-9 and HUD.config.effective(restored,weapon).shader_layers[1].opacity==1)
assert(handle.set('weapon_shader_layer_1_enabled',false));assert(not h.panel_settings().shader_layers[1].enabled)
assert(handle.activate('weapon_shader_layer_2_up'));assert(h.panel_settings().shader_layers[1].id==2)
assert(handle.activate('weapon_shader_layer_1_remove'));assert(not mod.controls.weapon_shader_layer_1_shader and mod.values.weapon_shader_layer_1_shader==nil)
weapon='a8cffb316f0b5c5f';menu.poll();assert(not mod.controls.weapon_shader_layer_2_shader)
weapon=nil;menu.poll();assert(mod.controls.weapon_shader_add.disabled)
assert(#errors==0,table.concat(errors,'\n'));menu.retire();assert(DBFMCM.mods.dbf_hud_fonts==nil)
print('PASS actual MCM dynamic add/remove/reorder, callbacks, weapon switching and registration cleanup')
