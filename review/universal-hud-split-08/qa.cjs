/* Asset/composition QA only: no browser or computer UI is controlled here. */
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),zlib=require('node:zlib');
const os=require('node:os');
let sharp;
try { sharp=require(process.env.DBF_HUD_SHARP_MODULE||'sharp'); }
catch (error) { if(process.env.DBF_HUD_SHARP_MODULE)throw error; sharp=require(path.join(os.homedir(),'.cache','codex-runtimes','codex-primary-runtime','dependencies','node','node_modules','sharp')); }
const out=__dirname;
const crcTable=Array.from({length:256},(_,n)=>{let c=n;for(let k=0;k<8;k++)c=(c&1)?0xedb88320^(c>>>1):c>>>1;return c>>>0;});
function chunk(type,bytes){const b=Buffer.alloc(bytes.length+12);b.writeUInt32BE(bytes.length,0);b.write(type,4);bytes.copy(b,8);let c=0xffffffff;for(const v of b.subarray(4,-4))c=crcTable[(c^v)&255]^(c>>>8);b.writeUInt32BE((c^0xffffffff)>>>0,b.length-4);return b;}
function png(w,h,pixels){const header=Buffer.alloc(13);header.writeUInt32BE(w,0);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;const raw=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)Buffer.from(pixels.buffer,pixels.byteOffset+y*w*4,w*4).copy(raw,y*(w*4+1)+1);return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',zlib.deflateSync(raw)),chunk('IEND',Buffer.alloc(0))]);}
function canvas(){return {width:0,height:0,pixels:null,getContext(){const self=this;return {createImageData(w,h){return {data:new Uint8ClampedArray(w*h*4)};},putImageData(image){self.pixels=image.data;}};},toDataURL(){return 'data:image/png;base64,'+png(this.width,this.height,this.pixels).toString('base64');}};}
const source=fs.readFileSync(path.join(out,'study.js'),'utf8').split('Object.entries(samples).forEach')[0];
const context=vm.createContext({document:{createElement(type){if(type!=='canvas')throw Error('unexpected DOM request');return canvas();}},console,Uint8ClampedArray});
vm.runInContext(source+';globalThis.api={samples,display,contexts,dimensions,layoutSize,render,maskImage};',context);const {api}=context;

