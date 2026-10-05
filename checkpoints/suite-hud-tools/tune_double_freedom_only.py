from pathlib import Path
import ctypes,os,shutil,datetime,subprocess,sys
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD');os.chdir(r)
p=Path(r'C:\Users\david\AppData\Local\DBF\DBF-HUD-tuning.lua');before=p.read_bytes();backup=r/'evidence'/('tuning-before-weapon-appearance-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.lua');backup.write_bytes(before)
d=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll');d.luaL_newstate.restype=ctypes.c_void_p;s=d.luaL_newstate();d.luaL_openlibs.argtypes=[ctypes.c_void_p];d.luaL_openlibs(s);d.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p];d.lua_pcall.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int];d.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];d.lua_tolstring.restype=ctypes.c_char_p
code=(r/'tests/contracts.lua').read_text().split('local tests=0')[0]+r'''
local config=HUD.config.new();HUD.config.apply(config,assert(loadfile('C:/Users/david/AppData/Local/DBF/DBF-HUD-tuning.lua'))())
local fallback=HUD.config.effective(config,'a8cffb316f0b5c5f')
HUD.config.set_panel(config,'72170a55a1f37ff1',{background_color='#131517',text_color='#BFC2C6',decoration_color='#777B80',panel_opacity=.9,text_opacity=1,decoration='none',frosted=false,effect_flicker=false,effect_sweep=false,effect_scanlines=true,effect_scanline_count=21,style_3d='standard'})
local other=HUD.config.effective(config,'a8cffb316f0b5c5f')
for k in pairs(HUD.config.panel_keys)do assert(fallback[k]==other[k],'Other weapon changed: '..k)end
local f=assert(io.open('C:/Users/david/AppData/Local/DBF/DBF-HUD-tuning.lua.weapon-pending','w'));assert(f:write(HUD.config.serialize(config)));assert(f:close())
'''
status=d.luaL_loadstring(s,code.encode()) or d.lua_pcall(s,0,0,0)
if status:raise RuntimeError(d.lua_tolstring(s,-1,None).decode())
assert p.read_bytes()==before,'Saved settings changed concurrently; refusing replacement'
os.replace(str(p)+'.weapon-pending',p)
print('Double Freedom overrides saved; global appearance preserved. Backup:',backup)
mdl=r/'src/mdl.lua';mdl.write_text(mdl.read_text().replace('20261003-WEAPON-PANELS per-weapon appearance; world scanline density restored','20261003-WEAPON-PANELS-TUNED isolated DF appearance; dense scanline layers'),encoding='utf-8')
for name in ['tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
