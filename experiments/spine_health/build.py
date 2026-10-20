"""Allowlisted standalone LLL candidate. Never bundles the maintained HUD."""
from pathlib import Path
import hashlib
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parent
VERSION = json.loads((ROOT / 'manifest.json').read_text())['version']
OUT = ROOT.parents[1] / 'dist' / ('spine-health-' + VERSION)
FILES = ('main.lua', 'manifest.json', 'backend.lua', 'renderer.lua', 'spine_health.lua')
def build():
    target = OUT / 'dbf_spine_health'
    target.mkdir(parents=True, exist_ok=True)
    hashes = {}
    for name in FILES:
        shutil.copy2(ROOT / name, target / name)
        hashes[name] = hashlib.sha256((target / name).read_bytes()).hexdigest()
    # Refuse unexpected leftovers rather than silently package them.
    assert {p.name for p in target.iterdir()} == set(FILES)
    (OUT / 'SHA256.json').write_text(json.dumps(hashes, indent=2)+'\n')
    with zipfile.ZipFile(OUT / ('SpineHealth-' + VERSION + '-LLL.zip'), 'w', zipfile.ZIP_DEFLATED) as z:
        for name in FILES:
            z.write(target / name, 'dbf_spine_health/' + name)
    print(OUT)
    return target, hashes
if __name__ == '__main__':
    build()
