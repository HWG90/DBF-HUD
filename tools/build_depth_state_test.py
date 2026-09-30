"""Build an isolated GUI library with hardware depth testing enabled.

No game files or process memory are modified. Import the resulting addon through
Arsenal. The native pass's scene-depth attachment still requires a live test.
"""
from pathlib import Path
import hashlib
import json
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SHADER = 'mods/dbf_hud/shaders/gui_depth_state_test'
MATERIAL = 'mods/dbf_hud/materials/depth_state_test'

def hash64(name):
    data = name.encode()
    mask, mix = (1 << 64) - 1, 0xc6a4a7935bd1e995
    value = len(data) * mix & mask
    end = len(data) // 8 * 8
    for (word,) in struct.iter_unpack('<Q', data[:end]):
        word = word * mix & mask
        word ^= word >> 47
        value = (value ^ (word * mix & mask)) * mix & mask
    if data[end:]:
        value = (value ^ int.from_bytes(data[end:], 'little')) * mix & mask
    value ^= value >> 47
    value = value * mix & mask
    return value ^ (value >> 47)

def build(control=False):
    if not control:
        raise ValueError('Depth-enabled test remains withdrawn; validate loader control first')
    shader = SHADER + '_loader_control'
    material_name = MATERIAL + '_loader_control'
    folder = ROOT / 'assets/depth-state-test'
    original = (folder / 'source.gpu').read_bytes()
    assert len(original) == 14576 and original.count(b'DXBC') == 2
    states = list(struct.iter_unpack('<4I', original[0xc88:0xc88 + 39 * 16]))
    assert {row[0]: row[2] for row in states}[10] == 0
    assert {row[0]: row[2] for row in states}[11] == 0
    assert {row[0]: row[2] for row in states}[12] == 7
    gpu = bytearray(original)
    variant = hash64(shader) >> 32
    program = hash64(shader + ':default:PLATFORM_WIN32:RENDERER_D3D11') >> 32
    for offset, old, new in [(0x88, 0x63ae484f, program),
                             (0xe0, 0xd78ab313, variant),
                             (0xa40, 0x63ae484f, program)]:
        assert struct.unpack_from('<I', gpu, offset)[0] == old
        struct.pack_into('<I', gpu, offset, new)
    # Disk library has an 0x88-byte prefix absent from the relocated live base.
    assert struct.unpack_from('<4I', gpu, 0xd98) == (10, 0, 0, 0)
    # Loader control deliberately preserves the native depth-disable state.
    struct.pack_into('<I', gpu, 0xda0, 0)
    allowed = {0xda0} | set(range(0x88, 0x8c)) | set(range(0xe0, 0xe4)) | set(range(0xa40, 0xa44))
    assert all(i in allowed for i, (a, b) in enumerate(zip(original, gpu)) if a != b)
    material = bytearray((folder / 'source.bin').read_bytes())
    assert len(material) == 144 and struct.unpack_from('<I', material, 128)[0] == 0x9fcfe126
    struct.pack_into('<I', material, 128, variant)
    group_name = 'core/stingray_renderer/shader_libraries/default_shaders'
    source_group = (folder / 'source-group.bin').read_bytes()
    assert len(source_group)==640 and struct.unpack_from('<I',source_group,16)[0]==77
    assert source_group[:16]==struct.pack('<I12x',142)
    group=bytearray(source_group)
    struct.pack_into('<I',group,16,78)
    group+=struct.pack('<Q',hash64(shader))
    assert bytes(group[24:640])==source_group[24:]
    resources = [(hash64(shader), hash64('shader_library'), struct.pack('<I', 4), bytes(gpu)),
                 (hash64(material_name), hash64('material'), bytes(material), b''),
                 (hash64(group_name),hash64('shader_library_group'),bytes(group),b'')]
    resources.sort(key=lambda row: (row[1], row[0]))
    types = sorted({row[1] for row in resources})
    offset = (72 + 32 * len(types) + 80 * len(resources) + 15) & ~15
    body = bytearray(offset)
    entries, gpu_body = bytearray(), bytearray()
    cpu_buffer=gpu_buffer=0
    for index, (name, kind, main, external) in enumerate(resources):
        main_alignment = 256 if kind == hash64('shader_library') else 16
        body += b'\0' * (-len(body) % main_alignment)
        offset = len(body)
        gpu_at = len(gpu_body)
        entries += struct.pack('<7Q6I', name, kind, offset, 0, gpu_at, cpu_buffer, gpu_buffer if external else 0,
                               len(main), 0, len(external), main_alignment, 256 if external else 16, index)
        cpu_buffer+=(len(main)+255)&~255
        if external:gpu_buffer+=(len(external)+255)&~255
        body += main
        body += b'\0' * (-len(body) % 16)
        offset = len(body)
        gpu_body += external
        gpu_body += b'\0' * (-len(gpu_body) % 256)
    header = struct.pack('<III20sQQ24s', 0xf0000011, len(types), len(resources), b'',
                         cpu_buffer, gpu_buffer, b'')
    table = b''.join(struct.pack('<IIQIIII', 0, 0, kind,
                                 sum(row[1] == kind for row in resources), 0,
                                 256 if kind == hash64('shader_library') else 16,
                                 256 if kind == hash64('shader_library') else
                                 64 if kind == hash64('shader_library_group') else 16) for kind in types)
    body[:len(header + table + entries)] = header + table + entries
    # Read back the exact archive rows and their external payload bounds.
    cpu_ranges=[];gpu_ranges=[]
    for row in struct.iter_unpack('<7Q6I', body[72 + 32 * len(types):72 + 32 * len(types) + 80*len(resources)]):
        assert body[row[2]:row[2] + row[7]]
        assert row[4] + row[9] <= len(gpu_body)
        assert row[2] % row[10] == 0 and row[4] % row[11] == 0
        assert row[5]+row[7]<=cpu_buffer and row[6]+row[9]<=gpu_buffer
        cpu_ranges.append((row[5],row[5]+row[7]))
        if row[9]:gpu_ranges.append((row[6],row[6]+row[9]))
    for ranges in (cpu_ranges,gpu_ranges):
        ordered=sorted(ranges)
        assert all(a[1]<=b[0] for a,b in zip(ordered,ordered[1:]))
    manifest = {'Version': 1, 'Guid': '37e62026-bb34-4ddb-9474-d48076246bfd',
                'Name': 'DBF-HUD Shader Loader Control 0.1',
                'Description': 'Loader-only control. Adds one unchanged-depth GUI library to the native default group; working HUD is unchanged.',
                'Options': [{'Name': 'Shader loader control', 'Include': ['DepthState']}]}
    output = ROOT.parent / 'DBF-HUD-Shader-Loader-Control-0.1.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('manifest.json', json.dumps(manifest, indent=2))
        stem = 'DepthState/9ba626afa44a3aa3.patch_0'
        archive.writestr(stem, body)
        archive.writestr(stem + '.stream', b'')
        archive.writestr(stem + '.gpu_resources', gpu_body)
        archive.writestr('README.txt', 'Loader control only. Import into Arsenal, enable and deploy, then restart.\nNo HUD change is expected. Depth testing remains off.\nPreserves all 77 native default-group references and appends the control library.\nThe native GUI shader resources are not replaced. Disable this control after the registration check.\nKeep the withdrawn WorldGUI Depth State Test disabled.\n')
    evidence = {'source_sha256': hashlib.sha256(original).hexdigest(),
                'shader_resource': shader, 'material_resource': material_name,
                'compiled_variant_id': hex(variant), 'program_id': hex(program),
                'depth_enable': 0, 'depth_write': 0, 'depth_compare': 7,
                'disk_depth_enable_offset': '0xda0',
                'live_status': 'not loaded or visually verified'}
    (folder / 'loader-control-build.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(output)

if __name__ == '__main__':
    import argparse
    parser=argparse.ArgumentParser()
    parser.add_argument('--loader-control',action='store_true')
    args=parser.parse_args()
    if not args.loader_control:
        raise SystemExit('Depth-enabled test remains disabled. Use --loader-control for the separate depth-disabled load check.')
    build(control=True)
