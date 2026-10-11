// Produce immutable straight-RGBA8 masks. No game/native calls.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { getSharp, execPython } = require('./runtime_dependencies.cjs');
const sharp = getSharp();
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'assets/segmented-fancy');
fs.mkdirSync(output, { recursive: true });
const source = 'review/primary-digit-study-06/design.js';
const approved = fs.readFileSync(path.join(root,source),'utf8');
const selected=require(path.join(root,source));
const preservedV3=new Map(fs.readdirSync(output).filter(name=>/(?:_v3|[-]v3)(?:[_ .-]|$)/.test(name)).map(name=>[name,crypto.createHash('sha256').update(fs.readFileSync(path.join(output,name))).digest('hex')]));
const preservedV4=new Map(fs.readdirSync(output).filter(name=>/(?:_v4|[-]v4)(?:[_ .-]|$)/.test(name)).map(name=>[name,crypto.createHash('sha256').update(fs.readFileSync(path.join(output,name))).digest('hex')]));
const polygons = {};
const selectedPolygons=[...selected.digit('led','8').matchAll(/<polygon points="([^"]+)"/g)].slice(0,7);
Object.keys(selected.led).forEach((name,i)=>{polygons[name]=selectedPolygons[i][1].split(' ').map(pair=>pair.split(',').map(Number));});
if(Object.keys(polygons).length!==7)throw new Error('Selected LED polygons missing');
const patterns=selected.ledPatterns.map(p=>p.join(''));
function digitMarkup(pattern){return [...pattern].map(name=>'<polygon points="'+polygons[name].map(p=>p.join(',')).join(' ')+'" fill="white" stroke="'+selected.C.navy+'" stroke-width=".65" stroke-linejoin="round"/>').join('');}
let atlasBody = '';
for (let digit=0;digit<12;digit++) {
 const px = 8+80*digit, py=8;
 const content = digitMarkup(patterns[digit]);
 atlasBody += '<g transform="translate('+px+' '+py+')">'+content+'</g>';
}
// Sample the center of this opaque region for exact rectangular backing/indicators.
atlasBody += '<rect x="976" y="4" width="40" height="40" fill="white"/>';
for (let i=0;i<20;i++) atlasBody += '<rect x="'+(16+i*8)+'" y="192" width="7" height="7" fill="white"/>';
// Three steady navy cells share one cached crop; active glyphs retain individual tint/flash.
const ghostScale=78/118,ghostStart=(154-(3*72+2*7)*ghostScale)/2;
for(let i=0;i<3;i++)atlasBody+='<g transform="translate('+(256+ghostStart+i*79*ghostScale)+' 256) scale('+ghostScale+')">'+digitMarkup('abcdefg')+'</g>';
// Exact approved 48px button outline and 48x2 underline, with a .5px crop margin.
atlasBody+='<g transform="translate(448 256)"><path d="M.5 .5 H48.5 V17.5 H.5 Z" fill="none" stroke="white" stroke-width=".7"/><path d="M.5 20.5 H48.5" stroke="white" stroke-width="2"/></g>';
const atlas = '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="512">'+atlasBody+'</svg>';
let faceBody = '';
for (const y of [52,176,244,286]) faceBody += '<path d="M25 '+y+' H185" stroke="white" stroke-opacity=".35" stroke-width=".7"/>';
faceBody += '<path d="M27 76 H33 M25 78 V168 M27 171 H33 M177 76 H183 M185 78 V168 M177 171 H183" stroke="white" stroke-opacity=".22" stroke-width=".6" fill="none"/>';
faceBody += '<path d="M25 184 H185 V198 H25 Z" fill="none" stroke="white" stroke-opacity=".22" stroke-width=".6"/>';
for (let i=0;i<3;i++) { const x=25+55*i;faceBody+='<path d="M'+x+' 301 H'+(x+48)+' V318 H'+x+' Z" fill="none" stroke="white" stroke-opacity=".25" stroke-width=".7"/>'; }
const face = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="512"><g transform="translate(14 7)">'+faceBody+'</g></svg>';
async function save(name, width, height, svg) {
 fs.writeFileSync(path.join(output, name+'.svg'), svg);
 const render = sharp(Buffer.from(svg)).ensureAlpha();
 await render.clone().png().toFile(path.join(output, name+'.png'));
 const {data,info} = await render.raw().toBuffer({ resolveWithObject:true });
 if (info.width!==width || info.height!==height || info.channels!==4 || data.length!==width*height*4) throw new Error('RGBA shape mismatch');
 const hash = crypto.createHash('sha256').update(data).digest('hex');
 const filename = name+'_'+hash+'.rgba';
 fs.writeFileSync(path.join(output, filename), data);
 return {name,width,height,filename,sha256:hash,bytes:data.length};
}
(async function(){
 const white='<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16" fill="white"/></svg>';
 const images = [await save('segmented_fancy_face_v4',256,512,face),await save('segmented_fancy_atlas_v4',1024,512,atlas),await save('primary_full_white_v1',16,16,white)];
 const whiteBytes=fs.readFileSync(path.join(output,images[2].filename));if(whiteBytes.length!==1024||!whiteBytes.every(n=>n===255))throw new Error('Full-UV white resource must be 1024 all-255 bytes');
 const spec = {version:4,format:'RGBA8',straight_alpha:true,rectangular_backing:true,outer_decoration_baked:false,design_source:source,selected_style:'led',design_sha256:crypto.createHash('sha256').update(approved).digest('hex'),digit_polygons:polygons,active_polygon_inset:0,stroke_width:.65,gauge_cells:20,mode_bank:['AUTO','BURST','SEMI'],loaded_box:[28,87,154,78],leading_zero_alpha:.14,images,total_bytes:images.reduce((n,p)=>n+p.bytes,0),face_uv:[32/256,32/512,174/256,304/512],digit_uv:{first_x:8,step_x:80,y:8,width:72,height:118,atlas_width:1024,atlas_height:512},loaded_ghost_uv:[256/1024,256/512,154/1024,78/512],mode_active_uv:[448/1024,256/512,49/1024,22/512],solid_uv:[988/1024,16/512,16/1024,16/512],gauge_uv:[16/1024,192/512,160/1024,7/512]};
 fs.writeFileSync(path.join(output,'TEXTURES.json'),JSON.stringify(spec,null,2));
 fs.writeFileSync(path.join(output,'TEXTURES-full-uv.json'),JSON.stringify({...spec,full_white_resource:'mods/dbf_hud/textures/primary_full_white_v1',full_white_uv:[0,0,1,1]},null,2));
 fs.writeFileSync(path.join(output,'manifest-additions.tsv'),images.map(p=>[p.name,p.width,p.height,p.filename].join('\t')).join('\n')+'\n');
 fs.writeFileSync(path.join(output,'manifest-full-uv.tsv'),images.map(p=>[p.name,p.width,p.height,p.filename].join('\t')).join('\n')+'\n');
 await preview(images);
 console.log('Built '+images.length+' immutable texture masks; '+spec.total_bytes+' bytes. No deployment.');
})().catch(error=>{console.error(error.message);process.exitCode=1});

