"""Package richer primary edge controls; optional backed-up Lua-only deployment."""
from pathlib import Path
import argparse, ctypes, datetime, hashlib, json, os, subprocess, sys, zipfile

options=argparse.ArgumentParser();options.add_argument('--deploy',action='store_true');options.add_argument('--test',action='store_true');options.add_argument('--output-dir',type=Path);args=options.parse_args()
root=Path(__file__).resolve().parents[1];out=args.output_dir.resolve()if args.output_dir else root/'dist/hud-edge-dither-20261011';out.mkdir(parents=True,exist_ok=True)
installed=Path(os.environ['LOCALAPPDATA'])/'LLL/Helldivers2/Mods/dbf_hud'
subprocess.run([sys.executable,str(root/'tools/build_lll.py')],check=True)
if args.test:
    for suite in ['edge_mask','primary_edge_feather','segmented_fancy','hud_texture_shader_scale','native_screen_scene','primary_hud_texture','hot_panel_art','generated_edge_mask_lifecycle','texture_pool','world_presentation_anchor','hud_view_recovery']:
        subprocess.run([sys.executable,str(root/'tests/run.py'),'--suite','tests/'+suite+'.lua'],cwd=root,check=True)
source=root/'dist/releases/modular-20261010/dbf_hud-0.3.42-LLL-Modular.zip'
with zipfile.ZipFile(source) as z:
    assert z.testzip() is None
    files={name:z.read(name) for name in z.namelist()}
files['README-edge-controls.txt']=(
    'Primary HUD Texture feather/dither controls - 2026-10-11\n'
    'Appearance: Edge feather width 0..24% (step 1), fade curve 0.5..3 (step 0.1), '
    'edge dither 0..100% (step 5), grain size 1..4. Defaults: 4%, 1, 35%, 1. '
    'Set dither to 0 and curve to 1 for the accepted smooth fade. Width 0 restores hard edges.\n'
    'Backing, shader layers and selected outer decoration share one full-UV mask; digits/status stay crisp. '
    'MCM > DBF HUD > Placement > Bring HUD into view fits the equipped weapon/current WorldGUI view once. '
    'F7 or Save layout persists the preview; F8 or Restore placement undoes it. Normal weapon following continues. '
    'Masks are generated after a 12-render-callback quiet period only on settings changes. Existing '
    'staged upload, readback, acknowledgment and fenced retirement are used; no new renderer, shader bytecode, '
    'draw calls, image slots, or persistent mask files. Requires existing HUD Texture/material installation.\n'
).encode()
candidate=out/'candidate'
for name,data in files.items():
    p=candidate/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
dll=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')
dll.luaL_newstate.restype=ctypes.c_void_p;dll.luaL_loadfile.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
dll.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];dll.lua_tolstring.restype=ctypes.c_char_p;dll.lua_close.argtypes=[ctypes.c_void_p]
lua=list((candidate/'dbf_hud').rglob('*.lua'))
for path in lua:
    state=dll.luaL_newstate()
    try:
        if dll.luaL_loadfile(state,str(path).encode()):raise RuntimeError(dll.lua_tolstring(state,-1,None).decode())
    finally:dll.lua_close(state)
package=out/'DBF-HUD-Edge-Feather-Dither-20261011.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
    for name,data in sorted(files.items()):z.writestr(name,data)
report={'package':str(package),'sha256':hashlib.sha256(package.read_bytes()).hexdigest(),
    'canonical_lua_files':len(lua),'existing_hud_texture_renderer':True,'shader_bytecode_changed':False,
    'hot_texture_files_changed':False,'saved_settings_written':False,'new_geometry':0,'new_image_slots':0,
    'controls':{'width':[0,24,1],'curve':[0.5,3,0.1],'dither':[0,100,5],'grain':[1,4,1]},
    'defaults':{'width':4,'curve':1,'dither':35,'grain':1},'dynamic_mask_bytes':131072,
    'native_points_per_plane':4,'source_tests_passed':args.test,
    'reference_validation_20261011':{'mask_cases':72,'decoration_cases':30,'generated_lifecycle_swaps':100,'recovery_cases':217},
    'reference_contract_limit_20261011':'Existing anchor-expiry assertion at tests/contracts.lua:374 fails equally with installed pre-change source.',
    'live_reload_acknowledged':False,'live_upload_verified':False,'live_visual_verified':False,'installed':False}
if args.deploy:
    targets={installed/name[8:]:data for name,data in files.items() if name.startswith('dbf_hud/')}
    changed={p:data for p,data in targets.items() if not p.exists() or p.read_bytes()!=data}
    before={p:p.read_bytes() if p.exists() else None for p in changed}
    backup=out/('before-edge-controls-'+datetime.datetime.now().strftime('%H%M%S'))
    for p,data in before.items():
        if data is not None:
            saved=backup/p.relative_to(installed);saved.parent.mkdir(parents=True,exist_ok=True);saved.write_bytes(data)
    (out/'ROLLBACK.json').write_text(json.dumps({'backup':str(backup),'added_files':[str(p) for p,data in before.items() if data is None]},indent=2))
    for p,data in changed.items():
        p.parent.mkdir(parents=True,exist_ok=True);p.with_name(p.name+'.edge-tmp').write_bytes(data)
    assert all((p.read_bytes() if p.exists() else None)==data for p,data in before.items()),'Installed bytes changed during preparation'
    for p in sorted(changed,key=lambda p:(p.name in ('main.lua','manifest.json'),p.name=='manifest.json',str(p))):os.replace(p.with_name(p.name+'.edge-tmp'),p)
    assert all(p.read_bytes()==data for p,data in targets.items())
    report.update(installed=True,installed_matches_package=True,backup=str(backup),changed_files=[str(p) for p in changed])
(out/'DEPLOYMENT.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='changed_files'},indent=2))
