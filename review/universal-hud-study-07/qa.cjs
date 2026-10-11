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
vm.runInContext(source+';globalThis.api={samples,display,contexts,dimensions,render,maskImage};',context);const {api}=context;
const opts={backing:35,feather:7,dither:40,grain:2,settings:true};
const checks=[];
for(const concept of Object.keys(api.dimensions))for(const [family,sample]of Object.entries(api.samples))for(const state of ['ready','chamber','low','empty','unknown']){
 const m=api.display(sample,state),body=api.render(concept,m,opts);if(/NaN|undefined|null/.test(body))throw Error(`invalid SVG ${concept}/${family}/${state}`);if(state==='unknown'&&!body.includes('NO DATA'))throw Error('unknown state omitted');if(!Array.isArray(api.contexts(m,true)))throw Error('invalid contexts');checks.push([concept,family,state]);
}
if(api.contexts(api.display(api.samples.shells,'ready'),true).length)throw Error('fixed fire mode invented');
if(api.contexts(api.display(api.samples.belt,'ready'),true)[0][1]!=='760 RPM')throw Error('RPM absent');
if(api.contexts(api.display(api.samples.charge,'ready'),true)[0][1]!=='SAFE')throw Error('safety absent');
if(api.contexts(api.display(api.samples.ammo,'ready'),true)[0][1]!=='HEAT')throw Error('ammunition selector absent');
if(api.display(api.samples.magazine,'chamber').mainValue!==46)throw Error('chamber count changed');
if(api.display(api.samples.expendable,'empty').status!=='SPENT')throw Error('spent state changed');
if(api.display(api.samples.expendable,'low').status)throw Error('low ammo invented for a full one-shot weapon');
const stress=api.contexts(api.samples.stress,true);if(stress.length!==4)throw Error('independent settings collapsed');
function svg(w,h,body){return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${body}</svg>`;}
(async()=>{
 const single=[];
 for(const concept of Object.keys(api.dimensions)){
  const [w,h]=api.dimensions[concept],body=api.render(concept,api.display(api.samples.magazine,'chamber'),opts),markup=svg(w+36,h+36,`<defs><linearGradient id="field"><stop stop-color="#26445a"/><stop offset="1" stop-color="#182e3c"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#field)"/><g transform="translate(18 18)">${body}</g>`);
  fs.writeFileSync(path.join(out,`${concept}-chamber.svg`),markup);await sharp(Buffer.from(markup)).resize((w+36)*3,(h+36)*3).png().toFile(path.join(out,`${concept}-chamber.png`));single.push([concept,body,w,h]);
 }
 let comparison=`<rect width="1380" height="385" fill="#0c1826"/>`;
 single.forEach(([concept,body,w,h],i)=>{const x=20+i*455;comparison+=`<rect x="${x}" y="20" width="435" height="344" fill="#1c3344" stroke="#486077"/><text x="${x+23}" y="54" font-family="Consolas,monospace" font-size="17" fill="#e9c45d">${concept.toUpperCase()}</text><text x="${x+23}" y="77" font-family="Consolas,monospace" font-size="11" fill="#a7bdcd">${w} Ã— ${h} px / illustrative 046 chambered</text><g transform="translate(${x+46} 123)">${body}</g>`;});
 const board=svg(1380,385,comparison);fs.writeFileSync(path.join(out,'comparison.svg'),board);await sharp(Buffer.from(board)).png().toFile(path.join(out,'comparison.png'));
 let stressBoard='<rect width="1380" height="385" fill="#0c1826"/>';
 Object.keys(api.dimensions).forEach((concept,i)=>{const [w,h]=api.dimensions[concept],x=20+i*455;stressBoard+=`<rect x="${x}" y="20" width="435" height="344" fill="#1c3344" stroke="#486077"/><text x="${x+23}" y="54" font-family="Consolas,monospace" font-size="17" fill="#e9c45d">${concept.toUpperCase()} / FOUR SETTINGS</text><text x="${x+23}" y="77" font-family="Consolas,monospace" font-size="11" fill="#a7bdcd">Illustrative mixed capability Â· not a real weapon</text><g transform="translate(${x+46} 115)">${api.render(concept,api.display(api.samples.stress,'ready'),opts)}</g>`;});
 const stressSvg=svg(1380,385,stressBoard);fs.writeFileSync(path.join(out,'settings-stress.svg'),stressSvg);await sharp(Buffer.from(stressSvg)).png().toFile(path.join(out,'settings-stress.png'));
 let actual='<rect width="990" height="260" fill="#193246"/>';
 Object.keys(api.dimensions).forEach((concept,i)=>{const x=14+i*330;actual+=`<text x="${x+18}" y="28" font-family="Consolas,monospace" font-size="13" fill="#e9c45d">${concept.toUpperCase()} / 70% GAMEPLAY SIZE</text><g transform="translate(${x+36} 65) scale(.7)">${api.render(concept,api.display(api.samples.magazine,'chamber'),opts)}</g>`;});
 const actualSvg=svg(990,260,actual);fs.writeFileSync(path.join(out,'actual-scale.svg'),actualSvg);await sharp(Buffer.from(actualSvg)).png().toFile(path.join(out,'actual-scale.png'));
 let familyBoard='<rect width="1155" height="920" fill="#0c1826"/><text x="25" y="31" font-family="Consolas,monospace" font-size="18" fill="#e9c45d">ORBIT / ONE HIERARCHY, NINE RESOURCE SYSTEMS</text><text x="25" y="51" font-family="Consolas,monospace" font-size="11" fill="#a8bed0">Illustrative data Â· preview only Â· source-owned units and independently applicable settings</text>';
 Object.entries(api.samples).filter(([family])=>family!=='stress').forEach(([family,sample],i)=>{const x=20+(i%3)*378,y=72+Math.floor(i/3)*280,m=api.display(sample,family==='magazine'?'chamber':'ready');familyBoard+=`<rect x="${x}" y="${y}" width="365" height="265" fill="#1c3344" stroke="#486077"/><text x="${x+15}" y="${y+24}" font-family="Consolas,monospace" font-size="12" fill="#e6eded">${sample.title}</text><g transform="translate(${x+12} ${y+43})">${api.render('orbit',m,opts)}</g>`;});
 const families=svg(1155,920,familyBoard);fs.writeFileSync(path.join(out,'family-overview.svg'),families);await sharp(Buffer.from(families)).png().toFile(path.join(out,'family-overview.png'));
 fs.writeFileSync(path.join(out,'CHECKS.json'),JSON.stringify({composition_cases:checks.length,concepts:Object.keys(api.dimensions),families:Object.keys(api.samples),states:5,unknown_is_not_zero:true,selected_contexts_present:true,four_independent_settings_stress_passed:true,unsupported_fields_not_fabricated:true,gameplay_default_scale:.7,reference_pixels:[1920,1080],mask_algorithm:'smoothstep + static 4x4 ordered threshold mixture',browser_layout_verified:false,browser_limitation:'file protocol URL policy',asset_rasterization:'Sharp standalone SVG',source_or_deployment_mutations:false},null,2)+'\n');console.log(`${checks.length} composition cases passed; three SVG/PNG snapshots and comparison.png generated.`);
})().catch(error=>{console.error(error);process.exitCode=1;});
