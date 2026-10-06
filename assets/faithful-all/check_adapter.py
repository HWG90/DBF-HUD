from pathlib import Path
import ctypes,json
P=Path('HUD/Texture-Faithful-All');H=P.parent
checker=(H/'install_epoch_plasma.py').read_text();exec(checker[checker.index('dll=ctypes.CDLL'):checker.index('check(after)')])
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return repr(v)
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
adapter=(P/'faithful_adapter.lua').read_text(encoding='utf-8-sig');check(adapter)
count=0;textured=0;cases=[]
for line in (P/'capture.jsonl').read_text().splitlines():
 row=json.loads(line)
 if row['state']not in ('normal','empty','full','unknown','opacity'):continue
 spec=json.loads((P/'weapons'/row['id']/'renderer-adapter.json').read_text())
 commands=[]
 for original in row['commands']:
  current={k:v for k,v in original.items()if k not in ('index','bounds')and not k.endswith('_reference')}
  for k in original:
   if k.endswith('_reference'):current[k[:-10]]={}
  commands.append(current)
 assets={fr['asset']:{'material':'test/material/'+fr['asset'],'texture':'test/texture/'+fr['asset']}for fr in spec['layers']}
 fixture={'id':row['id'],'state':row['state'],'commands':commands,'spec':spec,'assets':assets,'panel':.35 if row['state']=='opacity'else 1}
 # Separate states avoid the Lua 5.1 local-variable ceiling.
 cases.append('(function() local f='+lua(fixture)+r'''
 local out=adapter.prepare(f.commands,f.spec,f.assets,0,0,1,1,{panel_opacity=f.panel},function()return true end)
 if f.state=='normal'and #f.spec.layers>0 then assert(out~=f.commands,'Baseline fragment selection failed: '..f.id)end
 local retained={};for _,v in ipairs(out)do if v.type~='texture'then retained[#retained+1]=v end end
 local cursor=0
 for _,v in ipairs(retained)do
  local found=false
  for i=cursor+1,#f.commands do if rawequal(v,f.commands[i])then cursor=i;found=true;break end end
  assert(found,'Native command object or order changed')
 end
 -- Original live text survives by object identity, including nil/unknown readouts.
 for _,v in ipairs(f.commands)do if v.type=='text'or v.child or v.type=='panel'then
  local found=false;for _,q in ipairs(out)do if rawequal(q,v)then found=true;break end end;assert(found,'Live command removed')
 end end
 assert(rawequal(adapter.prepare(f.commands,f.spec,f.assets,0,0,1,1,{panel_opacity=f.panel},function()return false end),f.commands),'Unavailable asset did not fall back')
 assert(rawequal(adapter.prepare(f.commands,f.spec,f.assets,0,0,1,.55,{panel_opacity=f.panel},function()return true end),f.commands),'Non-baked opacity did not fall back')
 if out~=f.commands then textured=textured+1 end
 checked=checked+1
end)();
''')
 count+=1
code='local adapter=(function()\n'+adapter+'\nend)()\nlocal checked,textured=0,0;\n'+''.join(cases)+'\nlocal f=assert(io.open('+json.dumps((P/'adapter-checks.txt').resolve().as_posix())+',"w"));f:write(checked.." "..textured);f:close()\n'
(P/'adapter-tests.lua').write_text(code,encoding='utf-8');check(code,True)
print('PASS native Lua adapter identity/order/asset and opacity fallback checks:',(P/'adapter-checks.txt').read_text())
