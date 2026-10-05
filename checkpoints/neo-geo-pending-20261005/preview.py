from pathlib import Path
import json,html
from PIL import Image,ImageDraw
P=Path(__file__).resolve().parent
R=Path(r'C:\Users\david\Documents\Codex\2026-10-04\hud-checkout-before-relocation\assets\fonts\BigBlueTerminal')
meta=json.loads((R/'BigBlueTerm437NerdFont-Regular.json').read_text());atlas=Image.open(R/'BigBlueTerm437NerdFont-Regular.png').convert('L')
inventory=json.loads((P/'inventory.json').read_text());O=P/'previews';O.mkdir(exist_ok=True);cards=[]
for rid,a in inventory.items():
 commands=[]
 for line in (P/'commands'/(rid+'.tsv')).read_text().splitlines():
  q=line.split('\t');commands.append(dict(kind=q[0],x=float(q[1]),y=float(q[2]),w=float(q[3]),h=float(q[4]),size=float(q[5]),c=tuple(round(float(z))for z in q[6:9]),a=float(q[9]),text=q[10]if len(q)>10 else ''))
 f=commands[0];factor=3;low=min(v['y']-v['size'] for v in commands);high=max(v['y']+max(v['h'],v['size']) for v in commands)
 width=round(f['w']*factor+30)
 im=Image.new('RGBA',(width,round((high-low+20)*factor)),(17,23,26,255));ox=15-f['x']*factor;oy=(high+10)*factor
 for v in commands:
  layer=Image.new('RGBA',im.size);d=ImageDraw.Draw(layer);x,y=v['x'],v['y'];color=v['c'];alpha=max(0,min(1,v['a']))
  if v['kind'] in ('rect','panel') and v['w']>0 and v['h']>0:
   lx,ty=round(ox+x*factor),round(oy-(y+v['h'])*factor)
   d.rectangle((lx,ty,max(lx,round(ox+(x+v['w'])*factor)-1),max(ty,round(oy-y*factor)-1)),fill=color+(round(alpha*255),))
  elif v['kind']=='text':
   xx=ox+x*factor;baseline=oy-y*factor;scale=v['size']*factor/48
   for char in v['text']:
    g=meta['glyphs'].get(str(ord(char)),meta['glyphs']['63']);cx,cy,cw,ch=g['cell'];mask=atlas.crop((cx,cy,cx+cw,cy+ch)).resize((max(1,round(cw*scale)),max(1,round(ch*scale))),Image.Resampling.NEAREST)
    tinted=Image.new('RGBA',mask.size,color+(0,));tinted.putalpha(mask.point(lambda a:round(a*alpha)));layer.alpha_composite(tinted,(round(xx-meta['origin_x']*scale),round(baseline-meta['baseline']*scale)));xx+=g['advance']*scale
  im=Image.alpha_composite(im,layer)
 im.convert('RGB').save(O/(rid+'.png'))
 cards.append('<article data-name="'+html.escape(a['name'].lower())+'"><h2>'+html.escape(a['name'])+'</h2><img src="previews/'+rid+'.png"></article>')
keys=list(inventory)
for start in range(0,len(keys),20):
 sheet=Image.new('RGB',(1600,1050),(17,23,26));d=ImageDraw.Draw(sheet)
 for j,rid in enumerate(keys[start:start+20]):
  im=Image.open(O/(rid+'.png'));im.thumbnail((310,170));x=j%5*320;y=j//5*260;sheet.paste(im,(x,y+32));d.text((x+8,y+10),inventory[rid]['name'][:42],fill='white')
 sheet.save(P/('contact-'+str(start//20)+'.png'))
(P/'index.html').write_text('''<!doctype html><meta charset="utf-8"><title>Neo Geo weapon instruments</title><style>body{background:#11171a;color:#e5e7e2;font:14px system-ui;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(330px,1fr));gap:12px}article{border:1px solid #334047;padding:12px}img{width:100%;image-rendering:pixelated}h2{font-size:14px}input{padding:10px;background:#202b30;color:white;border:1px solid #53636a;width:300px}</style><h1>148 source-supported weapon identities</h1><p>Local native-primitive candidate. Sample readings. Existing camera mounts preserved; first-person and shoulder visibility need live verification. No deployment.</p><input placeholder="Find weapon" oninput="document.querySelectorAll('article').forEach(e=>e.hidden=!e.dataset.name.includes(this.value.toLowerCase()))"><main>'''+''.join(cards)+'</main>')
print('Rendered',len(cards),'weapon previews')
