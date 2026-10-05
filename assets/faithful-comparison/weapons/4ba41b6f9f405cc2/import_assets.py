"""Validate edited PNG exports and package renderer-neutral creator assets."""
from pathlib import Path
import argparse,json,zipfile,hashlib
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--resolution',type=int,choices=[2,4],default=4);a=p.parse_args()
root=Path(__file__).resolve().parent;layout=json.loads((root/'layout.json').read_text());size=tuple(round(x*a.resolution) for x in layout['logical_size'])
files=[]
for layer in layout['layers']:
    path=a.folder/layer['asset'];im=Image.open(path)
    assert im.mode=='RGBA',f'{path}: export RGBA with alpha'
    assert im.size==size,f'{path}: expected {size}, got {im.size}'
    files.append(path)
layout['texture_size']=size;layout['asset_sha256']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
out=a.folder/'creator-assets.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for path in files:z.write(path,path.name)
    z.writestr('layout.json',json.dumps(layout,indent=2))
print(out);print('Validated asset handoff; engine archive/material compilation belongs to DBF-HUD.')
