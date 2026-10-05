"""Prepare editable HUD fragment PNGs and tightly packed RGBA files."""
import argparse,os,json,shutil
from pathlib import Path
from PIL import Image
from convert_hot_panel_art import publish

def prepare(weapon,output,refresh=False):
 source=Path(__file__).resolve().parents[1]/'assets/faithful-all/weapons'/weapon
 if not source.is_dir():raise ValueError('Unknown weapon artwork: '+weapon)
 output.mkdir(parents=True,exist_ok=True);images=[]
 for original in sorted(source.glob('fragment-*.png')):
  name='faithful_'+weapon+'_'+original.stem.replace('-','_')
  editable=output/(name+'.png')
  if refresh or not editable.exists():shutil.copy2(original,editable)
  with Image.open(editable) as image:
   with Image.open(original) as baseline:
    if image.size!=baseline.size:raise ValueError('Keep original dimensions: '+editable.name)
   w,h=image.size
   if not(1<=w<=1024 and 1<=h<=1024):raise ValueError('Image dimensions exceed runtime limit')
   pixels=image.convert('RGBA').tobytes()
  images.append((name,w,h,pixels))
 if not images:raise ValueError('No artwork fragments found')
 return publish(output,images)
if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--weapon',default='968211c0033dce64');p.add_argument('--output',type=Path,default=Path(os.environ['LOCALAPPDATA'])/'DBF/HotTextures');p.add_argument('--reset-pngs',action='store_true');a=p.parse_args();print(prepare(a.weapon,a.output,a.reset_pngs))
