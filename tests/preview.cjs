// Offline JavaScript behavior checks with stubbed DOM/canvas, not a browser render.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(require('node:path').join(__dirname,'../preview/index.html'),'utf8');
const script=html.match(/<script>([\s\S]*?)<\/script>/)[1];
const elements=new Map();
const context2d=new Proxy({}, {get:(_,k)=>k.startsWith('create')?()=>({addColorStop(){}}):()=>{}});
function element(id){if(!elements.has(id))elements.set(id,{id,checked:true,value:id==='weapon'?'magazine':'',clientWidth:1100,clientHeight:600,style:{},
    append(){},querySelector(){return {};},getContext(){return context2d;},getBoundingClientRect(){return {left:0,top:0};},focus(){},setPointerCapture(){},click(){}});return elements.get(id);}
const sandbox={console,Math,URL:{createObjectURL(){return 'test';},revokeObjectURL(){}},Blob:class{},setTimeout(){},requestAnimationFrame(){},
    ResizeObserver:class{constructor(fn){this.fn=fn;}observe(){this.fn();}},
    window:{devicePixelRatio:1},document:{querySelector:s=>element(s.slice(1)),getElementById:element,createElement:()=>element(Math.random().toString())}};
vm.createContext(sandbox);vm.runInContext(fs.readFileSync(require('node:path').join(__dirname,'../preview/font-data.js'),'utf8'),sandbox);vm.runInContext(script,sandbox);
const run=s=>vm.runInContext(s,sandbox);
assert.equal(run('rounds'),45);run('fire()');assert.equal(run('rounds'),44);
run('weapon.value="disposable";resetAmmo();fire();reload()');assert.equal(run('rounds'),0);assert.equal(run('reloadUntil'),0);
run('weapon.value="heat";resetAmmo();for(let i=0;i<12;i++)fire()');assert.equal(run('locked'),true);
run('weapon.value="rounds";resetAmmo();rounds=2;reserve=3;reload();t=2;frame(16)');assert.equal(run('rounds'),5);assert.equal(run('reserve'),0);
run('cfg.follow=1;cfg.travel=55;aim={x:5000,y:5000};for(let i=0;i<1000;i++)motion(1/144)');assert(run('Math.hypot(spring.x,spring.y)')<=55.000001);
console.log('PASS preview script compiles, firing, disposable state, heat lock, shell reload, bounded motion (offline DOM/canvas stubs)');

run('cfg.flash_hz=2');
for(const [heat,color] of [[0,'heat_white'],[.74,'heat_white'],[.75,'heat_yellow'],[.85,'heat_yellow'],[.86,'heat_red'],[.94,'heat_red']])assert.equal(run(`heatColor(${heat},0)`),run(`cfg.${color}`));
assert.equal(run('heatColor(.95,0)'),run('cfg.heat_red'));assert.equal(run('heatColor(.95,.25)'),run('cfg.heat_yellow'));
run("document.getElementById('text_colorHex').onchange({target:{value:'aabbcc'}})");assert.equal(run('cfg.text_color'),'#AABBCC');
run("document.getElementById('text_colorHex').onchange({target:{value:'invalid'}})");assert.equal(run('cfg.text_color'),'#AABBCC');
run("document.querySelector('#reposition').checked=true;stage.onpointerdown({button:0,clientX:100,clientY:100,pointerId:1});stage.onpointermove({clientX:150,clientY:80});stage.onpointerup()");
assert.equal(run('cfg.offset_x'),152);assert.equal(run('cfg.offset_y'),31);assert.equal(run('held'),false);
assert(run('exportLua()').includes('text_color = "#AABBCC"'));assert(run('exportLua()').includes('return {'));
run("document.querySelector('#heatLevel').oninput({target:{value:'95'}});frame(32)");assert.equal(run('heat'),.95);
console.log('PASS hex editing, invalid input, drag placement, heat boundaries/flash, heat hold and Lua export');

run('H=1080;W=1920;weapon.value="heat";heat=.99');const fit99=run('drawHud()');run('heat=1');const fit100=run('drawHud()');assert(fit100.right-fit100.left>fit99.right-fit99.left);run('heat=.99');assert.equal(run('drawHud().right'),fit99.right);console.log('PASS preview frame grows and shrinks with content');

run("document.getElementById('font').onchange({target:{value:'debug'}})");assert.equal(run('cfg.font'),'debug');run("document.getElementById('font').onchange({target:{value:'bigblue'}})");assert(run('exportLua()').includes('font = \"bigblue\"'));console.log('PASS font selection and tuning export');
