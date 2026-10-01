"""Build isolated Hack native-font test assets from the validated debug template.

Engine loading, glyph metrics and appearance require live validation.
"""
from pathlib import Path
import argparse,io,json,struct,zipfile
from PIL import Image
from build_native_font_depth import hash64

ROOT=Path(__file__).resolve().parents[1]
FONT='mods/dbf_hud/fonts/hack_regular_test'
MATERIAL='mods/dbf_hud/materials/hack_regular_test'

def build():
    folder=ROOT/'assets/native-hack'
    metrics=json.loads((folder/'draft-metrics.json').read_text())
    glyphs=metrics['glyphs'];template=bytearray((folder/'font-template.bin').read_bytes())
    count=struct.unpack_from('<I',template,68)[0]
    assert count==len(glyphs)==193 and len(template)==88+count*32
    ids=struct.unpack_from(f'<{count}I',template,88)
    assert tuple(g['codepoint'] for g in glyphs)==ids
    struct.pack_into('<5f',template,8,48,48,48,1/1024,1/1024)
    for i,g in enumerate(glyphs):
        x,y,w,h=g['ink'];bx,by=g['bearing']
        row=struct.pack('<7f',x,y,max(1,w),max(1,h),bx,by,g['advance'])
        template[88+count*4+i*28:88+count*4+(i+1)*28]=row
        if g['codepoint']==63:template[40:68]=row
        assert 0<=x and 0<=y and x+w<=1024 and y+h<=1024
    mask=Image.open(folder/'HackNerdFont-Regular-atlas.png').convert('L')
    atlas=Image.new('RGBA',mask.size,(255,255,255,255));atlas.putalpha(mask)
    gpu=bytearray()
    while True:
        gpu+=atlas.tobytes()
        if atlas.width==1:break
        atlas=atlas.resize((atlas.width//2,atlas.height//2),Image.Resampling.LANCZOS)
    texture=bytearray((folder/'texture-template.bin').read_bytes())
    assert texture[192:196]==b'DDS ' and struct.unpack_from('<I',texture,320)[0]==28
    struct.pack_into('<II',texture,204,1024,1024)
    struct.pack_into('<I',texture,212,4096)
    struct.pack_into('<I',texture,220,11)
    source_zip=ROOT.parent/'DBF-HUD-Native-Font-Depth-Test-0.2.zip'
    resources=[]
    with zipfile.ZipFile(source_zip) as z:
        stem='DepthState/ee6b1ba7e22d71ed.patch_0';body=z.read(stem);external=z.read(stem+'.gpu_resources')
        _,nt,n=struct.unpack_from('<III',body)
        for row in struct.iter_unpack('<7Q6I',body[72+nt*32:72+nt*32+n*80]):
            resources.append((row[0],row[1],body[row[2]:row[2]+row[7]],external[row[4]:row[4]+row[9]]))
    base=next(r[2] for r in resources if r[1]==hash64('material'))
    material=bytearray(base)
    struct.pack_into('<Q',material,136,hash64(FONT))
    resources += [(hash64(FONT),hash64('font'),bytes(template),b''),
                  (hash64(FONT),hash64('texture'),bytes(texture),bytes(gpu)),
                  (hash64(MATERIAL),hash64('material'),bytes(material),b'')]
    resources.sort(key=lambda r:(r[1],r[0]));types=sorted({r[1] for r in resources})
    body=bytearray((72+len(types)*32+len(resources)*80+15)&~15);external=bytearray();entries=bytearray()
    cpu=gp=0
    for i,(name,kind,data,graphics) in enumerate(resources):
        align=256 if kind==hash64('shader_library') else 16
        body+=b'\0'*(-len(body)%align);offset=len(body);ext_at=len(external)
        entries+=struct.pack('<7Q6I',name,kind,offset,0,ext_at,cpu,gp if graphics else 0,len(data),0,len(graphics),align,256 if graphics else 16,i)
        body+=data;cpu+=(len(data)+255)&~255
        external+=graphics;external+=b'\0'*(-len(external)%256)
        if graphics:gp+=(len(graphics)+255)&~255
    header=struct.pack('<III20sQQ24s',0xf0000011,len(types),len(resources),b'',cpu,gp,b'')
    table=b''.join(struct.pack('<IIQIIII',0,0,t,sum(r[1]==t for r in resources),0,256 if t==hash64('shader_library') else 16,256 if t==hash64('shader_library') else 64 if t==hash64('shader_library_group') else 16) for t in types)
    body[:len(header+table+entries)]=header+table+entries
    for row in struct.iter_unpack('<7Q6I',entries):
        assert row[2]%row[10]==0 and row[4]%row[11]==0
        assert row[2]+row[7]<=len(body) and row[4]+row[9]<=len(external)
        assert row[5]+row[7]<=cpu and row[6]+row[9]<=gp
    output=ROOT.parent/'DBF-HUD-Native-Hack-Test-0.1.zip'
    manifest={'Version':1,'Guid':'caf20b85-619d-4bc2-8895-353d8e6c2014','Name':'DBF-HUD Native Hack Font Test 0.1','Description':'Isolated Hack Regular font and validated depth shader. Metrics and texture require live validation.','Options':[{'Name':'Native Hack test','Include':['HackTest']}]}
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('manifest.json',json.dumps(manifest,indent=2))
        stem='HackTest/ee6b1ba7e22d71ed.patch_0'
        z.writestr(stem,body);z.writestr(stem+'.stream',b'');z.writestr(stem+'.gpu_resources',external)
        z.writestr('README.txt','Disable previous native-font depth/loader test packages. Enable this package alone, deploy in Arsenal and restart.\nThe main HUD is unchanged. Use the separate MDL font probe to validate registration, appearance and occlusion.\nFirst test covers the 193 template characters; full Nerd icon coverage is not included.\n')
        z.write(ROOT/'assets/fonts/Hack/licenses/LICENSE.md','licenses/Hack-LICENSE.md')
    print(output)
    return output

if __name__=='__main__':build()
