"""Install only the MDL lifecycle build into the local MDL mod folder."""
from pathlib import Path
import os, shutil
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'mdl/dbf_hud/mod.lua'
body=source.read_text(encoding='utf-8')
if not body.startswith('-- DBF-HUD / MDL API 2 loose mod.') or 'on_enable=function(ctx)' not in body or 'on_disable=disable' not in body:
    raise SystemExit('Refusing installation: expected MDL API 2 lifecycle artifact')
destination=Path(os.environ['LOCALAPPDATA'])/'MDL/Helldivers2/Mods/dbf_hud/mod.lua'
destination.parent.mkdir(parents=True,exist_ok=True)
staging=destination.with_suffix('.lua.pending')
shutil.copyfile(source,staging)
os.replace(staging,destination)
print('Installed verified MDL lifecycle artifact')
