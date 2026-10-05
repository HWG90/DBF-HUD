from pathlib import Path
import ctypes,os
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD');os.chdir(r)
d=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll');d.luaL_newstate.restype=ctypes.c_void_p;s=d.luaL_newstate()
d.luaL_openlibs.argtypes=[ctypes.c_void_p];d.luaL_openlibs(s)
d.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p];d.lua_pcall.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int];d.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];d.lua_tolstring.restype=ctypes.c_char_p
lua=(r/'tests/contracts.lua').read_text().split('local tests=0')[0]+r'''
local cfg=HUD.config.new();HUD.config.apply(cfg,assert(loadfile('C:/Users/david/AppData/Local/DBF/DBF-HUD-tuning.lua'))())
for _,id in ipairs({'72170a55a1f37ff1','89c5493e08ca4207','a8cffb316f0b5c5f'}) do
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='rounds',rounds=2,capacity=2,reserve=30,reserve_kind='SHELLS',fire_mode='SEMI'}))
 local commands=HUD.layout.compose(m,0,0,1,1,cfg,0)
 local world=HUD.world_style.prepare(commands,{first_person=true},{scale=1,font=cfg.font,style_3d='standard',text_color=cfg.text_color})
 local panel=world[1];local child;for _,v in ipairs(world)do if v.child and v.type=='panel' then child=v end end
 local minx,maxx,miny,maxy=math.huge,-math.huge,math.huge,-math.huge;local n=0
 for _,v in ipairs(world)do if v.type=='rect' and v.a==.12 then minx=math.min(minx,v.x);maxx=math.max(maxx,v.x+v.w);miny=math.min(miny,v.y);maxy=math.max(maxy,v.y+v.h);n=n+1 end end
 print(id,'parent',panel.x,panel.y,panel.w,panel.h,'child',child and child.x,child and child.y,child and child.w,child and child.h,'scan',n,minx,maxx,miny,maxy)
end
'''
status=d.luaL_loadstring(s,lua.encode()) or d.lua_pcall(s,0,0,0)
if status:raise RuntimeError(d.lua_tolstring(s,-1,None).decode())
