"""Convert the retained 72 font families into native ASCII HUD font assets.

Full Nerd-symbol coverage is separate from this text conversion.
"""
from pathlib import Path
import argparse,hashlib,io,json,re,struct,tarfile,zipfile
from PIL import Image,ImageDraw,ImageFont
from build_native_font_depth import hash64

ROOT=Path(__file__).resolve().parents[1]

def archive(resources):
    resources.sort(key=lambda r:(r[1],r[0]));types=sorted({r[1] for r in resources})
    body=bytearray((72+len(types)*32+len(resources)*80+15)&~15);gpu=bytearray();entries=bytearray();cpu=gp=0
    for i,(name,kind,data,graphics) in enumerate(resources):
        align=256 if kind==hash64('shader_library') else 16
        body+=b'\0'*(-len(body)%align)
        entries+=struct.pack('<7Q6I',name,kind,len(body),0,len(gpu),cpu,gp if graphics else 0,len(data),0,len(graphics),align,256 if graphics else 16,i)
        body+=data;cpu+=(len(data)+255)&~255
        gpu+=graphics;gpu+=b'\0'*(-len(gpu)%256)
        if graphics:gp+=(len(graphics)+255)&~255
    header=struct.pack('<III20sQQ24s',0xf0000011,len(types),len(resources),b'',cpu,gp,b'')
    table=b''.join(struct.pack('<IIQIIII',0,0,t,sum(r[1]==t for r in resources),0,256 if t==hash64('shader_library') else 16,256 if t==hash64('shader_library') else 64 if t==hash64('shader_library_group') else 16) for t in types)
    body[:len(header+table+entries)]=header+table+entries
    for r in struct.iter_unpack('<7Q6I',entries):
        assert r[2]%r[10]==0 and r[4]%r[11]==0
        assert r[2]+r[7]<=len(body) and r[4]+r[9]<=len(gpu)
        assert r[5]+r[7]<=cpu and r[6]+r[9]<=gp
    return body,gpu

