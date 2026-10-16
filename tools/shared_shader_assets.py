"""Build the HUD/War Journalist shader closure from owning source inputs only.

Both release builders use this module. No installed files or cached releases are
read. Rebuild both payloads together when the shader closure digest changes.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import struct
import sys
import zipfile
from functools import lru_cache

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from build_native_font_depth import hash64

GROUP = hash64('shader_library_group')
SHADER = hash64('shader_library')

@lru_cache(maxsize=1)
def hud_resources():
    folder = ROOT / 'assets/native-runtime'
    metadata = json.loads((folder / 'provenance.json').read_text())
    path = folder / 'hud-native.zip'
    assert hashlib.sha256(path.read_bytes()).hexdigest() == metadata['archive_sha256'], 'HUD native snapshot changed'
    with zipfile.ZipFile(path) as z:
        stem = 'ee6b1ba7e22d71ed.patch_0'
        body, gpu = z.read(stem), z.read(stem + '.gpu_resources')
    for name, data in ((stem, body), (stem + '.gpu_resources', gpu)):
        assert hashlib.sha256(data).hexdigest() == metadata['files'][name]['sha256'], 'HUD resource identity changed'
    _, nt, n = struct.unpack_from('<III', body)
    return tuple((r[0], r[1], body[r[2]:r[2]+r[7]], gpu[r[4]:r[4]+r[9]])
                 for r in struct.iter_unpack('<7Q6I', body[72+nt*32:72+nt*32+n*80]))

def photo_module():
    folder = ROOT.parent / 'DBF_PhotoMode'
    path = folder / 'tools/build_release.py'
    if not path.is_file():
        raise RuntimeError('Coexistence build requires sibling DBF_PhotoMode source; refusing a partial shader registry')
    sys.path.insert(0, str(path.parent))
    spec = importlib.util.spec_from_file_location('coexistence_photo_release', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def merge_shader_closure(hud, photo, stock):
    count = struct.unpack_from('<I', stock, 16)[0]
    assert len(stock) == 24 + count * 8
    ids = list(struct.unpack_from('<%dQ' % count, stock, 24))
    assert len(ids) == len(set(ids))
    libraries = {}
    for row in list(hud) + list(photo):
        if row[1] != SHADER:
            continue
        if row[0] in libraries and libraries[row[0]] != row:
            raise ValueError('Conflicting shader definition: %016x' % row[0])
        libraries[row[0]] = row
    ids += sorted(set(libraries) - set(ids))
    header = bytearray(stock[:24]); struct.pack_into('<I', header, 16, len(ids))
    group = (hash64('core/stingray_renderer/shader_libraries/default_shaders'), GROUP,
             bytes(header) + struct.pack('<%dQ' % len(ids), *ids), b'')
    rows = [libraries[key] for key in sorted(libraries)] + [group]
    digest = hashlib.sha256(b''.join(struct.pack('<QQ', r[0], r[1]) +
                                   hashlib.sha256(r[2]).digest() + hashlib.sha256(r[3]).digest() for r in rows)).hexdigest()
    return rows, {'shader_closure_sha256': digest, 'shader_libraries': len(libraries),
                  'registry_ids': len(ids), 'stock_ids': count,
                  'source_owned': True, 'requires_matching_companion_closure': True}

def shared_resources(photo_core=None):
    module = photo_module()
    if photo_core is None:
        photo_core, _, _ = module.owned_resources()
    stock = (module.ROOT / 'freecam/assets/shaders/original-default-shaders.bin').read_bytes()
    return merge_shader_closure(hud_resources(), photo_core, stock)

def complete_hud_resources():
    shared, audit = shared_resources()
    return [r for r in hud_resources() if r[1] not in (SHADER, GROUP)] + shared, audit
