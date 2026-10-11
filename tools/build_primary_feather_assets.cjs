// Cached panel-alpha masks only. No game, upload, shader, or renderer changes.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const {getSharp,execPython}=require('./runtime_dependencies.cjs');
const sharp=getSharp();
const root=path.resolve(__dirname,'..'),output=path.join(root,'assets/primary-feather'),review=path.join(root,'dist/hud-edge-feather-20261011');
const oldAssets=path.join(root,'assets/segmented-fancy');
const preserved=new Map(fs.readdirSync(oldAssets).filter(n=>/(?:_v4|[-]v4)(?:[_ .-]|$)/.test(n)).map(n=>[n,crypto.createHash('sha256').update(fs.readFileSync(path.join(oldAssets,n))).digest('hex')]));
fs.mkdirSync(output,{recursive:true});fs.mkdirSync(review,{recursive:true});
const W=128,H=256;
function expect(v,message){if(!v)throw new Error(message)}
function smoothstep(t){t=Math.max(0,Math.min(1,t));return t*t*(3-2*t)}
async function make(percent){
 const raw=Buffer.alloc(W*H*4,255),feather=W*percent/100;
 for(let y=0;y<H;y++)for(let x=0;x<W;x++)raw[(y*W+x)*4+3]=Math.round(255*smoothstep(Math.min(x,W-1-x,y,H-1-y)/feather));
 let alphaLevels=new Set();
 for(let y=0;y<H;y++)for(let x=0;x<W;x++){
  const i=(y*W+x)*4,a=raw[i+3];expect(raw[i]===255&&raw[i+1]===255&&raw[i+2]===255,'Transparent RGB dark fringe');
  if(x===0||y===0||x===W-1||y===H-1)expect(a===0,'Boundary must be transparent');
  expect(a===raw[(y*W+(W-1-x))*4+3]&&a===raw[((H-1-y)*W+x)*4+3],'Mask symmetry');alphaLevels.add(a);
 }
 expect(raw[((H/2)*W+W/2)*4+3]===255,'Center must remain opaque');
 for(let x=1;x<W/2;x++)expect(raw[((H/2)*W+x)*4+3]>=raw[((H/2)*W+x-1)*4+3],'Mask alpha must rise inward');
 const name='primary_edge_mask_v1_'+String(percent).padStart(2,'0'),sha256=crypto.createHash('sha256').update(raw).digest('hex'),filename=name+'_'+sha256+'.rgba';
 fs.writeFileSync(path.join(output,filename),raw);await sharp(raw,{raw:{width:W,height:H,channels:4}}).png().toFile(path.join(output,name+'.png'));
 return {name,resource:'mods/dbf_hud/textures/'+name,width:W,height:H,softness_percent:percent,feather_mask_pixels:feather,filename,sha256,bytes:raw.length,alpha_levels:alphaLevels.size};
}
async function preview(images){
 const snapshot=path.join(output,'preview-commands.json');
 execPython(['tests/run.py','--suite','tests/segmented_fancy.lua'],{cwd:root,env:{...process.env,DBF_HUD_EDGE_PREVIEW:snapshot,DBF_HUD_ART_FONT:'hack'},stdio:'pipe'});
 const scenes=JSON.parse(fs.readFileSync(snapshot,'utf8')),urls={};
 const existing=JSON.parse(fs.readFileSync(path.join(oldAssets,'TEXTURES-full-uv.json'),'utf8')).images;
 for(const p of existing)urls['mods/dbf_hud/textures/'+p.name]={width:p.width,height:p.height,url:'data:image/png;base64,'+fs.readFileSync(path.join(oldAssets,p.name+'.png')).toString('base64')};
 for(const p of images)urls[p.resource]={width:p.width,height:p.height,url:'data:image/png;base64,'+fs.readFileSync(path.join(output,p.name+'.png')).toString('base64')};
 const fontPath=path.join(oldAssets,'preview-full-uv-native-hack.png'),fontInfo=await sharp(fontPath).metadata();
 const font={width:fontInfo.width,height:fontInfo.height,url:'data:image/png;base64,'+fs.readFileSync(fontPath).toString('base64')};
 const figures=[];let perimeterAlpha=[];
 for(const percent of [0,4,8,12]){
  const commands=scenes[String(percent)],frame=commands[0];let defs='',body='',decor='',index=0;
  if(frame.edge_mask_resource)urls[frame.edge_mask_resource]=urls[images.find(p=>p.softness_percent===percent).resource];
  if(frame.edge_mask_resource){const mask=urls[frame.edge_mask_resource];defs+='<mask id="edge" maskUnits="userSpaceOnUse" x="18" y="25" width="174" height="304" style="mask-type:alpha"><image x="18" y="25" width="174" height="304" href="'+mask.url+'"/></mask>';}
  function imageQuad(p,img,rect,color,alpha){const id='c'+(++index),r=color.map(n=>n/255);defs+='<filter id="'+id+'" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="'+r[0]+' 0 0 0 0 0 '+r[1]+' 0 0 0 0 0 '+r[2]+' 0 0 0 0 0 1 0"/></filter>';return '<svg x="'+p.x+'" y="'+(352-p.y-p.h)+'" width="'+p.w+'" height="'+p.h+'" viewBox="'+[rect[0]*img.width,rect[1]*img.height,rect[2]*img.width,rect[3]*img.height].join(' ')+'" preserveAspectRatio="none" opacity="'+alpha+'"><image width="'+img.width+'" height="'+img.height+'" href="'+img.url+'" filter="url(#'+id+')"/></svg>';}
  for(const c of commands){
   if(c.type==='texture'&&c.a>0)body+=imageQuad(c,urls[c.texture_resource],c.atlas_rect,c.c,c.a);
   else if(c.type==='text'&&c.text)for(const g of c.preview_glyphs)body+=imageQuad(g,font,g.atlas_rect,c.c,c.a);
   else if(c.decoration)decor+='<rect x="'+c.x+'" y="'+(352-c.y-c.h)+'" width="'+c.w+'" height="'+c.h+'" fill="rgb('+c.c.join(',')+')" opacity="'+c.a+'"/>';
  }
  const svg='<svg xmlns="http://www.w3.org/2000/svg" width="210" height="352" viewBox="0 0 210 352"><defs>'+defs+'</defs>'+body+'<g'+(frame.edge_mask_resource?' mask="url(#edge)"':'')+'>'+decor+'</g></svg>';
  fs.writeFileSync(path.join(review,'edge-'+percent+'.svg'),svg);const png=await sharp(Buffer.from(svg)).resize(420,704).png().toBuffer();fs.writeFileSync(path.join(review,'edge-'+percent+'.png'),png);figures.push({input:png,left:24+figures.length*444,top:96});
  const t=percent?Math.min(1,(.5/174*(W-1))/(W*percent/100)):1;perimeterAlpha.push({percent,approx_one_pixel_stroke_center_alpha:smoothstep(t)});
 }
 const title='<svg width="1800" height="856"><style>text{font:20px Consolas,monospace;fill:#e9c45d}</style><text x="24" y="32">HUD EDGE SOFTNESS / BACKING + SHARED HELLDIVERS DECORATION</text>'+[0,4,8,12].map((p,i)=>'<text x="'+(24+i*444)+'" y="76">'+(p?p+'% softness':'Hard edges / 0%')+'</text>').join('')+'<text x="24" y="836" style="font-size:14px;fill:#bac9d1">Actual compositor + native Hack · same loaded/status readings · one global alpha mask for perimeter rectangles · foreground remains crisp</text></svg>';
 figures.push({input:Buffer.from(title),left:0,top:0});await sharp({create:{width:1800,height:856,channels:4,background:'#264656'}}).composite(figures).png().toFile(path.join(review,'comparison.png'));
 fs.writeFileSync(path.join(review,'index.html'),'<!doctype html><meta charset="utf-8"><title>HUD edge softness</title><style>body{background:#132a36;color:#f5f6f0;font:16px system-ui;margin:28px}img{max-width:100%}p{color:#bed0d7}a{color:#e9c45d}</style><h1>Backing and perimeter feathering</h1><p>The backing and every shared Helldivers perimeter rectangle sample the same full-panel mask. Digits, rails, and status labels remain crisp.</p><img src="comparison.png" alt="Hard, 4%, 8%, and 12% feathered edges"><p>At 4%, a thin stroke directly on the boundary becomes very faint. Higher values soften the backing further and almost remove those outer strokes.</p>');
 return perimeterAlpha;
}
(async()=>{
 const images=[];for(const percent of [4,8,12])images.push(await make(percent));
 const perimeterAlpha=await preview(images);
 for(const [name,hash]of preserved)expect(crypto.createHash('sha256').update(fs.readFileSync(path.join(oldAssets,name))).digest('hex')===hash,'v4 artwork changed: '+name);
 const metadata={version:1,format:'straight RGBA8',rgb_all_pixels:[255,255,255],mask_size:[W,H],full_uv:[0,0,1,1],alpha:'smoothstep(min(x,127-x,y,255-y)/(128*softness_percent/100))',physical_mask_pixel_width:true,boundary_alpha:0,center_alpha:255,images,total_bytes:images.reduce((n,p)=>n+p.bytes,0),v4_files_preserved:preserved.size,perimeterAlpha};
 fs.writeFileSync(path.join(output,'MASKS.json'),JSON.stringify(metadata,null,2));fs.writeFileSync(path.join(output,'manifest-additions.tsv'),images.map(p=>[p.name,p.width,p.height,p.filename].join('\t')).join('\n')+'\n');
 fs.writeFileSync(path.join(output,'CHECKS.json'),JSON.stringify({passed:true,white_rgb_under_transparency:true,boundary_zero:true,center_255:true,symmetric:true,monotonic_inward:true,actual_composer_preview:true,shared_decoration_global_mask:true,foreground_unmasked:true,v4_files_preserved:preserved.size},null,2));
 console.log('Built 3 immutable feather masks; '+metadata.total_bytes+' bytes; review='+path.join(review,'comparison.png'));
})().catch(e=>{console.error(e);process.exitCode=1});
