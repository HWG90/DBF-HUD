from pathlib import Path
import datetime,zipfile,subprocess,sys,hashlib
h=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD');m=h.parent/'ModConfigurationMenu'
settings=Path(r'C:\Users\david\AppData\Local\DBF\DBF-HUD-tuning.lua');before=hashlib.sha256(settings.read_bytes()).hexdigest()
with zipfile.ZipFile(h/'evidence'/('color-menu-before-fix-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for root,names in [(h,['src/menu.lua','src/mdl.lua','tests/contracts.lua']),(m,['src/menu.lua','src/adapter.lua','tests/contracts.lua'])]:
  for n in names:z.write(root/n,root.name+'/'+n)
 for mod in ['dbf_hud','dbf_mcm']:z.write(Path(r'C:\Users\david\AppData\Local\MDL\Helldivers2\Mods')/mod/'mod.lua','installed/'+mod+'/mod.lua')
 z.write(settings,'saved-settings/DBF-HUD-tuning.lua')
p=m/'src/menu.lua';s=p.read_text().replace('for index=start,#commands do commands[index].layer=300 end','for index=start,#commands do commands[index].popup=true;commands[index].layer=300 end');p.write_text(s,encoding='utf-8')
p=m/'tests/contracts.lua';s=p.read_text().replace('if c.layer==300 then popup=popup+1;assert(z>200)end','if c.layer==300 then popup=popup+1;assert(z>200 and c.popup,\'color labels and fields must use the isolated popup GUI\')end');p.write_text(s,encoding='utf-8')
p=h/'src/menu.lua';s=p.read_text().replace('choices[#choices+1]=font_choices[i]','choices[#choices+1]=font_choices[i]:sub(1,48)');p.write_text(s,encoding='utf-8')
p=h/'tests/contracts.lua';s=p.read_text();end=s.rfind("print(string.format('%d contract tests passed'")
test='''test('complete font catalog registers through the real legacy menu validator without saving tuning',function()
 local old,host=ModOptionsMenu,DBFMCM;DBFMCM=nil
 local compat=assert(loadfile('../ModConfigurationMenu/src/compat.lua'))()
 local api,state=compat.new(nil);ModOptionsMenu=api
 local writes=0;local h={config=HUD.config.new()}
 h.configure=function(v)HUD.config.apply(h.config,v)end
 h.save_tuning=function()writes=writes+1 end
 local menu=HUD.menu.new(h);menu.poll()
 assert(menu.status=='Options > Mods > DBF-HUD',menu.status)
 for _,o in pairs(state.options) do for _,label in ipairs(o.choices or {}) do assert(#label<=48)end end
 assert(writes==0);menu.retire();ModOptionsMenu=old;DBFMCM=host
end)
'''
s=s[:end]+test+s[end:];p.write_text(s,encoding='utf-8')
p=m/'src/adapter.lua';s=p.read_text().replace("ctx.log('MCM preview enabled;", "ctx.log('COLOR_POPUP_GUI_FIX 20261003; MCM preview enabled;");p.write_text(s,encoding='utf-8')
p=h/'src/mdl.lua';s=p.read_text().replace('20261003-NOVA-SQUARE Double Freedom square silhouette and buckshot hulls','20261003-COLOR-MENU-FIX HUD legacy font labels bounded');p.write_text(s,encoding='utf-8')
for root,script,args in [(m,'tests/run.py',[]),(h,'tests/run.py',[]),(m,'build.py',['--install']),(h,'tools/build.py',[]),(h,'tools/install_mdl.py',[])]:
 subprocess.run([sys.executable,str(root/script),*args],cwd=root,check=True)
assert hashlib.sha256(settings.read_bytes()).hexdigest()==before,'user settings changed'
print('Saved tuning and opacity preserved byte-for-byte:',before)
