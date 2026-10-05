from pathlib import Path
import datetime,zipfile,subprocess,sys
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
with zipfile.ZipFile(r/'evidence'/('double-freedom-before-shell-anatomy-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for n in ['src/munition_art.lua','src/layout.lua','src/mdl.lua','mdl/dbf_hud/mod.lua']:z.write(r/n,n)
p=r/'src/munition_art.lua';s=p.read_text(encoding='utf-8');a=s.index("  if m.resource_hex=='72170a55a1f37ff1' then");b=s.index("  return stacked(shell(name)",a);q=s[a:b]
q=q.replace('local function rect(x,y,w,h,color) b.runs[#b.runs+1]={x,y,w,h,color,1} end','''local function rect(x,y,w,h,color)
    local center=x+w/2<75 and 39 or 111
    b.runs[#b.runs+1]={center+(x-center)*.78,y,w*.78,h,color,1}
   end''')
q=q.replace('44,54,loaded','44,65,loaded').replace('cx-22,43','cx-22,32').replace('cx-19,43,7,54','cx-19,32,7,65').replace('cx-10,43,9,54','cx-10,32,9,65').replace('cx+16,43,4,54','cx+16,32,4,65')
q=q.replace('cx-23,18,46,25','cx-23,18,46,14').replace('cx-20,20,9,21','cx-20,20,9,11').replace('cx+14,20,6,21','cx+14,20,6,11').replace('cx-22,40,44,3','cx-22,30,44,2')
q=q.replace('cx-16,27,3,6','cx-16,24,3,5').replace('cx+11,23,2,15','cx+11,21,2,9').replace('cx-18,34,36,1','cx-18,28,36,1')
q=q.replace('Original chunky cartridge silhouette with discrete arcade shading bands.','Straight ten-gauge hull: slender walls and a modest brass head, no projectile nose.')
p.write_text(s[:a]+q+s[b:],encoding='utf-8')
p=r/'src/mdl.lua';s=p.read_text(encoding='utf-8').replace('20261003-NOVA-NAVY-BRASS Double Freedom shells and matched receiver finish','20261003-NOVA-BUCKSHOT Double Freedom straight hulls and short brass heads');p.write_text(s,encoding='utf-8')
for name in ['tests/run.py','tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
