HUD={native_font_data={order={},faces={bigblue=true,hack=true}}}
HUD.config=dofile('src/config.lua');HUD.shader_layers=dofile('src/shader_layers.lua')
local C=HUD.config
local a,b='0123456789abcdef','fedcba9876543210'
local function equal(left,right,path)
 path=path or 'config'
 assert(type(left)==type(right),path..' type changed')
 if type(left)~='table'then assert(left==right,path..' value changed');return end
 for k,v in pairs(left)do equal(v,right[k],path..'.'..tostring(k))end
 for k in pairs(right)do assert(left[k]~=nil,path..'.'..tostring(k)..' is missing')end
end
local cfg=C.new();C.apply(cfg,C.split_defaults)
local cache=C.render_cache()
local function check(config,weapon)
 local value=cache(config,weapon)
 equal(value,C.effective(config,weapon));return value
end
local first=check(cfg,a)
assert(check(cfg,a)==first,'unchanged settings allocate a new render config')
-- Every frame gets clean settings even after route-specific writes/removals.
first.scale=123;first.panel_opacity=nil;first.presentation_view='third'
first.native_panel_projector=function()end;first.world_texture_depth=27
first.style_clock=20;first.layout_cache_token={};first.retained_mode='world'
first.shader_layers[1]={id=800,shader='carbon'}
assert(check(cfg,a)==first,'frame-only fields invalidated the saved input cache')
assert(first.native_panel_projector==nil and first.world_texture_depth==nil and first.style_clock==nil)
assert(cfg.scale==1 and cfg.panel_opacity==.35 and #cfg.shader_layers==0)
-- Both supported control changes and direct live edits invalidate immediately.
C.apply(cfg,{text_color='#FFFFFF',panel_edge_softness=12});assert(check(cfg,a)~=first)
cfg.panel_opacity=.2;check(cfg,a)
cfg.live_test_flag=true;check(cfg,a);cfg.live_test_flag=nil;check(cfg,a)
C.set_panel(cfg,a,{font_scale=1.2,panel_opacity=.7,shader_layers={{id=1,shader='carbon',strength=2}}})
local panel=check(cfg,a);assert(panel.font_scale==1.2 and panel.shader_layers[1].opacity==.35)
cfg.weapon_panels[a].panel_opacity=.9;check(cfg,a)
cfg.weapon_panels[a].shader_layers[1].strength=3
assert(check(cfg,a).shader_layers[1].opacity==.675,'in-place weapon shader edit stayed stale')
cfg.weapon_panels[a].shader_layers[1].opacity=.13;check(cfg,a)
cfg.weapon_panels[a].shader_layers[1].opacity=nil;check(cfg,a)
cfg.weapon_panels[a].shader_layers[2]={id=2,shader='circuit',opacity=.5};check(cfg,a)
table.remove(cfg.weapon_panels[a].shader_layers,1);check(cfg,a)
local render=check(cfg,a)
render.shader_layers[1].opacity=.99;render.shader_layers[1].extra=true
render.shader_layers[2]={id=999};render.shader_layers.extra={}
check(cfg,a)
render.shader_layers[1]=false;check(cfg,a)
render.shader_layers={};check(cfg,a)
-- Switching weapons and complete config replacement must never share state.
assert(check(cfg,b).font_scale==1 and check(cfg,a).font_scale==1.2)
local other=C.new();C.apply(other,C.split_defaults);C.apply(other,{font_scale=.8})
assert(check(other,a).font_scale==.8);check(cfg,a)
local second=C.render_cache();local independent=second(cfg,a)
assert(independent~=cache(cfg,a),'runtime instances shared their mutable render config')
-- Replacing/removing overrides and shader lists includes the legacy shader path.
cfg.weapon_panels[a]={texture_art_variant='original'};check(cfg,a)
cfg.weapon_panels[a]=nil;cfg.shader_layers=nil;cfg.theme_shader='carbon';check(cfg,a)
cfg.effect_shader='crt_scan';check(cfg,a)
cfg.shader_layers={{id=1,shader='carbon'}};check(cfg,a)
cfg.shader_layers[1].animate=true;cfg.shader_layers[1].speed=2;check(cfg,a)
C.set_panel(cfg,a,{texture_art_trial=true,texture_art_variant='split'})
C.apply(cfg,{force_all_hud_texture_off=true})
assert(check(cfg,a).texture_art_trial==false,'cache bypassed the global texture policy')
C.apply(cfg,{force_all_hud_texture_off=false});assert(check(cfg,a).texture_art_trial==true)
local public=C.effective(cfg,a);public.shader_layers[1].shader='crt_scan'
assert(C.effective(cfg,a).shader_layers[1].shader=='carbon','public menu settings are no longer independent')
-- Invalid edits still raise the same normalization error rather than reusing old output.
cfg.shader_layers[1].shader='missing'
assert(not pcall(cache,cfg,a)and not pcall(C.effective,cfg,a))
print('PASS render settings cache: exact effective parity, clean frame fields, direct scalar/nested edits, weapon/instance isolation, texture policy and invalid-edit rejection')
