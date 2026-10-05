"""Compile isolated depth probe bytecode; does not build or deploy game resources."""
from pathlib import Path
import ctypes

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/scene-depth-probe'
library = ctypes.WinDLL('d3dcompiler_47.dll')
compile_shader = library.D3DCompile
compile_shader.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p,
    ctypes.c_void_p, ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p,
    ctypes.c_uint, ctypes.c_uint, ctypes.POINTER(ctypes.c_void_p), ctypes.POINTER(ctypes.c_void_p)]
compile_shader.restype = ctypes.c_long
disassemble = library.D3DDisassemble
disassemble.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint,
    ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
disassemble.restype = ctypes.c_long

def blob_bytes(pointer):
    table = ctypes.cast(pointer, ctypes.POINTER(ctypes.POINTER(ctypes.c_void_p))).contents
    get_pointer = ctypes.WINFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p)(table[3])
    get_size = ctypes.WINFUNCTYPE(ctypes.c_size_t, ctypes.c_void_p)(table[4])
    data = ctypes.string_at(get_pointer(pointer), get_size(pointer))
    ctypes.WINFUNCTYPE(ctypes.c_ulong, ctypes.c_void_p)(table[2])(pointer)
    return data

for entry, filename in [('depth_access','screen_depth_probe.hlsl'),('depth_compare','screen_depth_probe.hlsl'),
                        ('hud_fill','hud_scene_fill.hlsl'),('hud_font','hud_scene_depth.hlsl')]:
    source = (FOLDER / filename).read_bytes()
    buffer = ctypes.create_string_buffer(source)
    output, error = ctypes.c_void_p(), ctypes.c_void_p()
    result = compile_shader(buffer, len(source), b'screen_depth_probe.hlsl', None, None,
        entry.encode(), b'ps_5_0', 1 << 15, 0, ctypes.byref(output), ctypes.byref(error))
    diagnostic = blob_bytes(error).decode(errors='replace') if error else ''
    if result < 0:
        raise RuntimeError(diagnostic)
    data = blob_bytes(output)
    assert data[:4] == b'DXBC'
    bytecode = ctypes.create_string_buffer(data)
    listing = ctypes.c_void_p()
    assert disassemble(bytecode, len(data), 0, None, ctypes.byref(listing)) >= 0
    text = blob_bytes(listing).decode(errors='replace')
    assert '__tex_linear_depth' in text and '__samp_linear_depth' in text
    assert 'sample_l' in text
    if entry != 'depth_access':
        assert 'discard' in text
    (FOLDER / (entry + '.dxbc')).write_bytes(data)
    (FOLDER / (entry + '.txt')).write_text(text)
    print(entry + ': compiled and reflected; live texture binding unverified')
