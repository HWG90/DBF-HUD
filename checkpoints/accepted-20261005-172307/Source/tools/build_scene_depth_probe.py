"""Build an isolated, access-only scene-depth probe for manual Arsenal deployment."""
from pathlib import Path
import ctypes
import hashlib
import json
import struct
import zipfile
from build_depth_state_test import hash64

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/scene-depth-probe'
SHADER = 'mods/dbf_hud/shaders/screen_scene_depth_access'
MATERIAL = 'mods/dbf_hud/materials/screen_scene_depth_access'

def archive_rows(resources):
    resources = sorted(resources, key=lambda r: (r[1], r[0]))
    types = sorted({r[1] for r in resources})
    body = bytearray((72 + 32 * len(types) + 80 * len(resources) + 15) & ~15)
    table, external = bytearray(), bytearray()
    cpu_buffer = gpu_buffer = 0
    for index, (name, kind, main, gpu) in enumerate(resources):
        alignment = 256 if kind == hash64('shader_library') else 16
        body += b'\0' * (-len(body) % alignment)
        table += struct.pack('<7Q6I', name, kind, len(body), 0, len(external), cpu_buffer,
            gpu_buffer if gpu else 0, len(main), 0, len(gpu), alignment, 256 if gpu else 16, index)
        cpu_buffer += (len(main) + 255) & ~255
        if gpu:
            gpu_buffer += (len(gpu) + 255) & ~255
        body += main
        body += b'\0' * (-len(body) % 16)
        external += gpu
        external += b'\0' * (-len(external) % 256)
    header = struct.pack('<III20sQQ24s', 0xf0000011, len(types), len(resources), b'', cpu_buffer, gpu_buffer, b'')
    kinds = b''.join(struct.pack('<IIQIIII', 0, 0, kind,
        sum(r[1] == kind for r in resources), 0,
        256 if kind == hash64('shader_library') else 16,
        256 if kind == hash64('shader_library') else 64 if kind == hash64('shader_library_group') else 16)
        for kind in types)
    body[:len(header + kinds + table)] = header + kinds + table
    for row, expected in zip(struct.iter_unpack('<7Q6I', table), resources):
        assert bytes(body[row[2]:row[2]+row[7]]) == expected[2]
        assert bytes(external[row[4]:row[4]+row[9]]) == expected[3]
        assert row[2] % row[10] == 0 and row[4] % row[11] == 0
        assert row[5]+row[7] <= cpu_buffer and row[6]+row[9] <= gpu_buffer
    return bytes(body), bytes(external)

