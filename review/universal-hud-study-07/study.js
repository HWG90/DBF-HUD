/* Offline, code-native spatial study. Illustrative data; no game API or runtime writes. */
'use strict';
const C={white:'#f5f6f0',gold:'#e9c45d',navy:'#091b35',muted:'#93aabd',red:'#ff5750'};
const samples={
 magazine:{title:'Magazine',code:'AR-23',name:'LIBERATOR',kind:'magazine',value:27,capacity:45,reserve:6,reserve_kind:'MAGS',fire_mode:'AUTO',label:'ROUNDS',fraction:.6,chamber_supported:true,description:'Rounds dominate. Magazine capacity sits beside the count; spare magazines form a small separate reading. Fire select appears because this example has a selectable mode.'},
 belt:{title:'Belt / selectable RPM',code:'MG-43',name:'MACHINE GUN',kind:'magazine',value:146,capacity:175,reserve:2,reserve_kind:'BELTS',rpm:760,label:'ROUNDS',fraction:146/175,description:'The same register accepts three digits. A single selected rate appears only when a selectable RPM value is available; fixed fire select stays absent.'},
 shells:{title:'Individual shells',code:'SG-8',name:'PUNISHER',kind:'rounds',value:9,capacity:16,reserve:34,reserve_kind:'SHELLS',label:'SHELLS',fraction:9/16,description:'Loose shells stay loose shells. The secondary reading names the reserve unit clearly; a fixed semi-auto mode does not occupy a selector row.'},
 heat:{title:'Heat / energy',code:'LAS-16',name:'SICKLE',kind:'heat',value:38,suffix:'%',reserve:3,reserve_kind:'SINKS',label:'HEAT',fraction:.38,description:'Heat replaces the ammunition count and fills the same gauge. Heat sinks remain a typed reserve. HOT and VENTING are explicit states, not ambiguous colors.'},
 charge:{title:'Charge / safety',code:'RS-422',name:'RAILGUN',kind:'rounds',value:1,capacity:1,reserve:16,reserve_kind:'SHOTS',label:'CHARGE',charge_fraction:.68,safety_mode:'SAFE',description:'While charging, the percentage takes priority. The loaded shot remains visible below it. Safety and spare shots stay separate; a dangerous release threshold is not invented.'},
 ammo:{title:'Ammunition selector',code:'GR-8',name:'RECOILLESS',kind:'rounds',value:1,capacity:1,reserve:5,reserve_kind:'PACK',label:'LOADED',ammo_mode:'HEAT',fraction:1,description:'Selected ammunition occupies one compact context node. The reserve unit is kept as PACK, matching the reader contract; it is not relabeled as magazines.'},
 expendable:{title:'Expendable',code:'EAT-17',name:'EXPENDABLE',kind:'rounds',value:1,capacity:1,label:'LOADED',reloadable:false,fraction:1,description:'One loaded shot and SINGLE USE. There is no invented reserve count or empty magazine capacity. After firing, the instrument clearly says SPENT.'},
 fuel:{title:'Fuel',code:'FLAM-66',name:'TORCHER',kind:'magazine',value:65,capacity:80,reserve:3,reserve_kind:'TANKS',label:'FUEL',fraction:65/80,description:'Fuel retains its own resource label and tank reserves. The gauge gives an immediate proportion while the numeric reading remains precise.'},
 infinite:{title:'Infinite energy',code:'ARC-12',name:'BLITZER',kind:'infinite',value:'∞',label:'ENERGY',fraction:1,description:'An infinite supply has no fabricated ammunition or reserve counts. The energy symbol expresses the resource concept; the runtime currently carries an infinite kind with a -- value.'},
 stress:{title:'Mixed settings · illustrative',code:'TEST',name:'CONTEXT STRESS',kind:'magazine',value:123,capacity:200,reserve:8,reserve_kind:'BELTS',fire_mode:'AUTO',rpm:900,ammo_mode:'HE',safety_mode:'UNSAFE',label:'ROUNDS',fraction:123/200,description:'A deliberate mixed-capability specimen, not an assertion about a real weapon. Fire mode, RPM, ammunition selection, and safety occupy four independent context slots. Orbit and Split stack the satellites vertically; Rail distributes them across the lower row.'}
};
const photos=[
 'reference/angle-1.png',
 'reference/angle-2.png',
 'reference/angle-3.png',
 'reference/angle-4.png'
];
const poses=[{x:1015,y:748,yaw:-18,pitch:10,roll:-3},{x:924,y:765,yaw:-27,pitch:8,roll:-7},{x:918,y:820,yaw:-38,pitch:18,roll:-12},{x:976,y:740,yaw:-25,pitch:9,roll:-6}];
const dimensions={orbit:[330,190],rail:[330,160],split:[320,161]};
const titles={orbit:'Orbit',rail:'Rail',split:'Split'};
const $=id=>document.getElementById(id),esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&apos;'}[c]));
let selected='orbit',view='fit',serial=0,customPosition=null,missingReference=false;
const maskCache=new Map();
const led={a:[[8,0],[51,0],[57,6],[50,12],[9,12],[3,6]],b:[[54,8],[60,14],[60,51],[54,57],[48,51],[48,14]],c:[[54,61],[60,67],[60,104],[54,110],[48,104],[48,67]],d:[[9,106],[50,106],[57,112],[51,118],[8,118],[3,112]],e:[[6,61],[12,67],[12,104],[6,110],[0,104],[0,67]],f:[[6,8],[12,14],[12,51],[6,57],[0,51],[0,14]],g:[[9,53],[50,53],[56,59],[50,65],[9,65],[3,59]]};
const digitPatterns=['abcdef','bc','abdeg','abcdg','bcfg','acdfg','acdefg','abc','abcdefg','abcdfg'];
function digit(value,color,quiet){
 const lit=value==='-'?'g':digitPatterns[Number(value)]||'';
 return Object.entries(led).map(([key,points])=>{const active=lit.includes(key),xy=points.map(([x,y])=>`${3+x+8*(1-y/118)},${y}`).join(' ');return `<polygon points="${xy}" fill="${active?color:'#aec1cb'}" opacity="${active?(quiet?.12:1):.075}" stroke="${C.navy}" stroke-width=".8" stroke-linejoin="round"/>`;}).join('');
}
function numeral(value,x,y,h,color=C.white,slots=2,flash=false){
 if(value==='∞')return text(x,y+h-8,'∞',h*.92,color,'start',500);
 const raw=value==null?'-'.repeat(slots):String(value),s=raw.padStart(slots,'0'),scale=h/118,leading=value==null?0:s.length-raw.length;
 return `<g class="${flash?'flash':''}" data-main-value="${esc(value??'unknown')}">`+[...s].map((v,i)=>`<g transform="translate(${x+i*76*scale} ${y}) scale(${scale})">${digit(v,color,i<leading)}</g>`).join('')+'</g>';
}
function numWidth(value,h,slots=2){return (Math.max(slots,String(value??'--').length)*76-5)*h/118;}
function text(x,y,s,size=11,color=C.white,anchor='start',weight=600,extra=''){return `<text x="${x}" y="${y}" text-anchor="${anchor}" fill="${color}" font-family="Consolas, 'Lucida Console', monospace" font-size="${size}" font-weight="${weight}" letter-spacing=".25" stroke="${C.navy}" stroke-width="${size<12?1.3:1.7}" paint-order="stroke fill" stroke-linejoin="round" ${extra}>${esc(s)}</text>`;}
function line(x1,y1,x2,y2,color=C.gold,opacity=.65,width=1){return `<path d="M${x1} ${y1} L${x2} ${y2}" fill="none" stroke="${color}" stroke-width="${width}" opacity="${opacity}"/>`;}
function icon(unit,x,y,scale=1,color=C.gold){
 const paths={MAGS:'M1 1H9V13H1ZM1 10H9M5 1V4',BELTS:'M1 2H4V11H1ZM6 1H9V10H6ZM11 2H14V11H11Z',SHELLS:'M2 4Q2 0 5 0Q8 0 8 4V12H2ZM2 10H8',SINKS:'M2 12V1M6 12V1M10 12V1M1 4H11M1 9H11',SHOTS:'M3 12V4L6 0L9 4V12ZM3 9H9',TANKS:'M2 3H10V12H2ZM4 3V0H8V3M2 9H10',PACK:'M1 3H11V12H1ZM4 3V0H8V3M4 6H8M6 4V8',ENERGY:'M7 0L1 7H5L3 13L11 5H7Z',HEAT:'M1 12C-2 7 5 6 2 0M6 12C3 7 10 6 7 0M11 12C8 7 15 6 12 0',AUTO:'M1 3H3V9H1ZM6 3H8V9H6ZM11 3H13V9H11Z',RPM:'M1 11A6 6 0 0 1 12 11M6 9L10 4',SAFE:'M2 5V12H10V5ZM4 5V2Q6 -1 8 2V5',AMMO:'M2 12V5L6 0L10 5V12ZM2 9H10',SINGLE:'M3 12V4L6 0L9 4V12Z'};
 return `<g transform="translate(${x} ${y}) scale(${scale})" fill="none" stroke="${color}" stroke-width="1.1" stroke-linejoin="round" stroke-linecap="round">${paths[unit]?`<path d="${paths[unit]}"/>`:`<path d="M1 2H11V12H1ZM1 7H11"/>`}</g>`;
}
function maskImage(shape,w,h,opts){
 const key=[shape,w,h,opts.feather,opts.dither,opts.grain].join('/');if(maskCache.has(key))return maskCache.get(key);
 const canvas=document.createElement('canvas');canvas.width=Math.ceil(w);canvas.height=Math.ceil(h);const ctx=canvas.getContext('2d'),p=ctx.createImageData(canvas.width,canvas.height),edge=Math.min(w,h)*opts.feather/100,bayer=[0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5],mix=opts.dither/100;
 for(let y=0;y<canvas.height;y++)for(let x=0;x<canvas.width;x++){
  let distance=shape==='circle'?Math.min(w,h)/2-Math.hypot(x-w/2,y-h/2):Math.min(x,y,w-1-x,h-1-y);
  let a=edge?Math.max(0,Math.min(1,distance/edge)):(distance>=0?1:0);a=a*a*(3-2*a);
  const bx=Math.floor(x/opts.grain)%4,by=Math.floor(y/opts.grain)%4,threshold=(bayer[by*4+bx]+.5)/16;
  const dithered=a>threshold?1:0;a=a*(1-mix)+dithered*mix;
  const i=(y*canvas.width+x)*4;p.data[i]=p.data[i+1]=p.data[i+2]=255;p.data[i+3]=Math.round(255*a);
 }ctx.putImageData(p,0,0);const url=canvas.toDataURL('image/png');maskCache.set(key,url);return url;
}
function soft(shape,x,y,w,h,content,opts){
 const id=`edge-${++serial}`,url=maskImage(shape,w,h,opts);return `<defs><mask id="${id}" x="${x}" y="${y}" width="${w}" height="${h}" maskUnits="userSpaceOnUse" style="mask-type:alpha"><image x="${x}" y="${y}" width="${w}" height="${h}" href="${url}"/></mask></defs><g mask="url(#${id})">${content}</g>`;
}
function contexts(m,shown=true){if(!shown||m.unknown)return [];let c=[];if(m.fire_mode)c.push(['AUTO',m.fire_mode]);if(m.rpm)c.push(['RPM',`${m.rpm} RPM`]);if(m.ammo_mode)c.push(['AMMO',m.ammo_mode]);if(m.safety_mode)c.push(['SAFE',m.safety_mode]);if(m.reloadable===false)c.push(['SINGLE','SINGLE USE']);return c;}
function display(sample,state){
 const m={...sample,status:'',ink:C.white};
 if(state==='unknown'){m.value=null;m.capacity=null;if(m.reserve!==undefined)m.reserve=null;m.unknown=true;m.status='NO DATA';m.fraction=0;m.charge_fraction=null;}
 else if(state==='chamber'&&m.chamber_supported){m.value=m.capacity+1;m.chamber_rounds=1;m.chamber_bonus=1;m.fraction=1;}
 else if(state==='low'){
  if(m.kind==='heat'){m.value=88;m.fraction=.88;m.status='HOT';m.ink=C.gold;}
  else if(m.charge_fraction!=null){m.charge_fraction=.92;m.status='CHARGING';}
  else if(m.kind!=='infinite'&&m.capacity>1){m.value=Math.max(1,Math.floor(m.capacity*.16));m.fraction=m.value/m.capacity;m.status='LOW AMMO';m.ink=C.gold;}
 }else if(state==='empty'){
  if(m.kind==='heat'){m.value=100;m.fraction=1;m.status='VENTING';m.ink=C.red;}
  else if(m.kind!=='infinite'){m.value=0;m.charge_fraction=m.charge_fraction==null?undefined:0;m.fraction=0;m.status=m.reloadable===false?'SPENT':'EMPTY';m.ink=C.red;m.flash=true;}
 }
 if(m.chamber_supported&&m.chamber_bonus===1&&m.chamber_rounds===1&&m.value===m.capacity+1)m.status='CHAMBERED +1';
 if(m.charge_fraction!=null&&state!=='empty'){m.mainValue=Math.round(m.charge_fraction*100);m.suffix='%';m.fraction=m.charge_fraction;m.sub=`${m.value} LOADED`;if(!m.status)m.status=m.charge_fraction>=1?'CHARGED':'CHARGING';}
 else{m.mainValue=m.value;m.sub=m.kind==='infinite'?'CONTINUOUS':m.capacity!=null&&m.reloadable!==false?`/ ${m.capacity}`:m.reloadable===false?'ONE SHOT':'';}
 if(m.unknown){m.mainValue=null;m.sub='';m.suffix='';}
 return m;
}
function status(m,x,y,w){if(!m.status)return '';const c=m.ink===C.red?C.red:C.gold;return `<rect x="${x}" y="${y}" width="${w}" height="18" fill="${C.navy}" opacity=".58"/><path d="M${x} ${y}V${y+18}" stroke="${c}" stroke-width="3"/>`+text(x+10,y+12.5,m.status,11.5,c);}
function reserve(m,x,y){if(m.reserve===undefined)return '';const value=m.unknown?'—':String(m.reserve);return icon(m.reserve_kind,x,y-26,.9)+text(x+19,y-3,value,29,C.white)+text(x,y+13,m.reserve_kind,11.5,C.white);}
function gauge(m,x,y,w,opts){let s=`<path d="M${x} ${y}H${x+w}" stroke="${C.white}" stroke-opacity=".18" stroke-width="3"/>`;if(!m.unknown){s+=`<path d="M${x} ${y}H${x+w*Math.min(1,m.fraction||0)}" stroke="${m.ink===C.white?C.gold:m.ink}" stroke-width="3"/>`;}for(let i=0;i<=8;i++)s+=line(x+i*w/8,y+4,x+i*w/8,y+6,C.white,.23,.7);return s;}
function contextRows(m,x,y,width,shown,vertical=false){
 const values=contexts(m,shown);if(!values.length)return '';let out='';values.forEach(([kind,label],i)=>{const xx=vertical?x:x+i*(width/values.length),yy=vertical?y+i*23:y;out+=icon(kind,xx,yy-11,.7);if(vertical&&label.length>9){const words=label.split(' ');out+=text(xx+15,yy,words[0],11.5,C.gold)+text(xx+15,yy+12,words.slice(1).join(' '),11.5,C.gold);}else out+=text(xx+15,yy,label,11.5,C.gold);});return out;
}
function arc(cx,cy,r,start,end){const rad=d=>d*Math.PI/180,point=d=>[cx+r*Math.cos(rad(d)),cy+r*Math.sin(rad(d))];const a=point(start),b=point(end);return `M${a[0]} ${a[1]}A${r} ${r} 0 ${end-start>180?1:0} 1 ${b[0]} ${b[1]}`;}
function orbit(m,opts){
 const cx=85,cy=90,r=66,start=132,end=408;
 let base=`<circle cx="85" cy="90" r="81" fill="${C.navy}" opacity="${opts.backing/100}"/><path d="${arc(cx,cy,78,start,end)}" fill="none" stroke="${C.gold}" stroke-width=".8" opacity=".5"/>`;
 base=soft('circle',2,7,166,166,base,opts);
 let main=base+text(23,13,m.code,10,C.gold)+text(cx,49,m.label,11.5,C.gold,'middle');
 main+=`<path d="${arc(cx,cy,r,start,end)}" fill="none" stroke="${C.white}" stroke-width="2" opacity=".17"/>`;
 if(!m.unknown&&(m.fraction||0)>0)main+=`<path d="${arc(cx,cy,r,start,start+(end-start)*Math.min(1,m.fraction||0))}" fill="none" stroke="${m.ink===C.white?C.gold:m.ink}" stroke-width="3.5"/>`;
 for(let i=0;i<=16;i++){const a=(start+(end-start)*i/16)*Math.PI/180,rr=i%4===0?72:71;main+=line(cx+70*Math.cos(a),cy+70*Math.sin(a),cx+rr*Math.cos(a),cy+rr*Math.sin(a),C.white,i%4===0?.5:.18,.7);}
 const hh=50,ww=numWidth(m.mainValue,hh);main+=numeral(m.mainValue,cx-ww/2,61,hh,m.ink,2,m.flash);
 if(m.suffix)main+=text(cx+ww/2+4,109,m.suffix,14,m.ink);
 main+=text(cx,129,m.sub,12,C.white,'middle',500);
 let secondary=m.reserve===undefined?'':line(154,62,176,62,C.gold,.45)+line(176,62,176,92,C.gold,.45)+reserve(m,187,72);
 let context=contextRows(m,184,117,135,opts.settings,true);
 if(!contexts(m,opts.settings).length&&m.reserve!==undefined)context=text(188,112,m.name,9,C.white,'start',500);
 let lower=status(m,31,165,151);
 return {base:lower,main,secondary,context};
}
function rail(m,opts){
 let back=`<rect x="2" y="17" width="326" height="104" fill="${C.navy}" opacity="${opts.backing/100}"/><path d="M5 20H175M5 20V113H323M323 113V96" fill="none" stroke="${C.gold}" stroke-width="1" opacity=".62"/>`;
 let main=soft('rect',0,14,330,112,back,opts)+text(15,13,m.code,10,C.gold)+text(323,13,m.name,9.2,C.white,'end',500)+text(14,37,m.label,11.5,C.gold);
 main+=numeral(m.mainValue,14,45,48,m.ink,2,m.flash);const ww=numWidth(m.mainValue,48);
 if(m.suffix)main+=text(14+ww+5,89,m.suffix,14,m.ink);else main+=text(14+ww+12,88,m.sub,14,C.white,'start',500);
 if(m.suffix)main+=text(14+ww+33,88,m.sub,10,C.white);
 main+=gauge(m,14,100,188,opts);
 let secondary=m.reserve===undefined?'':line(224,36,224,96,C.gold,.24)+reserve(m,239,66);
 let context=contextRows(m,14,121,302,opts.settings);
 return {base:status(m,15,139,165),main,secondary,context};
}
function split(m,opts){
 let back=`<rect x="77" y="25" width="151" height="108" fill="${C.navy}" opacity="${opts.backing/100}"/><path d="M77 26V126M77 26H113M229 126H193" fill="none" stroke="${C.gold}" stroke-width="1" opacity=".65"/>`;
 let main=soft('rect',72,19,164,121,back,opts)+text(87,16,m.code,10,C.gold)+text(87,43,m.label,11.5,C.gold);
 main+=numeral(m.mainValue,88,53,48,m.ink,2,m.flash);const ww=numWidth(m.mainValue,48);
 if(m.suffix)main+=text(88+ww+5,97,m.suffix,14,m.ink);
 main+=text(222,122,m.sub,11,C.white,'end',500)+gauge(m,88,111,134,opts);
 let secondary=m.reserve===undefined?'':line(62,80,72,80,C.gold,.6)+reserve(m,10,74);
 let context=line(233,55,244,55,C.gold,.4)+contextRows(m,247,66,75,opts.settings,true);
 if(!contexts(m,opts.settings).length)context='';
 return {base:status(m,87,141,166),main,secondary,context};
}
function render(concept,m,opts){
 const fn={orbit,rail,split}[concept],parts=fn(m,opts),[w,h]=dimensions[concept],classes={base:'base-unit',main:'main-unit',secondary:'secondary-unit',context:'context-unit'};
 return Object.entries(parts).map(([key,body])=>`<svg class="unit ${classes[key]}" xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" aria-hidden="true">${body}</svg>`).join('');
}
function options(){return {backing:+$('backing').value,feather:+$('feather').value,dither:+$('dither').value,grain:+$('grain').value,settings:$('settings').checked};}
function updatePose(){
 const a=$('angle').value,neutral=a==='neutral',p=neutral?{x:960,y:545,yaw:0,pitch:0,roll:0}:poses[+a],use=$('perspective').checked;
 if(!neutral&&$('scenePhoto').getAttribute('src')!==photos[+a]){missingReference=false;$('scenePhoto').src=photos[+a];}
 $('world').classList.toggle('neutral',neutral||missingReference);
 const pos=customPosition||p;$('instrument').style.left=pos.x+'px';$('instrument').style.top=pos.y+'px';
 $('instrument').style.setProperty('--yaw',(use?p.yaw:0)+'deg');$('instrument').style.setProperty('--pitch',(use?p.pitch:0)+'deg');$('instrument').style.setProperty('--roll',(use?p.roll:0)+'deg');
 $('instrument').style.setProperty('--depth',$('depth').value);$('instrument').style.setProperty('--base-scale',+$('scale').value/100);
}
function updateView(){
 const viewport=$('sceneViewport'),world=$('world'),w=viewport.clientWidth,h=viewport.clientHeight,scale=view==='pixels'?1:view==='inspect'?3:Math.min(w/1920,h/1080);
 world.style.setProperty('--scene-scale',scale);
 if(view==='fit'){world.style.left=(w-1920*scale)/2+'px';world.style.top=(h-1080*scale)/2+'px';}
 else{const x=parseFloat($('instrument').style.left)||960,y=parseFloat($('instrument').style.top)||540;world.style.left=(w/2-x*scale)+'px';world.style.top=(h/2-y*scale)+'px';}
 $('stageLabel').textContent=missingReference&&$('angle').value!=='neutral'?'OPTIONAL GAMEPLAY REFERENCE NOT INCLUDED · NEUTRAL FIELD':view==='inspect'?'INSPECT ×3 · DRAG TO PLACE':view==='pixels'?'100% · 1920 × 1080 REFERENCE · DRAG TO PLACE':'FIT SCENE · DRAG INSTRUMENT TO PLACE';
}
function draw(){
 const m=display(samples[$('family').value],$('state').value),opts=options(),[w,h]=dimensions[selected];
 $('instrument').style.width=w+'px';$('instrument').style.height=h+'px';$('instrument').innerHTML=render(selected,m,opts);
 $('conceptTitle').textContent=titles[selected];const screenScale=+$('scale').value/100;$('dimensions').textContent=`${Math.round(w*screenScale)} × ${Math.round(h*screenScale)} px · ${$('scale').value}% · 1920 × 1080 reference`;
 $('familyTitle').textContent=`${m.title} / ${m.code} ${m.name}`;$('readingExplanation').textContent=m.description;
 const fields=['value',...(m.capacity!=null?['capacity']:[]),...(m.reserve!==undefined?['reserve + reserve_kind']:[]),...contexts(m,true).map(([kind])=>({AUTO:'fire_mode',RPM:'rpm',AMMO:'ammo_mode',SAFE:'safety_mode',SINGLE:'reloadable / SPENT'}[kind])),...(m.charge_fraction!=null?['charge_fraction']:[])];
 $('capabilityLine').textContent='Illustrative data · source fields: '+fields.join(' / ');
 ['backing','feather','dither','scale'].forEach(id=>$(id+'Out').textContent=$(id).value+'%');$('grainOut').textContent=$('grain').value+' px';$('depthOut').textContent=$('depth').value+' px';
 $('familyGrid').innerHTML=Object.entries(samples).map(([key,s])=>{const example=display(s,key==='magazine'?'chamber':'ready');const modes=contexts(example,opts.settings).map(v=>v[1]).join(' · ')||'No selector row';return `<article class="family-card"><div class="mini-preview"><div class="mini-instrument" style="width:${w}px;height:${h}px">${render(selected,example,opts)}</div></div><footer><strong>${esc(s.title)} · ${esc(s.code)}</strong><span>${esc(modes)}</span></footer></article>`;}).join('');
 updatePose();updateView();
}
Object.entries(samples).forEach(([key,s])=>{const option=document.createElement('option');option.value=key;option.textContent=`${s.title} · ${s.code}`;$('family').appendChild(option);});
document.querySelectorAll('[data-concept]').forEach(button=>button.addEventListener('click',()=>{selected=button.dataset.concept;document.querySelectorAll('[data-concept]').forEach(b=>{const on=b===button;b.classList.toggle('active',on);b.setAttribute('aria-pressed',on);});draw();}));
document.querySelectorAll('[data-view]').forEach(button=>button.addEventListener('click',()=>{view=button.dataset.view;document.querySelectorAll('[data-view]').forEach(b=>b.classList.toggle('active',b===button));updateView();}));
['family','state','settings','backing','feather','dither','grain','perspective','depth','scale'].forEach(id=>$(id).addEventListener('input',()=>{if(id==='family'){const sample=samples[$('family').value],allowed={chamber:sample.chamber_supported===true,low:sample.kind==='heat'||sample.charge_fraction!=null||sample.capacity>1,empty:sample.kind!=='infinite'};for(const [value,on]of Object.entries(allowed)){$('state').querySelector(`[value="${value}"]`).disabled=!on;if(!on&&$('state').value===value)$('state').value='ready';}}draw();}));
$('angle').addEventListener('change',()=>{customPosition=null;updatePose();updateView();});
$('reset').addEventListener('click',()=>{Object.entries({family:'magazine',state:'ready',backing:35,feather:7,dither:40,grain:2,depth:16,scale:70}).forEach(([id,v])=>$(id).value=v);$('settings').checked=true;$('perspective').checked=true;['chamber','low','empty'].forEach(value=>$('state').querySelector(`[value="${value}"]`).disabled=false);draw();});
$('recenter').addEventListener('click',()=>{customPosition=null;updatePose();updateView();});
let drag=null;
$('instrument').addEventListener('pointerdown',e=>{e.preventDefault();const instrument=$('instrument');instrument.setPointerCapture(e.pointerId);drag={x:e.clientX,y:e.clientY,left:parseFloat(instrument.style.left),top:parseFloat(instrument.style.top),scale:parseFloat($('world').style.getPropertyValue('--scene-scale'))};});
$('instrument').addEventListener('pointermove',e=>{if(!drag)return;customPosition={x:drag.left+(e.clientX-drag.x)/drag.scale,y:drag.top+(e.clientY-drag.y)/drag.scale};updatePose();});
['pointerup','pointercancel'].forEach(name=>$('instrument').addEventListener(name,()=>{drag=null;}));
$('scenePhoto').addEventListener('error',()=>{missingReference=true;$('world').classList.add('neutral');updateView();});
$('scenePhoto').addEventListener('load',()=>{missingReference=false;$('world').classList.toggle('neutral',$('angle').value==='neutral');updateView();});
new ResizeObserver(updateView).observe($('sceneViewport'));draw();
window.UniversalStudy={samples,display,contexts,dimensions,render,options,maskCache,get selected(){return selected;}};
