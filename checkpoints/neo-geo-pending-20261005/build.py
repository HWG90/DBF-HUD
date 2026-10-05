from pathlib import Path
import json,re,zipfile,datetime,hashlib,ctypes,html
from PIL import Image,ImageDraw
P=Path(__file__).resolve().parent
ROOT=Path(r'C:\Users\david\Documents\Codex\2026-10-04\hud-checkout-before-relocation')
LIVE=Path(r'C:\Users\david\AppData\Local\LLL\Helldivers2\Mods\dbf_hud\mod.lua')
GAME=Path(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2')
P.mkdir(exist_ok=True);(P/'commands').mkdir(exist_ok=True)
source=LIVE.read_text(encoding='utf-8-sig')
backup=P/('accepted-whole-build-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip')
if not list(P.glob('accepted-whole-build-*.zip')):
 with zipfile.ZipFile(backup,'w',zipfile.ZIP_DEFLATED) as z:
  z.write(LIVE,'LiveRuntime/mod.lua')
  for f in ROOT.rglob('*'):
   if f.is_file() and '.git' not in f.parts:z.write(f,'Source/'+str(f.relative_to(ROOT)))
  for f in (GAME/'data').glob('ee6b1ba7e22d71ed.patch_0*'):z.write(f,'GameAssets/'+f.name)
  settings=Path(r'C:\Users\david\AppData\Local\DBF')
  for f in settings.glob('DBF-HUD*'):
   if f.is_file():z.write(f,'Settings/'+f.name)
def lua(v):
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return str(v).lower()
 if v is None:return 'nil'
 return str(v)
catalog={}
for rid,name,family in re.findall(r"\['([0-9a-f]{16})'\]=\{name='([^']*)'.*?family='([^']*)'",(ROOT/'src/weapon_styles.lua').read_text()):
 catalog[rid]={'name':name,'family':family}
old=json.loads((P.parent/'Mechanical-Live/layouts.json').read_text())
palette={'rifle':[205,194,108],'precision':[144,204,187],'shotgun':[219,169,100],'sidearm':[179,193,211],'compact':[132,199,177],'plasma':[103,200,220],'laser':[216,206,117],'belt':[198,181,122],'rocket':[198,164,125],'explosive':[219,179,113],'fuel':[218,152,104],'dart':[148,198,151],'arc':[157,176,225],'tool':[171,183,166]}
layouts={};profiles={}
for rid,a in catalog.items():
 family=a['family'];special=old.get(rid,{})
 # Each identity gets its own cut, accent and index placement, within one pixel vocabulary.
 seed=int(rid[:8],16);ink=palette.get(family,palette['rifle']);ink=[min(235,max(90,v+(seed%5-2)*4))for v in ink]
 profiles[rid]={'name':a['name'],'family':family,'ink':ink,'cut':2+seed%4,'tab':seed%3}
 zones={'count':[.08,.24,.37,.39],'reserve':[.08,.72,.55,.12],'mode':[.66,.76,.28,.12],'gauge':[.08,.65,.84,.035]}
 if rid in old:
  keys=set(special['zones']);zones={k:v for k,v in zones.items() if k in keys}
  if 'reading' in keys:zones['reading']=[.08,.25,.84,.25]
  extras=[k for k in special['zones'] if k not in zones and k not in ('icon','gauge','reading')]
  positions={'shells':[.52,.24,.36,.28],'compass':[.49,.25,.44,.12],'charge':[.49,.54,.43,.045],'capacity':[.5,.58,.42,.08],'selector':[.49,.23,.44,.09],'status':[.49,.38,.44,.09],'charge_label':[.49,.41,.44,.09],'total':[.49,.52,.44,.09],'aux_mode':[.49,.25,.44,.09]}
  for i,k in enumerate(extras):
   zones[k]=positions.get(k,[.49,.22+i*.10,.43,.08])
  if family in ('laser','fuel') and 'gauge' in keys:zones['gauge']=[.08,.56,.84,.06]
 if rid=='8d3d52a3b2f19402':zones['shells']=[.5,.24,.42,.31]
 if rid=='3828e2051aa9e897':zones['shells']=[.08,.4,.84,.22]
 # Rich per-barrel/cylinder presentations use slightly taller slim instrument housings.
 w=154+(seed%3)*6;h=86 if family in ('rocket','shotgun') else 76
 layouts[rid]={**special,'name':a['name'],'family':family,'source_box':special.get('source_box',[0,0,w,h]),'box':[0,0,w,h],'zones':zones}
(P/'inventory.json').write_text(json.dumps(profiles,indent=2))
(P/'layouts.lua').write_text('return '+lua(layouts))
(P/'profiles.lua').write_text('return '+lua(profiles))
module=(P.parent/'Mechanical-Live/mechanical.lua').read_text()
# Retain reader-owned formatting, selectors, special native state and safety controls.
module=module.replace("local material=a.material or", "local material=a.material or")
module=module.replace("if not M.enabled or not a or m.snow_party or m.mg43_flash or cfg.mechanical_art_enabled==false or cfg.texture_art_trial==false or (cfg.texture_art_variant and cfg.texture_art_variant~='faithful') then", "if not a or m.snow_party or m.mg43_flash then")
module=module.replace("if id=='8d3d52a3b2f19402'and m.cylinder_slots and cfg.senator_style~='upright' then", "if false then")
module=module.replace("if not available[asset_key]then", "if false then")
module=module[:module.index(' if false then')]+module[module.index(' local box=a.box'):]
module=module.replace('-- Static texture skin; reader/model and safety logic remain owned by DBF-HUD.', '-- Thin native instrument panels; reader/model and safety logic remain DBF-HUD owned.')
module=module.replace(' local box=a.box', " if cfg.effect_flicker then opacity=opacity*(.94+.04*math.sin((clock or 0)*17)+.02*math.sin((clock or 0)*31)) end\n local box=a.box",1)
module=module.replace("local zones=a.zones;", "local zones=a.zones;")
# No image artwork. Pure native commands work in both screen and world renderers.
start=module.index(' local out={{type=');end=module.index('\n local zones=',start)
module=module[:start]+''' local profile=HUD.neo_profiles[id]
 local accent=HUD.config.rgb(cfg.decoration_color or '#FFFFFF')
 if not cfg.weapon_panel_overrides or not cfg.weapon_panel_overrides.decoration_color then accent=profile.ink end
 local out={{type='panel',x=left,y=bottom,w=w,h=h,c=HUD.config.rgb(cfg.background_color or '#101619'),a=opacity*(cfg.panel_opacity or .8),frosted=false,mechanical_art=true,neo_panel=true}}
 local function line(px,py,pw,ph,c)out[#out+1]={type='rect',x=left+px*s,y=bottom+py*s,w=pw*s,h=ph*s,c=c or accent,a=opacity,neo_frame=true}end
 local nw,nh=w/s,h/s;local cut=profile.cut
 line(cut,nh-1,nw-cut*2,1);line(cut,0,nw-cut*2,1)
 line(0,cut,1,nh-cut*2);line(nw-1,cut,1,nh-cut*2)
 line(1,nh-cut,cut,1);line(nw-cut-1,cut-1,cut,1)
 line(8,nh-17,nw-16,1,{72,83,87})
 if profile.tab==0 then line(8,nh-4,20,2)elseif profile.tab==1 then line(nw-28,nh-4,20,2)else line(nw/2-10,nh-4,20,2)end
 -- One optional effect surface uses the existing effect shader; no CPU bands.
 local scan_shader=cfg.effect_scanlines and can_get and can_get('material','mods/dbf_hud/materials/mapped_crt_scan')==true
 if scan_shader or cfg.effect_shader and cfg.effect_shader~='none' and cfg.effect_shader~='auto' then
  out[#out+1]={type='rect',x=left,y=bottom,w=w,h=h,c=accent,a=.12*opacity,effect_shader_band=true,neo_effect_shader=scan_shader and 'crt_scan' or cfg.effect_shader}
 end
''' +module[end:]
module=module.replace(" local zones=a.zones;local ink", " local zones=a.zones;local ink")
module=module.replace(" local function bar(z,fraction,color,segments)"," text(profile.name:match('^([^ ]+)') or profile.name,{.06,.075,.88,.105},profile.ink)\n local function bar(z,fraction,color,segments)")
# All dynamic original text survives if the remapped implementation did not consume it.
marker=" M.status[id]='HUD Texture; native readouts active'"
module=module.replace(marker,''' local represented={}
 for _,v in ipairs(out)do if v.type=='text'then represented[v.text]=true end end
 local leftovers={}
 for _,v in ipairs(original)do
  if v.type=='text' and not represented[v.text] and not v.decoration and not v.mode_icon then
   local t=tostring(v.text or '')
   local title=t==profile.name or t==profile.name:upper() or v.weapon_label or v.ammo_heading or v.amr_heading or v.grenade_heading or v.railgun_heading
   local digit=v.heat_digit_slot or v.heat_prefix or v.heat_label
   if not title and not digit and not (t:match('^%d+$')and count and v==count) and not (reserve and t==m.reserve_kind) then leftovers[#leftovers+1]=v end
  end
 end
 -- Explicit child readouts stay attached below the thin main frame.
 for i,v in ipairs(leftovers)do text(v.text,{.06,1.02+(i-1)*.13,.88,.105},v.c,v)end
 M.status[id]='Neo Geo; native readouts'
''')
# Texture masks are irrelevant to the native-only output.
a=module.index(' if a.occupancy_mask then');b=module.index(' local charge_ink=',a);module=module[:a]+module[b:]
module=module.replace("  elseif v.effect_shader_band or v.df_effect_sweep or v.scanline_layer then", "  elseif v.df_effect_sweep or (v.effect_shader_band or v.scanline_layer) and not scan_shader then")
module=module.replace("   local q=copy(v);q.x=left+(v.x-x-box[1]*s);q.y=bottom+(v.y-y-box[2]*s);out[#out+1]=q", "   local q=copy(v);local owner=v.effect_owner or original[1];q.x=left;q.w=w;q.y=bottom+(v.y-owner.y)*h/math.max(.001,owner.h);q.h=v.h*h/math.max(.001,owner.h);q.effect_owner=out[1];q.neo_effect_shader='none';out[#out+1]=q")
module=module.replace("local prefix=m.kind=='heat' and", "local prefix=m.kind=='heat' and")
module=module.replace("or 'THERMAL')", "or (m.state=='VENT' and 'COOLDOWN' or 'CHARGE --'))")
module=module.replace("  text(prefix..': '..(finite(m.value)","  if id=='35a61296619cc47e' and not m.quasar_charge_verified then text('CHARGE: --',zones.reading,warning,reading) else\n  text(prefix..': '..(finite(m.value)")
module=module.replace("zones.reading,warning,reading)\n else", "zones.reading,warning,reading) end\n else")
module=module.replace(" if continuous and zones.gauge and finite(m.fraction)then", " if id=='35a61296619cc47e' and not m.quasar_charge_verified then\n elseif continuous and zones.gauge and finite(m.fraction)then")
module=module.replace(" if zones.status then text(m.chamber_rounds", " if zones.status and m.chamber_rounds~=nil then text(m.chamber_rounds")
module=module.replace(" text(status and status.text,zones.status,nil,status)", " text(status and status.text or (id=='3828e2051aa9e897' and (finite(m.value) and (m.value>0 and 'LOADED' or 'EMPTY') or '--')),zones.status,nil,status)")
module=module.replace(" remap(function(v)return v.shotgun_shell_art==true or v.barrel_indicator~=nil end,zones.shells)"," remap(function(v)return v.shotgun_shell_art==true or v.barrel_indicator~=nil or v.senator_slot~=nil or v.spear_projectile==true end,zones.shells)")
(P/'neo_panel.lua').write_text(module)
# A reviewable full runtime, rebased on the installed current checkpoint.
inject='HUD.neo_profiles=(function()\n'+(P/'profiles.lua').read_text()+'\nend)()\nHUD.mechanical_layouts=(function()\n'+(P/'layouts.lua').read_text()+'\nend)()\nHUD.neo_panel=(function()\n'+module+'\nend)()\n'
point=source.index('HUD.runtime=(function()');candidate=source[:point]+inject+source[point:]
target='        local out=HUD.layout.compose(m,x,y,scale,opacity,cfg,clock,measure)'
assert target in candidate
candidate=candidate.replace(target,target+"\n        do return HUD.neo_panel.compose(out,m,x,y,scale,opacity,cfg,clock,measure,function()return true end) end",1)
world_marker='                    -- Pixel glyphs quantize after world scaling; fit their actual bounds.'
candidate=candidate.replace(world_marker,'                    if f.neo_panel then return centered end\n'+world_marker,1)
(P/'mod.lua').write_text(candidate)
# Use current runtime prefix for authoritative behavior rather than old saved fixtures.
prefix=source[:source.index('HUD.memory=(function()')]
prefix=re.sub(r'        if not M\.(?:leveller|breacher|hotshot|sg8)_draw_verified then.*?\n        end\n','',prefix,flags=re.S)
start=source.index('HUD.world_style=(function()');end=source.index('\nend)()',start)+len('\nend)()');world=source[start:end]
world=world.replace(world_marker,'                    if f.neo_panel then return centered end\n'+world_marker,1)
prefix+='\n'+world+'\n'
test=(P.parent/'Mechanical-Live/test.py').read_text()
body=test[test.index("local checked=0;"):test.index("-- The renderer must retain")]
body=body.replace("assert(active and out[2].type=='texture'and out[1].mechanical_art,entry.id..' texture missing')","assert(active and out[1].type=='panel'and out[1].mechanical_art,entry.id..' native panel missing')")
body=body.replace("assert(out[2].a==.8*.7,'Skin opacity did not retain settings')","assert(out[1].a==.8*.7,'Panel opacity did not retain settings')")
body=body.replace("assert(math.abs(world[2].w/world[2].h-out[2].w/out[2].h)<1e-6,'Texture aspect changed in world projection')","assert(math.abs(world[1].w/world[1].h-out[1].w/out[1].h)<1e-6,'Panel aspect changed in world projection')")
body=body.replace("seen[entry.id]=true", "seen[entry.id]=true\n  local pcfg={};for k,v in pairs(cfg)do pcfg[k]=v end;pcfg.panel_opacity=.85;pcfg.text_opacity=1\n  local po=HUD.layout.compose(m,0,0,1,1,pcfg,.27,function(t,z)return HUD.font.measure(t,z,font)end)\n  out=skin.compose(po,m,0,0,1,1,pcfg,.27,nil,function()return true end)")
code=prefix+'\n'+inject+'\nlocal skin=HUD.neo_panel\nlocal entries='+lua([{'id':k,'family':v['family']}for k,v in catalog.items()])+'\n'+body
code=code.replace('OUTPUT',json.dumps((P/'commands').as_posix()))+"\nlocal f=assert(io.open("+json.dumps((P/'test-count.txt').as_posix())+",'w'));f:write(checked);f:close()"
checker=(P.parent/'install_epoch_plasma.py').read_text();exec(checker[checker.index('dll=ctypes.CDLL'):checker.index('check(after)')])
check(candidate);check(code,True)
(P/'test-fixture.lua').write_text(code)
(P/'validation.json').write_text(json.dumps({'catalog_identities':len(catalog),'compositions':int((P/'test-count.txt').read_text()),'current_runtime_sha256':hashlib.sha256(LIVE.read_bytes()).hexdigest(),'deployed':False,'live_verified':False},indent=2))
print('PASS',len(catalog),'identities;', (P/'test-count.txt').read_text(),'compositions; candidate syntax valid; no deployment')
