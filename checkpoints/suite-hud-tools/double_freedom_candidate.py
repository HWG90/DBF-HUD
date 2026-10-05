from pathlib import Path
import zipfile, datetime, shutil, subprocess, sys
root=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
backup=root/'evidence'/('double-freedom-before-'+stamp+'.zip')
installed=Path(r'C:\Users\david\AppData\Local\MDL\Helldivers2\Mods\dbf_hud\mod.lua')
with zipfile.ZipFile(backup,'w',zipfile.ZIP_DEFLATED) as z:
 for folder in ['src','tests','tools','dist','mdl']:
  for p in (root/folder).rglob('*'):
   if p.is_file() and '__pycache__' not in p.parts: z.write(p,p.relative_to(root))
 if installed.exists(): z.write(installed,'installed/mod.lua')
p=root/'src/layout.lua';s=p.read_text(encoding='utf-8')
a=s.index('    -- Double Freedom: twin breech windows');b=s.index('    if vent then',a)
(root/'evidence'/('double-freedom-unfinished-'+stamp+'.lua')).write_text(s[a:b],encoding='utf-8')
new='''    -- Double Freedom: compact precision instrument, in the AMR / Autocannon family.
    if m.resource_hex=='72170a55a1f37ff1' then
        local w,h=116,94
        local slate,silver,brass={22,29,34},{185,203,213},{209,165,82}
        out={{type='panel',x=x,y=y,w=w*scale,h=h*scale,c=slate,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='shotgun'}}
        local function part(dx,dy,pw,ph,c,a,barrel)
            out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,barrel_indicator=barrel}
        end
        local function label(value,dy,size,c)
            local left,right=0,#value*size*.6
            if measure then local a,b,e,t=measure(value,size*scale);left=a/scale;right=e/scale end
            out[#out+1]={type='text',text=value,font=cfg.font,x=x+(w/2-(left+right)/2)*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity}
        end
        -- Two understated cartridge silhouettes; native barrel order is retained.
        for barrel,cx in ipairs({46,64}) do
            local loaded=m.fire_mode=='VOLLEY' and m.value==2 or m.fire_mode~='VOLLEY' and (tonumber(m.value) or 0)>=(3-barrel)
            local color=loaded and brass or silver
            local strength=loaded and 1 or .18
            part(cx,76,6,10,color,strength,barrel)
            part(cx+1,86,4,2,color,strength,barrel)
            part(cx-1,74,8,2,color,strength,barrel)
            out[#out].shell_loaded=loaded
        end
        label(number,35,32,ink)
        out[#out].numeric_display=true
        label(m.fire_mode or 'SEMI',23,8,silver)
        part(15,19,86,.6,silver,.3)
        label(m.reserve~=nil and string.format('%03d SHELLS',m.reserve) or '--- SHELLS',7,11,{224,231,235})
        -- Calibrated edge marks echo the AMR without adding a nested housing.
        for _,side in ipairs({0,1}) do for k=0,2 do
            part(side==0 and 3 or w-5,h-(4+k*3),2,.6,brass,.65)
        end end
        M.decorate(out,out[1],scale,cfg,opacity)
    end
'''
p.write_text(s[:a]+new+s[b:],encoding='utf-8')
p=root/'tests/contracts.lua';s=p.read_text(encoding='utf-8').replace("assert(d.text~=string.format('%03d',n),'no redundant loaded numeral')","if d.numeric_display then assert(d.text==string.format('%03d',n)) end")
s=s.replace("test('Double Freedom twin breech panel preserves loaded states, mode and reserves'","test('Double Freedom precision panel preserves loaded states, mode and reserves'")
s=s.replace('assert(label and reserves and art and m.value==n and m.reserve==30)','assert(label and reserves and art and m.value==n and m.reserve==30)\n  assert(#out<65,\'compact rendering budget\')')
p.write_text(s,encoding='utf-8')
p=root/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-AE Double Freedom original compact HUD','20261003-NOVA Double Freedom precision panel');p.write_text(s,encoding='utf-8')
print('Recovery checkpoint:',backup)
subprocess.run([sys.executable,str(root/'tests/run.py')],cwd=root,check=True)
subprocess.run([sys.executable,str(root/'tools/build.py')],cwd=root,check=True)
subprocess.run([sys.executable,str(root/'tools/install_mdl.py')],cwd=root,check=True)
