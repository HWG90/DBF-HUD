"""Package startup and MDL installation choices with verified depth assets."""
from pathlib import Path
import argparse, importlib.util, json, subprocess, sys, zipfile, ctypes
ROOT=Path(__file__).resolve().parents[1]
def main():
 p=argparse.ArgumentParser();p.add_argument('--addon-builder',type=Path,required=True);args=p.parse_args()
 sys.path.insert(0,str(args.addon_builder.parent))
 spec=importlib.util.spec_from_file_location('addon_builder',args.addon_builder);builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
 subprocess.run([sys.executable,str(ROOT/'tools/build.py')],check=True)
 bridge=(ROOT/'bridge/render_bridge.lua').read_text().split('\n',1)[1]
 hud=(ROOT/'dist/dbf_hud.lua').read_text().split('\n',1)[1]
 combined='-- HD2-Addon: mods/dbf_hud/hud\nlocal bridge_ok,bridge_result=pcall(function()\n'+bridge+'\nend)\n'+hud
 entry=ROOT/'dist/dbf_hud_complete.lua';entry.write_text(combined,encoding='utf-8')
 # Compile without running any game API.
 dll=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')
 dll.luaL_newstate.restype=ctypes.c_void_p;state=dll.luaL_newstate()
 dll.luaL_loadfile.argtypes=[ctypes.c_void_p,ctypes.c_char_p];dll.lua_close.argtypes=[ctypes.c_void_p]
 try: assert dll.luaL_loadfile(state,str(entry).encode())==0,'combined startup Lua failed compilation'
 finally:dll.lua_close(state)
 temp=ROOT.parent/'DBF-HUD-startup-component.zip';live=ROOT.parent/'DBF-HUD-live-bridge-component.zip'
 builder.build_addon('mods/dbf_hud/hud',combined.encode(),'eb9de2f7-5733-46a0-96d8-8750becccd53',temp)
 builder.build_addon('mods/holographic_utility_display/render_bridge',(ROOT/'bridge/render_bridge.lua').read_bytes(),'2d860b40-510b-4a22-bbad-0911f9537d64',live)
 depth=ROOT.parent/'DBF-HUD-WorldGUI-Depth-Probe-0.3.zip'
 assert depth.exists(),'Build the verified depth probe first'
 manifest={'Version':1,'Guid':'eb9de2f7-5733-46a0-96d8-8750becccd53','Name':'DBF-HUD Complete 0.3.39','Description':'HUD, startup render bridge and verified WorldGUI depth assets. Requires Bingus Shared Loader. Choose one installation mode.','Options':[{'Name':'Complete HUD - startup','Include':['Startup','DepthState']},{'Name':'MDL live reload - bridge and depth assets','Include':['LiveBridge','DepthState']}]}
 output=ROOT.parent/'DBF-HUD-Complete-0.3.39.zip'
 with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as out:
  out.writestr('manifest.json',json.dumps(manifest,indent=2)+'\n')
  for component,prefix in [(temp,'Startup'),(live,'LiveBridge')]:
   with zipfile.ZipFile(component) as z:
    for n in z.namelist():
     if n.startswith('Addon/'):out.writestr(prefix+'/'+n.removeprefix('Addon/'),z.read(n))
  with zipfile.ZipFile(depth) as z:
   for n in z.namelist():
    if n.startswith('DepthState/'):out.writestr(n,z.read(n))
  out.write(ROOT/'INSTALL-COMPLETE.md','INSTALL.md')
  out.write(ROOT/'README.md','README.md')
  for path in sorted(ROOT.glob('*.md')):out.write(path,'Source/'+path.name)
  out.write(ROOT/'DBF-HUD-tuning.lua','Configuration/DBF-HUD-tuning.lua')
  out.write(ROOT/'mdl/dbf_hud/mod.lua','MDL/dbf_hud/mod.lua')
  out.write(ROOT/'MDL.md','MDL/dbf_hud/README.md')
  for path in sorted((ROOT/'licenses').rglob('*')):
   if path.is_file():out.write(path,path.relative_to(ROOT).as_posix())
  for path in sorted((ROOT/'assets/fonts').rglob('*')):
   if path.is_file():out.write(path,'Fonts/'+path.relative_to(ROOT/'assets/fonts').as_posix())
  for folder in ('src','tools','tests','bridge','preview'):
   for path in sorted((ROOT/folder).rglob('*')):
    if path.is_file() and '__pycache__' not in path.parts:out.write(path,'Source/'+path.relative_to(ROOT).as_posix())
 with zipfile.ZipFile(output) as z:
  assert z.testzip() is None
  assert len(z.namelist())==len(set(z.namelist()))
  assert 'MDL/dbf_hud/mod.lua' in z.namelist()
  with zipfile.ZipFile(depth) as baseline:
   for n in baseline.namelist():
    if n.startswith('DepthState/'):assert z.read(n)==baseline.read(n)
  for option in manifest['Options']:
   for prefix in option['Include']:assert any(n.startswith(prefix+'/') for n in z.namelist())
 print('PASS combined Lua compile, ZIP integrity, installation choices and exact verified depth payload')
 print(output)
if __name__=='__main__':main()
