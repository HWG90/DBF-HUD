import ctypes,os,json,re,zipfile
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1];os.chdir(root)
output=root/'preview/double-freedom-detailed-ribs-proposal.png';output.parent.mkdir(exist_ok=True)
d=ctypes.CDLL(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll');d.luaL_newstate.restype=ctypes.c_void_p;s=d.luaL_newstate()
for n in ['luaL_openlibs','lua_close']:getattr(d,n).argtypes=[ctypes.c_void_p]
d.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p];d.lua_pcall.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int];d.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_void_p];d.lua_tolstring.restype=ctypes.c_char_p;d.luaL_openlibs(s)
def run(lua):
 status=d.luaL_loadstring(s,lua.encode()) or d.lua_pcall(s,0,0,0)
 if status:raise RuntimeError(d.lua_tolstring(s,-1,None).decode())
init=(root/'tests/contracts.lua').read_text().split('local tests=0')[0]
run(init)

run("HUD.senator_state=assert(loadfile('preview/senator_cylinder_state_proposal.lua'))();HUD.senator_panel=assert(loadfile('src/senator_panel.lua'))()")
lua="cfg=HUD.config.new();cfg.senator_verify_raster=true;cfg.font='bigblue';cfg.text_color='#C6D2DA';cfg.panel_opacity=.9;cfg.decoration='helldivers';f=assert(io.open('preview/senator-cylinder-commands.tsv','w'));dftrack=HUD.df_shell_state.new();senatortrack=HUD.senator_state.new()\n"+"function export(k,raw)\n local m=HUD.model.normalize(HUD.ammo_types.apply(raw))\n HUD.df_shell_state.step(dftrack,m);HUD.senator_state.step(senatortrack,m);m.cylinder_preview_angle=animation_angle\n for _,v in ipairs(HUD.senator_panel.compose(m,0,0,1,1,cfg)) do\n if v.type=='text' then\n for _,part in ipairs(HUD.font.numeric_parts(v)) do\n local c=part.c or v.c\n f:write(table.concat({k,'text',v.x+part.dx,v.y,0,0,v.size,part.text,c[1],c[2],c[3],v.a*part.alpha},'\\t'),'\\n')\n end\n else\n f:write(table.concat({k,(v.senator_part~=nil) and 'art' or v.type,v.x,v.y,v.w or 0,v.h or 0,0,'',v.c[1],v.c[2],v.c[3],v.a},'\\t'),'\\n')\n end\n end\nend\n"
lua+="""
cfg.decoration='helldivers';cfg.decoration_color='#FFFFFF'
function q(k,n) export(k,{resource_hex='8d3d52a3b2f19402',id=1,unit_ref=9,kind='rounds',rounds=n,capacity=6,reserve=30,reserve_kind='ROUNDS',fire_mode='SEMI'}) end
q(0,6);q(1,0)
HUD.senator_panel=assert(loadfile('preview/senator_cylinder_panel_proposal.lua'))();cfg.senator_closeup_preview=true;senatortrack=HUD.senator_state.new()
q(2,6);q(3,5);q(4,4);q(5,3);q(6,2);q(7,1);q(8,0);q(9,1);q(10,6)
senatortrack=HUD.senator_state.new();q(20,6)
for shot=1,6 do
 for frame=0,6 do
  animation_angle=-(shot-1+frame/6)*math.pi/3
  q(20+shot*7+frame,6-shot)
 end
end
animation_angle=nil
f:close()
""";run(lua);d.lua_close(s)
meta=json.loads((root/'assets/fonts/BigBlueTerminal/BigBlueTerm437NerdFont-Regular.json').read_text());atlas=Image.open(root/'assets/fonts/BigBlueTerminal/BigBlueTerm437NerdFont-Regular.png').convert('RGBA')
rows={i:[] for i in range(80)}
for line in (root/'preview/senator-cylinder-commands.tsv').read_text().splitlines():
 a=line.split('\t');rows[int(a[0])].append(a[1:])
bg=(10,15,20);im=Image.new('RGB',(1420,890),bg);draw=ImageDraw.Draw(im);font=r'C:\Windows\Fonts\consola.ttf'
def label(x,y,t,size=20,color=(198,210,218)):draw.text((x,y),t,font=ImageFont.truetype(font,size),fill=color)
def panel(i,ox,oy,k=2.3):
 for kind,x,y,w,h,size,t,r,g,b,a in rows[i]:
  x,y,w,h,size,a=map(float,(x,y,w,h,size,a));c=tuple(int(float(v)) for v in (r,g,b));a=min(1,max(0,a))
  if kind=='text':
   offset=0;factor=size*k/48
   for ch in t:
    glyph=meta['glyphs'][str(ord(ch))];cx,cy,cw,chh=glyph['cell'];l,top,rr,bot=glyph['bounds']
    if bot>top:
     mask=atlas.crop((cx+meta['origin_x']+l,cy+meta['baseline']+top,cx+meta['origin_x']+rr,cy+meta['baseline']+bot)).convert('L')
     mask=mask.resize((max(1,round((rr-l)*factor)),max(1,round((bot-top)*factor))),Image.Resampling.NEAREST).point(lambda v:round(v*a))
     im.paste(c,(round(ox+x*k+offset+l*factor),round(oy-y*k+top*factor)),mask)
    offset+=glyph['advance']*factor
  else:
   box=(round(ox+x*k),round(oy-(y+h)*k),round(ox+(x+w)*k),round(oy-y*k));overlay=Image.new('RGB',(max(1,box[2]-box[0]),max(1,box[3]-box[1])),c);im.paste(Image.blend(im.crop((box[0],box[1],box[0]+overlay.width,box[1]+overlay.height)),overlay,a),(box[0],box[1]))



im=Image.new('RGB',(1600,2010),bg);draw=ImageDraw.Draw(im)
label(30,20,'SENATOR / ROTATING CYLINDER / UNINSTALLED',28,(218,172,78))
label(30,64,'Each shot turns clockwise 60 degrees; the next live round stays at the fixed bottom cue.',18)
label(30,92,'Count-driven display model. Chamber telemetry, speedloader and live performance unverified.',17)
for index,(i,title) in enumerate([(2,'LOADED / 0 DEG'),(3,'SHOT 1 / 60 DEG'),(4,'SHOT 2 / 120 DEG'),(5,'SHOT 3 / 180 DEG'),(6,'SHOT 4 / 240 DEG'),(7,'SHOT 5 / 300 DEG'),(8,'EMPTY / 360 DEG'),(9,'ONE REFILL / BOTTOM'),(10,'FULL REFILL')]):
 x=130+(index%3)*480;row=index//3;panel(i,x,650+row*620,2.4);label(x,750+row*620,title,18)
im.save(root/'preview/senator-rotating-cylinder-proposal.png');print(root/'preview/senator-rotating-cylinder-proposal.png')

frames=[];durations=[]
for i in [20]+[20+shot*7+frame for shot in range(1,7) for frame in range(7)]:
 im=Image.new('RGB',(500,670),bg);draw=ImageDraw.Draw(im)
 label(20,18,'UNINSTALLED / ROTATION MODEL',19,(218,172,78))
 panel(i,60,560,2.5)
 label(35,625,'Fixed bottom firing position',18)
 frames.append(im);durations.append(650 if i==20 or (i-20)%7==6 else 80)
frames[0].save(root/'preview/senator-cylinder-rotation-proposal.gif',save_all=True,append_images=frames[1:],duration=durations,loop=0,disposal=2)
print(root/'preview/senator-cylinder-rotation-proposal.gif')
