from pathlib import Path
import zipfile,datetime,subprocess,sys
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
with zipfile.ZipFile(r/'evidence'/('before-chosen-breech-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for n in ['src/munition_art.lua','src/layout.lua','src/world_style.lua','src/mdl.lua','tests/contracts.lua','mdl/dbf_hud/mod.lua']:z.write(r/n,n)
p=r/'src/munition_art.lua';s=p.read_text(encoding='utf-8');a=s.index("  if m.resource_hex=='72170a55a1f37ff1' then");b=s.index("  return stacked(shell(name)",a)
q='''  if m.resource_hex=='72170a55a1f37ff1' then
   local b={w=150,h=110,runs={},loaded={}}
   local function rect(x,y,w,h,color)b.runs[#b.runs+1]={x,y,w,h,color,1}end
   local function disc(cx,cy,r,color)
    for y=-r,r-1,6 do
     local height=math.min(6,r-y);local dy=y+height/2
     local half=math.sqrt(math.max(0,r*r-dy*dy))
     local c=type(color)=='function' and color((dy+r)/(2*r)) or color
     rect(cx-half,cy+y,half*2,height,c)
    end
   end
   -- A steel breech block, chamfered at its corners, carries two circular bores.
   rect(18,20,114,5,{77,73,69});rect(12,25,126,6,{93,91,89})
   rect(6,31,138,54,{102,101,99});rect(12,85,126,6,{123,122,119})
   rect(18,91,114,5,{157,155,149});rect(18,95,114,1,{196,193,184})
   rect(3,48,3,16,{67,67,67});rect(144,48,3,16,{67,67,67})
   for barrel=1,2 do
    local cx=barrel==1 and 39 or 111
    local loaded=m.fire_mode=='VOLLEY' and m.value>=2 or (m.fire_mode~='VOLLEY' and m.value>=(barrel==1 and 2 or 1))
    b.loaded[barrel]=loaded
    disc(cx,62,32,{43,40,35})
    disc(cx,62,30,function(t)local v=math.floor(99+64*t);return {v,v,v-3}end)
    disc(cx,62,28,{14,14,13})
    if loaded then
     disc(cx,62,26,function(t)return {math.floor(163+39*t),math.floor(128+33*t),math.floor(68+25*t)}end)
     disc(cx,62,9,{72,50,20});disc(cx,62,7,{194,165,105})
     disc(cx,62,5,{163,173,185})
    else
     disc(cx,62,25,{5,7,9})
    end
   end
   disc(75,28,7,{34,33,31});disc(75,28,5,{145,146,146});disc(75,28,3,{9,11,13})
   assert(#b.runs<=128,'cached breech geometry budget')
   return b
  end
'''
p.write_text(s[:a]+q+s[b:],encoding='utf-8')
p=r/'src/layout.lua';s=p.read_text(encoding='utf-8');a=s.index('    -- Double Freedom: exposed blue');b=s.index('    if vent then',a);q=s[a:b]
q=q.replace('exposed blue shotgun hulls with brass heads, in the AMR family.','chosen rear-facing breech with loaded heads and empty bores.').replace('local w,h=132,116','local w,h=150,108').replace('local slate,silver,brass={12,21,34},{174,196,217},{207,160,77}','local slate,silver,brass={19,21,23},{189,193,199},{202,165,100}')
start=q.index('        -- Cool receiver finish');stop=q.index('        -- Cached loaded/spent',start);q=q[:start]+q[stop:]
q=q.replace('local factor=.6','local factor=.9').replace('42+r[2]*factor','9+r[2]*factor').replace(',43,24*.6,.6',',29,24*.9,.6')
q=q.replace('        label(number,22,20,ink)\n        out[#out].numeric_display=true\n','').replace('        part(15,19,w-30,.6,brass,.45)\n','')
q=q.replace(",5,10,{224,231,235})",",4,10,silver)")
# The chosen reference uses quiet steel corners; the shared user decoration stays configurable.
q=q.replace('part(side==0 and 3 or w-5,h-(4+k*3),2,.6,brass,.65)','part(side==0 and 3 or w-5,h-(4+k*3),2,.6,silver,.35)')
s=s[:a]+q+s[b:]
s=s.replace("for k=1,count do out[#out+1]={type='rect',x=frame.x,y=frame.y+frame.h*k/(count+1),w=frame.w,h=thickness,c=ink,a=.12*opacity} end","for k=1,count do out[#out+1]={type='rect',x=frame.x,y=frame.y+frame.h*k/(count+1),w=frame.w,h=thickness,c=ink,a=.12*opacity,df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,df_effect_fraction=k/(count+1)} end")
s=s.replace("w=frame.w,h=band,c=ink,a=.2*opacity}","w=frame.w,h=band,c=ink,a=.2*opacity,df_effect_frame=m.resource_hex=='72170a55a1f37ff1' and (frame.child and 'child' or 'main') or nil,df_effect_fraction=(((clock or 0)*.35+k/3)%1),df_effect_sweep=true}")
p.write_text(s,encoding='utf-8')
p=r/'src/world_style.lua';s=p.read_text(encoding='utf-8');mark="                    if c.style_3d=='hologram' then"
insert='''                    -- Double Freedom effects follow final font-fitted parent / child bounds.
                    for _,v in ipairs(centered) do if v.df_effect_frame then
                        local target=v.df_effect_frame=='child' and child_panel or panel
                        if target then
                            v.x=target.x;v.w=target.w
                            v.y=target.y+(target.h-(v.df_effect_sweep and v.h or 0))*v.df_effect_fraction
                        end
                    end end
'''
s=s.replace(mark,insert+mark);p.write_text(s,encoding='utf-8')
p=r/'tests/contracts.lua';s=p.read_text(encoding='utf-8');end=s.rfind("print(string.format('%d contract tests passed'")
s=s[:end]+'''test('Double Freedom scanlines and sweeps follow final BigBlue parent and child bounds',function()
 local cfg=HUD.config.new();cfg.font='bigblue';cfg.effect_scanlines=true;cfg.effect_sweep=true
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=2,capacity=2,reserve=30,fire_mode='SEMI'}))
 local out=HUD.world_style.prepare(HUD.layout.compose(m,0,0,1,1,cfg,.4),{first_person=true},cfg)
 local parent,child=out[1];for _,v in ipairs(out)do if v.type=='panel' and v.child then child=v end end
 local n=0;for _,v in ipairs(out)do if v.df_effect_frame then
  local frame=v.df_effect_frame=='child' and child or parent
  assert(v.x==frame.x and v.w==frame.w and v.y>=frame.y and v.y+v.h<=frame.y+frame.h+.001);n=n+1
 end end
 assert(n==48)
end)
'''+s[end:];p.write_text(s,encoding='utf-8')
p=r/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-COLOR-MENU-FIX HUD legacy font labels bounded','20261003-BREECH-REFERENCE-FIX rear shell heads and fitted scanlines');p.write_text(s,encoding='utf-8')
for name in ['tests/run.py','tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
