"""Bundle clean modules; optionally package with an installed Bingus addon builder."""
import argparse
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ORDER = ['bundled_defaults', 'native_font_data', 'native_font_uv', 'native_font', 'config', 'font', 'motion', 'ammo_types', 'model', 'fire_icons', 'munition_art', 'mg_easter', 'df_shell_state', 'recoilless_state', 'senator_state', 'senator_panel', 'melta_panel', 'speargun_panel', 'recoilless_panel', 'catalog_housing', 'sta11_panel','weapon_styles', 'layout', 'memory', 'layouts', 'reader', 'pose', 'camera_mode', 'projection', 'anchor', 'view', 'pose_motion', 'world_probe', 'depth_marker', 'offscreen_test', 'world_style', 'archived_mesh', 'scene_test', 'screen_scene', 'placement', 'weapon_names', 'weapon_offsets', 'layout_editor', 'menu', 'runtime']

def bundle():
    parts = ['-- HD2-Addon: mods/dbf_hud/hud\nlocal HUD={}\n']
    for name in ORDER:
        parts.append(f'HUD.{name}=(function()\n{(ROOT / "src" / (name+".lua")).read_text(encoding="utf-8")}\nend)()\n')
    parts.append('local ok,result=pcall(function() return HUD.runtime.start(assert(rawget(_G,"stingray"),"stingray missing"),HUD.memory.native()) end)\n'
                 'if not ok then rawset(_G,"DBFHUD",{status=tostring(result),version="0.3.42"}) end\nreturn rawget(_G,"DBFHUD")\n')
    target = ROOT / 'dist' / 'dbf_hud.lua'
    target.parent.mkdir(exist_ok=True)
    target.write_text(''.join(parts), encoding='utf-8')
    live = ROOT / 'mdl' / 'dbf_hud' / 'mod.lua'
    live.parent.mkdir(parents=True, exist_ok=True)
    live_parts = ['-- DBF-HUD / MDL API 2 loose mod.\nlocal HUD={}\n']
    for name in ORDER:
        live_parts.append(f'HUD.{name}=(function()\n{(ROOT / "src" / (name+".lua")).read_text(encoding="utf-8")}\nend)()\n')
    live_parts.append(f'return (function()\n{(ROOT / "src" / "mdl.lua").read_text(encoding="utf-8")}\nend)()\n')
    live.write_text(''.join(live_parts), encoding='utf-8')
    with zipfile.ZipFile(ROOT.parent / 'DBF-HUD-MDL-0.3.42.zip','w',zipfile.ZIP_DEFLATED) as archive:
        archive.write(live,'dbf_hud/mod.lua')
        if (ROOT / 'MDL.md').exists(): archive.write(ROOT / 'MDL.md','dbf_hud/README.md')
        archive.write(ROOT / 'DBF-HUD-weapon-offsets.lua','DBF-HUD-weapon-offsets.lua')
        archive.write(ROOT / 'DBF-HUD-tuning.lua','DBF-HUD-tuning.lua')
        for path in sorted((ROOT/'presets').glob('*.layout')): archive.write(path,'Presets/'+path.name)
        for path in sorted((ROOT / 'licenses').rglob('*')):
            if path.is_file(): archive.write(path,'dbf_hud/'+path.relative_to(ROOT).as_posix())
    return target

if __name__ == '__main__':
    p=argparse.ArgumentParser();p.add_argument('--addon-builder',type=Path);args=p.parse_args()
    target=bundle();print(target)
    if args.addon_builder:
        subprocess.run([sys.executable,str(args.addon_builder),'--name','mods/dbf_hud/hud','--entry',str(target),
            '--guid','eb9de2f7-5733-46a0-96d8-8750becccd53','--display-name','DBF-HUD — Configurable HUD 0.3.42',
            '--output',str(ROOT.parent / 'DBF-HUD-0.3.42.zip')],check=True)

        with zipfile.ZipFile(ROOT.parent / 'DBF-HUD-0.3.42.zip','a',zipfile.ZIP_DEFLATED) as archive:
            for name in ['README.md','NATIVE_ANCHOR.md','DBF-HUD-tuning.lua','DBF-HUD-weapon-offsets.lua']:
                archive.write(ROOT / name,name)
            for path in sorted((ROOT / 'licenses').rglob('*')):
                if path.is_file(): archive.write(path,path.relative_to(ROOT).as_posix())
