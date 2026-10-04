"""Build isolated Liberator artwork assets from existing native GUI templates.

No deployment. Native loading/blending still requires game validation.
"""
from pathlib import Path
import argparse, hashlib, json, struct, subprocess, zipfile
from PIL import Image
from build_native_font_depth import hash64
from build_scene_hud import padded
from build_scene_depth_probe import archive_rows

ROOT=Path(__file__).resolve().parents[1]

def windows(data):
    found=[];at=0
    while True:
        at=data.find(b'DXBC',at)
        if at<0:return found
        size=struct.unpack_from('<I',data,at+24)[0]
        found.append((at,size));at+=size

def library(code,name):
    original=(ROOT/'assets/scene-depth-probe/source-diffuse-blur.gpu').read_bytes()
    result=bytearray(original);slots=windows(original)
    assert len(slots)==2
    start,size=slots[1];result[start:start+size]=padded(code,size)
    # Use the known untextured GUI vertex program; pixel UVs are reconstructed.
    blur=(ROOT/'assets/scene-depth-probe/source-blur.gpu').read_bytes()
    source,size_source=windows(blur)[0];target,size_target=slots[0]
    result[target:target+size_target]=padded(blur[source:source+size_source],size_target)
    replacements={
        struct.unpack_from('<I',original,0x88)[0]:hash64(name+':default:PLATFORM_WIN32:RENDERER_D3D11')>>32,
        struct.unpack_from('<I',original,0xe0)[0]:hash64(name)>>32,
        struct.unpack_from('<I',original,0xbec)[0]:hash64(name+':pixel')>>32,
        hash64('hdr0_div4_fullres')>>32:hash64('linear_depth')>>32,
        hash64('diffuse_map')>>32:hash64('artwork_texture')>>32,
    }
    counts={key:0 for key in replacements}
    for at in range(0,len(original)-3,4):
        if any(a<=at<a+n for a,n in slots):continue
        value=struct.unpack_from('<I',original,at)[0]
        if value in replacements:
            struct.pack_into('<I',result,at,replacements[value]);counts[value]+=1
    assert counts[hash64('diffuse_map')>>32]==4
    assert counts[hash64('hdr0_div4_fullres')>>32]==4
    assert counts[struct.unpack_from('<I',original,0x88)[0]]==2
    assert windows(result)==slots
    return bytes(result),{hex(k):v for k,v in counts.items()}

def texture(image):
    image=image.convert('RGBA');w,h=image.size
    template=bytearray((ROOT/'assets/native-hack/texture-template.bin').read_bytes())
    # One mip deliberately: preserve source pixels for the initial filtering test.
    struct.pack_into('<II',template,204,w,h)
    struct.pack_into('<I',template,212,w*4)
    struct.pack_into('<I',template,220,1)
    return bytes(template),image.tobytes()

