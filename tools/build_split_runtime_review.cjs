// Rasterize the actual Split compositor and retained native font atlas offline.
// All generated donor-bearing SVGs stay in ignored dist. No browser/game calls.
'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {getSharp,execPython}=require('./runtime_dependencies.cjs'),sharp=getSharp();
const root=path.resolve(__dirname,'..'),out=path.join(root,'dist/split-hud-in-game-20261011');fs.mkdirSync(out,{recursive:true});
const commandsPath=path.join(out,'runtime-commands.json'),assetsPath=path.join(root,'assets/split-hud');
function expect(v,message){if(!v)throw Error(message)}
function sha(bytes){return crypto.createHash('sha256').update(bytes).digest('hex')}
const svg=(w,h,body)=>'<svg xmlns="http://www.w3.org/2000/svg" width="'+w+'" height="'+h+'" viewBox="0 0 '+w+' '+h+'">'+body+'</svg>';
const label=(x,y,s,size=12,color='#e9c45d')=>'<text x="'+x+'" y="'+y+'" fill="'+color+'" font-family="Consolas,monospace" font-size="'+size+'">'+s+'</text>';
const field='#1c3344';
async function main(){
 execPython(['tests/run.py','--suite','tests/split_hud.lua'],{cwd:root,env:{...process.env,DBF_HUD_SPLIT_PREVIEW:commandsPath.replace(/\\/g,'/')},stdio:'pipe'});
 const snapshot=JSON.parse(fs.readFileSync(commandsPath,'utf8')),spec=JSON.parse(fs.readFileSync(path.join(assetsPath,'TEXTURES.json'),'utf8'));
 const images={},generated=[];
 for(const p of spec.images)images[p.resource]={width:p.width,height:p.height,url:'data:image/png;base64,'+fs.readFileSync(path.join(assetsPath,p.name+'.png')).toString('base64')};
 for(const [name,p]of Object.entries(snapshot.generated)){
  const bytes=fs.readFileSync(path.join(out,p.filename));expect(bytes.length===p.width*p.height*4,'Generated mask byte count mismatch');
  const png=await sharp(bytes,{raw:{width:p.width,height:p.height,channels:4}}).png().toBuffer();fs.writeFileSync(path.join(out,name+'.png'),png);
  images['mods/dbf_hud/textures/'+name]={width:p.width,height:p.height,url:'data:image/png;base64,'+png.toString('base64')};generated.push({name,...p,sha256:sha(bytes)});
 }
 const fontPath=path.join(root,'assets/segmented-fancy/preview-full-uv-native-hack.png'),fontBytes=fs.readFileSync(fontPath),fontMeta=await sharp(fontBytes).metadata();
 const font={width:fontMeta.width,height:fontMeta.height,url:'data:image/png;base64,'+fontBytes.toString('base64')};
 let unique=0;
 function panel(scene){
  let defs='',body='';let textures=0,glyphs=0;
  function quad(p,img,rect,color,alpha){
   expect(img,'Missing raster texture');const id='t'+(++unique),rgb=color.map(n=>n/255);
   defs+='<filter id="'+id+'" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="'+rgb[0]+' 0 0 0 0 0 '+rgb[1]+' 0 0 0 0 0 '+rgb[2]+' 0 0 0 0 0 1 0"/></filter>';
   return '<svg x="'+p.x+'" y="'+(scene.height-p.y-p.h)+'" width="'+p.w+'" height="'+p.h+'" viewBox="'+[rect[0]*img.width,rect[1]*img.height,rect[2]*img.width,rect[3]*img.height].join(' ')+'" preserveAspectRatio="none" opacity="'+alpha+'"><image width="'+img.width+'" height="'+img.height+'" href="'+img.url+'" filter="url(#'+id+')"/></svg>';
  }
  for(const c of scene.commands){
   expect(c.spatial_plane,'Production command lost spatial grouping');
   if(c.type==='texture'&&c.a>0){textures++;body+=quad(c,images[c.texture_resource],c.atlas_rect,c.c,c.a)}
   else if(c.type==='text'&&c.text){expect(c.font==='hack'&&Array.isArray(c.preview_glyphs),'Native Hack glyph snapshot missing');for(const g of c.preview_glyphs){glyphs++;body+=quad(g,font,g.atlas_rect,c.c,c.a)}}
  }
  return {body:'<defs>'+defs+'</defs>'+body,textures,glyphs};
 }
 const panels={};const cases=[];
 for(const [name,scene]of Object.entries(snapshot.scenes)){
  const p=panel(scene);panels[name]={scene,...p};const markup=svg(scene.width,scene.height,'<rect width="100%" height="100%" fill="'+field+'"/>'+p.body);
  fs.writeFileSync(path.join(out,'runtime-'+name+'.svg'),markup);const png=await sharp(Buffer.from(markup)).resize(Math.round(scene.width*3),Math.round(scene.height*3)).png().toBuffer();fs.writeFileSync(path.join(out,'runtime-'+name+'.png'),png);
  cases.push({name,width:scene.width,height:scene.height,texture_quads:p.textures,native_glyph_quads:p.glyphs,png_sha256:sha(png),native_font:'hack',preserved_planes:[...new Set(scene.commands.map(c=>c.spatial_plane))]});
 }
 const renderGroup=(name,x,y,scale=1)=>'<g transform="translate('+x+' '+y+') scale('+scale+')">'+panels[name].body+'</g>';
 let actual='<rect width="1080" height="250" fill="'+field+'"/>'+label(22,24,'ACTUAL SPLIT / NATIVE HACK / 70% GAMEPLAY REFERENCE',15);
 [['READY','ready'],['CHAMBERED +1','chamber'],['EMPTY / COUNTER FLASHES','empty']].forEach(([title,name],i)=>{const x=22+i*350;actual+=label(x,55,title,12)+renderGroup(name,x+15,80,.7)});
 actual+=label(22,230,'Four spatial planes are flattened for artwork comparison. In-game perspective and depth remain separate live checks.',10,'#a9bdc9');
 await write('runtime-actual-scale',1080,250,actual);
 let family='<rect width="1290" height="885" fill="#102234"/>'+label(20,28,'ACTUAL SPLIT / NINE RESOURCE SYSTEMS / NATIVE READER SEMANTICS',17);
 const names=[['Magazine','magazine'],['Belt + selected RPM','belt'],['Individual shells','shells'],['Heat + sinks','heat'],['Charge + safety','charge'],['Selected ammunition','ammo'],['Single use','expendable'],['Fuel + tanks','fuel'],['Infinite energy','infinite']];
 names.forEach(([title,key],i)=>{const x=20+i%3*420,y=54+Math.floor(i/3)*275;family+='<rect x="'+x+'" y="'+y+'" width="407" height="259" fill="'+field+'" stroke="#425b6e"/>'+label(x+16,y+25,title,13)+renderGroup('family-'+key,x+26,y+62)});
 await write('runtime-families',1290,885,family);
 let controls='<rect width="980" height="290" fill="#102234"/>'+label(22,28,'FOUR INDEPENDENT SETTINGS / ACTUAL COMPOSITOR',17)+label(22,56,'COMBAT',13)+renderGroup('mixed',24,88)+label(452,56,'INSPECT',13)+renderGroup('mixed-inspect',454,88);
 await write('runtime-settings',980,290,controls);
 const studyBytes=fs.readFileSync(path.join(root,'review/universal-hud-split-08/split-combat-chamber.png'));
 const sourceImage='data:image/png;base64,'+studyBytes.toString('base64');
 let comparison='<rect width="756" height="245" fill="#102234"/>'+label(22,27,'ACCEPTED STUDY / ILLUSTRATIVE CONSOLAS',12)+label(396,27,'ACTUAL COMPOSITOR / NATIVE HACK',12);
 comparison+='<image x="12" y="39" width="356" height="197" href="'+sourceImage+'"/><rect x="386" y="39" width="356" height="197" fill="'+field+'"/>'+renderGroup('chamber',404,57);
 await write('runtime-study-comparison',756,245,comparison,2);
 const report={passed:true,actual_production_compositor:true,font:'hack',font_dimensions:[font.width,font.height],font_atlas_sha256:sha(fontBytes),font_source:'existing retained native font atlas; no substitute font rasterization',generated_masks:generated,appearance:{backing_percent:35,feather_percent:7,dither_percent:40,grain:2,curve:1,depth_px:16,gameplay_scale:.7},cases,source_sha256:sha(fs.readFileSync(path.join(root,'src/split_hud.lua'))),native_raster_verified:true,live_game_verified:false,depth_and_perspective:'not represented in flat reference figures; production plane metadata retained in runtime-commands.json'};
 fs.writeFileSync(path.join(out,'RUNTIME-REVIEW.json'),JSON.stringify(report,null,2)+'\n');
 fs.writeFileSync(path.join(out,'index.html'),'<!doctype html><meta charset="utf-8"><title>Split / actual compositor review</title><style>body{margin:28px;background:#102234;color:#f5f6f0;font:15px system-ui}h1{font-weight:500}img{display:block;max-width:100%;margin:18px 0}p{max-width:950px;color:#adc1cf}a{color:#e9c45d}</style><h1>Split: actual HUD Texture compositor</h1><p>Native Hack labels, authored slanted digits, and production feather/dither masks. White, gold, and navy. These flat references preserve the four production spatial planes in their command data; perspective, mounting, occlusion, and firing stability need a live game check.</p><img src="runtime-study-comparison.png" alt="Accepted Study compared with actual compositor"><img src="runtime-actual-scale.png" alt="Normal chambered and empty at seventy percent"><img src="runtime-settings.png" alt="Combat and inspect preserve four independent settings"><img src="runtime-families.png" alt="Nine native resource systems"><p><a href="runtime-commands.json">Actual commands</a> · <a href="RUNTIME-REVIEW.json">Raster evidence</a></p>');
 console.log('Rendered '+cases.length+' actual Split/native Hack cases; font '+font.width+'×'+font.height+'; '+path.join(out,'index.html'));
}
async function write(name,w,h,body,scale=1){const markup=svg(w,h,body);fs.writeFileSync(path.join(out,name+'.svg'),markup);await sharp(Buffer.from(markup)).resize(Math.round(w*scale),Math.round(h*scale)).png().toFile(path.join(out,name+'.png'))}
main().catch(e=>{console.error(e.stack);process.exitCode=1});
