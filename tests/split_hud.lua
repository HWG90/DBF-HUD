-- Study 08 presentation contracts. Offline LuaJIT only; no game/native calls.
HUD={weapon_names=dofile('src/weapon_names.lua'),segmented_primary_specs=dofile('src/segmented_primary_specs.lua'),native_font_data=dofile('src/native_font_data.lua')}
HUD.config=dofile('src/config.lua');HUD.font=dofile('src/font.lua');HUD.model=dofile('src/model.lua');HUD.layout=dofile('src/layout.lua')
HUD.edge_mask=dofile('src/edge_mask.lua');HUD.split_hud_assets=dofile('src/split_hud_assets.lua')
HUD.split_hud=dofile('src/split_hud.lua')
local S,A=HUD.split_hud,HUD.split_hud_assets
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
local function near(a,b,message)assert(finite(a)and math.abs(a-b)<1e-8,message or 'geometry differs from Study 08')end
local function copy(t)local q={};for k,v in pairs(t or {})do q[k]=v end;return q end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function role(out,name)local q={};for _,v in ipairs(out)do if v.split_role==name then q[#q+1]=v end end;return q end
local function text(out,str,name)for _,v in ipairs(out)do if v.type=='text'and v.text==str and(not name or v.split_role==name)then return v end end end
local function chars(out)local q={};for _,v in ipairs(role(out,'loaded'))do if v.digit_character and not v.outline then q[#q+1]=v.digit_character end end;return table.concat(q)end
local resources={};for _,name in ipairs({A.face,A.atlas,A.coverage,A.hard_coverage})do resources[name]=true end
local function resource(name)return resources[name]end
local function can_get(kind,name)return kind=='material'and name==A.material end
local function config(extra)local c=HUD.config.new();c.texture_art_trial=true;c.texture_art_variant='split';c.hud_presentation='fancy';c.font='hack';c.font_scale=1;c.panel_opacity=.35;c.split_readout_view='combat';c.panel_spatial_depth=16;c.decoration='split';c.text_color='#F5F6F0';c.decoration_color='#E9C45D';c.background_color='#091B35';c.heat_red='#FF5750';c.heat_yellow='#E9C45D';for k,v in pairs(extra or {})do c[k]=v end;return c end
local function model(extra)local m={resource_hex='968211c0033dce64',kind='magazine',value=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',state='READY',fraction=.6};for k,v in pairs(extra or {})do m[k]=v end;return m end
local function compose(m,cfg,clock,x,y,scale,opacity)return assert(S.compose(m,x or 0,y or 0,scale or 1,opacity or 1,cfg or config(),clock or 0,resource,can_get),'Split composer unexpectedly unavailable')end
local function numeric(out)
 local q={};for _,v in ipairs(role(out,'loaded'))do if v.type=='texture'and v.digit_character and not v.outline then q[#q+1]=v end end;return q
end
local function count_images(out)local n=0;for _,v in ipairs(out)do if v.type=='texture'then n=n+1 end end;return n end

-- Assets retain the selected glyphs while fitting the established image budget.
assert(A.width==320 and A.height==161 and A.gameplay_scale==.7)
assert(A.atlas_width==1024 and A.atlas_height==512 and equal(A.atlas_pixel_dimensions,{2048,1024}),'Physical 2x raster changed logical UV coordinates')
assert(equal(A.digit_uv(4,false),{328/1024,8/512,72/1024,118/512}))
assert(equal(A.digit_uv(0,true),{8/1024,144/512,72/1024,118/512}))
assert(equal(A.outline_uv(4),{328/1024,384/512,72/1024,118/512}))
assert(equal(A.quiet_zero_outline_uv,{800/1024,264/512,72/1024,118/512}),'Quiet-zero outline must preserve .075 inactive strokes')
assert(A.infinity and A.infinity_outline,'Infinite energy needs an authored sprite and independent outline')
for _,kind in ipairs({'MAGS','BELTS','SHELLS','SINKS','SHOTS','TANKS','PACK','ENERGY','HEAT','AUTO','RPM','SAFE','AMMO','SINGLE'})do assert(A.icons[kind],'Typed symbol missing: '..kind)end
for _,kind in ipairs({'AUTO','RPM','AMMO','SAFE','SINGLE'})do assert(A.context_nodes[kind]and A.inspect_context_nodes[kind],'Combined combat/inspect setting node missing: '..kind)end

for _,settings in ipairs({{hud_presentation='practical'},{texture_art_trial=false},{force_all_hud_texture_off=true},{texture_art_variant='original'},{texture_art_variant='faithful'}})do
 assert(not S.compose(model(),0,0,1,1,config(settings),0,resource,can_get),'Existing alternate/Simple selection was overridden')
end
assert(not S.compose(model(),0,0,1,1,config(),0,nil,can_get),'Missing resource callback must fall back')
assert(not S.compose(model(),0,0,1,1,config(),0,resource,function()return false end),'Missing material must fall back')
resources[A.atlas]=false;assert(not S.compose(model(),0,0,1,1,config(),0,resource,can_get),'False atlas handle treated as ready');resources[A.atlas]=true
assert(not S.compose(model({resource_hex='ffffffffffffffff'}),0,0,1,1,config(),0,resource,can_get),'Unknown identity was silently adopted')

local base=compose(model());assert(base[1].type=='panel'and base[1].a==0 and base[1].w==320 and base[1].h==161 and base[1].hud_texture_split)
-- HMG must enter Split through the same catalog gate as the runtime.
assert(S.supported('2152d5147b0ac418'),'Heavy Machine Gun missing from Split catalog')
for _,view in ipairs({'first','third'})do
 local hmg=compose(model({resource_hex='2152d5147b0ac418',value=75,capacity=100,reserve=2}),config({presentation_view=view}))
 assert(hmg[1].hud_texture_split and chars(hmg)=='75'and text(hmg,'MG-206'),'HMG must use shared Split artwork in both views')
end
local digits=numeric(base);assert(#digits==2,'Combat number has an unnecessary leading register')
for i,v in ipairs(digits)do near(v.x,88+(i-1)*76*48/118);near(v.y,60);near(v.w,72*48/118);near(v.h,48);assert(equal(v.atlas_rect,A.digit_uv(tonumber(v.digit_character),false)),'Selected glyph crop changed')end
assert(chars(base)=='27'and text(base,'/ 45')and text(base,'6','reserve')and text(base,'MAGS')and text(base,'AUTO','context'))
assert(text(base,'AR-23')and text(base,'ROUNDS'),'Study identity/resource hierarchy was lost')
local scaled=compose(model(),nil,0,10,20,.7,.8);local dscaled=numeric(scaled)
near(scaled[1].w,224);near(scaled[1].h,112.7);near(dscaled[1].x,10+88*.7);near(dscaled[1].y,20+60*.7);near(dscaled[1].h,33.6)
local gauge=role(base,'gauge');assert(#gauge>=1,'Immediate resource proportion is missing')
near(role(base,'gauge_inactive')[1].a,1,'Study gauge opacity is already encoded in its sprite and must not be applied twice')
near(role(base,'reserve')[1].a,1,'Study reserve-connector opacity is already encoded in its sprite and must not be applied twice')
local full=role(base,'backing')[1];assert(full and full.coverage_mask and equal(full.atlas_rect,{0,0,1,1}),'Existing shader carrier must retain full UVs')
for _,v in ipairs(role(base,'loaded'))do
 if v.type=='texture'then assert(v.texture_layer%1==0 and v.texture_layer>full.texture_layer,'Counter must sort above backing on an integer layer')end
 if v.outline then assert(v.texture_layer<digits[1].texture_layer,'Outline must sort below lit digits')end
end
assert(role(base,'gauge_inactive')[1].texture_layer<gauge[1].texture_layer,'Inactive gauge must sort below fill')
local transparent=compose(model(),config({panel_opacity=0}));assert(role(transparent,'backing')[1].a==0)
for i,v in ipairs(base)do if v.split_role~='backing'then assert(equal(v,transparent[i]),'Panel opacity changed crisp foreground')end end
for _,size in ipairs({.25,1,4})do local c=role(compose(model(),config({theme_shader_scale=size})),'backing')[1];assert(equal(c.atlas_rect,{0,0,1,1}),'Pattern scale changed shader UVs')end
for _,v in ipairs(base)do assert(v.type~='rect','Authored Split artwork regressed to Lua rectangles');assert(type(v.spatial_plane)=='string','3D grouping is missing')end

local families={
 magazine=model(),
 belt=model({resource_hex='11c27d3babb38956',value=146,capacity=175,reserve=2,reserve_kind='BELTS',fire_mode=false,rpm=760,rpm_selectable=true,fraction=146/175}),
 shells=model({resource_hex='41eac4a03987faa0',kind='rounds',value=9,capacity=16,reserve=34,reserve_kind='SHELLS',fire_mode=false,fraction=9/16}),
 heat=model({resource_hex='8645f167b3c813a2',kind='heat',value=38,capacity=false,reserve=3,reserve_kind='SINKS',fire_mode=false,fraction=.38}),
 charge=model({resource_hex='2e9d0bdc48b09e60',kind='rounds',value=1,capacity=1,reserve=16,reserve_kind='SHOTS',fire_mode=false,safety_mode='SAFE',charge_fraction=.68*.7,fraction=1}),
 ammo=model({resource_hex='9f80d67a12a7e40f',kind='rounds',value=1,capacity=1,reserve=5,reserve_kind='PACK',fire_mode=false,ammo_mode='HEAT',fraction=1}),
 expendable=model({resource_hex='b2b5e0d185605f9e',kind='rounds',value=1,capacity=1,reserve=false,reserve_kind=false,fire_mode=false,reloadable=false,fraction=1}),
 fuel=model({resource_hex='4fb0f8c02f55c82b',kind='resource',label='FUEL',value=65,capacity=80,reserve=3,reserve_kind='TANKS',fire_mode=false,fraction=65/80}),
 infinite=model({resource_hex='076dd5d4f4360204',kind='infinite',value='--',capacity=false,reserve=false,reserve_kind=false,fire_mode=false,fraction=1})
}
local max_images,cases=0,0
for name,m in pairs(families)do for _,view in ipairs({'combat','inspect'})do
 local out=compose(m,config({split_readout_view=view}));local image_count=count_images(out);max_images=math.max(max_images,image_count);assert(image_count<=20,'Established four-shader image budget exceeded: '..name)
 local expected_h=view=='inspect'and 178 or 161;assert(out[1].h==expected_h and out[1].w==(view=='inspect'and 410 or 320),'Study detail canvas changed')
 if m.reserve~=false then assert(text(out,tostring(m.reserve),'reserve')and text(out,m.reserve_kind),'Native reserve count/unit was changed: '..name)else assert(#role(out,'reserve')==0,'Unsupported reserve was fabricated: '..name)end
 if name=='shells'then assert(#role(out,'context')==0,'Fixed fire mode invented a selector row')end
 if name=='fuel'then assert(text(out,'FUEL'),'Fuel renamed to generic ammunition')end
 if name=='heat'then assert(text(out,'HEAT')and text(out,'%'),'Heat reading needs clear resource/percentage semantics')end
 if name=='charge'then assert(chars(out)=='68'and text(out,'1 LOADED')and text(out,'SAFE','context'),'Charge priority/loaded shot/safety were conflated')end
 if name=='expendable'then local supply=text(out,'SINGLE USE','context')or(text(out,'SINGLE','context')and text(out,'USE','context'));assert(supply and not text(out,'/ 1'),'Single use invented spare capacity')end
 if name=='infinite'then local symbol,outline_index,symbol_index=false;for i,v in ipairs(role(out,'loaded'))do if equal(v.atlas_rect,A.infinity.uv)then symbol=true;symbol_index=i elseif v.outline then outline_index=i end end;assert(symbol and not text(out,'/ 0'),'Infinite supply must remain a symbol');assert(outline_index and outline_index<symbol_index,'The thick navy infinity outline covers the luminous energy symbol')end
 cases=cases+1
end end
-- Exercise the actual provider-to-model boundary too; presentation samples alone
-- cannot prove native units, selectable fields, and single-use state survive it.
local provider_cases={
 {'magazine',{resource_hex='968211c0033dce64',kind='magazine',rounds=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO'},27,'ROUNDS'},
 {'belt',{resource_hex='11c27d3babb38956',kind='magazine',rounds=146,capacity=175,reserve=2,reserve_kind='BELTS',rpm=760,rpm_selectable=true},146,'ROUNDS'},
 {'shells',{resource_hex='41eac4a03987faa0',kind='rounds',rounds=9,capacity=16,reserve=34,reserve_kind='SHELLS'},9,'SHELLS'},
 {'heat',{resource_hex='8645f167b3c813a2',kind='heat',heat=.38,reserve=3,reserve_kind='SINKS'},38,'HEAT'},
 {'charge',{resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,reserve=16,reserve_kind='SHOTS',safety_mode='SAFE',charge_fraction=.476},68,'CHARGE'},
 {'ammo',{resource_hex='9f80d67a12a7e40f',kind='rounds',rounds=1,capacity=1,reserve=5,reserve_kind='PACK',ammo_mode='HEAT'},1,'LOADED'},
 {'expendable',{resource_hex='b2b5e0d185605f9e',kind='rounds',rounds=1,capacity=1,reloadable=false},1,'LOADED'},
 {'fuel',{resource_hex='4fb0f8c02f55c82b',kind='resource',rounds=65,capacity=80,label='FUEL',reserve=3,reserve_kind='TANKS'},65,'FUEL'},
 {'infinite',{resource_hex='076dd5d4f4360204',kind='infinite'},false,'ENERGY'}
}
for _,case in ipairs(provider_cases)do
 local name,raw,expected_value,label=unpack(case);local normalized=assert(HUD.model.normalize(raw));local r=S.readouts(normalized,config())
 assert(r.value==(expected_value or nil)and r.label==label,'Provider-normalized readout changed: '..name)
 assert(r.reserve==raw.reserve and r.unit==raw.reserve_kind,'Provider reserve unit/count changed: '..name)
 if raw.reloadable==false then assert(normalized.reloadable==false and r.sub=='ONE SHOT','Single-use provider flag was discarded')end
 if raw.rpm then assert(normalized.rpm==raw.rpm and r.contexts[1].kind=='RPM','Verified selectable RPM was discarded')end
 compose(normalized)
end
local mixed=model({value=123,capacity=200,reserve=8,reserve_kind='BELTS',fire_mode='AUTO',rpm=900,rpm_selectable=true,ammo_mode='HE',safety_mode='UNSAFE',fraction=123/200})
for _,view in ipairs({'combat','inspect'})do
 local out=compose(mixed,config({split_readout_view=view}));assert(chars(out)=='123'and text(out,'AUTO','context')and text(out,'900 RPM','context')and text(out,'HE','context')and text(out,'UNSAFE','context'),'Four independent selected settings were collapsed')
 if view=='inspect'then for _,s in ipairs({'FIRE SELECT','FIRE RATE','AMMUNITION','SAFETY'})do assert(text(out,s),'Inspect setting name missing: '..s)end end
 assert(count_images(out)<=20,'Mixed capability specimen exhausted shader budget')
end

local chamber=model({value=46,chamber_bonus=1,fraction=1});local chamber_out=compose(chamber);assert(chars(chamber_out)=='46'and text(chamber_out,'CHAMBERED +1','status'),'Reader-owned chamber count/status changed')
assert(not text(compose(model({value=46,fraction=1})),'CHAMBERED +1'),'Chamber bonus inferred without native flag')
local verified=HUD.model.normalize({resource_hex='968211c0033dce64',kind='magazine',rounds=46,capacity=45,reserve=6,reserve_kind='MAGS',chamber_supported=true,chamber_rounds=1});assert(verified.chamber_bonus==1 and chars(compose(verified))=='46','Normalized native chamber value was altered')
local empty=model({value=0,fraction=0,state='EMPTY'});local bright,dim=compose(empty,nil,0),compose(empty,nil,.25);assert(text(bright,'EMPTY','status')and chars(bright)=='00')
local changed=0;for i,v in ipairs(bright)do if not equal(v,dim[i])then changed=changed+1;assert(v.split_role=='loaded','Empty flash affected a non-counter element');if not v.outline then assert(v.c[1]==255 and v.c[2]==87 and v.c[3]==80,'Empty counter is not red')end;near(dim[i].a,v.a*.22,'Empty pulse is not bounded')end end
assert(changed>0 and equal(bright,compose(empty,nil,.5)),'Empty counter must flash at 2Hz')
assert(equal(bright,compose(empty,config({reduced_motion=true}),.25)),'Reduced motion unexpectedly flashed')
local empty_reload=copy(empty);empty_reload.reloading=true
local reload_empty_out=compose(empty_reload)
assert(text(reload_empty_out,'RELOADING','status'),'Native reload status was lost')
for _,v in ipairs(numeric(reload_empty_out))do assert(equal(v.c,{255,87,80}),'Reloading changed an empty counter away from red')end
assert(equal(compose(model()),compose(model(),nil,.25)),'Refilled counter retained empty flash')
local spent=copy(families.expendable);spent.value=0;spent.fraction=0;spent.state='SPENT';assert(text(compose(spent),'SPENT','status'),'Expendable empty state lost SPENT')
local unknown=model({value=false,capacity=false,reserve=false,fraction=false,unknown=true});local out=compose(unknown);assert(chars(out)=='--'and text(out,'NO DATA','status'),'Unknown reading turned into zero')
assert(equal(out,compose(unknown,nil,.25)),'Unknown data falsely flashed as empty')
local hot=copy(families.heat);hot.value=100;hot.fraction=1;hot.state='VENT';hot.warning=true;assert(text(compose(hot),'VENTING','status')or text(compose(hot),'VENT','status'),'Native venting state disappeared')
local hot_bright,hot_dim=compose(hot,nil,0),compose(hot,nil,.25)
near(numeric(hot_dim)[1].a,numeric(hot_bright)[1].a*.25,'Existing 2Hz venting pulse was lost')
assert(equal(hot_bright,compose(hot,config({reduced_motion=true}),.25)),'Reduced motion retained venting pulse')
local hot_gauge=role(compose(hot),'gauge')[1];assert(hot_gauge.c[1]==255 and hot_gauge.c[2]==87 and hot_gauge.c[3]==80,'Venting gauge lost the Study danger color')
local quasar=model({resource_hex='35a61296619cc47e',kind='heat',value=68,capacity=false,reserve=3,reserve_kind='SINKS',fire_mode=false,fraction=.68,quasar_charge_verified=true});local qout=compose(quasar);assert(text(qout,'CHARGE')and not text(qout,'HEAT'),'Verified Quasar charge mislabeled as heat')
assert(not S.readouts(quasar,config()).sub:find('LOADED',1,true),'Quasar charge percentage was fabricated into loaded ammunition')
assert(#role(qout,'reserve')==0,'Quasar fabricated a replaceable heat-sink reserve')
local arbitrary=model({resource_hex='30061f91af477f5e',charge_fraction=.5});assert(not text(compose(arbitrary),'CHARGING'),'Unverified generic charge field became a charge reading')
local fixed=HUD.model.normalize({resource_hex='11c27d3babb38956',kind='magazine',rounds=146,capacity=175,rpm=760,rpm_selectable=false});assert(not fixed.rpm,'Fixed RPM became a selectable setting')
local danger=assert(HUD.model.normalize({resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,reserve=16,reserve_kind='SHOTS',safety_mode='UNSAFE',charge_fraction=.976,charge_seconds=2.8}))
danger.charge_sample_clock=5;danger.charge_frame_delay=1/60
assert(text(compose(danger,nil,5.05),'RELEASE','status'),'Verified unsafe reaction margin was lost by the new readout')
assert(not text(compose(danger,nil,5.3),'RELEASE','status'),'Stale unsafe timer fabricated a release warning')

-- Restore weapon behavior from the retained native normalizer/state machines,
-- independently of the old artwork. Counts and reserved units stay untouched.
local function native(raw)return assert(HUD.model.normalize(raw),'Native behavior fixture failed to normalize')end
local function cannon(n)return native({resource_hex='a8cffb316f0b5c5f',kind='rounds',rounds=n,capacity=10,reserve=30,reserve_kind='ROUNDS',ammo_mode='FLAK'})end
for _,n in ipairs({10,6})do local m=cannon(n);assert(not m.reload_reminder and equal(compose(m,nil,0),compose(m,nil,.25)),'Autocannon above five retained its reminder pulse')end
for _,n in ipairs({5,4,3,2,1})do
 local m=cannon(n);local bright,dim=compose(m,nil,0),compose(m,nil,.25)
 assert(m.reload_reminder and chars(bright)==string.format('%02d',n),'Autocannon native count/reminder was lost')
 near(numeric(dim)[1].a,numeric(bright)[1].a*.35,'Autocannon <=5 must retain its smooth 2Hz reload reminder')
 assert(text(bright,n<=3 and'LOW AMMO'or'RELOAD ADVISED','status'),'Autocannon <=3 warning and <=5 reminder were conflated')
 assert(equal(role(bright,'reserve'),role(dim,'reserve'))and equal(role(bright,'context'),role(dim,'context')),'Autocannon counter flash affected reserves/settings')
 local reduced=compose(m,config({reduced_motion=true}),.25);near(numeric(reduced)[1].a,1,'Reduced motion did not stop the reminder')
end
local slow=config({flash_hz=.5,heat_yellow='#AABBCC'});local slow_bright,slow_dim=compose(cannon(3),slow,0),compose(cannon(3),slow,1)
near(numeric(slow_dim)[1].a,numeric(slow_bright)[1].a*.35,'Saved reminder frequency was ignored')
assert(equal(numeric(slow_dim)[1].c,{170,187,204}),'Saved low-ammo warning color was ignored')
local zero_cannon=compose(cannon(0),nil,.25);near(numeric(zero_cannon)[1].a,.22,'Empty counter must override the clip reminder pulse');assert(text(zero_cannon,'EMPTY','status'))
local refilled_cannon=compose(cannon(10),nil,.25);near(numeric(refilled_cannon)[1].a,1,'Refilled Autocannon retained reminder pulse')

for _,case in ipairs({{.64,false,'#F5F6F0'},{.65,'gold','#E9C45D'},{.84,'gold','#E9C45D'},{.85,'red','#FF5750'},{.94,'red','#FF5750'}})do
 local f,warning=case[1],case[2];local m=native({resource_hex='8645f167b3c813a2',kind='heat',heat=f,reserve=3,reserve_kind='SINKS'})
 local cfg=config({heat_white='#F5F6F0'});local r=S.readouts(m,cfg,0);assert(r.warning==(warning or nil),'Prior heat band changed at '..f)
 assert(equal(numeric(compose(m,cfg,0))[1].c,HUD.config.rgb(case[3])),'Prior heat band tint changed at '..f)
end
local near_vent=native({resource_hex='8645f167b3c813a2',kind='heat',heat=.95})
assert(equal(numeric(compose(near_vent,nil,0))[1].c,{255,87,80})and equal(numeric(compose(near_vent,nil,.25))[1].c,{233,196,93}),'95% heat counter must alternate red/gold at the saved warning rate')
assert(equal(role(compose(near_vent,nil,.0625),'gauge')[1].c,HUD.config.rgb(config().heat_white)),'Prior fast heat danger gauge cue was lost')
assert(equal(numeric(compose(near_vent,config({reduced_motion=true}),.25))[1].c,{255,87,80}),'Reduced motion must keep heat danger steadily red')

for _,label in ipairs({'FUEL','GAS'})do for _,case in ipairs({{36,nil},{35,'gold'},{15,'red'}})do
 local m=native({resource_hex=label=='GAS'and'88f61afff48ac8a4'or'4fb0f8c02f55c82b',kind='resource',rounds=case[1],capacity=100,label=label,reserve=2,reserve_kind='TANKS'})
 local r=S.readouts(m,config());assert(r.label==label and r.warning==case[2],'Fuel/gas 35% and 15% warning bands were lost')
 if case[2]then assert(r.status=='LOW '..label)end
end end
local purifier=native({resource_hex='fb3a19078694708a',kind='magazine',rounds=8,capacity=15,reserve=4,reserve_kind='MAGS',purifier_charge_fraction=1,charge_ready=true})
local pur_bright,pur_dim=compose(purifier,nil,0),compose(purifier,nil,.25)
assert(text(pur_bright,'CHARGED','status')and chars(pur_bright)=='100'and text(pur_bright,'8 LOADED'),'Purifier full-charge cue changed the loaded ammunition')
near(numeric(pur_dim)[1].a,numeric(pur_bright)[1].a*.35,'Purifier ready counter pulse was lost')
purifier.charge_ready=false;assert(equal(compose(purifier,nil,0),compose(purifier,nil,.25)),'Purifier readiness inferred without the existing verified flag')
local epoch=native({resource_hex='e8d5f49ad7780e54',kind='magazine',rounds=6,capacity=8,reserve=3,reserve_kind='MAGS',epoch_charge_fraction=1})
near(role(compose(epoch,nil,.125),'gauge')[1].a,.35,'Epoch full-charge 4Hz red gauge warning was lost')
assert(equal(role(compose(epoch),'gauge')[1].c,{255,87,80})and text(compose(epoch),'CHARGED','status'))
local safe=native({resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,safety_mode='SAFE',charge_fraction=.7})
assert(text(compose(safe),'SAFE READY','status'),'Verified Railgun SAFE cap readiness was lost')
local early=native({resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,safety_mode='UNSAFE',charge_fraction=.82,charge_seconds=1.5});early.charge_sample_clock=5
assert(text(compose(early,nil,5),'UNSAFE 1.50s','status'),'Verified unsafe time remaining was lost')
local limit=native({resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,safety_mode='UNSAFE',charge_fraction=1,charge_seconds=3});limit.charge_sample_clock=5
assert(text(compose(limit,nil,5),'LIMIT','status'),'Railgun limit was collapsed into the earlier release margin')
local fallback=native({resource_hex='2e9d0bdc48b09e60',kind='rounds',rounds=1,capacity=1,safety_mode='UNSAFE',charge_fraction=.94,charge_warning=true})
assert(not equal(role(compose(fallback,nil,0),'gauge')[1].c,role(compose(fallback,nil,.125),'gauge')[1].c),'Existing verified unsafe warning fallback stopped flashing')

HUD.senator_state=dofile('src/senator_state.lua');HUD.df_shell_state=dofile('src/df_shell_state.lua');HUD.df_reload_state=dofile('src/df_reload_state.lua');HUD.recoilless_state=dofile('src/recoilless_state.lua');HUD.mg_easter=dofile('src/mg_easter.lua')
local senator_state=HUD.senator_state.new()
for _,n in ipairs({6,5,4,0,2,6})do
 local m=native({id=17,unit_ref=31,resource_hex='8d3d52a3b2f19402',kind='rounds',rounds=n,capacity=6,reserve=40,reserve_kind='ROUNDS',fire_mode='SEMI'})
 HUD.senator_state.step(senator_state,m,0);local out=compose(m);local slots=role(out,'gauge');local loaded=0
 assert(#slots==6,'Senator six-slot count-driven indicator was lost')
 for _,v in ipairs(slots)do assert(v.count_driven_slot and v.ammo_slot>=1 and v.ammo_slot<=6);loaded=loaded+(v.slot_loaded and 1 or 0)end
 assert(loaded==n and chars(out)==string.format('%02d',n),'Senator count transition invented loaded chambers');assert(count_images(out)+4<=24,'Senator indicator exhausted existing shader/image slots')
end
local shell_state,reload_state=HUD.df_shell_state.new(),HUD.df_reload_state.new()
for _,n in ipairs({2,1,0,2})do
 local m=native({id=3,unit_ref=4,resource_hex='72170a55a1f37ff1',kind='rounds',rounds=n,capacity=2,reserve=20,reserve_kind='SHELLS',fire_mode='SEQUENTIAL'})
 HUD.df_shell_state.step(shell_state,m);HUD.df_reload_state.step(reload_state,m)
 local out=compose(m);local slots=role(out,'gauge');assert(#slots==2 and slots[1].slot_loaded==(n>=2)and slots[2].slot_loaded==(n>=1),'Double Freedom sequential barrel indications changed')
 if n==1 then assert(slots[1].slot_observed_spent and not slots[2].slot_observed_spent,'Observed first-barrel shot latch was lost')end
 assert(count_images(out)+4<=24,'Double Freedom indicator exhausted existing image slots')
end
local reload=native({id=3,unit_ref=4,resource_hex='72170a55a1f37ff1',kind='rounds',rounds=0,capacity=2})
HUD.df_reload_state.step(reload_state,reload,{verified=true,weapon_id=3,unit_ref=4,phase='start'});assert(text(compose(reload),'RELOADING','status'),'Verified Double Freedom reload event was lost')
HUD.df_reload_state.step(reload_state,reload,{verified=true,weapon_id=3,unit_ref=4,phase='cancel'});assert(text(compose(reload),'EMPTY','status'),'Cancelled reload remained open')
local rr_state=HUD.recoilless_state.new();local rr=native({id=5,unit_ref=6,resource_hex='9f80d67a12a7e40f',kind='rounds',rounds=1,capacity=1})
HUD.recoilless_state.step(rr_state,rr);rr.value=0;rr.fraction=0;rr.state='EMPTY';HUD.recoilless_state.step(rr_state,rr);assert(text(compose(rr),'SPENT','status'),'Recoilless observed-shot latch was lost')
local mg=model({resource_hex='11c27d3babb38956',value=100,capacity=175,fraction=100/175,reserve_kind='BELTS',mg43_flash=true})
assert(text(compose(mg),'GET SOME!!!','status')and chars(compose(mg))=='100','Existing MG-43 easter egg displaced the native ammo readout')
assert(not text(compose(mg,config({mg43_easter_egg=false})),'GET SOME!!!','status'),'Disabled MG-43 easter egg was shown')
for _,case in ipairs({{0,'HDG 000 N'},{45,'HDG 045 NE'},{270,'HDG 270 W'},{359.7,'HDG 000 N'},{-90,'HDG 270 W'}})do
 local m=model({resource_hex='4dbd74f49c8ffc13',compass_heading=case[1]});local out=compose(m)
 assert(text(out,case[2],'status')and S.readouts(m,config()).compass_heading==case[1]%360,'Existing heading source was lost or changed')
end
for _,invalid in ipairs({false,'90',math.huge,0/0})do assert(not S.readouts(model({compass_heading=invalid}),config()).compass_heading,'Invalid heading fabricated compass data')end
for _,critical in ipairs({model({value=0,fraction=0,compass_heading=90}),cannon(3),chamber,danger,reload})do
 critical.compass_heading=90;assert(not S.readouts(critical,config(),5.05).status:find('HDG',1,true),'Compass displaced a warning/chamber/charge/reload status')
end
local loose=compose(model({reserve=250,reserve_kind='ROUNDS'}));assert(text(loose,'250','reserve')and text(loose,'ROUNDS'),'Large loose reserve got converted into magazines')
local wide=compose(model({value=100000,capacity=100000,reserve=100000,reserve_kind='ROUNDS'}));assert(text(wide,'100000','loaded')and text(wide,'/ 100000','capacity')and text(wide,'100000','reserve'),'Large native counts were clipped or replaced by estimates')
local no_decor=compose(model(),config({decoration='none'}));assert(#role(no_decor,'decoration')==0 and chars(no_decor)=='27','None decoration was overridden by baked artwork')
local deep=compose(model(),config({panel_spatial_depth=32}));local flat=compose(model(),config({panel_spatial_depth=0}));local plane_depth={main=32,reserve=-16,context=57.6,status=0}
for _,v in ipairs(deep)do near(v.spatial_depth,plane_depth[v.spatial_plane],'Study spatial separation changed')end
for _,v in ipairs(flat)do near(v.spatial_depth,0,'Zero depth did not flatten the open cluster')end
local no_mutation=config();local before=copy(no_mutation);compose(model(),no_mutation);assert(equal(before,no_mutation),'Composer mutated saved settings')
print('PASS Split Study08: '..cases..' family/view compositions + '..#provider_cases..' native provider cases, exact geometry/units/chamber/charge, restored Autocannon reminders, heat/fuel/gas bands, charge readiness/danger, Senator/Double Freedom slots, observed reload/spent events, MG-43/idle compass status, saved/reduced-motion controls, shaders/depth and image budget (family max '..max_images..')')

-- Optional snapshot of actual production commands and retained native glyph UVs.
-- This path only writes an explicitly requested offline review directory.
local export=os.getenv('DBF_HUD_SPLIT_PREVIEW')
if export then
 HUD.native_font_uv=dofile('src/native_font_uv.lua')
 local folder=export:match('^(.*)[/\\][^/\\]+$')or'.'
 local function json(v)
  if type(v)=='string'then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"'end
  if type(v)=='number'or type(v)=='boolean'then return tostring(v)end
  assert(type(v)=='table','Unsupported snapshot field');local out={}
  if #v>0 then for _,q in ipairs(v)do out[#out+1]=json(q)end;return '['..table.concat(out,',')..']'end
  for k,q in pairs(v)do out[#out+1]=json(tostring(k))..':'..json(q)end;return '{'..table.concat(out,',')..'}'
 end
 local inputs={};local manifest=assert(io.open('assets/split-hud/manifest-additions.tsv','rb'))
 for line in manifest:lines()do
  local name,w,h,file=line:match('^(%S+)\t(%d+)\t(%d+)\t(%S+)')
  if name then local f=assert(io.open('assets/split-hud/'..file,'rb'));inputs[name]={width=tonumber(w),height=tonumber(h),rgba=f:read('*a')};f:close()end
 end;manifest:close()
 local palette=config({panel_edge_softness=7,panel_edge_dither=40,panel_edge_grain=2,panel_edge_curve=1})
 local generated=HUD.edge_mask.split_images(HUD.edge_mask.settings(palette),inputs.split_hud_hard_coverage_v1,inputs.split_hud_face_v1)
 local generated_meta={};for name,p in pairs(generated.images)do
  local file=name..'.rgba';local f=assert(io.open(folder..'/'..file,'wb'));f:write(p.rgba);f:close()
  resources['mods/dbf_hud/textures/'..name]=true
  generated_meta[name]={filename=file,width=p.width,height=p.height,bytes=#p.rgba}
 end
 local scenes={}
 local function scene(key,m,cfg,clock)
  local out=compose(m,cfg or palette,clock or 0)
  for _,v in ipairs(out)do if v.type=='text'then
   local face=HUD.native_font_data.faces[v.font];local uv=HUD.native_font_uv[v.font];local factor=v.size/face.em;local advance=0;v.preview_glyphs={}
   for i=1,#v.text do
    local code=v.text:byte(i);local g=face.glyphs[code]or face.glyphs[63];local coords=uv[code]or uv[63]
    local w,h=(g[4]-g[2])*factor,(g[5]-g[3])*factor
    if w>0 and h>0 then v.preview_glyphs[#v.preview_glyphs+1]={x=v.x+advance+g[2]*factor,y=v.y+g[3]*factor,w=w,h=h,atlas_rect={coords[1],coords[2],coords[3]-coords[1],coords[4]-coords[2]}}end
    advance=advance+g[1]*factor
   end
  end end
  scenes[key]={width=out[1].w,height=out[1].h,commands=out}
 end
 scene('ready',model());scene('chamber',chamber);scene('empty',empty);scene('empty-dim',empty,nil,.25);scene('unknown',unknown)
 scene('mixed',mixed);scene('mixed-inspect',mixed,config({split_readout_view='inspect',panel_edge_softness=7,panel_edge_dither=40,panel_edge_grain=2,panel_edge_curve=1}))
 for name,m in pairs(families)do scene('family-'..name,m)end
 local output={scenes=scenes,generated=generated_meta,font='hack',palette=palette,flat_review=true,spatial_depths_preserved_in_commands=true}
 local f=assert(io.open(export,'wb'));f:write(json(output));f:close()
 print('Exported '..export..' from actual Split compositor/native Hack glyph metrics')
end

-- Cache decisions must preserve the complete command output, including pulses.
local reuse=0
for _,m in ipairs({model(),empty,chamber,mixed,model({resource_hex='a8cffb316f0b5c5f',value=5,reload_reminder=true})})do
 local previous_key,previous_out
 for _,clock in ipairs({0,.01,.1,.249,.25,.26,.5,1,2})do
  local cfg=config();cfg.style_clock=clock
  local key=S.layout_key(m,cfg,1,clock,resource)
  local actual=compose(m,cfg,clock)
  if previous_key and S.same_layout(key,previous_key)then
   assert(equal(actual,previous_out),'Layout cache hid an animated or changed readout');reuse=reuse+1
  end
  previous_key,previous_out=key,actual
 end
end
assert(reuse>0,'Unchanged layouts never reused')
local cfg=config();local key=S.layout_key(model(),cfg,1,0,resource)
for _,change in ipairs({{font='bigblue'},{panel_opacity=.8},{decoration='none'},{scale=2},{split_readout_view='inspect'}})do
 assert(not S.same_layout(key,S.layout_key(model(),config(change),1,0,resource)),'Appearance change did not invalidate layout')
end
assert(not S.same_layout(key,S.layout_key(model({value=26}),cfg,1,0,resource)))
assert(not S.same_layout(key,S.layout_key(model(),cfg,.5,0,resource)))
resources[A.atlas]={replacement=true}
assert(not S.same_layout(key,S.layout_key(model(),cfg,1,0,resource)),'Texture replacement did not invalidate layout')
print('PASS cached Split output matches fresh commands across time; data, appearance, opacity and artwork invalidate immediately')


local c=config();local a=model({compass_heading=276.51});local b=model({compass_heading=276.52})
assert(equal(compose(a,c,0),compose(b,c,0)))
assert(S.same_layout(S.layout_key(a,c,1,0,resource),S.layout_key(b,c,1,0,resource)),
 'Undisplayed sub-degree heading invalidated layout')
b.compass_heading=277.51
assert(not S.same_layout(S.layout_key(a,c,1,0,resource),S.layout_key(b,c,1,0,resource)),
 'Displayed heading change did not invalidate layout')
