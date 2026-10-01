"""Build the isolated MDL camera sampler, optionally install atomically."""
from pathlib import Path
import argparse,os
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--install',action='store_true');args=p.parse_args()
parts=['local HUD={}']
for name in ['ammo_types','memory','layouts','reader','pose','camera_state']:
 parts.append('HUD.'+name+'=(function()\n'+(ROOT/'src'/f'{name}.lua').read_text()+'\nend)()')
parts.append((ROOT/'src/camera_research_mdl.lua').read_text())
output=ROOT/'dist/dbf_camera_research.lua';output.write_text('\n'.join(parts))
if args.install:
 target=Path(os.environ['LOCALAPPDATA'])/'MDL/Helldivers2/Mods/dbf_camera_research/mod.lua'
 target.parent.mkdir(parents=True,exist_ok=True)
 temp=target.with_suffix('.lua.next');temp.write_bytes(output.read_bytes());temp.replace(target)
 print('Installed',target)
print(output)
