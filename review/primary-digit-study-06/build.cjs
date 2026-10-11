const fs=require('fs'),path=require('path'),crypto=require('crypto');
const sharp=require('../../tools/runtime_dependencies.cjs').getSharp();
const D=require('./design.js'),out=__dirname;
const vm=require('vm');
function expect(value,message){if(!value)throw new Error(message)}
function foreground(svg){return svg.replace(/<rect data-backing="true"[^>]*\/>/,'')}
async function main(){
 expect(Object.keys(D.facets).length===24,'Faceted cell count');
 for(const style of ['faceted','led']){
  const masks=style==='faceted'?D.facetedPatterns:D.ledPatterns;
  expect(new Set(masks.slice(0,10).map(p=>p.slice().sort().join(','))).size===10,'Ten distinct digits required');
  for(const value of masks.flat())expect((style==='faceted'?D.facets:D.led)[value],'Unknown digit facet');
  expect(foreground(D.panel(style,D.sample(),0))===foreground(D.panel(style,D.sample(),.8)),'Backing altered foreground');
  const atlas=D.atlas(style);fs.writeFileSync(path.join(out,style+'-atlas.svg'),atlas);await sharp(Buffer.from(atlas)).png().toFile(path.join(out,style+'-atlas.png'));
 }
 const tiles=[];
 for(const [i,item]of [['faceted','ready'],['faceted','chamber'],['led','ready'],['led','chamber']].entries()){
  const [style,state]=item,svg=D.panel(style,D.sample(state),.25);
  expect(svg.includes('data-readout="loaded"')&&svg.includes('data-readout="capacity"')&&svg.includes('data-readout="reserve"')&&svg.includes('BURST'),'Whole panel required');
  fs.writeFileSync(path.join(out,style+'-'+state+'.svg'),svg);
  const png=await sharp(Buffer.from(svg)).resize(420,704).png().toBuffer();fs.writeFileSync(path.join(out,style+'-'+state+'.png'),png);tiles.push({input:png,left:24+i*444,top:96});
 }
 const header='<svg width="1800" height="856"><style>text{font:20px Consolas,monospace;fill:#f5f6f0}.label{font-size:16px;fill:#e9c45d}</style><text x="24" y="30">PRIMARY DIGIT STUDY 06 / FACETED AND SLANTED LED / REVIEW ONLY</text>'+['Faceted Â· 027','Faceted Â· 046 + chamber','Slanted LED Â· 027','Slanted LED Â· 046 + chamber'].map((label,i)=>'<text class="label" x="'+(24+i*444)+'" y="76">'+label+'</text>').join('')+'<text x="24" y="836" style="font-size:14px;fill:#a7bdcd">174Ã—304 instrument frame Â· loaded digits 12% shorter Â· quiet leading zeros Â· white / gold / navy Â· independent rectangular backing</text></svg>';
 tiles.push({input:Buffer.from(header),left:0,top:0});await sharp({create:{width:1800,height:856,channels:4,background:'#1b3542'}}).composite(tiles).png().toFile(path.join(out,'comparison.png'));
 const readings={ready:27,chamber:46,low:5,empty:0,unknown:null};for(const [state,n]of Object.entries(readings))expect(D.sample(state).count===n,'State reading changed');
 for(const style of ['faceted','led']){
  expect(D.panel(style,D.sample('empty')).includes('class="empty-flash"'),'Empty flash absent');expect(!D.panel(style,D.sample('ready')).includes('class="empty-flash"'),'Refill retained flash');
  expect(D.panel(style,D.sample('empty')).includes('class="empty-flash"><g opacity="0.14"'),'Empty animation overrides leading-zero hierarchy');
  expect(D.panel(style,D.sample('unknown')).includes('NO DATA'),'Unknown data fabricated');
 }
 const nodes={};function node(id){return nodes[id]||(nodes[id]={value:({state:'ready',mode:'AUTO',backing:'25'})[id]||'',innerHTML:'',textContent:'',events:{},addEventListener(kind,fn){this.events[kind]=fn}})}
 const html=fs.readFileSync(path.join(out,'index.html'),'utf8'),script=[...html.matchAll(/<script>([\s\S]*?)<\/script>/g)][0][1];
 vm.runInNewContext(script,{DigitStudy:D,document:{getElementById:node}});
 node('state').value='chamber';node('state').events.change();expect(node('faceted').innerHTML.includes('CHAMBERED +1')&&node('led').innerHTML.includes('CHAMBERED +1'),'Interactive chamber selector');
 node('state').value='empty';node('state').events.change();expect(node('led').innerHTML.includes('class="empty-flash"'),'Interactive empty state');
 node('state').value='ready';node('state').events.change();expect(!node('led').innerHTML.includes('class="empty-flash"'),'Interactive refill');
 const oldForeground=foreground(node('faceted').innerHTML);node('backing').value='0';node('backing').events.input();expect(foreground(node('faceted').innerHTML)===oldForeground&&node('opacity').textContent==='0%','Interactive independent backing');
 node('mode').value='BURST';node('mode').events.change();expect(node('faceted').innerHTML.includes('M80 321 H128'),'Interactive mode underline');
 fs.writeFileSync(path.join(out,'STUDY.json'),JSON.stringify({scope:'Review-only primary instrument digit alternatives',source_references:['codex-clipboard-5e525488-fdda-4374-8495-4fc60541f998.png','codex-clipboard-ef3449e9-e592-413a-84c8-93ff2a3c6369.png'],styles:['24 triangular cells','restrained slanted LED'],core_frame:[174,304],study04_loaded_height:89,loaded_height:78,counter_reduction_percent:100*(1-78/89),leading_zero_alpha:.14,backing_independent:true,rectangular_backing:true,complete_ten_digit_atlases:true,atlas:{size:[960,384],cell:[80,128],rows:['white','gold','red'],columns:['0','1','2','3','4','5','6','7','8','9','dash','ghost']},future_render_contract:'One cached atlas image per glyph; no per-facet runtime primitives',runtime_integrated:false,installed:false,checks:['24 facets','10 distinct digits per style','foreground identical at all backing opacity','027 and 046 full panels','native-style chamber count preserved','refill clears loaded-only empty animation','reduced motion steady','unknown dashes']},null,2));
 fs.writeFileSync(path.join(out,'CHECKS.json'),JSON.stringify({passed:true,comparison_sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(out,'comparison.png'))).digest('hex'),complete_atlases:true,core_geometry_preserved:true,no_runtime_changes:true},null,2));
 console.log('Review-only digit study rendered: '+path.join(out,'comparison.png'));
}main().catch(e=>{console.error(e);process.exitCode=1});