def main(cache):
    catalog=json.loads((ROOT/'assets/fonts/catalog.json').read_text())
    template=(ROOT/'assets/native-hack/font-template.bin').read_bytes()
    ids=struct.unpack_from('<193I',template,88)
    texture_source=(ROOT/'assets/native-hack/texture-template.bin').read_bytes()
    original_material=(ROOT/'assets/native-font-depth/source.bin').read_bytes()
    resources=[]
    with zipfile.ZipFile(ROOT.parent/'DBF-HUD-Native-Font-Depth-Test-0.2.zip') as z:
        stem='DepthState/ee6b1ba7e22d71ed.patch_0';b=z.read(stem);g=z.read(stem+'.gpu_resources')
        _,nt,n=struct.unpack_from('<III',b)
        for r in struct.iter_unpack('<7Q6I',b[72+nt*32:72+nt*32+n*80]):resources.append((r[0],r[1],b[r[2]:r[2]+r[7]],g[r[4]:r[4]+r[9]]))
    depth_source=next(r[2] for r in resources if r[1]==hash64('material'))
    # The shared renderer group must register both native text and solid HUD depth shaders.
    with zipfile.ZipFile(ROOT.parent/'DBF-HUD-WorldGUI-Depth-Probe-0.3.zip') as z:
        stem='DepthState/ee6b1ba7e22d71ed.patch_0';b=z.read(stem);g=z.read(stem+'.gpu_resources')
        _,nt,n=struct.unpack_from('<III',b)
        for r in struct.iter_unpack('<7Q6I',b[72+nt*32:72+nt*32+n*80]):
            if r[1]!=hash64('shader_library_group'):resources.append((r[0],r[1],b[r[2]:r[2]+r[7]],g[r[4]:r[4]+r[9]]))
            else:
                extra=b[r[2]+640:r[2]+r[7]]
                for i,item in enumerate(resources):
                    if item[1]==hash64('shader_library_group'):
                        group=bytearray(item[2]);struct.pack_into('<I',group,16,struct.unpack_from('<I',group,16)[0]+len(extra)//8)
                        resources[i]=(item[0],item[1],bytes(group)+extra,item[3])

    lua=['-- Native font metrics only; no rectangle glyph data.','local M={faces={},order={}}']
    reports=[];selected={}
    for family in catalog['families']:
        name=family['family'];key='bigblue' if name=='BigBlueTerminal' else re.sub('[^a-z0-9]','',name.lower())
        assert key not in selected
        faces=family['faces'];regular=[f for f in faces if 'Regular' in f['name']]
        face=next((f for f in regular if 'FontMono-' in f['name']),regular[0] if regular else faces[0])
        if name=='Hack':face=next(f for f in faces if f['name']=='HackNerdFont-Regular.ttf')
        if name=='Meslo':face=next(f for f in faces if f['name']=='MesloLGMNerdFontMono-Regular.ttf')
        path=cache/(name+'.tar.xz')
        assert hashlib.sha256(path.read_bytes()).hexdigest()==family['archive_sha256']
        with tarfile.open(path) as t:
            member=next(m for m in t.getmembers() if Path(m.name).name==face['name'])
            source=t.extractfile(member).read()
        meta=json.loads((ROOT/'assets/fonts'/face['metrics']).read_text())
        assert hashlib.sha256(source).hexdigest()==meta['source_sha256']
        font=ImageFont.truetype(io.BytesIO(source),48)
        metrics={};missing=meta.get('missing_ascii',[])
        # The symbols-only family cannot display ASCII: retain visible native
        # fallback text rather than pretending its source contains letters.
        if missing:
            with tarfile.open(cache/'Hack.tar.xz') as t:
                member=next(m for m in t.getmembers() if Path(m.name).name=='HackNerdFont-Regular.ttf')
                fallback=ImageFont.truetype(io.BytesIO(t.extractfile(member).read()),48)
        else:fallback=font
        boxes=[(fallback if cp in missing else font).getbbox(chr(cp),anchor='ls') for cp in ids if cp>=32]
        baseline=max(48,2-min(b[1] for b in boxes))
        cell=max(64,max(b[2]-b[0]+4 for b in boxes),baseline+max(b[3] for b in boxes)+4)
        cell=(cell+15)//16*16
        dimension=1
        while dimension<16*cell:dimension*=2
        atlas=Image.new('L',(dimension,dimension));draw=ImageDraw.Draw(atlas)
        data=bytearray(template);struct.pack_into('<5f',data,8,48,48,baseline,1/dimension,1/dimension)
        for i,code in enumerate(ids):
            cp=code if code>=32 else 63;chosen=fallback if cp in missing else font
            ch=chr(cp);a,b,c,d=chosen.getbbox(ch,anchor='ls');x=(i%16)*cell+2;y=(i//16)*cell+baseline
            assert x+c-a<dimension and y+b>=0 and y+d<dimension
            draw.text((x-a,y),ch,font=chosen,fill=255,anchor='ls')
            advance=chosen.getlength(ch)
            record=struct.pack('<7f',x,y+b,max(1,c-a),max(1,d-b),a,baseline+b,advance)
            data[860+i*28:860+(i+1)*28]=record
            if code==63:data[40:68]=record
            metrics[code]=[advance,a,-d,c,-b]
        rgba=Image.new('RGBA',atlas.size,(255,255,255,255));rgba.putalpha(atlas)
        graphics=bytearray()
        while True:
            graphics+=rgba.tobytes()
            if rgba.width==1:break
            rgba=rgba.resize((rgba.width//2,rgba.height//2),Image.Resampling.LANCZOS)
        tex=bytearray(texture_source);struct.pack_into('<II',tex,204,dimension,dimension);struct.pack_into('<I',tex,212,dimension*4);struct.pack_into('<I',tex,220,dimension.bit_length())
        resource='mods/dbf_hud/fonts/native_'+key
        materials=[]
        for suffix,base in [('_depth',depth_source),('_clear',original_material)]:
            material=bytearray(base);assert struct.unpack_from('<I',material,136)[0]==0x3aa8b87e
            struct.pack_into('<Q',material,140,hash64(resource));mat='mods/dbf_hud/materials/native_'+key+suffix
            resources.append((hash64(mat),hash64('material'),bytes(material),b''));materials.append(mat)
        resources += [(hash64(resource),hash64('font'),bytes(data),b''),(hash64(resource),hash64('texture'),bytes(tex),bytes(graphics))]
        label=name+' Nerd Font'+(' (Hack text fallback)' if missing else '')
        lua.append('M.faces[%s]={label=%s,font=%s,depth=%s,clear=%s,em=48,glyphs={'%tuple(json.dumps(x) for x in [key,label,resource,*materials]))
        for code,g in metrics.items():
            if 32<=code<=126:lua.append('[%d]={%s},'%(code,','.join(format(v,'.6g') for v in g)))
        lua.append('}}');selected[key]=label
        reports.append({'family':name,'id':key,'face':face['name'],'source_sha256':meta['source_sha256'],'ascii_fallback':missing,'template_path_live_verified':name=='Hack'})
        print('Converted',name,flush=True)
    old=['bigblue','debug','jetbrainsmono','firacode','meslo','hack','cascadiacode','iosevka','0xproto','sourcecodepro','firamono','cascadiamono']
    order=old+[k for k in sorted(selected) if k not in old]
    lua.append('M.order={'+','.join(json.dumps(k) for k in order)+'}');lua.append('return M')
    (ROOT/'src/native_font_data.lua').write_text('\n'.join(lua)+'\n')
    body,gpu=archive(resources);output=ROOT.parent/'DBF-HUD-Native-Fonts-0.2.zip'
    manifest={'Version':1,'Guid':'ed90893b-9a66-4c80-8b30-8d1240f6bd60','Name':'DBF-HUD Native Fonts 0.2','Description':'72 converted font families. Only Hack has been visually validated.','Options':[{'Name':'Native font library','Include':['NativeFonts']}]}
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('manifest.json',json.dumps(manifest,indent=2));stem='NativeFonts/ee6b1ba7e22d71ed.patch_0'
        z.writestr(stem,body);z.writestr(stem+'.stream',b'');z.writestr(stem+'.gpu_resources',gpu)
        z.writestr('conversion-report.json',json.dumps(reports,indent=2))
        z.writestr('README.txt','Replace prior Hack/native-font test assets with this library. Deploy in Arsenal and restart. Enable only this native-font asset package.\n72 families, one regular face each; template Latin/ASCII coverage, not full Nerd Unicode. Only Hack is live-verified. Symbols-only ASCII uses Hack fallback.\n')
        for p in sorted((ROOT/'assets/fonts').glob('*/licenses/*')):
            if p.is_file():z.write(p,'licenses/'+p.relative_to(ROOT/'assets/fonts').as_posix())
    (ROOT/'assets/fonts/native-conversion-report.json').write_text(json.dumps(reports,indent=2)+'\n')
    print(output)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--cache',type=Path,required=True);main(p.parse_args().cache)
