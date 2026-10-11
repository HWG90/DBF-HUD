-- Focused standalone presentation contract; no game/native calls.
HUD={segmented_primary_specs=dofile('src/segmented_primary_specs.lua')}
HUD.native_font_data=dofile('src/native_font_data.lua');HUD.font=dofile('src/font.lua')
HUD.edge_mask=dofile('src/edge_mask.lua')
local S=dofile('src/segmented_fancy.lua');local Scene=dofile('src/screen_scene.lua');local id='968211c0033dce64'
local resources={[S.face]=true,[S.atlas]=true}
local function resource(name)return resources[name]end
local function can_get(kind,name)return kind=='material'and name==S.material end
local function model(extra)local m={resource_hex=id,kind='magazine',value=27,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',state='READY',fraction=.6};for k,v in pairs(extra or {})do m[k]=v end;return m end
local function compose(m,cfg,clock)return assert(S.compose(m,10,20,1,.8,cfg or {},clock or 0,resource,can_get))end
local function equal(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not equal(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
local function role(out,name)local q={};for _,v in ipairs(out)do if v.segmented_role==name then q[#q+1]=v end end;return q end
local function contains(out,name,value)for _,v in ipairs(role(out,name))do if v.text==value then return true end end;return false end
local function lit(out,name)local q={};for _,v in ipairs(role(out,name))do if v.segment_lit then q[#q+1]=v end end;return q end
local identities=0;for _ in pairs(S.specs)do identities=identities+1 end;assert(identities==54)
assert(S.compose(model(),0,0,1,1,{presentation_view='third'})==nil,'Simple must be untouched')
assert(S.compose(model(),0,0,1,1,{hud_presentation='practical'})==nil,'Explicit Simple must be untouched')
assert(S.compose(model({resource_hex='e8d5f49ad7780e54'}),0,0,1,1,{})==nil,'Support weapon excluded')
assert(S.compose(model({resource_hex='416d053372c4e433'}),0,0,1,1,{})==nil,'Secondary excluded')
assert(S.compose(model({resource_hex='4e4a613eb9bf5c24'}),0,0,1,1,{})==nil,'Unresolved alias excluded')
assert(S.compose(model(),0,0,1,1,{},0)==nil,'Missing callbacks must not create primitive art')
assert(S.compose(model(),0,0,1,1,{},0,resource,function()return false end)==nil,'Material must be ready')
resources[S.face]=nil;assert(S.compose(model(),0,0,1,1,{},0,resource,can_get)==nil,'Face must be ready')
resources[S.face]=true;resources[S.atlas]=nil;assert(S.compose(model(),0,0,1,1,{},0,resource,can_get)==nil,'Atlas must be ready')
resources[S.atlas]=false;assert(not S.assets_ready(resource,can_get),'False resource handle treated as ready');resources[S.atlas]=true
assert(S.assets_ready(resource,can_get),'Newly ready assets were cached as unavailable')
assert(S.assets_ready(resource),'Existing HUD Texture resource-only readiness failed')
local ready=compose(model());local open=compose(model(),{panel_opacity=0});assert(role(open,'backing')[1].a==0 and role(ready,'backing')[1].a>0)
for i=1,#ready do if ready[i].segmented_role~='backing'then assert(equal(ready[i],open[i]),'Backing opacity changed foreground')end end
assert(ready[1].type=='panel'and ready[1].w==S.width and ready[1].h==S.height and ready[1].a==0 and ready[1].atlas_frame)
assert(equal(role(ready,'face')[1].atlas_rect,{32/256,32/512,174/256,304/512}))
assert(equal(role(ready,'backing')[1].atlas_rect,{988/1024,16/512,16/1024,16/512}))
resources[S.full_white]=true
local full=compose(model());local carrier=role(full,'backing')[1]
assert(carrier.texture_resource==S.full_white and carrier.coverage_mask and equal(carrier.atlas_rect,{0,0,1,1}),'Ready white backing must carry unit UVs for existing texture shaders')
for i=1,#ready do if ready[i].segmented_role~='backing'then assert(equal(ready[i],full[i]),'Full-UV backing changed the approved foreground')end end
for _,size in ipairs({.25,1,4})do
 local c=role(compose(model(),{theme_shader_scale=size}),'backing')[1]
 assert(equal(c.atlas_rect,{0,0,1,1})and c.x==carrier.x and c.y==carrier.y and c.w==carrier.w and c.h==carrier.h,'Pattern scale changed the full-panel carrier coordinates')
end
resources[S.full_white]=false;assert(role(compose(model()),'backing')[1].texture_resource==S.atlas and S.assets_ready(resource,can_get),'Pending white resource blanked the established artwork')
resources[S.full_white]=nil
assert(S.edge_softness(nil)==4 and S.edge_softness(0)==0 and S.edge_softness(2)==2 and S.edge_softness(6)==6 and S.edge_softness(10)==10 and S.edge_softness(99)==24 and S.edge_softness(-1)==0 and S.edge_softness(0/0)==4,'Edge softness quantization changed')
resources[S.full_white]=true
local hard=compose(model(),{panel_edge_softness=0})
assert(not hard[1].edge_mask_resource and role(hard,'backing')[1].texture_resource==S.full_white,'Zero softness must retain hard edges')
for _,softness in ipairs({4,8,12})do
 local name=HUD.edge_mask.resource;resources[name]=false
 local pending=compose(model(),{panel_edge_softness=softness})
 assert(not pending[1].edge_mask_resource and role(pending,'backing')[1].texture_resource==S.full_white,'Pending edge mask must preserve the hard backing')
 resources[name]=true;local feather=compose(model(),{panel_edge_softness=softness});local backing=role(feather,'backing')[1]
 assert(feather[1].a==0 and feather[1].edge_mask_resource==name and feather[1].edge_mask_material==S.material and backing.texture_resource==name and backing.coverage_mask and equal(backing.atlas_rect,{0,0,1,1}),'Ready feather mask must be shared by backing and perimeter')
 for i=2,#hard do if hard[i].segmented_role~='backing'then assert(equal(hard[i],feather[i]),'Edge softness blurred or moved the approved foreground')end end
 local transparent=compose(model(),{panel_edge_softness=softness,panel_opacity=0})
 assert(transparent[1].edge_mask_resource==name and role(transparent,'backing')[1].a==0,'Transparent backing lost the outer-decoration mask')
 resources[name]=nil
end
resources[S.full_white]=nil
for _,v in ipairs(ready)do assert(not v.decoration and not v.segmented_fancy,'Intrinsic decoration/special renderer flag forbidden')end
assert(lit(ready,'loaded')[1].c[1]==245 and contains(ready,'reserve_unit','MAGS')and contains(ready,'mode','AUTO'))
local empty=model({value=0,fraction=0,state='EMPTY'});local bright,dim=compose(empty,{},0),compose(empty,{},.25)
assert(#bright==#dim and #lit(bright,'loaded')==3,'Three zero cells must use three active glyph textures')
for i,a in ipairs(bright)do local b=dim[i];if a.segmented_role=='loaded'and a.segment_lit then assert(a.c[1]==255 and a.c[2]==87);assert(math.abs(b.a-a.a*.22)<1e-9)else assert(equal(a,b),'Flash affected another readout')end end
assert(equal(bright,compose(empty,{},.5)),'Flash cycle must be 2Hz')
assert(equal(bright,compose(empty,{reduced_motion=true},.25)),'Reduced motion must remain steady red')
local lead=lit(bright,'loaded')[1];local significant=lit(bright,'loaded')[3];assert(lead.leading_zero and not significant.leading_zero and math.abs(lead.a/significant.a-.14)<1e-9)
for _,v in ipairs(role(bright,'loaded_ghost'))do assert(v.atlas_column==11 and not v.segment_lit and v.a==.8*.18,'Ghost/stroke cells must remain steady navy')end
local loaded=lit(ready,'loaded');local scale=78/118;local start=28+(154-(3*72+2*7)*scale)/2
for i,v in ipairs(loaded)do assert(math.abs(v.x-(10+start-18+(i-1)*79*scale))<1e-9 and v.h==78 and v.atlas_rect[3]==72/1024,'Selected LED crop/spacing/compact height changed')end
assert(equal(role(ready,'loaded_ghost')[1].atlas_rect,{256/1024,256/512,154/1024,78/512}),'Ghost strip crop differs from selected loaded box')
local low=compose(model({value=5,fraction=5/45}));assert(contains(low,'status','LOW AMMO')and lit(low,'loaded')[1].c[1]==233)
assert(equal(low,compose(model({value=5,fraction=5/45}),{},.25)),'Low ammo unexpectedly flashed')
local unknown=compose(model({value=false,capacity=false,reserve=false,fraction=false}));assert(contains(unknown,'status','NO DATA')and #lit(unknown,'loaded')==3)
for _,v in ipairs(lit(unknown,'loaded'))do assert(v.atlas_column==10 and v.digit_character=='-','Unknown value must select atlas dash')end
assert(equal(unknown,compose(model({value=false,capacity=false,reserve=false,fraction=false}),{},.25)),'Unknown reading flashed')
assert(contains(unknown,'mode','AUTO')and contains(unknown,'mode','BURST')and contains(unknown,'mode','SEMI'),'Approved fixed mode bank missing')
for _,v in ipairs(role(unknown,'mode'))do assert(v.mode_active==(v.text=='AUTO'),'Unknown count fabricated a different live mode')end
local no_mode=model();no_mode.fire_mode=nil;assert(contains(compose(no_mode),'mode','--'))
for _,mode in ipairs({'AUTO','BURST','SEMI'})do
 local bank=compose(model({fire_mode=mode}));local active=0
 for _,v in ipairs(role(bank,'mode'))do if v.mode_active then active=active+1;assert(v.text==mode)else assert(v.a==.8*.55)end end
 assert(active==1 and #role(bank,'mode_underline')==1,'Live mode bank selection/underline incorrect')
 local frame=role(bank,'mode_underline')[1]
 assert(frame.w==49 and frame.h==22 and equal(frame.atlas_rect,{448/1024,256/512,49/1024,22/512}),'Active mode outline/underline must share one bounded atlas crop')
end
local safety=compose(model({safety_mode='SAFE',fire_mode=false}));assert(contains(safety,'mode','SAFE')and #role(safety,'mode_underline')==0,'Unlisted native mode must remain explicit without a fabricated highlight')
for name,baseline in pairs({identity=44,name=44,loaded_label=67,status=194,capacity_label=218,reserve_label=260,reserve_unit=278,mode_label=296,mode=313})do
 for _,v in ipairs(role(ready,name))do assert(math.abs(v.y-(20+S.height-(baseline-25)))<1e-9,'Approved label baseline changed: '..name)end
end
local heat=model({resource_hex='27ee1ed8f6fb6356',kind='heat',value=0,capacity=false,reserve=3,reserve_kind='SINKS',fraction=0});local h=compose(heat)
assert(contains(h,'loaded_label','HEAT')and contains(h,'capacity','%')and not contains(h,'status','EMPTY'))
assert(equal(h,compose(heat,{},.25)),'Cold heat meter treated as empty ammunition')
local infinite=model({resource_hex='076dd5d4f4360204',kind='infinite',value='--',fraction=1,reserve=false,capacity=false});local arc=compose(infinite)
assert(contains(arc,'loaded_label','ARC')and #role(arc,'gauge')==0 and #lit(arc,'loaded')==3,'Infinite arc fabricated count or charge')
local fuel=compose(model({resource_hex='4fb0f8c02f55c82b',kind='resource',label='FUEL',reserve_kind='CANISTERS'}));assert(contains(fuel,'loaded_label','FUEL')and contains(fuel,'reserve_unit','CANISTERS'))
local purifier=compose(model({resource_hex='fb3a19078694708a',purifier_charge_fraction=.4}));assert(contains(purifier,'status','CHARGE 40%'))
local accelerator=compose(model({resource_hex='30061f91af477f5e',charge_fraction=.4}));assert(not contains(accelerator,'status','CHARGE 40%'),'Unverified Accelerator charge invented')
local chamber=model({value=46,capacity=45,chamber_bonus=1});assert(S.readouts(chamber,S.specs[id]).loaded==46,'Chamber count modified')
assert(contains(compose(chamber),'status','CHAMBERED +1'),'Known chamber bonus status missing')
assert(not contains(compose(model({value=46,capacity=45})),'status','CHAMBERED +1'),'Chamber bonus inferred without the native flag')
local bonus=lit(compose(chamber),'loaded');assert(bonus[2].c[1]==245 and bonus[#bonus].c[1]==233,'Only verified chamber-bonus last digit should be gold')
assert(bonus[2].digit_character=='4'and bonus[3].digit_character=='6','Native chamber count altered by atlas selection')
local cfg={font='hack',font_scale=1.5,text_color='#FFFFFF',decoration_color='#E9C45D',background_color='#091B35'};local override=compose(model(),cfg)
assert(role(override,'backing')[1].c[3]==53 and lit(override,'loaded')[1].c[1]==255)
for _,v in ipairs(override)do if v.type=='text'then assert(v.font=='hack')end end
local exact=compose(model({value=100000,capacity=100000,reserve=100000}));assert(contains(exact,'loaded','100000')and contains(exact,'capacity','100000')and contains(exact,'reserve','100000'),'Wide counts truncated or invented')
local native_reserve=compose(model({reserve=250,reserve_kind='ROUNDS'}));assert(contains(native_reserve,'reserve','250')and contains(native_reserve,'reserve_unit','ROUNDS'),'Reserve unit/count changed into an estimated total')
assert(contains(compose(model({reserve=0})),'reserve_unit','MAGS')and lit(compose(model({reserve=0})),'reserve')[2].digit_character=='0','Known empty reserve treated as unknown')
assert(equal(ready,compose(model(),{},.25)),'Refilled counter retained empty flash')
local max,max_images=0,0
for resource in pairs(S.specs)do for _,value in ipairs({0,5,27,100000})do for _,scale in ipairs({.5,1,2})do
 local out=assert(S.compose(model({resource_hex=resource,value=value,capacity=100000,reserve=100000}),10,20,scale,1,{},.25,function(name)return resources[name]end,can_get));max=math.max(max,#out)
 local images=0
 for _,v in ipairs(out)do
  assert(v.type=='panel'or v.type=='texture'or v.type=='text','Primitive rectangle art remains');assert(v.x==v.x and v.y==v.y and v.a>=0 and v.a<=1)
  if v.type=='texture'then
   if v.a>0 then images=images+1 end
   assert(v.texture_theme~=false and v.texture_material==S.material and resources[v.texture_resource],'Existing texture themes disabled or unverified resource used')
   local uv=v.atlas_rect;assert(uv[1]>=0 and uv[2]>=0 and uv[3]>0 and uv[4]>0 and uv[1]+uv[3]<=1 and uv[2]+uv[4]<=1,'Unbounded UV crop')
  end
  if v.type~='text'then assert(v.w>0 and v.h>0 and v.x>=10-1e-6 and v.y>=20-1e-6 and v.x+v.w<=10+S.width*scale+1e-6 and v.y+v.h<=20+S.height*scale+1e-6,'Unbounded geometry')
  else local l,b,right,top=HUD.font.measure(v.text,v.size,v.font,true);assert(v.x+l>=10-1e-6 and v.y+b>=20-1e-6 and v.x+right<=10+S.width*scale+1e-6 and v.y+top<=20+S.height*scale+1e-6,'Unbounded native label')end
 end
 assert(images<=Scene.max_texture_images,'Texture image budget exceeded');max_images=math.max(max_images,images)
 Scene.expand_texture_layers(out)
end end end
local typical_images=0;for _,v in ipairs(ready)do if v.type=='texture'and v.a>0 then typical_images=typical_images+1 end end
assert(typical_images==20 and #ready<40,'Four shader-layer image slots must remain available: '..#ready)
Scene.expand_texture_layers(ready)
for _,v in ipairs(ready)do if v.type=='text'then assert(v.texture_readout and v.readout_zone and v.readout_zone.w>0 and v.readout_zone.h>0,'HUD Texture readout occupancy missing')end end
print('PASS primary HUD Texture artwork: 54 primaries, readiness, Simple/exclusions, backing isolation, UV/bounds/four-layer budget, exact native readouts, 2Hz loaded-only flash; typical='..#ready..' commands/'..typical_images..' images; wide-value max='..max..' commands/'..max_images..' images')
-- Asset builder requests an actual composer snapshot for its raster preview.
local export=os.getenv('DBF_HUD_ART_PREVIEW')
local edge_export=os.getenv('DBF_HUD_EDGE_PREVIEW')
if export or edge_export then
 if os.getenv('DBF_HUD_FULL_WHITE_READY')=='1'then resources[S.full_white]=true end
 HUD.native_font_uv=dofile('src/native_font_uv.lua')
 local function json(v)
  local t=type(v);if t=='string'then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r')..'"' end
  if t=='number'or t=='boolean'then return tostring(v)end
  assert(t=='table','Unsupported preview value');local out={}
  if #v>0 then for _,q in ipairs(v)do out[#out+1]=json(q)end;return '['..table.concat(out,',')..']'end
  for k,q in pairs(v)do out[#out+1]=json(tostring(k))..':'..json(q)end;return '{'..table.concat(out,',')..'}'
 end
 local scenes={};local palette={font=os.getenv('DBF_HUD_ART_FONT')or'bigblue',text_color='#F5F6F0',decoration_color='#E9C45D',background_color='#091B35',heat_red='#FF5750',heat_yellow='#E9C45D',panel_opacity=.25}
 if edge_export then
  HUD.config=dofile('src/config.lua');HUD.layout=dofile('src/layout.lua')
  palette.decoration='helldivers';palette.panel_opacity=.5;resources[S.full_white]=true
  for _,name in pairs(S.edge_masks)do resources[name]=true end
  resources[HUD.edge_mask.resource]=true;palette.panel_edge_dither=0;palette.panel_edge_curve=1
  for _,softness in ipairs({0,4,8,12})do
   palette.panel_edge_softness=softness
   local out=assert(S.compose(model({reloading=true}),18,23,1,1,palette,0,resource,can_get))
   HUD.layout.decorate(out,out[1],1,palette,1);scenes[tostring(softness)]=out
  end
 else
  for name,extra in pairs({ready={value=27,fraction=.6},chamber={value=46,capacity=45,chamber_bonus=1,chamber_rounds=1,fraction=1},low={value=5,fraction=5/45},empty={value=0,state='EMPTY',fraction=0},unknown={value=false,capacity=false,reserve=false,fraction=false}})do
   scenes[name]=assert(S.compose(model(extra),18,23,1,1,palette,0,resource,can_get))
  end
 end
 for _,out in pairs(scenes)do
  for _,v in ipairs(out)do if v.type=='text'then
   local face=HUD.native_font_data.faces[v.font];local uv=HUD.native_font_uv[v.font];local factor=v.size/face.em;local advance=0;v.preview_glyphs={}
   for i=1,#v.text do local code=v.text:byte(i);local g=face.glyphs[code]or face.glyphs[63];local coords=uv[code]or uv[63]
    local w,h=(g[4]-g[2])*factor,(g[5]-g[3])*factor
    if w>0 and h>0 then v.preview_glyphs[#v.preview_glyphs+1]={x=v.x+advance+g[2]*factor,y=v.y+g[3]*factor,w=w,h=h,atlas_rect={coords[1],coords[2],coords[3]-coords[1],coords[4]-coords[2]}}end
    advance=advance+g[1]*factor
   end
  end end
 end
 local f=assert(io.open(edge_export or export,'wb'));f:write(json(scenes));f:close()
end
