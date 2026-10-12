"""Package the Split instrument and install its authorized fresh baseline explicitly."""
from pathlib import Path
import argparse, ctypes, datetime, hashlib, json, os, subprocess, sys, zipfile

parser=argparse.ArgumentParser();parser.add_argument('--deploy',action='store_true');args=parser.parse_args()
root=Path(__file__).resolve().parents[1];out=root/'dist/split-hud-in-game-20261011';out.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(root/'tools/build_lll.py')],check=True)
with zipfile.ZipFile(root/'dist/releases/modular-20261010/dbf_hud-0.3.42-LLL-Modular.zip')as z:
    assert z.testzip()is None;files={name:z.read(name)for name in z.namelist()}
hot=Path(os.environ['LOCALAPPDATA'])/'DBF/HotTextures';installed=Path(os.environ['LOCALAPPDATA'])/'LLL/Helldivers2/Mods/dbf_hud'
manifest=(hot/'manifest.tsv').read_bytes();rows={line.split(b'\t')[0]:line for line in manifest.splitlines()if line and not line.startswith(b'#')}
additions=(root/'assets/split-hud/manifest-additions.tsv').read_bytes()
for line in additions.decode().splitlines():
    name,w,h,filename=line.split('\t');data=(root/'assets/split-hud'/filename).read_bytes()
    assert len(data)==int(w)*int(h)*4 and hashlib.sha256(data).hexdigest()in filename
    if name.encode()in rows:assert rows[name.encode()]==line.encode(),'Immutable Split resource already differs'
    else:manifest=manifest.rstrip(b'\r\n')+b'\n'+line.encode()+b'\n';rows[name.encode()]=line.encode()
    files['HotTextures/'+filename]=data
# Publish initial coordinated masks with the file batch, then reuse them from
# the same generated-image pipeline when appearance controls change.
dynamic=[]
for name in ['split_hud_dynamic_coverage_v1','split_hud_dynamic_face_v1','split_hud_dynamic_soft_v1']:
    data=(out/(name+'.rgba')).read_bytes();assert len(data)==640*322*4
    digest=hashlib.sha256(data).hexdigest();filename=name+'_'+digest+'.rgba';line=f'{name}\t640\t322\t{filename}'
    if name.encode()in rows:assert rows[name.encode()]==line.encode(),'Initial Split mask already differs'
    else:manifest=manifest.rstrip(b'\r\n')+b'\n'+line.encode()+b'\n';rows[name.encode()]=line.encode()
    files['HotTextures/'+filename]=data;dynamic.append(line)
files['HotTextures/manifest.tsv']=manifest
files['HotTextures/manifest-additions.tsv']=additions+'\n'.join(dynamic).encode()+b'\n'
defaults=json.loads(files['dbf_hud/config/defaults.cfg'])
defaults['split_activation']='split-study08-20261011-v3'
files['dbf_hud/config/defaults.cfg']=(json.dumps(defaults,indent=2)+'\n').encode()
files['dbf_hud/FILES-SHA256.txt']=''.join(hashlib.sha256(data).hexdigest()+'  '+name[8:]+'\n' for name,data in sorted(files.items())if name.startswith('dbf_hud/')and name!='dbf_hud/FILES-SHA256.txt').encode()
files['README.txt']=(
    'DBF-HUD Split instrument first pass, 2026-10-11\n'
    'Existing HUD Texture/WorldGUI materials, texture shaders, native fonts and renderer are required. '
    'Copy dbf_hud into LocalAppData/LLL/Helldivers2/Mods, merge HotTextures rows and copy RGBA files. '
    'LLL applies the fresh Split baseline once through its existing configuration path.\n'
    'The baseline replaces appearance choices while preserving placement, with white/gold/navy, native Hack, '
    'Split artwork, 35% backing, 7% feather, 40% dither, grain2, depth spacing16, Combat detail. '
    'Native weapon readers and shader controls remain. No native DLL/shader bytecode is changed.\n'
    'Readout detail and Layer spacing are in Appearance. Placement > Bring HUD into view recovers '
    'the equipped view; F7 saves placement and F8 restores its editor snapshot.\n'
).encode()
candidate=out/'candidate'
for name,data in files.items():
    p=candidate/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
dll=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')
dll.luaL_newstate.restype=ctypes.c_void_p;dll.luaL_loadfile.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
dll.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];dll.lua_tolstring.restype=ctypes.c_char_p;dll.lua_close.argtypes=[ctypes.c_void_p]
lua=list((candidate/'dbf_hud').rglob('*.lua'))
for p in lua:
    state=dll.luaL_newstate()
    try:
        if dll.luaL_loadfile(state,str(p).encode()):raise RuntimeError(dll.lua_tolstring(state,-1,None).decode())
    finally:dll.lua_close(state)
package=out/'DBF-HUD-Split-Instrument-20261011.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED)as z:
    for name,data in sorted(files.items()):z.writestr(name,data)
with zipfile.ZipFile(package)as z:assert z.testzip()is None
report={'package':str(package),'sha256':hashlib.sha256(package.read_bytes()).hexdigest(),'lua_files_compiled':len(lua),
    'existing_hud_texture_renderer':True,'native_assets_changed':False,'four_shader_slots_preserved':True,
    'native_points_per_active_plane':4,'max_active_planes':4,'hot_manifest_rows':len(rows),
    'static_texture_bytes':10861568,'initial_dynamic_bytes':3*640*322*4,'fresh_baseline_authorized':True,
    'live_loaded':False,'live_visual_verified':False,'live_performance_verified':False,'installed':False}
if args.deploy:
    targets={}
    for name,data in files.items():
        if name.startswith('dbf_hud/'):targets[installed/name[8:]]=data
        elif name.startswith('HotTextures/')and name!='HotTextures/manifest-additions.tsv':targets[hot/name[12:]]=data
    changed={p:data for p,data in targets.items()if not p.exists()or p.read_bytes()!=data}
    before={p:p.read_bytes()if p.exists()else None for p in changed}
    backup=out/('before-split-'+datetime.datetime.now().strftime('%H%M%S'))
    for p,data in before.items():
        relative=p.relative_to(installed)if p.is_relative_to(installed)else Path('DBF')/p.relative_to(hot.parent)
        if data is not None:
            saved=backup/relative;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(data)
    for name in ['DBF-HUD-tuning.lua','DBF-HUD-weapon-offsets.lua']:
        p=hot.parent/name
        if p.exists():saved=backup/'DBF'/name;saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(p.read_bytes())
    for p,data in changed.items():p.parent.mkdir(parents=True,exist_ok=True);p.with_name(p.name+'.split-tmp').write_bytes(data)
    assert all((p.read_bytes()if p.exists()else None)==data for p,data in before.items()),'Deployment targets changed during preparation'
    for p in sorted(changed,key=lambda p:(p.is_relative_to(installed),p.name=='main.lua',p.name=='manifest.json',str(p))):os.replace(p.with_name(p.name+'.split-tmp'),p)
    assert all(p.read_bytes()==data for p,data in targets.items())
    report.update(installed=True,installed_matches_package=True,backup=str(backup),changed_files=[str(p)for p in changed])
    (out/'ROLLBACK.json').write_text(json.dumps({'backup':str(backup),'added_files':[str(p)for p,data in before.items()if data is None]},indent=2)+'\n')
(out/'DEPLOYMENT.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items()if k!='changed_files'},indent=2))
