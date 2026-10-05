from pathlib import Path
import json,re,ctypes
P=Path(__file__).resolve().parent
s=(P/'mod.lua').read_text()
checker=(P.parent/'install_epoch_plasma.py').read_text();exec(checker[checker.index('dll=ctypes.CDLL'):checker.index('check(after)')])
for f in (P/'Source').glob('*.lua'):
 try:check('local HUD={}\nreturn (function()\n'+f.read_text()+'\nend)()')
 except AssertionError as e:raise AssertionError(f.name+': '+str(e))
prefix=s[:s.index('HUD.memory=(function()')]
methods=(P/'Source/runtime.lua').read_text();a=methods.index('    function self.appearance_weapon()');b=methods.index('    function self.appearance_model(',a)
code=prefix+'\nHUD.weapon_names=(function()\n'+(P/'Source/weapon_names.lua').read_text()+'\nend)()\nHUD.menu=(function()\n'+(P/'Source/menu.lua').read_text()+'\nend)()\n'+r'''
local A='05e4e5c2db6e44a2';local B='35a61296619cc47e'
local model={resource_hex=A};local appearance_selection
local self={config=HUD.config.new(),appearance_revision=0,clock=0}
function self.configure(v)HUD.config.apply(self.config,v);self.appearance_revision=self.appearance_revision+1 end
''' +methods[a:b]+r'''
local saves=0
function self.save_tuning()saves=saves+1 end
function self.equipped_resource()return model and model.resource_hex end
function self.panel_settings(id)return HUD.config.effective(self.config,id)end
function self.shader_status()return 'offline' end
function self.list_presets()return {} end
function self.configure_panel(values,id)HUD.config.set_panel(self.config,id,values);self.appearance_revision=self.appearance_revision+1 end
function self.blacklist_equipped()return true end
DBFMCM={mods={}}
function DBFMCM.register(spec)
 local mod={pages=spec.pages,controls={},values={}}
 for _,page in ipairs(spec.pages)do for _,c in ipairs(page.controls)do
  if c.id then mod.controls[c.id]=c;mod.values[c.id]=c.default end
 end end
 DBFMCM.mods[spec.id]=mod;return {unregister=function()end}
end
local menu=HUD.menu.new(self);menu.poll()
local mod=assert(DBFMCM.mods.dbf_hud_fonts,'MCM registration failed')
assert(mod.controls.weapon_heading.label:find('Peacemaker'),'Initial equip not selected')
model={resource_hex=B};menu.poll()
assert(mod.controls.weapon_heading.label:find('Quasar'),'Weapon swap did not follow')
assert(saves==0,'Automatic follow wrote tuning')
mod.controls.weapon_panel_opacity.on_change(.63)
assert(self.config.weapon_panels[B].panel_opacity==.63 and not self.config.weapon_panels[A],'Wrong weapon changed')
self.select_appearance_weapon(A);menu.poll()
assert(self.appearance_weapon()==A and self.config.appearance_follow_equipped==false,'Manual preview did not pin')
model={resource_hex=B};menu.poll();assert(self.appearance_weapon()==A,'Manual preview lost on equip')
mod.controls.appearance_follow_equipped.on_change(true);menu.poll();assert(self.appearance_weapon()==B,'Follow toggle failed')
model=nil;menu.poll();assert(self.appearance_weapon()==nil and mod.controls.weapon_panel_opacity.disabled,'Unequipped controls unsafe')
model={resource_hex=A};menu.poll();assert(self.appearance_weapon()==A and not mod.controls.weapon_panel_opacity.disabled,'Re-equip did not refresh')
local serialized=HUD.config.serialize(self.config)
assert(serialized:find('appearance_follow_equipped = true',1,true),'Selection mode not persisted')
local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(serialized))());assert(restored.weapon_panels[B].panel_opacity==.63,'Weapon settings did not round trip')
assert(not mod.controls.weapon_texture_art_trial and not mod.controls.weapon_style_3d and not mod.controls.weapon_frosted,'Obsolete controls exposed')
assert(mod.controls.weapon_effect_flicker and mod.controls.weapon_effect_sweep,'Unreplaced effects removed')
'''
check(code,True)
(P/'selection-test.lua').write_text(code)
# Dedicated safety/slot fixture using current authoritative compose functions.
code=prefix+'\nHUD.mechanical_layouts=(function()\n'+(P/'layouts.lua').read_text()+'\nend)()\nHUD.neo_profiles=(function()\n'+(P/'profiles.lua').read_text()+'\nend)()\nlocal skin=(function()\n'+(P/'neo_panel.lua').read_text()+'\nend)()\n'+r'''
local cfg=HUD.config.new();cfg.anchor_mode='world';cfg.senator_style='cylinder';cfg.effect_scanlines=true
local m=HUD.model.normalize({resource_hex='8d3d52a3b2f19402',kind='rounds',rounds=3,capacity=6,reserve=12,reserve_kind='ROUNDS',fire_mode='SEMI'})
m.cylinder_slots={true,false,true,false,true,false};m.cylinder_render_angle=0
local original=HUD.layout.compose(m,0,0,1,1,cfg,0,function(t,z)return HUD.font.measure(t,z,'bigblue')end)
local out=skin.compose(original,m,0,0,1,1,cfg,0,nil,function()return true end)
local slots={};local surfaces=0
for _,v in ipairs(out)do if v.senator_slot then slots[v.senator_slot]=true end;if v.neo_effect_shader=='crt_scan' then surfaces=surfaces+1 end end
local n=0;for _ in pairs(slots)do n=n+1 end;assert(n==6,'Cylinder slot state removed')
assert(surfaces==1,'Scanlines did not use one GPU surface')
local fallback=skin.compose(original,m,0,0,1,1,cfg,0,nil,function()return false end)
local lines=0;for _,v in ipairs(fallback)do if v.effect_shader_band then lines=lines+1 end end;assert(lines>1,'Missing shader lost fallback')
cfg.effect_scanlines=false;cfg.effect_sweep=true
original=HUD.layout.compose(m,0,0,1,1,cfg,.7,function(t,z)return HUD.font.measure(t,z,'bigblue')end)
out=skin.compose(original,m,0,0,1,1,cfg,.7,nil,function()return true end)
local sweep=0;for _,v in ipairs(out)do if v.df_effect_sweep then sweep=sweep+1 end end;assert(sweep>0,'Animated sweep removed without equivalent')
'''
check(code,True);(P/'mechanics-test.lua').write_text(code)
r=json.loads((P/'validation.json').read_text());r.update(selection_mcm_tests=True,persistence_roundtrip=True,cylinder_six_slots=True,gpu_scanline_single_surface=True,missing_shader_fallback=True,animated_sweep_retained=True)
(P/'validation.json').write_text(json.dumps(r,indent=2))
print('PASS source syntax; MCM equip/swap/manual/follow/unequip/re-equip; persistence; six cylinder slots; GPU scanlines and missing-asset fallback; animated sweep')