def build(art,output,base):
    output.mkdir(parents=True,exist_ok=True)
    compiler=Path(r'C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\fxc.exe')
    shader_output=output/'texture_art.cso'
    subprocess.run([str(compiler),'/T','ps_5_0','/E','hud_fill','/O3','/Fo',str(shader_output),str(ROOT/'assets/panel-shaders/texture_art.hlsl')],check=True)
    shader='mods/dbf_hud/shaders/texture_liberator_v1'
    gpu,metadata=library(shader_output.read_bytes(),shader)
    resources=[(hash64(shader),hash64('shader_library'),struct.pack('<I',4),gpu)]
    # Extend the installed library group, not an older template that omits animations.
    installed=base.read_bytes();_,types,entries=struct.unpack_from('<III',installed)
    rows=list(struct.iter_unpack('<7Q6I',installed[72+types*32:72+types*32+entries*80]))
    assert entries>=732,'Base must include the accepted fonts and animated shaders, not the isolated trial'
    installed_graphics=Path(str(base)+'.gpu_resources').read_bytes()
    # Arsenal replaces conflicting archive files wholesale. Preserve ALL base rows.
    resources.extend((r[0],r[1],installed[r[2]:r[2]+r[7]],installed_graphics[r[4]:r[4]+r[9]]) for r in rows if r[1]!=hash64('shader_library_group'))
    group_row=next(r for r in rows if r[0]==hash64('core/stingray_renderer/shader_libraries/default_shaders') and r[1]==hash64('shader_library_group'))
    group=bytearray(installed[group_row[2]:group_row[2]+group_row[7]])
    count=struct.unpack_from('<I',group,16)[0]
    assert len(group)==24+count*8
    struct.pack_into('<I',group,16,count+1);group+=struct.pack('<Q',hash64(shader))
    resources.append((hash64('core/stingray_renderer/shader_libraries/default_shaders'),hash64('shader_library_group'),bytes(group),b''))
    material_base=(ROOT/'assets/native-font-depth/source.bin').read_bytes()
    assert len(material_base)==160 and struct.unpack_from('<I',material_base,136)[0]==hash64('diffuse_map')>>32
    report={'metadata_replacements':metadata,'native_live_verified':False,'mip_count':1,'base_archive_sha256':hashlib.sha256(installed).hexdigest(),'preserved_base_resources':entries,'preserved_shader_group_entries':count,'assets':[]}
    for variant in ('faithful','realistic'):
        for layer in ('underlay','recesses','details'):
            if variant=='faithful':
                source=art/(layer+'.png');image=Image.open(source).convert('RGBA')
            else:
                source=art/'hyperreal-material-source.png'
                # Retain the approved complete image; do not crop to faithful masks.
                image=Image.open(source).convert('RGBA').resize((496,440),Image.Resampling.LANCZOS) if layer=='details' else Image.new('RGBA',(496,440))
            assert image.size==(496,440)
            resource='mods/dbf_hud/textures/liberator_'+variant+'_'+layer
            name='mods/dbf_hud/materials/texture_liberator_'+variant+'_'+layer
            data,pixels=texture(image)
            material=bytearray(material_base)
            struct.pack_into('<I',material,128,hash64(shader)>>32)
            struct.pack_into('<I',material,136,hash64('artwork_texture')>>32)
            struct.pack_into('<Q',material,140,hash64(resource))
            resources.extend([(hash64(resource),hash64('texture'),data,pixels),(hash64(name),hash64('material'),bytes(material),b'')])
            report['assets'].append({'variant':variant,'layer':layer,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'pixel_sha256':hashlib.sha256(pixels).hexdigest(),'bytes':len(pixels),'material':name,'texture':resource})
    body,graphics=archive_rows(resources)
    # Arsenal must deploy this as another patch of the existing native HUD archive.
    # An invented archive identity was not discovered by the live game.
    stem='TextureLiberator/'+base.name
    target=output/'DBF-HUD-Liberator-Texture-Trial.zip'
    manifest={'Version':1,'Guid':'bcc9d6ae-47c5-4d78-8c35-c77c10bf9d51','Name':'DBF-HUD Liberator texture trial','Description':'Bounded experimental faithful/realistic artwork assets; existing HUD assets still required.','Options':[{'Name':'Liberator artwork','Include':['TextureLiberator']}]}
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('manifest.json',json.dumps(manifest,indent=2))
        z.writestr(stem,body);z.writestr(stem+'.gpu_resources',graphics);z.writestr(stem+'.stream',b'')
        z.writestr('build-report.json',json.dumps(report,indent=2))
    with zipfile.ZipFile(target) as z:
        assert z.testzip() is None and z.read(stem)==body and z.read(stem+'.gpu_resources')==graphics
    (output/'build-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(target)
    print('PASS 6 RGBA textures, 6 unique materials, shader and archive bounds; live loading unverified')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--art',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);parser.add_argument('--base',type=Path,required=True)
    args=parser.parse_args();build(args.art,args.output,args.base)
