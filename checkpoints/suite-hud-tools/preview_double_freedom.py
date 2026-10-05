from pathlib import Path
import ctypes,os
from PIL import Image,ImageDraw,ImageFont
root=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD');os.chdir(root)
output=Path(r'C:\Users\david\Proton Drive\davidmdrury\My files\Helldivers Projects\DBF-Suite\double-freedom-preview.png')
d=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')
d.luaL_newstate.restype=ctypes.c_void_p;s=d.luaL_newstate()
for name in ['luaL_openlibs','lua_close']:getattr(d,name).argtypes=[ctypes.c_void_p]
d.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p];d.lua_pcall.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int]
d.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];d.lua_tolstring.restype=ctypes.c_char_p
d.luaL_openlibs(s)
init=(root/'tests/contracts.lua').read_text().split('local tests=0')[0]
lua=init+r'''local f=assert(io.open('preview/double-freedom-commands.tsv','w'))
for n=2,0,-1 do
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=n,capacity=2,reserve=30-n,reserve_kind='SHELLS',fire_mode='SEMI'}))
 for _,v in ipairs(HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)) do
  f:write(table.concat({n,v.type,v.x,v.y,v.w or 0,v.h or 0,v.size or 0,v.text or '',v.c[1],v.c[2],v.c[3],v.a},'\t'),'\n')
 end
end
f:close()
'''
status=d.luaL_loadstring(s,lua.encode()) or d.lua_pcall(s,0,0,0)
if status:raise RuntimeError(d.lua_tolstring(s,-1,None).decode())
d.lua_close(s)
im=Image.new('RGB',(1050,430),(10,15,20));draw=ImageDraw.Draw(im)
fontpath=r'C:\Windows\Fonts\consola.ttf'
draw.text((30,18),'DOUBLE FREEDOM / PRECISION PANEL',font=ImageFont.truetype(fontpath,23),fill=(209,165,82))
draw.text((30,52),'Offline geometry preview - text font approximated',font=ImageFont.truetype(fontpath,16),fill=(185,203,213))
for row in (root/'preview/double-freedom-commands.tsv').read_text().splitlines():
 n,kind,x,y,w,h,size,text,r,g,b,a=row.split('\t');n=int(n);x,y,w,h,size=map(float,(x,y,w,h,size));a=float(a)
 ox=80+(2-n)*325;oy=335;k=2
 color=tuple(int(float(c)*a+base*(1-a)) for c,base in zip((r,g,b),(10,15,20)))
 if kind=='text':draw.text((ox+x*k,oy-y*k),text,font=ImageFont.truetype(fontpath,max(1,round(size*k))),fill=color,anchor='ls')
 else:draw.rectangle((ox+x*k,oy-(y+h)*k,ox+(x+w)*k,oy-y*k),fill=color)
for i,label in enumerate(['TWO LOADED','ONE LOADED','EMPTY']):draw.text((80+i*325,370),label,font=ImageFont.truetype(fontpath,17),fill=(185,203,213))
im.save(output);print(output)
