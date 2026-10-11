/* Review-only vector digit styles. No game APIs, settings, or runtime renderer. */
(function(root){
const C={white:'#f5f6f0',gold:'#e9c45d',navy:'#091b35',muted:'#284568',red:'#ff5750'};
const facets={};
for(let row=0;row<3;row++)for(let col=0;col<2;col++){
 const x=col*30,y=row*118/3,w=30,h=118/3,cx=x+w/2,cy=y+h/2,g=1.1;
 const pieces={N:[[x+g,y+g],[x+w-g,y+g],[cx,cy-g]],E:[[x+w-g,y+g],[x+w-g,y+h-g],[cx+g,cy]],S:[[x+w-g,y+h-g],[x+g,y+h-g],[cx,cy+g]],W:[[x+g,y+h-g],[x+g,y+g],[cx-g,cy]]};
 for(const [d,p]of Object.entries(pieces))facets[(row*2+col)+d]=p;
}
const A=['0N','1N'],D=['4S','5S'],G=['2W','2E','3W','3E'];
const facetedPatterns=[
 [...A,'0W','1E','2W','3E','4W','5E',...D],
 ['1E','3E','5E'],
 [...A,'1E','3N','3W','2E','2S','4W',...D],
 [...A,'1E',...G,'3E','5E',...D],
 ['0W','1E',...G,'3E','5E'],
 [...A,'0W',...G,'5E',...D],
 [...A,'0W',...G,'4W','5E',...D],
 [...A,'1E','3E','5E'],
 [...A,'0W','1E',...G,'4W','5E',...D],
 [...A,'0W','1E',...G,'3E','5E',...D],G,Object.keys(facets)
].map(p=>[...new Set(p)]);
const led={
 a:[[8,0],[51,0],[57,6],[50,12],[9,12],[3,6]],
 b:[[54,8],[60,14],[60,51],[54,57],[48,51],[48,14]],
 c:[[54,61],[60,67],[60,104],[54,110],[48,104],[48,67]],
 d:[[9,106],[50,106],[57,112],[51,118],[8,118],[3,112]],
 e:[[6,61],[12,67],[12,104],[6,110],[0,104],[0,67]],
 f:[[6,8],[12,14],[12,51],[6,57],[0,51],[0,14]],
 g:[[9,53],[50,53],[56,59],[50,65],[9,65],[3,59]]
};
const ledPatterns=['abcdef','bc','abdeg','abcdg','bcfg','acdfg','acdefg','abc','abcdefg','abcdfg','g','abcdefg'].map(p=>[...p]);
function points(style,p){const lean=style==='faceted'?6:8;return p.map(([x,y])=>[3+x+lean*(1-y/118),y]);}
function shape(style,name,fill,alpha,active){
 const p=points(style,(style==='faceted'?facets:led)[name]);
 return '<polygon points="'+p.map(a=>a.join(',')).join(' ')+'" fill="'+fill+'" opacity="'+alpha+'" stroke="'+C.navy+'" stroke-width="'+(style==='faceted'?.7:.65)+'" stroke-linejoin="round" data-lit="'+active+'"/>';
}
function digit(style,value,color=C.white,leading=false,flash=false){
 const names=style==='faceted'?Object.keys(facets):Object.keys(led),patterns=style==='faceted'?facetedPatterns:ledPatterns;
 const index=value==='-'?10:Number(value),lit=patterns[index]||[];
 let out=names.map(n=>shape(style,n,C.muted,.18,false)).join('');
 // Animate the parent; each cell keeps its quieter leading-zero alpha.
 out+='<g'+(flash?' class="empty-flash"':'')+'><g opacity="'+(leading?.14:1)+'">'+lit.map(n=>shape(style,n,color,1,true)).join('')+'</g></g>';
 return out;
}
function digits(style,value,slots,x,y,w,h,color,role,chamber=false,flash=false){
 const raw=value==null?'-'.repeat(slots):String(value),str=value==null?raw:raw.padStart(slots,'0');
 const scale=Math.min(w/(str.length*72+(str.length-1)*7),h/118),start=x+(w-(str.length*72+(str.length-1)*7)*scale)/2;
 const leading=value==null?0:str.length-raw.length;
 return '<g data-readout="'+role+'">'+[...str].map((c,i)=>'<g transform="translate('+(start+i*79*scale)+' '+y+') scale('+scale+')">'+digit(style,c,chamber&&i===str.length-1?C.gold:color,i<leading,flash)+'</g>').join('')+'</g>';
}
function sample(state='ready',mode='AUTO'){
 return {state,mode,count:state==='unknown'?null:state==='empty'?0:state==='low'?5:state==='chamber'?46:27,capacity:state==='unknown'?null:45,reserve:state==='unknown'?null:6};
}
function panel(style,data=sample(),opacity=.25){
 const status=data.state==='chamber'?'CHAMBERED +1':data.state==='low'?'LOW AMMO':data.state==='empty'?'EMPTY':data.state==='unknown'?'NO DATA':'';
 const ink=data.state==='empty'?C.red:data.state==='low'?C.gold:C.white;
 const ratio=data.count==null?0:Math.min(1,data.count/45);
 let out='<svg xmlns="http://www.w3.org/2000/svg" width="210" height="352" viewBox="0 0 210 352"><style>.label{font:700 10px Consolas,monospace;letter-spacing:.07em}.small{font:700 9px Consolas,monospace}.empty-flash{animation:counter-pulse .5s steps(1,end) infinite}@keyframes counter-pulse{0%,100%{opacity:1}50%{opacity:.22}}@media(prefers-reduced-motion:reduce){.empty-flash{animation:none}}</style>';
 out+='<rect data-backing="true" x="18" y="25" width="174" height="304" fill="'+C.navy+'" opacity="'+opacity+'"/><g data-foreground="true">';
 out+='<g fill="none" stroke="'+C.gold+'" stroke-opacity=".35" stroke-width=".7"><path d="M25 52 H185 M25 176 H185 M25 244 H185 M25 286 H185"/><path d="M27 76 H33 M25 78 V168 M27 171 H33 M177 76 H183 M185 78 V168 M177 171 H183" stroke-opacity=".22"/>';
 out+='<path d="M25 184 H185 V198 H25 Z" stroke-opacity=".22"/></g>';
 out+='<text x="25" y="44" fill="'+C.gold+'" class="label">AR-23</text><text x="184" y="44" text-anchor="end" fill="'+C.white+'" class="small">LIBERATOR</text><text x="25" y="67" fill="'+C.gold+'" class="small">LOAD</text>';
 out+=digits(style,data.count,3,28,87,154,78,ink,'loaded',data.state==='chamber',data.state==='empty');
 out+='<rect x="25" y="184" width="3" height="14" fill="'+C.gold+'" opacity="'+(status?1:.15)+'"/><text x="34" y="194" fill="'+C.gold+'" class="small">'+status+'</text><text x="25" y="218" fill="'+C.gold+'" class="label">CAP</text>';
 out+=digits(style,data.capacity,3,136,206,49,22,C.gold,'capacity');
 for(let i=0;i<20;i++){const x=25+i*8,fill=Math.min(1,Math.max(0,ratio*20-i));out+='<rect x="'+x+'" y="231" width="7" height="7" fill="'+C.muted+'" opacity=".35"/>';if(fill>0)out+='<rect x="'+x+'" y="231" width="'+(7*fill)+'" height="7" fill="'+C.gold+'"/>';}
 out+='<text x="25" y="260" fill="'+C.gold+'" class="small">RESERVE</text><text x="25" y="278" fill="'+C.white+'" class="label">MAGS</text>';
 out+=digits(style,data.reserve,2,132,250,53,33,C.white,'reserve');
 out+='<text x="25" y="296" fill="'+C.gold+'" class="small">MODE</text>';
 for(const [i,mode]of ['AUTO','BURST','SEMI'].entries()){
  const x=25+i*55,on=data.mode===mode;
  out+='<rect x="'+x+'" y="301" width="48" height="17" fill="none" stroke="'+(on?C.gold:C.muted)+'" stroke-width=".7" opacity="'+(on?1:.7)+'"/><text x="'+(x+24)+'" y="313" text-anchor="middle" class="small" fill="'+(on?C.gold:C.muted)+'">'+mode+'</text>';
  if(on)out+='<path d="M'+x+' 321 H'+(x+48)+'" stroke="'+C.gold+'" stroke-width="2"/>';
 }
 return out+'</g></svg>';
}
function atlas(style){let out='<svg xmlns="http://www.w3.org/2000/svg" width="960" height="384" viewBox="0 0 960 384">';for(let row=0;row<3;row++)for(let col=0;col<12;col++){const color=[C.white,C.gold,C.red][row];out+='<g transform="translate('+(col*80+4)+' '+(row*128+5)+')">'+(col===11?(style==='faceted'?Object.keys(facets):Object.keys(led)).map(n=>shape(style,n,C.muted,.4,false)).join(''):digit(style,col===10?'-':col,color))+'</g>';}return out+'</svg>';}
const api={C,facets,facetedPatterns,led,ledPatterns,digit,panel,sample,atlas};
if(typeof module!=='undefined'&&module.exports)module.exports=api;else root.DigitStudy=api;
})(globalThis);
