"""Queue a bounded, debug-only camera snapshot and save acknowledged evidence."""
from pathlib import Path
import argparse,time
p=argparse.ArgumentParser();p.add_argument('label');args=p.parse_args()
assert args.label.replace('_','').replace('-','').isalnum() and len(args.label)<=64
root=Path(r'C:/Program Files (x86)/Steam/steamapps/common/Helldivers 2')
request=root/'DBF-HUD-camera-request.txt';log=root/'DBF-HUD-camera.log'
assert not request.exists(),'Existing request left untouched'
start=log.stat().st_size
request.write_text(args.label,encoding='ascii')
end=time.monotonic()+12
while time.monotonic()<end:
 time.sleep(.2)
 with log.open('rb') as f:f.seek(start);text=f.read().decode(errors='replace')
 if 'CAMERA_CAPTURE complete label='+args.label in text or 'CAMERA_CAPTURE failure label='+args.label in text:
  out=Path(__file__).resolve().parents[3]/'work'/('camera-state-'+args.label+'.txt')
  out.write_text(text);print(text);print('Saved',out);break
else:
 # Do not leave a delayed sample to be mislabeled after the player switches modes.
 if request.exists() and request.read_text()==args.label:request.unlink()
 raise SystemExit('No snapshot acknowledged; enable Debug logging and equip a weapon')
