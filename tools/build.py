"""Bundle clean modules; optionally package with an installed Bingus addon builder."""
import argparse
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ORDER = ['config','font_data','font','motion', 'model', 'layout', 'memory', 'layouts', 'reader', 'pose','projection', 'anchor', 'view','pose_motion','world_probe', 'offscreen_test', 'menu', 'runtime']

def bundle():
    parts = ['-- HD2-Addon: mods/astra_ammo/hud\nlocal AA={}\n']
    for name in ORDER:
        parts.append(f'AA.{name}=(function()\n{(ROOT / "src" / (name+".lua")).read_text(encoding="utf-8")}\nend)()\n')
    parts.append('local ok,result=pcall(function() return AA.runtime.start(assert(rawget(_G,"stingray"),"stingray missing"),AA.memory.native()) end)\n'
                 'if not ok then rawset(_G,"AstraAmmo",{status=tostring(result),version="0.3.35"}) end\nreturn rawget(_G,"AstraAmmo")\n')
    target = ROOT / 'dist' / 'astra_ammo.lua'
    target.parent.mkdir(exist_ok=True)
    target.write_text(''.join(parts), encoding='utf-8')
    live = ROOT / 'mdl' / 'astra_ammo' / 'mod.lua'
    live.parent.mkdir(parents=True, exist_ok=True)
    live_parts = ['-- Astra Ammo / MDL API 2 loose mod.\nlocal AA={}\n']
    for name in ORDER:
        live_parts.append(f'AA.{name}=(function()\n{(ROOT / "src" / (name+".lua")).read_text(encoding="utf-8")}\nend)()\n')
    live_parts.append(f'return (function()\n{(ROOT / "src" / "mdl.lua").read_text(encoding="utf-8")}\nend)()\n')
    live.write_text(''.join(live_parts), encoding='utf-8')
    with zipfile.ZipFile(ROOT.parent / 'AstraAmmo-MDL-0.3.35.zip','w',zipfile.ZIP_DEFLATED) as archive:
        archive.write(live,'astra_ammo/mod.lua')
        if (ROOT / 'MDL.md').exists(): archive.write(ROOT / 'MDL.md','astra_ammo/README.md')
        for path in sorted((ROOT / 'licenses').rglob('*')):
            if path.is_file(): archive.write(path,'astra_ammo/'+path.relative_to(ROOT).as_posix())
    return target

if __name__ == '__main__':
    p=argparse.ArgumentParser();p.add_argument('--addon-builder',type=Path);args=p.parse_args()
    target=bundle();print(target)
    if args.addon_builder:
        subprocess.run([sys.executable,str(args.addon_builder),'--name','mods/astra_ammo/hud','--entry',str(target),
            '--guid','eb9de2f7-5733-46a0-96d8-8750becccd53','--display-name','Astra Ammo — Configurable HUD 0.3.35',
            '--output',str(ROOT.parent / 'AstraAmmo-0.3.35.zip')],check=True)

        with zipfile.ZipFile(ROOT.parent / 'AstraAmmo-0.3.35.zip','a',zipfile.ZIP_DEFLATED) as archive:
            for name in ['README.md','NATIVE_ANCHOR.md','AstraAmmo-tuning.lua']:
                archive.write(ROOT / name,name)
            for path in sorted((ROOT / 'licenses').rglob('*')):
                if path.is_file(): archive.write(path,path.relative_to(ROOT).as_posix())
