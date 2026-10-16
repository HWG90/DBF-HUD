"""Build and verify the matched HUD / War Journalist Arsenal asset payloads."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import zipfile
from shared_shader_assets import ROOT, GROUP, SHADER, shared_resources

HUD = ROOT/'dist/releases/shader-coexistence/DBF-HUD-Complete-0.3.42.zip'
PHOTO_ROOT = ROOT.parent/'DBF_PhotoMode'
PHOTO_OUTPUT = PHOTO_ROOT/'dist/releases/shader-coexistence-20261015'

def shader_rows(path):
    with zipfile.ZipFile(path) as z:
        assert z.testzip() is None
        stem='Assets/ee6b1ba7e22d71ed.patch_0'
        cpu=z.read(stem)
        _,nt,n=struct.unpack_from('<III',cpu)
        table=list(struct.iter_unpack('<7Q6I',cpu[72+nt*32:72+nt*32+n*80]))
        rows=[]
        # Read only library slices of the large HUD GPU companion.
        with z.open(stem+'.gpu_resources') as gpu:
            for r in sorted(table,key=lambda r:r[4]):
                if r[1] not in (GROUP,SHADER):continue
                gpu.seek(r[4]);data=gpu.read(r[9]);assert len(data)==r[9]
                rows.append((r[0],r[1],cpu[r[2]:r[2]+r[7]],data))
        manifest=json.loads(z.read('manifest.json'))
        assert any('Assets' in o['Include'] for o in manifest['Options'])
        return sorted(rows)

def verify(photo=None):
    photo=photo or PHOTO_OUTPUT/('War-Journalist-'+(PHOTO_ROOT/'VERSION').read_text().strip()+'-Assets.zip')
    expected,audit=shared_resources()
    for package in (HUD,photo):
        assert shader_rows(package)==sorted(expected), 'Package shader closure differs: '+str(package)
    receipt=dict(audit,verified_both_load_orders=True,packages={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in (HUD,photo)},deployed=False,live_visibility_verified=False)
    (HUD.parent/'PAIR-VERIFICATION.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps(receipt,indent=2))

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-only',action='store_true')
    parser.add_argument('--photo-package',type=Path,help='Explicit companion asset ZIP to verify, including a published release')
    args=parser.parse_args()
    if not args.verify_only:
        subprocess.run([sys.executable,str(ROOT/'tools/test_shared_shader_assets.py')],check=True)
        subprocess.run([sys.executable,str(ROOT/'tools/build_complete.py')],check=True)
        subprocess.run([sys.executable,str(PHOTO_ROOT/'tools/build_release.py'),'--assets-only','--output',str(PHOTO_OUTPUT)],check=True)
    verify(args.photo_package)
