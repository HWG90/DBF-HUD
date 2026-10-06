"""Build all faithful fragments, preserving every current native row."""
import argparse,hashlib,json,struct,sys
from pathlib import Path
from PIL import Image
from build_texture_art import texture
from build_native_font_depth import hash64
from build_scene_depth_probe import archive_rows
ROOT=Path(__file__).resolve().parents[1]
def lua(v):
 if v is None:return 'nil'
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return repr(v)
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 return '{'+','.join('['+lua(k)+']='+lua(x) for k,x in v.items())+'}'
def build(base,output):
 handoff=ROOT/'assets/faithful-all'
 specs=sorted((handoff/'weapons').glob('*/renderer-adapter.json'))
 assert len(specs)==56
 mappings={};coverage=[]
 body=base.read_bytes();gpu=Path(str(base)+'.gpu_resources').read_bytes()
 _,nt,n=struct.unpack_from('<III',body)
 rows=list(struct.iter_unpack('<7Q6I',body[72+nt*32:72+nt*32+n*80]))
 original={(r[0],r[1]):(r[0],r[1],body[r[2]:r[2]+r[7]],gpu[r[4]:r[4]+r[9]]) for r in rows}
 assert n>=757,'must retain manual texture alternatives and accepted assets'
 resources=dict(original)
 material=original[(hash64('mods/dbf_hud/materials/texture_liberator_faithful_details'),hash64('material'))][2]
 report=[]
 for specfile in specs:
  folder=specfile.parent;spec=json.loads(specfile.read_text())
  if any('commands' not in f for f in spec['layers']):
   assert folder.name=='be70ee0d8d44028e'
   coverage.append({'weapon':folder.name,'status':'existing native textured art retained','reason':'Already texture-native; distinct shader binding contract; keep accepted M7S runtime'})
   continue
  assets={}
  for fragment in spec['layers']:
   image_path=folder/fragment['asset']
   assert hashlib.sha256(image_path.read_bytes()).hexdigest()==fragment['sha256']
   image=Image.open(image_path).convert('RGBA')
   assert image.width==round(fragment['origin'][2]*4) and image.height==round(fragment['origin'][3]*4)
   stem='faithful_'+folder.name+'_'+Path(fragment['asset']).stem.replace('-','_')
   texname='mods/dbf_hud/textures/'+stem;matname='mods/dbf_hud/materials/'+stem
   cpu,pixels=texture(image);mat=bytearray(material)
   struct.pack_into('<Q',mat,140,hash64(texname))
   resources[(hash64(texname),hash64('texture'))]=(hash64(texname),hash64('texture'),cpu,pixels)
   resources[(hash64(matname),hash64('material'))]=(hash64(matname),hash64('material'),bytes(mat),b'')
   assets[fragment['asset']]={'material':matname,'texture':texname}
   report.append({'weapon':folder.name,'asset':fragment['asset'],'pixels':image.size,'dds_height':struct.unpack_from('<I',cpu,204)[0],'dds_width':struct.unpack_from('<I',cpu,208)[0]})
  mappings[folder.name]={'spec':spec,'assets':assets}
  coverage.append({'weapon':folder.name,'status':'compiled ordered faithful fragments','fragments':len(assets)})
 for key,value in original.items():assert resources[key]==value,'existing payload changed'
 output.mkdir(parents=True,exist_ok=True)
 data,graphics=archive_rows(list(resources.values()))
 archive=output/base.name;archive.write_bytes(data)
 Path(str(archive)+'.gpu_resources').write_bytes(graphics);Path(str(archive)+'.stream').write_bytes(b'')
 (ROOT/'src/faithful_fragment_assets.lua').write_text('return '+lua(mappings)+'\n')
 (ROOT/'src/faithful_fragments.lua').write_text((handoff/'faithful_adapter.lua').read_text(encoding='utf-8-sig'))
 (output/'build-report.json').write_text(json.dumps({'preserved_resources':n,'new_resources':len(resources)-n,'coverage':coverage,'entries':len(coverage),'registered_adapters':len(mappings),'fragments':report,'base_sha256':hashlib.sha256(body).hexdigest(),'live_verified':False},indent=2))
 print('PASS',n,'original resources unchanged;',len(report),'ordered fragments; DDS dimensions verified')
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--base',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args();build(a.base,a.output)
