from pathlib import Path
import subprocess,sys,zipfile,datetime
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
with zipfile.ZipFile(r/'evidence'/('double-freedom-shells-before-child-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for name in ['src/layout.lua','src/mdl.lua','tests/contracts.lua','mdl/dbf_hud/mod.lua']:z.write(r/name,name)
p=r/'src/layout.lua';s=p.read_text(encoding='utf-8');a=s.index('    -- Double Freedom: exposed blue');b=s.index('    if vent then',a);block=s[a:b]
block=block.replace('local w,h=116,110','local w,h=116,116\n        local shared_child={}\n        for _,v in ipairs(out) do if v.child and not v.decoration then shared_child[#shared_child+1]=v end end')
block=block.replace('local factor=.48','local factor=.6').replace('49+r[2]*factor','42+r[2]*factor').replace(',50,24*.48,.6',',43,24*.6,.6')
block=block.replace('label(number,28,24,ink)','label(number,22,20,ink)').replace("        label(m.fire_mode or 'SEMI',18,8,silver)\n",'').replace('part(15,15,86,.6','part(15,19,86,.6').replace(",4,9,{224,231,235})",",5,10,{224,231,235})")
block=block.replace('        M.decorate(out,out[1],scale,cfg,opacity)','''        M.decorate(out,out[1],scale,cfg,opacity)
        -- Preserve the shared functional mode child and reposition it below this frame.
        local child=shared_child[1]
        if child and child.type=='panel' then
            local dx=x+w*scale/2-(child.x+child.w/2)
            local dy=y-2*scale-child.h-child.y
            for _,v in ipairs(shared_child) do v.x=v.x+dx;v.y=v.y+dy;v.c=v.type=='panel' and slate or silver end
            child.x=x;child.w=w*scale
            local group={};M.decorate(group,child,scale,cfg,opacity)
            for _,v in ipairs(group) do v.child=true;shared_child[#shared_child+1]=v end
            for _,v in ipairs(shared_child) do out[#out+1]=v end
        end''')
p.write_text(s[:a]+block+s[b:],encoding='utf-8')
p=r/'tests/contracts.lua';s=p.read_text(encoding='utf-8').replace('assert(label and reserves and art and m.value==n and m.reserve==30)','assert(child and label and reserves and art and m.value==n and m.reserve==30)');p.write_text(s,encoding='utf-8')
p=r/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-NOVA-SHELLS Double Freedom exposed shotgun shells','20261003-NOVA-SHELLS-CHILD Double Freedom large shells and shared mode child');p.write_text(s,encoding='utf-8')
for name in ['tests/run.py','tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
