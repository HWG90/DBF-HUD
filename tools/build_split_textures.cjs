// Authored Split 08 artwork. Offline rasterization only; no game/native calls.
'use strict';
const fs=require('fs'),path=require('path'),crypto=require('crypto'),vm=require('vm');
const {getSharp}=require('./runtime_dependencies.cjs');const sharp=getSharp();
const root=path.resolve(__dirname,'..'),out=path.join(root,'assets/split-hud'),review=path.join(root,'dist/split-hud-in-game-20261011');
const source='review/universal-hud-split-08/study.js',study=fs.readFileSync(path.join(root,source),'utf8');
fs.mkdirSync(out,{recursive:true});fs.mkdirSync(review,{recursive:true});
function expect(ok,message){if(!ok)throw Error(message)}
function hash(bytes){return crypto.createHash('sha256').update(bytes).digest('hex')}
function literal(expression){return vm.runInNewContext('('+expression+')',Object.create(null))}
const led=literal(study.match(/const led=(\{[^\n]+\});/)[1]),patterns=literal(study.match(/const digitPatterns=(\[[^\n]+\]);/)[1]);
const paths=literal(study.match(/const paths=(\{[^\n]+\});/)[1]);
const polygons=Object.fromEntries(Object.entries(led).map(([key,points])=>[key,points.map(([x,y])=>[3+x+8*(1-y/118),y])]));
const prior=JSON.parse(fs.readFileSync(path.join(root,'assets/segmented-fancy/TEXTURES-v4.json'),'utf8'));
expect(JSON.stringify(polygons)===JSON.stringify(prior.digit_polygons),'The approved slanted LED polygon changed');
const W=320,H=161,AW=1024,AH=512,R=2,defaults={feather:7,curve:1,dither:40,grain:2};
const bayer=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5];
function uv(x,y,w,h,aw=AW,ah=AH){return [x/aw,y/ah,w/aw,h/ah]}
function alphaAt(x,y,settings=defaults){
 const xx=x-72,yy=y-19,w=164,h=121;if(xx<0||yy<0||xx>w-1||yy>h-1)return 0;
 const edge=Math.min(w,h)*settings.feather/100,d=Math.min(xx,yy,w-1-xx,h-1-yy);
 let a=edge?Math.max(0,Math.min(1,d/edge)):1;a=(a*a*(3-2*a))**settings.curve;
 const bx=Math.floor(xx/settings.grain)%4,by=Math.floor(yy/settings.grain)%4,t=(bayer[by*4+bx]+.5)/16,mix=settings.dither/100;
 return a*(1-mix)+(a>t?1:0)*mix;
}
function digit(pattern,quiet=false){
 return Object.entries(polygons).map(([key,points])=>{const active=pattern.includes(key),opacity=active?(quiet?.12:1):.075;
  // Black stroke is converted to transparent alpha after rasterization. The user's
  // selected navy backing supplies the cap outline, keeping every RGB texel white.
  return '<polygon points="'+points.map(p=>p.join(',')).join(' ')+'" fill="white" opacity="'+opacity+'" stroke="black" stroke-width=".8" stroke-linejoin="round"/>';
 }).join('');
}
const numeric={normal:[],quiet:[],width:72,height:118,pitch:76,baseline:118,ghost_alpha:.075,quiet_active_alpha:.12,outline_width:.8};
let atlasBody='';
for(let row=0;row<2;row++)for(let column=0;column<12;column++){
 const x=8+column*80,y=8+row*136,pattern=column<10?patterns[column]:column===10?'g':'';
 atlasBody+='<g transform="translate('+x+' '+y+')">'+digit(pattern,row===1)+'</g>';
 numeric[row?'quiet':'normal'].push(uv(x,y,72,118));
}
const icons={};Object.entries(paths).forEach(([name,d],i)=>{
 const x=8+i*32,y=288;atlasBody+='<g transform="translate('+(x+2)+' '+(y+2)+')" fill="none" stroke="white" stroke-width="1.1" stroke-linejoin="round" stroke-linecap="round"><path d="'+d+'"/></g>';
 icons[name]={uv:uv(x,y,18,18),width:18,height:18,ink_offset:[2,2]};
});
const fallbackX=8+Object.keys(paths).length*32;
atlasBody+='<g transform="translate('+(fallbackX+2)+' 290)" fill="none" stroke="white" stroke-width="1.1"><path d="M1 2H11V12H1ZM1 7H11"/></g>';
icons.UNKNOWN={uv:uv(fallbackX,288,18,18),width:18,height:18,ink_offset:[2,2]};
// Full gauge track plus calibrated tick rail share one texture image.
atlasBody+='<path d="M9 353.5H143" stroke="white" stroke-opacity=".18" stroke-width="3"/>';
for(let i=0;i<=8;i++)atlasBody+='<path d="M'+(9+i*134/8)+' 357.5V359.5" stroke="white" stroke-width=".7" stroke-opacity=".23"/>';
atlasBody+='<path d="M161 353.5H171" stroke="white" stroke-width="1" stroke-opacity=".6"/>';
atlasBody+='<path d="M193 361H201" stroke="white" stroke-width=".8" stroke-opacity=".32"/><path d="M203 352V369" stroke="white" stroke-width=".8" stroke-opacity=".6"/>';
atlasBody+='<path d="M243 352V369" stroke="white" stroke-width="3"/>';
atlasBody+='<rect x="272" y="352" width="16" height="16" fill="white"/>';
const sprites={gauge:{uv:uv(8,352,136,10),box:[87,109.5,136,10]},reserve_connector:{uv:uv(160,352,12,3),box:[61,78.5,12,3]},context_connector:{uv:uv(192,350,14,21),box:[232,46,14,21]},context_shadow:{uv:uv(232,350,14,21),box:[232,46,14,21]},solid:{uv:uv(274,354,12,12)}};
// Combined symbol + connecting rail takes one image per present setting.
const contextNodes={};
for(const [i,kind]of ['AUTO','RPM','AMMO','SAFE','SINGLE'].entries()){
 const x=8+i*40,y=312;
 atlasBody+='<g transform="translate('+x+' '+y+')"><path d="M1 9H9" stroke="white" stroke-width=".8" stroke-opacity=".32"/><path d="M11 0V17" stroke="white" stroke-width=".8" stroke-opacity=".6"/><g transform="translate(16 2) scale(.75)" fill="none" stroke="white" stroke-width="1.1" stroke-linejoin="round" stroke-linecap="round"><path d="'+paths[kind]+'"/></g></g>';
 contextNodes[kind]={uv:uv(x,y,32,20),box:[232,48,32,20]};
}
const inspectContextNodes={};
for(const [i,kind]of ['AUTO','RPM','AMMO','SAFE','SINGLE'].entries()){
 const x=320+i*60,y=352;
 atlasBody+='<g transform="translate('+x+' '+y+')"><path d="M1 9H30" stroke="white" stroke-width=".8" stroke-opacity=".32"/><path d="M32 0V17" stroke="white" stroke-width=".8" stroke-opacity=".6"/><g transform="translate(37 2) scale(.75)" fill="none" stroke="white" stroke-width="1.1" stroke-linejoin="round" stroke-linecap="round"><path d="'+paths[kind]+'"/></g></g>';
 inspectContextNodes[kind]={uv:uv(x,y,56,20),box:[232,33,56,20]};
}
const outlines=[];
for(let column=0;column<12;column++){
 const x=8+column*80,y=384,pattern=column<10?patterns[column]:column===10?'g':'';
 atlasBody+='<g transform="translate('+x+' '+y+')">'+Object.entries(polygons).map(([key,points])=>'<polygon points="'+points.map(p=>p.join(',')).join(' ')+'" fill="none" stroke="white" stroke-width=".8" stroke-linejoin="round" opacity="'+(pattern.includes(key)?1:.075)+'"/>').join('')+'</g>';
 outlines.push(uv(x,y,72,118));
}
// Infinite energy remains a symbol, not a fabricated numeric resource reading.
// Two linked lobes form a continuous instrument glyph, with a separately tintable
// outline so it stays legible even with the backing completely transparent.
const infinityPath='M5 24C5 12 12 5 23 5C37 5 44 19 55 31C63 39 68 43 77 43C88 43 95 36 95 24C95 12 88 5 77 5C63 5 56 19 45 31C37 39 32 43 23 43C12 43 5 36 5 24Z';
atlasBody+='<g transform="translate(512 288)" fill="none" stroke="white" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"><path d="'+infinityPath+'"/></g>';
atlasBody+='<g transform="translate(624 288)" fill="none" stroke="white" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"><path d="'+infinityPath+'"/></g>';
const infinity={uv:uv(512,288,100,48),width:60,height:32,box:[88,61,60,32]},infinityOutline={uv:uv(624,288,100,48),width:60,height:32,box:[88,61,60,32]};
// Only a leading zero uses the quiet mode. Preserve inactive .075 outlines
// independently of the .12 active strokes, matching the approved Study glyph.
atlasBody+='<g transform="translate(800 264)">'+Object.entries(polygons).map(([key,points])=>'<polygon points="'+points.map(p=>p.join(',')).join(' ')+'" fill="none" stroke="white" stroke-width=".8" stroke-linejoin="round" opacity="'+(patterns[0].includes(key)?.12:.075)+'"/>').join('')+'</g>';
const quietZeroOutlineUV=uv(800,264,72,118);
const svg=(width,height,body,view)=>'<svg xmlns="http://www.w3.org/2000/svg" width="'+width+'" height="'+height+'"'+(view?' viewBox="'+view+'"':'')+'>'+body+'</svg>';
const atlas=svg(AW*R,AH*R,atlasBody,'0 0 '+AW+' '+AH),face=svg(W*R,H*R,'<path d="M77 26V126M77 26H113M229 126H193" fill="none" stroke="white" stroke-width="1" opacity=".65"/>','0 0 '+W+' '+H);
async function saveSVG(name,width,height,markup,luminanceAlpha=false){
 fs.writeFileSync(path.join(out,name+'.svg'),markup);
 const {data,info}=await sharp(Buffer.from(markup)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
 expect(info.width===width&&info.height===height&&info.channels===4,'Invalid raster dimensions '+name);
 for(let i=0;i<data.length;i+=4){if(luminanceAlpha)data[i+3]=Math.round(data[i+3]*data[i]/255);data[i]=data[i+1]=data[i+2]=255;}
 return saveRaw(name,width,height,data);
}
async function saveRaw(name,width,height,data){
 const sha256=hash(data),filename=name+'_'+sha256+'.rgba';fs.writeFileSync(path.join(out,filename),data);
 await sharp(data,{raw:{width,height,channels:4}}).png().toFile(path.join(out,name+'.png'));
 return {name,resource:'mods/dbf_hud/textures/'+name,width,height,filename,sha256,bytes:data.length};
}
function coverage(settings){
 const width=W*R,height=H*R,data=Buffer.alloc(width*height*4,255);
 for(let y=0;y<height;y++)for(let x=0;x<width;x++){
  const sx=x/R,sy=y/R,inside=sx>=77&&sx<228&&sy>=25&&sy<133;
  data[(y*width+x)*4+3]=inside?Math.round(255*alphaAt(sx,sy,settings)):0;
 }return data;
}
async function preview(images){
 const urls={};for(const p of images)urls[p.name]='data:image/png;base64,'+fs.readFileSync(path.join(out,p.name+'.png')).toString('base64');
 const defs='<filter id="gold" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values=".914 0 0 0 0 0 .769 0 0 0 0 0 .365 0 0 0 0 0 1 0"/></filter><filter id="navy" color-interpolation-filters="sRGB"><feColorMatrix type="matrix" values=".0353 0 0 0 0 0 .1059 0 0 0 0 0 .2078 0 0 0 0 0 1 0"/></filter>';
 function crop(rect,x,y,w,h,color){return '<svg x="'+x+'" y="'+y+'" width="'+w+'" height="'+h+'" viewBox="'+[rect[0]*AW,rect[1]*AH,rect[2]*AW,rect[3]*AH].join(' ')+'" preserveAspectRatio="none"><image width="1024" height="512" href="'+urls.split_hud_atlas_v1+'"'+(color?' filter="url(#'+color+')"':'')+'/></svg>'}
 const text=(x,y,s,size=11.5,color='#f5f6f0',anchor='start')=>'<text x="'+x+'" y="'+y+'" fill="'+color+'" font-size="'+size+'" font-family="Consolas,monospace" text-anchor="'+anchor+'" stroke="#091b35" stroke-width="1.3" paint-order="stroke fill">'+s+'</text>';
 let body='<rect width="320" height="161" fill="#1c3344"/><image width="320" height="161" href="'+urls.split_hud_coverage_v1+'" filter="url(#navy)" opacity=".35"/><image width="320" height="161" href="'+urls.split_hud_face_v1+'" filter="url(#gold)"/>';
 body+=text(87,16,'AR-23',10,'#e9c45d')+text(87,43,'ROUNDS',11.5,'#e9c45d');
 [4,6].forEach((d,i)=>{body+=crop(outlines[d],88+i*76*48/118,53,72*48/118,48,'navy');body+=crop(numeric.normal[d],88+i*76*48/118,53,72*48/118,48)});
 body+=crop(sprites.gauge.uv,...sprites.gauge.box)+crop(sprites.solid.uv,88,109.5,134,3,'gold')+text(222,122,'/ 45',11,'#f5f6f0','end');
 body+=crop(sprites.reserve_connector.uv,...sprites.reserve_connector.box,'gold')+crop(icons.MAGS.uv,8.2,46.2,16.2,16.2,'gold')+text(29,71,'6',29)+text(10,87,'MAGS');
 body+=crop(sprites.context_shadow.uv,...sprites.context_shadow.box,'navy')+crop(sprites.context_connector.uv,...sprites.context_connector.box,'gold')+crop(icons.AUTO.uv,246.5,48.5,13.5,13.5,'gold')+text(264,61,'AUTO',11.5,'#e9c45d');
 body+='<rect x="87" y="141" width="166" height="18" fill="#091b35" opacity=".58"/>'+crop(sprites.solid.uv,85.5,141,3,18,'gold')+text(97,153.5,'CHAMBERED +1',11.5,'#e9c45d');
 const markup=svg(960,483,'<defs>'+defs+'</defs>'+body,'0 0 320 161');fs.writeFileSync(path.join(review,'asset-preview.svg'),markup);await sharp(Buffer.from(markup)).png().toFile(path.join(review,'asset-preview.png'));
 const strip=svg(1112,292,'<rect width="1112" height="292" fill="#102234"/><image x="24" y="24" width="1024" height="256" href="'+urls.split_hud_atlas_v1+'"/>');
 fs.writeFileSync(path.join(review,'atlas-review.svg'),strip);await sharp(Buffer.from(atlas)).png().toFile(path.join(review,'atlas.png'));
}
async function main(){
 const images=[await saveSVG('split_hud_face_v1',W*R,H*R,face),await saveSVG('split_hud_atlas_v1',AW*R,AH*R,atlas,true),await saveRaw('split_hud_coverage_v1',W*R,H*R,coverage(defaults)),await saveRaw('split_hud_hard_coverage_v1',W*R,H*R,coverage({...defaults,feather:0,dither:0}))];
 // Alpha assertions cover intentional open space, not just image bounds.
 const raw=fs.readFileSync(path.join(out,images[2].filename));for(const [x,y]of [[10,60],[62,80],[250,55],[87,150],[0,0],[319,160]])expect(raw[((y*R)*(W*R)+x*R)*4+3]===0,'Backing leaked into the open cluster');
 expect(raw[((80*R)*(W*R)+150*R)*4+3]===255,'Main coverage center is not opaque');
 for(const p of images){const b=fs.readFileSync(path.join(out,p.filename));for(let i=0;i<b.length;i+=4)expect(b[i]===255&&b[i+1]===255&&b[i+2]===255,'Hardcoded RGB prevents palette tint');}
 const atlasBytes=fs.readFileSync(path.join(out,images[1].filename));
 expect(images[1].width===2048&&images[1].height===1024&&atlasBytes.length===8388608,'Physical 2x atlas shape/byte budget mismatch');
 function pixelsIn(rect){let count=0;const [x,y,w,h]=rect.map(n=>Math.round(n*R));for(let j=y;j<y+h;j++)for(let i=x;i<x+w;i++)if(atlasBytes[(j*2048+i)*4+3]>0)count++;return count;}
 for(let column=0;column<12;column++)expect(pixelsIn([8+column*80,8,72,118])>100,'Blank physical numeric cell '+column);
 for(const p of Object.values(icons))expect(pixelsIn([p.uv[0]*AW,p.uv[1]*AH,p.uv[2]*AW,p.uv[3]*AH])>5,'Blank physical symbol cell');
 expect(pixelsIn([800,264,72,118])>100&&pixelsIn([512,288,100,48])>100&&pixelsIn([624,288,100,48])>100,'Blank quiet/infinity physical cell');
 const metadata={version:1,format:'straight RGBA8',rgb_all_pixels:[255,255,255],design_source:source,design_sha256:hash(study),canvas:[W,H],gameplay_scale:.7,gameplay_reference_pixels:[224,112.7],atlas_size:[AW,AH],full_uv:[0,0,1,1],face_uv:[0,0,1,1],numeric,icons,sprites,context_nodes:contextNodes,inspect_context_nodes:inspectContextNodes,outlines,infinity,infinity_outline:infinityOutline,polygons,study_polygon_match:true,outline:'separate white stroke cells tint to the selected navy palette; cap inset .8 preserves the stroke beneath lit/ghost cells',images,total_bytes:images.reduce((s,p)=>s+p.bytes,0),mask_defaults:defaults,coverage:{soft_bounds:[72,19,164,121],backing_bounds:[77,25,151,108],empty_space_preserved:true,all_pods_share_full_canvas_uv:true,dynamic_optional_pods:'reserve/settings/status remain transparent unless the compositor supplies separately controlled pod coverage'},layout:{main:{identity:[87,16,10],label:[87,43,11.5],numeral:[88,53,48],suffix_baseline:97,capacity:[222,122,11,'right'],gauge:[88,111,134]},secondary:{numeral:[29,71,29],unit:[10,87,11.5],icon:[10,48,.9]},context:{x:247,baseline:61,step:23,icon:[248,50,.75],label:[264,61,11.5],inspect:{x:268,baseline:46,step:29,label:[286,36,8.5],value:[286,49,11.5]}},status:{backing:[87,141,166,18],bar:[85.5,141,3,18],label:[97,153.5,11.5]},depth_px:{main:16,secondary:-8,context:28.8,status:0}},coordinate_conversion:'top-left box [x,y,w,h] to bottom-left [x,161-y-h,w,h]; text baseline y to161-y'};
 metadata.quiet_zero_outline_uv=quietZeroOutlineUV;
 metadata.atlas_coordinate_units='logical 1024x512 units; normalized UVs unchanged';metadata.atlas_pixel_dimensions=[2048,1024];metadata.atlas_raster_scale=R;
 fs.writeFileSync(path.join(out,'TEXTURES.json'),JSON.stringify(metadata,null,2)+'\n');fs.writeFileSync(path.join(out,'manifest-additions.tsv'),images.map(p=>[p.name,p.width,p.height,p.filename].join('\t')).join('\n')+'\n');
 fs.writeFileSync(path.join(out,'CHECKS.json'),JSON.stringify({passed:true,study_polygon_match:true,normal_digit_cells:12,quiet_digit_cells:12,symbols:Object.keys(icons),palette_tintable_white_rgb:true,open_space_coverage_verified:true,three_digit_supported:true,unknown_dash_supported:true,infinite_energy_symbol:true,independent_infinity_outline:true,physical_atlas_dimensions:[2048,1024],physical_atlas_bytes:8388608,physical_glyph_and_symbol_pixels_verified:true,normalized_uvs_unchanged:true,full_uv_coverage:true,rgba_bytes_verified:true,no_game_or_native_calls:true},null,2)+'\n');
 const lua='-- Generated by tools/build_split_textures.cjs. Authored top-left Study 08 coordinates.\nlocal M={width=320,height=161,gameplay_scale=.7,face="mods/dbf_hud/textures/split_hud_face_v1",atlas="mods/dbf_hud/textures/split_hud_atlas_v1",coverage="mods/dbf_hud/textures/split_hud_coverage_v1",hard_coverage="mods/dbf_hud/textures/split_hud_hard_coverage_v1",material="mods/dbf_hud/materials/adjudicator_tall_v1",full_uv={0,0,1,1},digit_width=72,digit_height=118,digit_pitch=76,digit_y=8,digit_step=80,digit_x=8,atlas_width=1024,atlas_height=512}\nM.icons={\n'+Object.entries(icons).map(([name,p])=>' '+name+'={uv={'+p.uv.join(',')+'},w=18,h=18,ink_x=2,ink_y=2},').join('\n')+'\n}\nM.sprites={\n'+Object.entries(sprites).map(([name,p])=>' '+name+'={uv={'+p.uv.join(',')+'}'+(p.box?',box={'+p.box.join(',')+'}':'')+'},').join('\n')+'\n}\nM.context_nodes={\n'+Object.entries(contextNodes).map(([name,p])=>' '+name+'={uv={'+p.uv.join(',')+'},box={'+p.box.join(',')+'}},').join('\n')+'\n}\nfunction M.digit_uv(column,quiet)return {(8+80*column)/1024,(quiet and 144 or 8)/512,72/1024,118/512}end\nfunction M.outline_uv(column)return {(8+80*column)/1024,384/512,72/1024,118/512}end\nreturn M\n';
 fs.writeFileSync(path.join(root,'src/split_hud_assets.lua'),lua.replace('return M\n','M.inspect_context_nodes={\n'+Object.entries(inspectContextNodes).map(([name,p])=>' '+name+'={uv={'+p.uv.join(',')+'},box={'+p.box.join(',')+'}},').join('\n')+'\n}\nM.infinity={uv={'+infinity.uv.join(',')+'},w=60,h=32,box={88,61,60,32}}\nM.infinity_outline={uv={'+infinityOutline.uv.join(',')+'},w=60,h=32,box={88,61,60,32}}\nM.quiet_zero_outline_uv={'+quietZeroOutlineUV.join(',')+'}\nM.atlas_pixel_dimensions={2048,1024}\nreturn M\n'));await preview(images);
 console.log('Built '+images.length+' Split textures; '+metadata.total_bytes+' RGBA bytes; source='+metadata.design_sha256);
}
main().catch(e=>{console.error(e.stack);process.exitCode=1});
