"""Run offline contract tests with a local LuaJIT DLL; never starts the game."""
import argparse, ctypes, os, gzip, tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--lua-dll',type=Path,default=Path(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll'))
args=p.parse_args();os.chdir(ROOT)
dll=ctypes.CDLL(str(args.lua_dll));dll.luaL_newstate.restype=ctypes.c_void_p
state=dll.luaL_newstate()
dll.luaL_openlibs.argtypes=[ctypes.c_void_p];dll.luaL_openlibs(state)
dll.luaL_loadfile.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
dll.lua_pcall.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int]
dll.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];dll.lua_tolstring.restype=ctypes.c_char_p
# Keep the accepted-render fixture compressed in source; exact comparisons use a temporary copy.
with tempfile.NamedTemporaryFile(suffix='.snapshot',delete=False) as fixture:
    fixture.write(gzip.decompress((ROOT/'tests/approved-panels.snapshot.gz').read_bytes()))
    fixture_path=Path(fixture.name)
dll.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
setup=('DBF_APPROVED_SNAPSHOT=[['+fixture_path.as_posix()+']]').encode()
try:
    status=dll.luaL_loadstring(state,setup) or dll.lua_pcall(state,0,0,0)
    if not status: status=dll.luaL_loadfile(state,b'tests/contracts.lua') or dll.lua_pcall(state,0,0,0)
finally:
    fixture_path.unlink(missing_ok=True)
if status: print(dll.lua_tolstring(state,-1,None).decode(errors='replace'))
dll.lua_close.argtypes=[ctypes.c_void_p];dll.lua_close(state)
raise SystemExit(status)
