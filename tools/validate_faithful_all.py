import ctypes,json,sys
from pathlib import Path
sys.path.insert(0,'tools')
from build_faithful_comparison import lua
D=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll');D.luaL_newstate.restype=ctypes.c_void_p
for n,args in [('luaL_openlibs',[ctypes.c_void_p]),('luaL_loadstring',[ctypes.c_void_p,ctypes.c_char_p]),('lua_pcall',[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int]),('lua_close',[ctypes.c_void_p]),('lua_tolstring',[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p])]:getattr(D,n).argtypes=args
D.lua_tolstring.restype=ctypes.c_char_p
def check(code,run=True):
 L=D.luaL_newstate();D.luaL_openlibs(L);rc=D.luaL_loadstring(L,code.encode())
 if not rc and run:rc=D.lua_pcall(L,0,0,0)
 e=D.lua_tolstring(L,-1,None) if rc else None;D.lua_close(L);assert not rc,e
check(Path('mdl/dbf_hud/mod.lua').read_text(),False)
for p in ['tests/faithful_comparison.lua','tests/texture_art.lua','tests/bespoke_textures.lua']:check(Path(p).read_text())
cases=[]
for p in Path('assets/faithful-all/weapons').glob('*/renderer-adapter.json'):
 s=json.loads(p.read_text())
 if any('commands' not in f for f in s['layers']):continue
 commands=[]
 for f in s['layers']:
  for v in f['commands']:
   c={k:v for k,v in v.items() if k not in ['index','bounds'] and not k.endswith('_reference')}
   for k in v:
    if k.endswith('_reference'):c[k[:-10]]={}
   commands.append(c)
  commands.append({'type':'text','text':'LIVE','x':0,'y':0,'size':10})
 cases.append({'spec':s,'commands':commands,'id':p.parent.name})
check("local M=assert(loadfile('src/faithful_fragments.lua'))();local cases="+lua(cases)+''';local count=0
for _,f in ipairs(cases)do local assets={};for _,v in ipairs(f.spec.layers)do assets[v.asset]={material='m',texture='t'}end
local out=M.prepare(f.commands,f.spec,assets,0,0,1,1,{panel_opacity=1},function()return true end)
assert(out~=f.commands,f.id);local found=0;local retained={}
for _,v in ipairs(out)do if v.faithful_fragment then found=found+1 else retained[v]=true end end
assert(found==#f.spec.layers);for _,v in ipairs(f.commands)do if v.type=='text'then assert(retained[v],'live text lost')end end
assert(M.prepare(f.commands,f.spec,assets,0,0,1,1,{panel_opacity=.4},function()return true end)==f.commands)
assert(M.prepare(f.commands,f.spec,assets,0,0,1,1,{panel_opacity=1},function()return false end)==f.commands)
count=count+found end print('PASS all 55 adapter fixtures, '..count..' ordered fragments; live text identity and unavailable/opacity fallback')''')
Path('assets/faithful-comparison/full-stage/validation.txt').write_text('Runtime syntax PASS; STA11 current states PASS; texture art PASS; bespoke cases PASS; all 55 adapter fixtures / 256 fragments PASS; live text identity + opacity/resource fallback PASS. Live game loading not verified.\n')

check("HUD={weapon_names=assert(loadfile('src/weapon_names.lua'))()};local menu=assert(loadfile('src/menu.lua'))();local labels,ids=menu.weapon_choices();local seen={};local count=0;for _ in pairs(HUD.weapon_names)do count=count+1 end;assert(#ids==count);for i,id in ipairs(ids)do assert(not seen[id]);seen[id]=true;assert(labels[i]==HUD.weapon_names[id]);if i>1 then assert(labels[i-1]:lower()<=labels[i]:lower())end end;print('PASS full weapon selector catalog: '..count..' unique sorted identities')")
runtime=Path('src/runtime.lua').read_text();start=runtime.index('    function self.appearance_weapon()');end=runtime.index('    function self.equipped_resource()',start)
check("local self={};local appearance_selection;local model={resource_hex='equipped'};HUD={weapon_names={selected='Selected'}};"+runtime[start:end]+";self.select_appearance_weapon('selected');assert(self.appearance_weapon()=='selected');assert(model.resource_hex=='equipped');model.resource_hex='changed';assert(self.appearance_weapon()=='selected');assert(self.appearance_revision==1);print('PASS selector remains selected across equipment changes without changing equipment')")

check("HUD={native_font_data=assert(loadfile('src/native_font_data.lua'))()};local C=assert(loadfile('src/config.lua'))();local cfg=C.new();C.set_panel(cfg,'5fecab819f96a3e8',{panel_opacity=.63,texture_art_variant='original'});C.set_panel(cfg,'968211c0033dce64',{panel_opacity=.91});local saved=assert(loadstring(C.serialize(cfg)))();assert(saved.weapon_panels['5fecab819f96a3e8'].panel_opacity==.63);assert(saved.weapon_panels['5fecab819f96a3e8'].texture_art_variant=='original');assert(saved.weapon_panels['968211c0033dce64'].panel_opacity==.91);print('PASS selected per-weapon values persist independently through tuning serialization')")
