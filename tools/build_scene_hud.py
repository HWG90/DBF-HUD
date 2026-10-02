"""Package screen-projected HUD shaders and existing native font atlases.

Preserves serialized bindings and bytecode windows; no deployed assets changed.
"""
from pathlib import Path
import ctypes,json,struct,zipfile,hashlib
from build_native_font_depth import hash64
from build_scene_depth_probe import archive_rows

ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'assets/scene-depth-probe'

def padded(code,size):
    dll=ctypes.WinDLL('d3dcompiler_47.dll');fn=dll.D3DSetBlobPart
    fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_uint,ctypes.c_uint,ctypes.c_void_p,ctypes.c_size_t,ctypes.POINTER(ctypes.c_void_p)]
    fn.restype=ctypes.c_long
    def make(n):
        source=ctypes.create_string_buffer(code);private=ctypes.create_string_buffer(n);out=ctypes.c_void_p()
        assert fn(source,len(code),10,0,private,n,ctypes.byref(out))>=0
        t=ctypes.cast(out,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
        ptr=ctypes.WINFUNCTYPE(ctypes.c_void_p,ctypes.c_void_p)(t[3])(out)
        length=ctypes.WINFUNCTYPE(ctypes.c_size_t,ctypes.c_void_p)(t[4])(out)
        result=ctypes.string_at(ptr,length);ctypes.WINFUNCTYPE(ctypes.c_ulong,ctypes.c_void_p)(t[2])(out)
        return result
    first=make(4);result=make(size-len(first)+4)
    assert len(result)==size and struct.unpack_from('<I',result,24)[0]==size
    fn=dll.D3DDisassemble;fn.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_uint,ctypes.c_char_p,ctypes.POINTER(ctypes.c_void_p)];fn.restype=ctypes.c_long
    buf=ctypes.create_string_buffer(result);out=ctypes.c_void_p();assert fn(buf,size,0,None,ctypes.byref(out))>=0
    t=ctypes.cast(out,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    ctypes.WINFUNCTYPE(ctypes.c_ulong,ctypes.c_void_p)(t[2])(out)
    return result

def library(source,old_name,name,entry):
    original=source.read_bytes();gpu=bytearray(original)
    windows=[];at=0
    while True:
        at=original.find(b'DXBC',at)
        if at<0:break
        size=struct.unpack_from('<I',original,at+24)[0];windows.append((at,size));at+=size
    assert len(windows)==2
    start,size=windows[1];gpu[start:start+size]=padded((FOLDER/(entry+'.dxbc')).read_bytes(),size)
    # Patch only metadata, never matching values in compiled shader instructions.
    program=struct.unpack_from('<I',original,0x88)[0]
    variant=struct.unpack_from('<I',original,0xe0)[0];pixel=struct.unpack_from('<I',original,0xbe4 if entry=='hud_fill' else 0xbec)[0]
    changes={program:hash64(name+':default:PLATFORM_WIN32:RENDERER_D3D11')>>32,
             variant:hash64(name)>>32,pixel:hash64(name+':pixel')>>32,
             hash64('hdr0_div4_fullres')>>32:hash64('linear_depth')>>32}
    counts={key:0 for key in changes}
    for offset in range(0,len(gpu)-3,4):
        if any(a<=offset<a+n for a,n in windows):continue
        old=struct.unpack_from('<I',original,offset)[0]
        if old in changes:struct.pack_into('<I',gpu,offset,changes[old]);counts[old]+=1
    assert counts[program]==2 and counts[variant]==1 and counts[pixel]==2 and counts[hash64('hdr0_div4_fullres')>>32]==4,counts
    assert bytes(gpu[windows[0][0]:sum(windows[0])])==original[windows[0][0]:sum(windows[0])]
    return bytes(gpu),{'source_sha256':hashlib.sha256(original).hexdigest(),'metadata_changes':counts,'shader':name}

def rows_from_zip(path):
    with zipfile.ZipFile(path) as z:
        stem=next(n for n in z.namelist() if n.endswith('.patch_0'))
        body=z.read(stem);gpu=z.read(stem+'.gpu_resources');_,nt,n=struct.unpack_from('<III',body)
        return [(r[0],r[1],body[r[2]:r[2]+r[7]],gpu[r[4]:r[4]+r[9]]) for r in struct.iter_unpack('<7Q6I',body[72+nt*32:72+nt*32+n*80])]

def build():
    fill='mods/dbf_hud/shaders/screen_hud_fill';font='mods/dbf_hud/shaders/screen_hud_font'
    resources=rows_from_zip(ROOT.parent/'DBF-HUD-Scene-Depth-Occlusion-Probe-0.2.zip')
    group_hash=hash64('shader_library_group');group=bytearray(next(r[2] for r in resources if r[1]==group_hash))
    resources=[r for r in resources if r[1]!=group_hash]
    fill_gpu,fill_report=library(FOLDER/'source-blur.gpu','gui:blur_background',fill,'hud_fill')
    font_gpu,font_report=library(FOLDER/'source-diffuse-blur.gpu','gui:diffuse_map:blur_background',font,'hud_font')
    resources += [(hash64(fill),hash64('shader_library'),struct.pack('<I',4),fill_gpu),
                  (hash64(font),hash64('shader_library'),struct.pack('<I',4),font_gpu)]
    material=bytearray((ROOT/'assets/depth-state-test/source.bin').read_bytes());struct.pack_into('<I',material,128,hash64(fill)>>32)
    resources.append((hash64('mods/dbf_hud/materials/screen_hud_fill'),hash64('material'),bytes(material),b''))
    native=rows_from_zip(ROOT.parent/'DBF-HUD-Native-Fonts-0.1.zip');by_id={(r[0],r[1]):r for r in native}
    # Native glyph records provide exact atlas UVs; draw glyphs as two triangles.
    import re
    text=(ROOT/'src/native_font_data.lua').read_text()
    faces=re.findall(r'M.faces\["([^"]+)"\]=\{label=.*?font="([^"]+)"',text)
    lua=['-- Generated from existing native font atlases; no new font rasterization.','local M={}']
    for key,resource in faces:
        data=by_id[(hash64(resource),hash64('font'))][2]
        texture=by_id[(hash64(resource),hash64('texture'))][2];w,h=struct.unpack_from('<II',texture,204)
        ids=struct.unpack_from('<193I',data,88);glyphs=[]
        for i,code in enumerate(ids):
            if code<32 or code>126:continue
            x,y,gw,gh,ox,oy,advance=struct.unpack_from('<7f',data,860+i*28)
            glyphs.append('[%d]={%.9g,%.9g,%.9g,%.9g},'%(code,x/w,y/h,(x+gw)/w,(y+gh)/h))
        lua.append('M[%s]={%s}'%(json.dumps(key),''.join(glyphs)))
        clear=resource.replace('/fonts/','/materials/')+'_clear'
        base=bytearray(by_id[(hash64(clear),hash64('material'))][2]);struct.pack_into('<I',base,128,hash64(font)>>32)
        resources.append((hash64(clear[:-6]+'_scene'),hash64('material'),bytes(base),b''))
    lua.append('return M');(ROOT/'src/native_font_uv.lua').write_text('\n'.join(lua)+'\n')
    count=struct.unpack_from('<I',group,16)[0];struct.pack_into('<I',group,16,count+2)
    group+=struct.pack('<2Q',hash64(fill),hash64(font));resources.append((hash64('core/stingray_renderer/shader_libraries/default_shaders'),group_hash,bytes(group),b''))
    assert len({(r[0],r[1]) for r in resources})==len(resources)
    body,gpu=archive_rows(resources)
    output=ROOT.parent/'DBF-HUD-Screen-Depth-Renderer-0.3.zip'
    manifest={'Version':1,'Guid':'b160d891-7bce-4079-82ef-57f165e54211','Name':'DBF-HUD Screen Depth Renderer 0.3',
              'Description':'Screen-projected weapon HUD with scene-depth comparison. Native atlas colors and alpha retained. Live HUD validation pending.',
              'Options':[{'Name':'Screen depth renderer','Include':['SceneHUD']}]}
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('manifest.json',json.dumps(manifest,indent=2));stem='SceneHUD/ee6b1ba7e22d71ed.patch_0'
        z.writestr(stem,body);z.writestr(stem+'.gpu_resources',gpu);z.writestr(stem+'.stream',b'')
        z.writestr('README.txt','Replace the occlusion probe. Keep this LAST after existing depth and native-font packages. Deploy and restart.\nThe real HUD switches only when its new materials are available. Layout files are never replaced.\n')
    with zipfile.ZipFile(output) as z:assert z.read(stem)==body and z.read(stem+'.gpu_resources')==gpu
    (FOLDER/'hud-package-build.json').write_text(json.dumps({'fill':fill_report,'font':font_report,'font_count':len(faces),'group_entries':count+2,'status':'offline validated; complete HUD live validation pending'},indent=2)+'\n')
    print(output)
if __name__=='__main__':build()
