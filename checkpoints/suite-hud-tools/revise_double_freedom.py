from pathlib import Path
import datetime,zipfile,subprocess,sys
root=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
with zipfile.ZipFile(root/'evidence'/('double-freedom-rejected-precision-'+stamp+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for name in ['src/layout.lua','src/mdl.lua','tests/contracts.lua','dist/dbf_hud.lua','mdl/dbf_hud/mod.lua']:
  z.write(root/name,name)
 z.write(Path(r'C:\Users\david\AppData\Local\MDL\Helldivers2\Mods\dbf_hud\mod.lua'),'installed/mod.lua')
p=root/'src/layout.lua';s=p.read_text(encoding='utf-8');start=s.index('    -- Double Freedom: compact precision instrument');end=s.index('    if vent then',start);block=s[start:end]
block=block.replace('compact precision instrument, in the AMR / Autocannon family.','exposed blue shotgun hulls with brass heads, in the AMR family.').replace('local w,h=116,94','local w,h=116,110')
a=block.index('        -- Two understated cartridge silhouettes');b=block.index('        -- Calibrated edge marks',a)
block=block[:a]+'''        -- Cached loaded/spent shell artwork is the primary display, not a small glyph.
        local art=HUD.munition_art.icon(HUD.weapon_styles.catalog[m.resource_hex],m,nil)
        local factor=.48
        local origin=(w-art.w*factor)/2
        for _,r in ipairs(art.runs) do
            part(origin+r[1]*factor,49+r[2]*factor,r[3]*factor,r[4]*factor,r[5],1)
            out[#out].shotgun_shell_art=true
        end
        for barrel=1,2 do
            part(origin+(barrel==1 and 14 or 86)*factor,50,24*.48,.6,art.loaded[barrel] and brass or silver,art.loaded[barrel] and .8 or .2,barrel)
            out[#out].shell_loaded=art.loaded[barrel]
        end
        label(number,28,24,ink)
        out[#out].numeric_display=true
        label(m.fire_mode or 'SEMI',18,8,silver)
        part(15,15,86,.6,silver,.3)
        label(m.reserve~=nil and string.format('%03d SHELLS',m.reserve) or '--- SHELLS',4,9,{224,231,235})
'''+block[b:]
p.write_text(s[:start]+block+s[end:],encoding='utf-8')
p=root/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-NOVA Double Freedom precision panel','20261003-NOVA-SHELLS Double Freedom exposed shotgun shells');p.write_text(s,encoding='utf-8')
p=root/'tests/contracts.lua';s=p.read_text(encoding='utf-8').replace("assert(#out<65,'compact rendering budget')","assert(#out<160,'cached shell rendering budget')\n  local shells=0;for _,d in ipairs(out) do if d.shotgun_shell_art then shells=shells+1 end end\n  assert(shells>=40,'recognizable full shotgun artwork')")
p.write_text(s,encoding='utf-8')
for script in ['tests/run.py','tools/build.py','tools/install_mdl.py']:
 subprocess.run([sys.executable,str(root/script)],cwd=root,check=True)
