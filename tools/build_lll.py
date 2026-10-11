from pathlib import Path
import importlib.util,json,re
ROOT=Path(__file__).resolve().parents[1]

def package(root,mod_id,title,version,main,modules,extra=None,restart_only=False):
    import hashlib,json,zipfile
    output=root/'dist/releases/modular-20261010';output.mkdir(parents=True,exist_ok=True)
    folder=output/mod_id;folder.mkdir(exist_ok=True)
    files={'main.lua':main.encode('utf-8'),'config/defaults.cfg':b'{}\n'}
    files.update({name:body.encode('utf-8') if isinstance(body,str) else body for name,body in modules.items()})
    files.update(extra or {})
    manifest={'id':mod_id,'name':title,'version':version,'author':'Goose','lll':{'entry':'main.lua','defaults':'config/defaults.cfg','modules':sorted(modules),'restart_only':restart_only,'retain_until_exit':True}}
    files['manifest.json']=(json.dumps(manifest,indent=2)+'\n').encode()
    files['INSTALL.txt']=('Requires LLL R30 or later. Copy '+mod_id+' into LLL/Helldivers2/Mods. Remove the old loose/bundled provider of the same mod before starting. This is a source-layout migration; native DLLs need a normal restart. Existing mod settings are retained. Do not activate alongside the archive provider. '+('This mod remains restart-only; startup hook ownership is unchanged.' if restart_only else 'Lifecycle callbacks and cleanup are preserved.')+'\n').encode()
    files['FILES-SHA256.txt']=''.join(hashlib.sha256(body).hexdigest()+'  '+name+'\n' for name,body in sorted(files.items())).encode()
    for name,body in files.items():
        path=folder/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(body)
    target=output/(mod_id+'-'+version+'-LLL-Modular.zip')
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
        for name,body in sorted(files.items()):z.writestr(mod_id+'/'+name,body)
    print(target)
    return target

spec=importlib.util.spec_from_file_location('hud_build',ROOT/'tools/build.py');build=importlib.util.module_from_spec(spec);spec.loader.exec_module(build)
main=['local HUD={}','mod.scope.HUD=HUD'];modules={}
for name in build.ORDER:
    path='src/'+name+'.lua';modules[path]=(ROOT/path).read_bytes();main.append('HUD.'+name+'=mod.require("'+path+'")')
    if name=='bundled_defaults':main.append('for key,value in pairs(mod.config.defaults or {})do HUD.bundled_defaults.settings[key]=value end')
modules['src/console.lua']=(ROOT/'src/console.lua').read_bytes();main.append('HUD.console=mod.require("src/console.lua")')
adapter=(ROOT/'src/mdl.lua').read_text().replace('        started=true\n','        HUD.console(hud,mod)\n        started=true\n')
assert 'HUD.console(hud,mod)' in adapter,'Console must be registered after HUD startup'
modules['src/mdl.lua']=adapter;main.append('return mod.require("src/mdl.lua")')
defaults_source=(ROOT/'src/bundled_defaults.lua').read_text()
defaults={}
for key in ['panel_opacity','text_opacity','third_person_opacity']:
    match=re.search(r'\b'+key+r'\s*=\s*([0-9.]+)',defaults_source)
    if match:defaults[key]=float(match[1])
extra={'config/defaults.cfg':(json.dumps({'defaults':defaults},indent=2)+'\n').encode()}
package(ROOT,'dbf_hud' ,'DBF HUD','0.3.42','\n'.join(main)+'\n',modules,extra)
