-- Exercise HUD registration against the real maintained MCM choice validator.
-- In-memory persistence and no rendered UI; no game/settings files are written.
HUD={shader_catalog={},native_font_data=dofile('src/native_font_data.lua'),weapon_names=dofile('src/weapon_names.lua'),segmented_primary_specs=dofile('src/segmented_primary_specs.lua')}
HUD.config=dofile('src/config.lua');HUD.shader_layers=dofile('src/shader_layers.lua')
HUD.split_hud_assets=dofile('src/split_hud_assets.lua');HUD.split_hud=dofile('src/split_hud.lua')
local Menu=dofile('src/menu.lua')
local core_path=os.getenv('DBF_MCM_CORE')or'../DBF-MCM/src/core.lua'
local Core=assert(loadfile(core_path),'Maintained DBF-MCM core required; set DBF_MCM_CORE to its src/core.lua')()
local old_host,old_options,old_open=rawget(_G,'DBFMCM'),rawget(_G,'ModOptionsMenu'),io.open
-- Menu publishes a diagnostic file in normal use. Suppress only that optional
-- diagnostic during this offline integration test.
io.open=function(path,...)
 if tostring(path):find('Pattern-scale-registration.log',1,true)then return nil end
 return old_open(path,...)
end
local function copy(t)if type(t)~='table'then return t end;local q={};for k,v in pairs(t)do q[k]=copy(v)end;return q end
local stored,logs,writes={dbf_hud_fonts={decoration=6,family=1,text_color='#010203',panel_color='#111111',decoration_color='#222222',hud_scale=.55}}, {},0
local store={load=function(id)return copy(stored[id]or{})end,save=function(id,v)stored[id]=copy(v);writes=writes+1;return true end}
local api=Core.new(store,function(message)logs[#logs+1]=message end)
_G.DBFMCM=api
_G.ModOptionsMenu={api=1,register_option=function()error('Modern MCM unexpectedly published legacy rows')end}
local resource='968211c0033dce64'
local hud={clock=0,config=HUD.config.new(),appearance_revision=0,first_person=false}
local callbacks={configure=0,panel=0,saves=0}
function hud.configure(values)callbacks.configure=callbacks.configure+1;HUD.config.apply(hud.config,values);hud.appearance_revision=hud.appearance_revision+1 end
function hud.configure_panel(values,id)callbacks.panel=callbacks.panel+1;HUD.config.set_panel(hud.config,id,values);hud.appearance_revision=hud.appearance_revision+1 end
function hud.panel_settings(id)return HUD.config.effective(hud.config,id)end
function hud.appearance_weapon()return resource end
function hud.equipped_resource()return resource end
function hud.select_appearance_weapon(id)resource=id;hud.appearance_revision=hud.appearance_revision+1 end
function hud.follow_equipped_appearance(value)hud.config.appearance_follow_equipped=value end
function hud.save_tuning()callbacks.saves=callbacks.saves+1;return true,'memory'end
function hud.faithful_status()return 'Split active'end
function hud.shader_status()return 'existing shader path'end
function hud.list_presets()return{}end
function hud.appearance_preview()return{}end
local menu=Menu.new(hud)
menu.poll()
local mod=assert(api.mods.dbf_hud_fonts,'Split defaults failed strict MCM registration')
local global=assert(mod.controls.decoration);local panel=assert(mod.controls.weapon_decoration)
assert(global.type=='choice'and #global.choices==7 and global.choices[7]=='Split instrument')
assert(global.default==7 and mod.values.decoration==7,'Split global default is outside its registered schema')
assert(panel.type=='choice'and #panel.choices==7 and mod.values.weapon_decoration==7)
local hack
for i,name in ipairs(HUD.config.fonts)do if name=='hack'then hack=i;break end end
assert(hack and mod.values.family==hack and mod.values.text_color==hud.config.text_color and mod.values.panel_color==hud.config.background_color and mod.values.decoration_color==hud.config.decoration_color)
assert(mod.values.hud_scale==hud.config.scale,'Registration retained an old saved scale instead of runtime config')
assert(callbacks.configure==0 and callbacks.panel==0 and callbacks.saves==0 and writes==0,'Registration synchronization invoked persistence or on_change')
assert(stored.dbf_hud_fonts.decoration==6 and stored.dbf_hud_fonts.family==1 and stored.dbf_hud_fonts.text_color=='#010203','Runtime display synchronization rewrote stored MCM values')
-- Later runtime edits (a reset/preset path) synchronize immediately without
-- replaying MCM callbacks or saving a second settings file.
local baseline=copy(hud.config)
hud.config.decoration='brackets';hud.config.font='bigblue';hud.config.style_3d='retro';hud.config.text_color='#ABCDE0';hud.config.background_color='#102030';hud.config.decoration_color='#FFEEDD';hud.config.scale=1.3
menu.sync()
assert(mod.values.decoration==3 and mod.values.family==1 and mod.values.style==5 and mod.values.text_color=='#ABCDE0')
assert(mod.values.panel_color=='#102030'and mod.values.decoration_color=='#FFEEDD'and mod.values.hud_scale==1.3)
assert(callbacks.configure==0 and callbacks.panel==0 and callbacks.saves==0 and writes==0,'Runtime sync invoked a callback/write')
hud.config=baseline;menu.sync()
assert(mod.values.decoration==7 and mod.values.family==hack and mod.values.text_color==hud.config.text_color)
assert(mod.controls.weapon_texture_art_variant.choices[1]=='Split instrument'and mod.values.weapon_texture_art_variant==1)
assert(mod.values.weapon_split_readout_view==1)
local handle=mod.handle
-- The actual core rejects an out-of-range value; this is not a permissive mock.
assert(not pcall(handle.edit,'decoration',8),'Real core choice validation was bypassed')
assert(handle.edit('decoration',6));assert(hud.config.decoration=='deadeye')
assert(handle.edit('decoration',7));assert(hud.config.decoration=='split')
assert(handle.edit('weapon_decoration',6));assert(hud.panel_settings(resource).decoration=='deadeye')
assert(handle.edit('weapon_decoration',7));assert(hud.panel_settings(resource).decoration=='split')
local font=mod.controls.weapon_font;local registered=mod
assert(hack and handle.edit('weapon_font',hack+1));assert(hud.panel_settings(resource).font=='hack')
-- Camera-view changes and combat/inspect editing keep one registered font
-- control and the same per-weapon choice, without stale enum ranges.
for _,first in ipairs({false,true})do
 hud.first_person=first;menu.poll();menu.sync()
 assert(api.mods.dbf_hud_fonts==registered and registered.controls.weapon_font==font)
 assert(handle.edit('weapon_split_readout_view',2));assert(hud.panel_settings(resource).split_readout_view=='inspect')
 menu.poll();menu.sync();assert(registered.values.weapon_font==hack+1)
 assert(handle.edit('weapon_split_readout_view',1));assert(hud.panel_settings(resource).split_readout_view=='combat')
 assert(handle.edit('weapon_decoration',7)and handle.edit('decoration',7))
end
assert(writes>0,'Actual MCM edits did not use its supported persistence contract')
for _,message in ipairs(logs)do assert(not message:find('Registration failed',1,true)and not message:find('Callback failed',1,true),message)end
menu.retire();assert(api.mods.dbf_hud_fonts==nil,'HUD did not unregister its native MCM definition')
-- A new HUD instance on the retained API registers the new seven-choice schema.
local reloaded=Menu.new(hud);reloaded.poll();reloaded.sync()
assert(api.mods.dbf_hud_fonts.controls.decoration.choices[7]=='Split instrument')
assert(api.mods.dbf_hud_fonts.controls.weapon_decoration.choices[7]=='Split instrument')
reloaded.retire()
-- The actual historical bundle is loaded before configuration in production.
-- Its old palette/artwork and weapon overrides must not defeat fresh Split setup.
local old_bundle,old_config=HUD.bundled_defaults,HUD.config
local bundle=dofile('src/bundled_defaults.lua')
assert(bundle.settings.decoration=='helldivers'and bundle.settings.font=='bigblue','Historical fixture unexpectedly stopped testing old defaults')
HUD.bundled_defaults=bundle
local Fresh=dofile('src/config.lua');local fresh=Fresh.new()
assert(fresh.texture_art_variant=='split'and fresh.texture_art_trial and fresh.hud_presentation=='weapon_specific'and fresh.font=='hack')
assert(fresh.text_color=='#F5F6F0'and fresh.decoration_color=='#E9C45D'and fresh.background_color=='#091B35'and fresh.heat_red=='#FF5750')
assert(fresh.decoration=='split'and fresh.panel_opacity==.35 and fresh.panel_edge_softness==7 and fresh.panel_edge_curve==1 and fresh.panel_edge_dither==40 and fresh.panel_edge_grain==2)
assert(fresh.panel_spatial_depth==16 and fresh.split_readout_view=='combat'and next(fresh.weapon_panels)==nil and next(Fresh.weapon_clearance)==nil)
assert(next(fresh.shader_layers)==nil and fresh.theme_shader=='none'and fresh.effect_shader=='none')
assert(bundle.settings.decoration=='helldivers'and bundle.settings.font=='bigblue','Fresh setup modified recovery defaults')
fresh.weapon_panels['968211c0033dce64']={decoration='none'}
assert(next(Fresh.new().weapon_panels)==nil,'New configurations shared weapon overrides')
HUD.bundled_defaults=old_bundle;HUD.config=old_config
_G.DBFMCM=old_host;_G.ModOptionsMenu=old_options;io.open=old_open
print('PASS Split menu: real MCM strict choices, immediate runtime-authoritative sync over saved globals without callbacks/writes, Split artwork and stable font/detail controls, supported persistence/reload, authoritative fresh Split defaults over the actual historical bundle')
