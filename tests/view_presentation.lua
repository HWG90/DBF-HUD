HUD={}
for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end end
local P=HUD.view_presentation;local cfg=HUD.config.new()
assert(P.select(true,true)=='first')
assert(P.select(true,false)=='third','stored first-person preference is not an active first-person camera')
assert(P.select(false,true)=='third','shoulder aiming is not first person')
assert(P.select(false,false)=='third')
assert(cfg.hud_presentation=='automatic')
for _,native in ipairs({true,false})do for _,aim in ipairs({true,false})do
 assert(P.select(native,aim,'practical')=='third');assert(P.select(native,aim,'weapon_specific')=='first')
end end
assert(P.select(nil,nil,'practical')=='third' and P.select(nil,nil,'weapon_specific')=='first')
assert(not pcall(HUD.config.apply,cfg,{hud_presentation='invalid'}))
for _,mode in ipairs({'automatic','practical','weapon_specific'})do
 HUD.config.apply(cfg,{hud_presentation=mode});local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(HUD.config.serialize(cfg)))());assert(restored.hud_presentation==mode)
end
HUD.config.apply(cfg,{hud_presentation='automatic'})
assert(P.select(nil,true)=='third' and P.select(true,nil)=='third','unknown camera state must remain practical')
local m=HUD.model.normalize({kind='rounds',rounds=2,capacity=2,reserve=31,reserve_kind='SHELLS',fire_mode='VOLLEY',resource_hex='72170a55a1f37ff1'})
local r=P.readouts(m,cfg);assert(r.loaded=='2' and r.reserve=='31' and r.mode=='VOLLEY')
local before=HUD.config.serialize(cfg)
for _,value in ipairs({0,1,2})do
 m.value=value;local out=P.compose(m,0,0,1,1,cfg)
 assert(out[1].w==64 and out[1].h==86 and #out<=14)
 for _,v in ipairs(out)do assert(v.type~='texture' and v.texture==nil);assert(v.x==v.x and v.y==v.y)end
 assert(P.readouts(m,cfg).loaded==tostring(value))
end
assert(HUD.config.serialize(cfg)==before,'drawing mutated settings')
assert(P.readouts({value=0,reserve=0},cfg).loaded=='0' and P.readouts({value=0,reserve=0},cfg).reserve=='0')
assert(P.readouts({},cfg).loaded=='?' and P.readouts({},cfg).reserve=='?','unknown must not become zero')
assert(P.readouts({kind='heat',value=90,fraction=.9,state='VENT'},cfg).state=='VENT')
assert(P.readouts({value=1,epoch_charge_fraction=.4},cfg).state=='CHARGE 40%')
assert(P.readouts({value=1,epoch_charge_fraction=1},cfg).state=='CHARGED')
assert(P.readouts({value=0,df_ejector_open=true},cfg).state=='RELOADING')
assert(P.readouts({value=0,state='EMPTY'},cfg).state=='EMPTY','empty does not imply reload')
assert(P.readouts({value=1,charge_fraction=0/0},cfg).progress==nil)
HUD.config.apply(cfg,{third_person_scale=.6,third_person_opacity=.7})
local copy=HUD.config.new();HUD.config.apply(copy,assert(loadstring(HUD.config.serialize(cfg)))());assert(copy.third_person_scale==.6 and copy.third_person_opacity==.7)
local df='72170a55a1f37ff1';HUD.config.set_panel(copy,df,{texture_art_trial=false,texture_art_variant='original'})
assert(HUD.config.effective(copy,df).texture_art_trial==false)
print('PASS camera switching, shoulder/unknown fallback, shared authoritative counts, heat/charge/reload states, no textures, bounded geometry and independent setting persistence')
