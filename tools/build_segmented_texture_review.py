# Historical one-off review builder; use tools/build_lll.py for maintained modular HUD packages.
"""Build the local Fancy texture review ZIP; never changes installed files."""
from pathlib import Path
import hashlib, json, subprocess, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'dist/segmented-fancy-texture-20261010'
subprocess.run([sys.executable, str(ROOT / 'tools/build_lll.py')], check=True)
OUT.mkdir(parents=True, exist_ok=True)
source = ROOT / 'dist/releases/modular-20261010/dbf_hud'
assets = ROOT / 'assets/segmented-fancy'
metadata = json.loads((assets / 'TEXTURES.json').read_text())
readme = '''DBF-HUD Fancy primary texture candidate - October 10, 2026

Requires the installed DBF-HUD font/depth/material assets and LLL R30 or later.
Copy dbf_hud into Local AppData/LLL/Helldivers2/Mods, preserving local configuration.
Copy the two HotTextures/*.rgba files into Local AppData/DBF/HotTextures.
MERGE manifest-additions.tsv into the existing HotTextures/manifest.tsv by name.
Keep every existing row: an artwork reload publishes the entire manifest together.
Reload only DBF HUD, then use Appearance > Reload texture files if needed.
Do not activate an older giant mod.lua alongside the modular provider.

Fancy primaries only: cached rectangular face, digit atlas, white/gold/navy,
independent backing translucency, shared Decorations, red 2Hz empty counter.
Native labels remain font glyphs. No per-frame primitive segment construction.
Legacy styles, shader layers and aiming upright/zoom effects are suppressed
for this instrument. Saved placement and weapon pose remain authoritative.
WorldGUI uses native explicit-UV bitmaps for the complete texture instrument,
including recoil and diving camera offsets. Native fonts, textures and decoration
share scene-depth controls, using calibrated native projection converted to metres.
Other render modes retain their existing camera/depth route.
54 verified primary identities are covered offline; Defender is unresolved.
No tuning, weapon placement, native DLLs, or old designs are included/replaced.
Live acceptance is recorded separately in DEPLOYMENT.json, outside this ZIP.
'''
with zipfile.ZipFile(source.parent / 'dbf_hud-0.3.42-LLL-Modular.zip') as modular:
    assert modular.testzip() is None
    files = {name.removeprefix('dbf_hud/'): modular.read(name) for name in modular.namelist()}
module_paths = set(files)
for item in metadata['images']:
    data = (assets / item['filename']).read_bytes()
    assert len(data) == item['width'] * item['height'] * 4
    assert hashlib.sha256(data).hexdigest() == item['sha256']
    files['HotTextures/' + item['filename']] = data
files['HotTextures/manifest-additions.tsv'] = (assets / 'manifest-additions.tsv').read_bytes()
files['HotTextures/TEXTURES.json'] = (assets / 'TEXTURES.json').read_bytes()
files['README.txt'] = readme.encode()
target = OUT / 'DBF-HUD-Fancy-Primary-Textures-20261010.zip'
with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
    for name, data in sorted(files.items()):
        archive.writestr(('dbf_hud/' + name) if name in module_paths else name, data)
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
(OUT / 'PACKAGE.json').write_text(json.dumps({'zip': str(target), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'texture_bytes': metadata['total_bytes'], 'files': len(files)}, indent=2) + '\n')
print(target)