def build(compare=False):
    global SHADER, MATERIAL
    if compare:
        SHADER = 'mods/dbf_hud/shaders/screen_scene_depth_compare'
        MATERIAL = 'mods/dbf_hud/materials/screen_scene_depth_compare'
    original = (FOLDER / 'source-blur.gpu').read_bytes()
    assert len(original) == 15792 and original.count(b'DXBC') == 2
    gpu = bytearray(original)
    changes = [(0x88, 0xbfc28883, hash64(SHADER + ':default:PLATFORM_WIN32:RENDERER_D3D11') >> 32),
        (0xa50, 0xbfc28883, hash64(SHADER + ':default:PLATFORM_WIN32:RENDERER_D3D11') >> 32),
        (0xe0, 0x47f7f610, hash64(SHADER) >> 32),
        (0xbe4, 0x5ee82747, hash64(SHADER + ':pixel') >> 32),
        (0x3d54, 0x5ee82747, hash64(SHADER + ':pixel') >> 32)]
    old_texture, new_texture = hash64('hdr0_div4_fullres') >> 32, hash64('linear_depth') >> 32
    for offset in (0x5ec, 0xf18, 0x3d88, 0x3d98):
        changes.append((offset, old_texture, new_texture))
    for offset, old, new in changes:
        assert struct.unpack_from('<I', original, offset)[0] == old, hex(offset)
        struct.pack_into('<I', gpu, offset, new)
    # Preserve serialized offsets with compiler-owned private-data padding.
    # Raw trailing zero padding was rejected by D3D and is never packaged.
    start = 0x2378
    size = struct.unpack_from('<I', original, start + 24)[0]
    assert size == 6620 and struct.unpack_from('<I', original, 0xbe0)[0] == size
    code = (FOLDER / ('depth_compare.dxbc' if compare else 'depth_access.dxbc')).read_bytes()
    assert code[:4] == b'DXBC' and struct.unpack_from('<I', code, 24)[0] == len(code) < size
    compiler = ctypes.WinDLL('d3dcompiler_47.dll')
    set_part = compiler.D3DSetBlobPart
    set_part.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint, ctypes.c_uint,
        ctypes.c_void_p, ctypes.c_size_t, ctypes.POINTER(ctypes.c_void_p)]
    set_part.restype = ctypes.c_long
    def padded_shader(amount):
        source_buffer = ctypes.create_string_buffer(code)
        private = ctypes.create_string_buffer(amount)
        result = ctypes.c_void_p()
        assert set_part(source_buffer,len(code),10,0,private,amount,ctypes.byref(result)) >= 0
        table = ctypes.cast(result,ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
        pointer = ctypes.WINFUNCTYPE(ctypes.c_void_p,ctypes.c_void_p)(table[3])(result)
        length = ctypes.WINFUNCTYPE(ctypes.c_size_t,ctypes.c_void_p)(table[4])(result)
        data = ctypes.string_at(pointer,length)
        ctypes.WINFUNCTYPE(ctypes.c_ulong,ctypes.c_void_p)(table[2])(result)
        return data
    minimal = padded_shader(4)
    padded = padded_shader(size-len(minimal)+4)
    assert len(padded) == size and struct.unpack_from('<I',padded,24)[0] == size
    gpu[start:start+size] = padded
    allowed = set(range(start, start+size))
    for offset, _, _ in changes:
        allowed.update(range(offset, offset+4))
    assert all(i in allowed for i,(a,b) in enumerate(zip(original,gpu)) if a != b)
    # Verify padded shader bytecode using the same D3D parser used for extraction.
    parser = compiler.D3DDisassemble
    parser.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint, ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
    parser.restype = ctypes.c_long
    buffer = ctypes.create_string_buffer(bytes(gpu[start:start+size])); output = ctypes.c_void_p()
    assert parser(buffer, size, 0, None, ctypes.byref(output)) >= 0, 'padded bytecode rejected'
    vtable = ctypes.cast(output, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    ctypes.WINFUNCTYPE(ctypes.c_ulong, ctypes.c_void_p)(vtable[2])(output)
    material = bytearray((ROOT / 'assets/depth-state-test/source.bin').read_bytes())
    assert len(material) == 144 and struct.unpack_from('<I',material,128)[0] == 0x9fcfe126
    struct.pack_into('<I', material, 128, hash64(SHADER) >> 32)
    old_group = (FOLDER / 'source-current-group.bin').read_bytes()
    count = struct.unpack_from('<I', old_group, 16)[0]
    assert len(old_group) == 24 + count*8 and count == 79
    group = bytearray(old_group)
    assert struct.pack('<Q',hash64(SHADER)) not in old_group[24:]
    struct.pack_into('<I',group,16,count+1)
    group += struct.pack('<Q',hash64(SHADER))
    assert bytes(group[24:len(old_group)]) == old_group[24:]
    resources = [(hash64(SHADER),hash64('shader_library'),struct.pack('<I',4),bytes(gpu)),
        (hash64(MATERIAL),hash64('material'),bytes(material),b''),
        (hash64('core/stingray_renderer/shader_libraries/default_shaders'),hash64('shader_library_group'),bytes(group),b'')]
    body, external = archive_rows(resources)
    manifest = {'Version':1,'Guid':'b160d891-7bce-4079-82ef-57f165e54211',
        'Name':'DBF-HUD Scene Depth Occlusion Probe 0.2' if compare else 'DBF-HUD Scene Depth Access Probe 0.1',
        'Description':'Private screen-depth comparison test; main HUD and layouts unchanged.' if compare else 'Private access-only scene-depth shader test. No occlusion discard or HUD layout changes.',
        'Options':[{'Name':'Scene depth access probe','Include':['SceneDepthAccess']}]}
    destination = ROOT.parent / ('DBF-HUD-Scene-Depth-Occlusion-Probe-0.2.zip' if compare else 'DBF-HUD-Scene-Depth-Access-Probe-0.1.zip')
    with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('manifest.json',json.dumps(manifest,indent=2))
        stem = 'SceneDepthAccess/ee6b1ba7e22d71ed.patch_0'
        archive.writestr(stem,body);archive.writestr(stem+'.stream',b'');archive.writestr(stem+'.gpu_resources',external)
        archive.writestr('README.txt',('Replace the access-only probe with this update. Keep existing depth/font packages enabled.\nPlace this probe LAST, after depth and fonts, in Arsenal. Deploy and restart.\nGreen compares scene depth with sampled bone depth; magenta remains visible.\nDepth units and viewport alignment need a live test. No weapon offsets are changed.\n' if compare else 'Import into Arsenal, enable, deploy and restart. Keep existing depth/font packages enabled.\nThe Lua diagnostic displays a grayscale tile near the magenta square when the new material loads.\nThis is an access-only probe. Texture binding and depth units are not live verified.\nDisable this package, deploy and restart to remove the probe. No weapon offsets are changed.\n'))
    with zipfile.ZipFile(destination) as archive:
        assert archive.read(stem) == body and archive.read(stem+'.gpu_resources') == external
        assert json.loads(archive.read('manifest.json'))['Options'][0]['Include'] == ['SceneDepthAccess']
    (FOLDER / ('compare-package-build.json' if compare else 'access-package-build.json')).write_text(json.dumps({
        'source_sha256':hashlib.sha256(original).hexdigest(),'source_group_sha256':hashlib.sha256(old_group).hexdigest(),
        'preserved_group_entries':count,'appended_group_entries':1,'shader':SHADER,'material':MATERIAL,
        'texture':'linear_depth','compiled_shader_bytes':len(code),'serialized_shader_window':size,
        'status':'package validated offline; native library parsing and texture binding require live test'},indent=2)+'\n')
    print(destination)

if __name__ == '__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--compare',action='store_true')
    build(parser.parse_args().compare)