const opts={backing:35,feather:7,dither:40,grain:2,settings:true,readoutView:'combat'};
const checks=[];
for(const readoutView of ['combat','inspect'])for(const [family,sample]of Object.entries(api.samples))for(const state of ['ready','chamber','low','empty','unknown']){
 const m=api.display(sample,state),body=api.render('split',m,{...opts,readoutView});
 if(/NaN|undefined|null/.test(body))throw Error(`invalid SVG ${readoutView}/${family}/${state}`);
 if(state==='unknown'&&!body.includes('NO DATA'))throw Error('unknown state omitted');
 const expected=api.contexts(m,true).length,actual=(body.match(/data-context=/g)||[]).length;
 if(actual!==expected)throw Error(`context lost ${readoutView}/${family}/${state}`);
 checks.push([readoutView,family,state]);
}
if(api.contexts(api.display(api.samples.shells,'ready'),true).length)throw Error('fixed fire mode invented');
if(api.display(api.samples.magazine,'ready').status==='CHAMBERED +1')throw Error('chamber bonus inferred from ordinary count');
if(api.display(api.samples.magazine,'chamber').mainValue!==46)throw Error('native chamber count changed');
if(api.display(api.samples.expendable,'empty').status!=='SPENT')throw Error('spent state lost');
if(api.display(api.samples.expendable,'low').status)throw Error('low ammo invented for a full one-shot weapon');
if(api.contexts(api.samples.stress,true).length!==4)throw Error('independent settings collapsed');
for(const readoutView of ['combat','inspect'])if((api.render('split',api.display(api.samples.stress,'ready'),{...opts,settings:false,readoutView}).match(/data-context=/g)||[]).length!==4)throw Error('needed selected values hidden');
function svg(w,h,body){return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;}
async function write(name,w,h,body,scale=1){const markup=svg(w,h,body);fs.writeFileSync(path.join(out,name+'.svg'),markup);await sharp(Buffer.from(markup)).resize(Math.round(w*scale),Math.round(h*scale)).png().toFile(path.join(out,name+'.png'));}
const field='<rect width="100%" height="100%" fill="#1c3344"/>';
const label=(x,y,s,size=12,color='#e9c45d')=>`<text x="${x}" y="${y}" font-family="Consolas,monospace" font-size="${size}" fill="${color}">${s}</text>`;
(async()=>{
 const chamber=api.display(api.samples.magazine,'chamber');
 await write('split-combat-chamber',356,197,field+`<g transform="translate(18 18)">${api.render('split',chamber,opts)}</g>`,3);
 await write('split-inspect-settings',446,214,field+`<g transform="translate(18 18)">${api.render('split',api.display(api.samples.stress,'ready'),{...opts,readoutView:'inspect'})}</g>`,3);
 let comparison='<rect width="1170" height="360" fill="#0c1826"/>';
 const examples=[['AMMUNITION / CHAMBERED +1',chamber],['CHARGE / SAFETY',api.display(api.samples.charge,'ready')],['FOUR INDEPENDENT SETTINGS',api.display(api.samples.stress,'ready')]];
 examples.forEach(([title,m],i)=>{const x=15+i*385;comparison+=`<rect x="${x}" y="18" width="375" height="325" fill="#1c3344" stroke="#486077"/>`+label(x+18,49,title,14)+label(x+18,69,'SPLIT / SELECTED DIRECTION / REVIEW ONLY',10,'#a7bdcd')+`<g transform="translate(${x+21} 118)">${api.render('split',m,opts)}</g>`;});
 await write('comparison',1170,360,comparison);
 let actual='<rect width="930" height="250" fill="#193246"/>';
 [['NORMAL','ready'],['CHAMBERED +1','chamber'],['EMPTY / FLASHES AT 2 HZ','empty']].forEach(([title,state],i)=>{const x=15+i*305;actual+=label(x+10,28,title,12)+label(x+10,44,'70% / ~224 Ã— 113 reference pixels',9,'#a7bdcd')+`<g transform="translate(${x+24} 76) scale(.7)">${api.render('split',api.display(api.samples.magazine,state),opts)}</g>`;});
 await write('actual-scale',930,250,actual);
 let stressBoard='<rect width="940" height="355" fill="#0c1826"/>';
 ['combat','inspect'].forEach((readoutView,i)=>{const x=15+i*460;stressBoard+=`<rect x="${x}" y="18" width="450" height="320" fill="#1c3344" stroke="#486077"/>`+label(x+18,49,readoutView==='combat'?'COMBAT / SELECTED VALUES':'INSPECT / FIELD NAMES + VALUES',14)+label(x+18,70,'Illustrative mixed capability, not a real weapon',10,'#a7bdcd')+`<g transform="translate(${x+23} 111)">${api.render('split',api.display(api.samples.stress,'ready'),{...opts,readoutView})}</g>`;});
 await write('settings-stress',940,355,stressBoard);
 let families='<rect width="1155" height="920" fill="#0c1826"/>'+label(25,31,'SPLIT / ONE OPEN CLUSTER, NINE RESOURCE SYSTEMS',18)+label(25,51,'Selected direction Â· illustrative values Â· source-owned units Â· independently applicable settings',11,'#a8bed0');
 Object.entries(api.samples).filter(([family])=>family!=='stress').forEach(([family,sample],i)=>{const x=20+(i%3)*378,y=72+Math.floor(i/3)*280,m=api.display(sample,family==='magazine'?'chamber':'ready');families+=`<rect x="${x}" y="${y}" width="365" height="265" fill="#1c3344" stroke="#486077"/>`+label(x+15,y+24,sample.title,12,'#e6eded')+`<g transform="translate(${x+17} ${y+65})">${api.render('split',m,opts)}</g>`;});
 await write('family-overview',1155,920,families);
 fs.writeFileSync(path.join(out,'CHECKS.json'),JSON.stringify({composition_cases:checks.length,direction:'Split',selected_by:'David',selection_date:'2026-10-11',families:Object.keys(api.samples),states:5,context_views:['combat','inspect'],known_selected_values_preserved_in_both_views:true,four_independent_settings_stress_passed:true,chamber_bonus_requires_verified_capacity_plus_one:true,unknown_is_not_zero:true,fixed_modes_omitted:true,unsupported_fields_not_fabricated:true,gameplay_default_scale:.7,reference_pixels:[1920,1080],critical_reference_label_size:11.5,optional_reference_fallback:'neutral field with message',browser_layout_verified:false,browser_limitation:'file protocol URL policy; no workaround used',asset_rasterization:'Sharp standalone SVG',runtime_implementation_claimed:false,source_or_deployment_mutations:false},null,2)+'\n');
 console.log(`${checks.length} Split family/state/context compositions passed; 6 standalone SVG/PNG review assets generated.`);
})().catch(error=>{console.error(error);process.exitCode=1;});
