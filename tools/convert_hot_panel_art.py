"""Publish complete, immutable RGBA batches through one atomic manifest switch."""
from pathlib import Path
import hashlib,os,re,tempfile
from PIL import Image

def atomic(path,data):
    handle,name=tempfile.mkstemp(prefix='.'+path.name+'-',dir=path.parent)
    try:
        with os.fdopen(handle,'wb') as f:
            f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(name,path)
    finally:
        if os.path.exists(name):os.unlink(name)

def publish(root,images):
    rows=[];seen=set();total=0
    for name,width,height,pixels in images:
        if not re.fullmatch(r'[A-Za-z0-9_-]+',name) or name in seen:raise ValueError('Invalid or duplicate artwork name')
        seen.add(name)
        if not(1<=width<=1024 and 1<=height<=1024) or len(pixels)!=width*height*4:raise ValueError('Invalid artwork dimensions or pixel length')
        total+=len(pixels)
        if len(seen)>512 or total>32*1024*1024:raise ValueError('Artwork batch exceeds upload limits')
        digest=hashlib.sha256(pixels).hexdigest()
        filename=name+'_'+digest+'.rgba';path=root/filename
        if path.exists():
            if path.read_bytes()!=pixels:raise ValueError('Immutable artwork file changed: '+filename)
        else:atomic(path,pixels)
        rows.append(f'{name}\t{width}\t{height}\t{filename}')
    if not rows:raise ValueError('No artwork selected')
    # A reader sees the whole old batch or the whole new batch. Old files remain
    # available for an in-flight reader and are never overwritten or removed.
    manifest=('\n'.join(rows)+'\n').encode()
    if len(manifest)>65536:raise ValueError('Artwork manifest exceeds runtime limit')
    atomic(root/'manifest.tsv',manifest)
    return len(rows),total

def convert(root):
    images=[]
    for line in (root/'manifest.tsv').read_text().splitlines():
        if not line or line.startswith('#'):continue
        fields=line.split('\t')
        if len(fields)not in (3,4):raise ValueError('Invalid manifest row')
        name,w,h=fields[:3];w=int(w);h=int(h)
        if not re.fullmatch(r'[A-Za-z0-9_-]+',name):raise ValueError('Invalid artwork name')
        with Image.open(root/(name+'.png')) as image:
            if image.size!=(w,h):raise ValueError('Keep the manifest dimensions: '+name)
            images.append((name,w,h,image.convert('RGBA').tobytes()))
    return publish(root,images)

if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parent)
    result=convert(parser.parse_args().root)
    print('Published',result[0],'images. Use Reload texture files in MCM.')
