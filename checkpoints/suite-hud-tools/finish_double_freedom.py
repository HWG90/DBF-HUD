from pathlib import Path
import zipfile,datetime,subprocess,sys,hashlib
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
baseline=sorted((r/'evidence').glob('double-freedom-before-*.zip'))[0]
with zipfile.ZipFile(baseline) as z:
 print('Menu source unchanged from pre-candidate checkpoint:',hashlib.sha256(z.read('src/menu.lua')).digest()==hashlib.sha256((r/'src/menu.lua').read_bytes()).digest())
with zipfile.ZipFile(r/'evidence'/('double-freedom-before-finish-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for n in ['src/layout.lua','src/mdl.lua','tests/contracts.lua','mdl/dbf_hud/mod.lua']:z.write(r/n,n)
p=r/'src/layout.lua';s=p.read_text(encoding='utf-8');a=s.index('    -- Double Freedom: exposed blue');b=s.index('    if vent then',a);q=s[a:b]
q=q.replace('local slate,silver,brass={22,29,34},{185,203,213},{209,165,82}','local slate,silver,brass={12,21,34},{174,196,217},{207,160,77}')
q=q.replace('        -- Cached loaded/spent shell artwork','''        -- Cool receiver finish and warm brass rails support the blue hulls.
        part(9,47,98,63,{18,33,53},.65)
        part(5,3,1,h-6,{51,75,97},.55)
        part(w-6,3,1,h-6,{51,75,97},.55)
        part(8,h-3,w-16,.7,brass,.5)
        part(8,2,w-16,.7,brass,.35)
        -- Cached loaded/spent shell artwork''')
q=q.replace('part(15,19,86,.6,silver,.3)','part(15,19,86,.6,brass,.45)')
q=q.replace('            child.x=x;child.w=w*scale','''            child.x=x;child.w=w*scale
            for _,offset in ipairs({7,w-9}) do
                shared_child[#shared_child+1]={type='rect',child=true,x=x+offset*scale,y=child.y+4*scale,w=2*scale,h=child.h-8*scale,c=brass,a=.6*opacity}
            end''')
p.write_text(s[:a]+q+s[b:],encoding='utf-8')
p=r/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-NOVA-SHELLS-CHILD Double Freedom large shells and shared mode child','20261003-NOVA-NAVY-BRASS Double Freedom shells and matched receiver finish');p.write_text(s,encoding='utf-8')
for name in ['tests/run.py','tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
