"""Convert all Nerd Fonts release faces to lossless ASCII mask atlases for future HUD use.
Keeps source archive checksums, glyph metrics and upstream licenses. No system font installation.
"""
from pathlib import Path
import argparse,concurrent.futures,hashlib,io,json,tarfile,time,urllib.request,sys
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/"work/font-tools"))
from fontTools.ttLib import TTFont
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
def fetch(url):
 return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'DBF-HUD-font-import'}),timeout=120)
def convert(asset,cache,out):
 family=asset['name'].removesuffix('.tar.xz');source=cache/asset['name'];source.parent.mkdir(parents=True,exist_ok=True)
 if not source.exists() or source.stat().st_size!=asset['size']:
  tmp=source.with_suffix('.part')
  with fetch(asset['browser_download_url']) as response,tmp.open('wb') as f:
   while data:=response.read(1024*1024):f.write(data)
  assert tmp.stat().st_size==asset['size'];tmp.replace(source)
 digest=hashlib.sha256(source.read_bytes()).hexdigest()
 if asset.get('digest'):assert asset['digest']=='sha256:'+digest
 folder=out/family;folder.mkdir(parents=True,exist_ok=True);faces=[]
 with tarfile.open(source,'r:xz') as tar:
  for member in tar:
   if not member.isfile():continue
   path=Path(member.name);name=path.name
   if path.suffix.lower() in ('.ttf','.otf'):
    data=tar.extractfile(member).read();font=ImageFont.truetype(io.BytesIO(data),48)
    cmap=TTFont(io.BytesIO(data)).getBestCmap() or {}
    codes=list(range(32,127)) if family!='NerdFontsSymbolsOnly' else sorted(cmap)
    glyphs={};bboxes=[font.getbbox(chr(c),anchor='ls') if c in cmap else (0,0,0,0) for c in codes]
    left=min(0,min(b[0] for b in bboxes));right=max(max(b[2] for b in bboxes),int(max(font.getlength(chr(c)) for c in codes))+1)
    top=min(b[1] for b in bboxes);bottom=max(b[3] for b in bboxes)
    cw=right-left+4;ch=bottom-top+4;atlas=Image.new('L',(16*cw,((len(codes)+15)//16)*ch));draw=ImageDraw.Draw(atlas)
    for i,c in enumerate(codes):
     x=(i%16)*cw;y=(i//16)*ch
     if c in cmap:draw.text((x+2-left,y+2-top),chr(c),font=font,fill=255,anchor='ls')
     # Guard cells must remain clear: prevents accidental cross-glyph sampling.
     cell=atlas.crop((x,y,x+cw,y+ch));bb=cell.getbbox()
     assert bb is None or (bb[0]>=2 and bb[1]>=2 and bb[2]<=cw-2 and bb[3]<=ch-2),(family,name,c,bb)
     glyphs[str(c)]={'cell':[x,y,cw,ch],'bounds':list(bboxes[i]),'advance':font.getlength(chr(c)),'supported':c in cmap}
    stem=path.stem;atlas.save(folder/(stem+'.png'),optimize=True)
    metadata={'format':'dbf-hud-alpha-atlas-v1','family':family,'face':name,'source_sha256':hashlib.sha256(data).hexdigest(),'raster_size':48,'baseline':2-top,'origin_x':2-left,'characters':'ASCII U+0020-U+007E' if family!='NerdFontsSymbolsOnly' else 'All symbols in source cmap','missing_ascii':[c for c in range(32,127) if c not in cmap],'glyphs':glyphs}
    (folder/(stem+'.json')).write_text(json.dumps(metadata,separators=(',',':'))+'\n')
    faces.append({'name':name,'atlas':family+'/'+stem+'.png','metrics':family+'/'+stem+'.json'})
   elif any(k in name.lower() for k in ('license','ofl','copyright','readme','authors','notice')):
    # Save nested license paths without trusting archive path traversal.
    safe=[p for p in path.parts if p not in ('..','.','/','\\')]
    target=folder/'licenses'/Path(*safe);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(tar.extractfile(member).read())
 assert faces,(family,'no font faces')
 record={'family':family,'source_url':asset['browser_download_url'],'archive_sha256':digest,'faces':faces}
 (folder/'IMPORT.json').write_text(json.dumps(record,indent=2)+'\n')
 print('CONVERTED',family,len(faces),'faces',flush=True);return record
def main():
 p=argparse.ArgumentParser();p.add_argument('--release',default='v3.5.1');p.add_argument('--workers',type=int,default=4);p.add_argument('--cache',type=Path,required=True);args=p.parse_args()
 with fetch('https://api.github.com/repos/ryanoasis/nerd-fonts/releases/tags/'+args.release) as r:release=json.load(r)
 assets=[a for a in release['assets'] if a['name'].endswith('.tar.xz')]
 out=ROOT/'assets/fonts';out.mkdir(parents=True,exist_ok=True);records=[];errors=[]
 with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
  jobs={pool.submit(convert,a,args.cache,out):a['name'] for a in assets}
  for job in concurrent.futures.as_completed(jobs):
   try:records.append(job.result())
   except Exception as e:errors.append({'archive':jobs[job],'error':str(e)});print('FAILED',jobs[job],str(e),flush=True)
 catalog={'release':args.release,'raster_size':48,'coverage':'Printable ASCII; Nerd Font icons and additional Unicode can be converted from retained source archives later.','families':sorted(records,key=lambda x:x['family']),'errors':errors}
 (out/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
 print('RESULT',len(records),'families',sum(len(r['faces']) for r in records),'faces',len(errors),'errors',flush=True)
 if errors:raise SystemExit(1)
if __name__=='__main__':main()