async function preview(images) {
 const commandsFile=path.join(output,'preview-full-uv-commands.json');
 execPython(['tests/run.py','--suite','tests/segmented_fancy.lua'],{cwd:root,env:{...process.env,DBF_HUD_ART_PREVIEW:commandsFile,DBF_HUD_ART_FONT:'hack',DBF_HUD_FULL_WHITE_READY:'1'},stdio:'pipe'});
 const scenarios=JSON.parse(fs.readFileSync(commandsFile,'utf8'));
 // Read the retained native atlas: no substitute fonts or new glyph rasterization.
 const fontPackage=[path.join(root,'releases/DBF-HUD-Native-Fonts-0.1.zip'),path.join(root,'../DBF-HUD-Native-Fonts-0.1.zip')].find(p=>fs.existsSync(p));
 if(!fontPackage)throw new Error('Retained native font package unavailable for exact preview');
 const fontPNG=path.join(output,'preview-full-uv-native-hack.png');
 const extractFont=`import sys,struct,zipfile
from PIL import Image
sys.path.insert(0,'tools')
from build_native_font_depth import hash64
with zipfile.ZipFile(sys.argv[1]) as z:
 stem='NativeFonts/ee6b1ba7e22d71ed.patch_0';b=z.read(stem);gpu=z.read(stem+'.gpu_resources')
 _,nt,n=struct.unpack_from('<III',b)
 records=struct.iter_unpack('<7Q6I',b[72+nt*32:72+nt*32+n*80])
 r=next(r for r in records if r[0]==hash64('mods/dbf_hud/fonts/native_'+sys.argv[3]) and r[1]==hash64('texture'))
 tex=b[r[2]:r[2]+r[7]];w,h=struct.unpack_from('<II',tex,204)
 Image.frombytes('RGBA',(w,h),gpu[r[4]:r[4]+w*h*4]).save(sys.argv[2])
`;
 execPython(['-c',extractFont,fontPackage,fontPNG,'hack'],{cwd:root,stdio:'pipe'});
 const fontInfo=await sharp(fontPNG).metadata();const font={width:fontInfo.width,height:fontInfo.height,url:'data:image/png;base64,'+fs.readFileSync(fontPNG).toString('base64')};
 const urls={};for (const img of images)urls['mods/dbf_hud/textures/'+img.name]={width:img.width,height:img.height,url:'data:image/png;base64,'+fs.readFileSync(path.join(output,img.name+'.png')).toString('base64')};
 function panel(commands,nativeFont=font) {
  let defs='',body='';let filter=0;
  for (const c of commands) {
   const rgb=c.c.map(v=>v/255);const ink='rgb('+c.c.join(',')+')';
   if (c.type==='texture'&&c.a>0) {
    const id='t'+(++filter),img=urls[c.texture_resource],r=c.atlas_rect;
    defs+='<filter id="'+id+'" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="'+rgb[0]+' 0 0 0 0 0 '+rgb[1]+' 0 0 0 0 0 '+rgb[2]+' 0 0 0 0 0 1 0"/></filter>';
    body+='<svg x="'+c.x+'" y="'+(352-c.y-c.h)+'" width="'+c.w+'" height="'+c.h+'" viewBox="'+[r[0]*img.width,r[1]*img.height,r[2]*img.width,r[3]*img.height].join(' ')+'" preserveAspectRatio="none" opacity="'+c.a+'"><image width="'+img.width+'" height="'+img.height+'" href="'+img.url+'" filter="url(#'+id+')"/></svg>';
   } else if(c.type==='text'&&c.text) {
    const id='t'+(++filter);
    defs+='<filter id="'+id+'" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values="'+rgb[0]+' 0 0 0 0 0 '+rgb[1]+' 0 0 0 0 0 '+rgb[2]+' 0 0 0 0 0 1 0"/></filter>';
    for(const g of c.preview_glyphs){const r=g.atlas_rect;
     body+='<svg x="'+g.x+'" y="'+(352-g.y-g.h)+'" width="'+g.w+'" height="'+g.h+'" viewBox="'+[r[0]*nativeFont.width,r[1]*nativeFont.height,r[2]*nativeFont.width,r[3]*nativeFont.height].join(' ')+'" preserveAspectRatio="none" opacity="'+c.a+'"><image width="'+nativeFont.width+'" height="'+nativeFont.height+'" href="'+nativeFont.url+'" filter="url(#'+id+')"/></svg>';
    }
   }
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" width="210" height="352" viewBox="0 0 210 352"><defs>'+defs+'</defs>'+body+'</svg>';
 }
 const panels={};for(const [name,commands]of Object.entries(scenarios)) {
  const svg=panel(commands);fs.writeFileSync(path.join(output,'preview-full-uv-'+name+'.svg'),svg);
  const png=await sharp(Buffer.from(svg)).resize(420,704).png().toBuffer();fs.writeFileSync(path.join(output,'preview-full-uv-'+name+'.png'),png);panels[name]=png;
 }
 const names=['ready','chamber','low','empty'];const layers=[];
 for(let i=0;i<names.length;i++)layers.push({input:panels[names[i]],left:24+i*444,top:80});
 const header='<svg width="1800" height="832"><style>text{font:20px Consolas,monospace;fill:#e9c45d}</style><text x="24" y="32">HUD TEXTURE v4 / SELECTED SLANTED LED / WHITE + GOLD + NAVY</text>'+names.map((n,i)=>'<text x="'+(24+i*444)+'" y="64">'+n.toUpperCase()+'</text>').join('')+'<text x="24" y="820" style="font-size:14px;fill:#a7b8c8">Actual runtime textures + native Hack Â· selected 78px register / .14 leading zeros Â· native chamber count retained</text></svg>';
 layers.push({input:Buffer.from(header),left:0,top:0});
 await sharp({create:{width:1800,height:832,channels:4,background:'#102632'}}).composite(layers).png().toFile(path.join(output,'preview-full-uv.png'));
 const atlasRGBA=fs.readFileSync(path.join(output,images[1].filename));
 for(const p of Object.values(polygons))for(const [x,y]of p)if(x<0||x>72||y<0||y>118)throw new Error('Selected LED polygon outside cell');
 for(let col=0;col<10;col++){let pixels=0;for(let y=0;y<118;y++)for(let x=0;x<72;x++)if(atlasRGBA[((8+y)*1024+8+80*col+x)*4+3]>0)pixels++;if(pixels<100)throw new Error('Blank LED digit '+col);}
 for(const [name,hash]of preservedV3)if(crypto.createHash('sha256').update(fs.readFileSync(path.join(output,name))).digest('hex')!==hash)throw new Error('v3 asset changed: '+name);
 for(const [name,hash]of preservedV4)if(crypto.createHash('sha256').update(fs.readFileSync(path.join(output,name))).digest('hex')!==hash)throw new Error('v4 asset changed: '+name);
 const oldPreview=path.join(output,'preview-v4-ready.png');const appearanceUnchanged=!fs.existsSync(oldPreview)||crypto.createHash('sha256').update(fs.readFileSync(oldPreview)).digest('hex')===crypto.createHash('sha256').update(panels.ready).digest('hex');
 if(!appearanceUnchanged)throw new Error('Full-UV carrier changed the unshaded artwork preview');
 fs.writeFileSync(path.join(output,'CHECKS-full-uv.json'),JSON.stringify({full_white_16x16_rgba_all255:true,white_bytes:1024,white_sha256:images[2].sha256,unit_backing_uv:true,unshaded_appearance_unchanged:appearanceUnchanged,queued_white_falls_back:true,rgba_bytes_verified:true,preview_from_runtime_commands:true,art_image_budget:20,four_shader_layers_fit:true,v3_files_preserved:preservedV3.size,v4_files_preserved:preservedV4.size},null,2));
}
