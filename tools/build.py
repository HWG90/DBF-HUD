"""Bundle clean modules; optionally package with an installed Bingus addon builder."""
import argparse
from pathlib import Path
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ORDER = (
    'bundled_defaults',
    'native_font_data',
    'native_font_uv',
    'native_font',
    'config',
    'shader_layers',
    'font',
    'font_scale',
    'motion',
    'ammo_types',
    'model',
    'fire_icons',
    'munition_art',
    'mg_easter',
    'df_reload_state',
    'df_shell_state',
    'recoilless_state',
    'senator_state',
    'senator_panel',
    'melta_panel',
    'speargun_panel',
    'recoilless_panel',
    'catalog_housing',
    'sta11_panel',
    'weapon_styles',
    'layout',
    'simple_vertical',
    'view_presentation',
    'memory',
    'layouts',
    'reader',
    'pose',
    'camera_mode',
    'projection',
    'anchor',
    'view',
    'pose_motion',
    'world_probe',
    'depth_marker',
    'offscreen_test',
    'world_style',
    'archived_mesh',
    'scene_test',
    'texture_art',
    'texture_art_assets',
    'runtime_textures',
    'runtime_texture_source',
    'texture_completion','texture_retirement','texture_pool','runtime_texture_native',
    'runtime_texture_bridge',
    'hot_panel_art',
    'bespoke_texture_specs',
    'panel_texture_layers',
    'bespoke_texture_panel',
    'texture_theme',
    'screen_scene',
    'placement',
    'weapon_names',
    'weapon_offsets',
    'layout_editor',
    'menu',
    'mechanical_layouts',
    'double_freedom_atlas',
    'df_neogeo_atlas',
    'mechanical_art',
    'faithful_fragment_assets',
    'faithful_fragments',
    'df_media_panel',
    'ballistic_family_specs','ballistic_family',
    'df_designer_texture',
    'compass','df_retro_spec','df_retro_primitive','df_retro_panel',
    'control_requests',
    'runtime',
)

def render_bundles():
    """Both startup paths embed exactly the same ordered module body."""
    if len(ORDER) != len(set(ORDER)):
        raise ValueError('Duplicate bundle module')
    parts = ['local HUD={}\n']
    for name in ORDER:
        source = (ROOT / 'src' / (name + '.lua')).read_text(encoding='utf-8')
        parts.append(f'HUD.{name}=(function()\n{source}\nend)()\n')
    common = ''.join(parts)
    startup = ('-- HD2-Addon: mods/dbf_hud/hud\n' + common +
        'local ok,result=pcall(function() return HUD.runtime.start(assert(rawget(_G,"stingray"),"stingray missing"),HUD.memory.native()) end)\n'
        'if not ok then rawset(_G,"DBFHUD",{status=tostring(result),version="0.3.42"}) end\nreturn rawget(_G,"DBFHUD")\n')
    managed = ('-- DBF-HUD / MDL API 2 loose mod.\n' + common +
        'return (function()\n' + (ROOT / 'src' / 'mdl.lua').read_text(encoding='utf-8') + '\nend)()\n')
    return {'dist/dbf_hud.lua': startup, 'mdl/dbf_hud/mod.lua': managed}


def bundle(output_dir=ROOT, check=False):
    """Generate only source artifacts. Never installs or packages implicitly."""
    output_dir = Path(output_dir)
    stale = []
    for relative, text in render_bundles().items():
        target = output_dir / relative
        encoded = text.encode('utf-8')
        if check:
            if not target.exists() or target.read_bytes() != encoded:
                stale.append(relative)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(encoded)
    if stale:
        raise SystemExit('Stale generated bundles: ' + ', '.join(stale))
    return output_dir / 'dist/dbf_hud.lua'


def package_mdl(output_dir=ROOT):
    output_dir = Path(output_dir)
    live = output_dir / 'mdl/dbf_hud/mod.lua'
    with zipfile.ZipFile(ROOT.parent / 'DBF-HUD-MDL-0.3.42.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.write(live, 'dbf_hud/mod.lua')
        for name, target in [('MDL.md', 'dbf_hud/README.md'),
                             ('DBF-HUD-weapon-offsets.lua', 'DBF-HUD-weapon-offsets.lua'),
                             ('DBF-HUD-tuning.lua', 'DBF-HUD-tuning.lua')]:
            archive.write(ROOT / name, target)
        for path in sorted((ROOT / 'presets').glob('*.layout')):
            archive.write(path, 'Presets/' + path.name)
        for path in sorted((ROOT / 'licenses').rglob('*')):
            if path.is_file():
                archive.write(path, 'dbf_hud/' + path.relative_to(ROOT).as_posix())

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--addon-builder', type=Path)
    parser.add_argument('--output-dir', type=Path, default=ROOT)
    parser.add_argument('--check', action='store_true', help='Reject stale bundles without writing files')
    parser.add_argument('--package-mdl', action='store_true', help='Explicitly create the MDL ZIP')
    args = parser.parse_args()
    target = bundle(args.output_dir, args.check)
    print(target)
    if args.check:
        return
    if args.package_mdl or args.addon_builder:
        package_mdl(args.output_dir)
    if args.addon_builder:
        output = ROOT.parent / 'DBF-HUD-0.3.42.zip'
        subprocess.run([sys.executable, str(args.addon_builder), '--name', 'mods/dbf_hud/hud',
                        '--entry', str(target), '--guid', 'eb9de2f7-5733-46a0-96d8-8750becccd53',
                        '--display-name', 'DBF-HUD Configurable HUD 0.3.42', '--output', str(output)], check=True)
        with zipfile.ZipFile(output, 'a', zipfile.ZIP_DEFLATED) as archive:
            for name in ['README.md', 'NATIVE_ANCHOR.md', 'DBF-HUD-tuning.lua', 'DBF-HUD-weapon-offsets.lua']:
                archive.write(ROOT / name, name)
            for path in sorted((ROOT / 'licenses').rglob('*')):
                if path.is_file():
                    archive.write(path, path.relative_to(ROOT).as_posix())


if __name__ == '__main__':
    main()
