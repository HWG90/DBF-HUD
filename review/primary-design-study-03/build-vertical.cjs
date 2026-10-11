const fs = require('fs');
const path = require('path');
const directory = __dirname;
const base = path.resolve(directory, '../primary-design-study-02');
let html = fs.readFileSync(path.join(base, 'index.html'), 'utf8');
function replace(before, after) {
  if (!html.includes(before)) throw new Error('Missing source text: ' + before);
  html = html.replace(before, after);
}
replace('DBF HUD â€” Open / Background study', 'DBF HUD â€” Open / Vertical candidate');
replace('STUDY 02', 'STUDY 03');
replace('../primary-design-study-03/index.html', '../primary-design-study-02/index.html');
replace('View the vertical Open candidate', 'Return to the horizontal Open study');
replace('Open, with adjustable backing.', 'Open, vertically.');
replace('Floating readouts stay crisp. Only the background changes.', 'A narrow stack of floating readouts, with adjustable backing.');
replace('.hero{min-height:300px;', '.hero{min-height:410px;');
replace('max-width:450px', 'max-width:240px');
replace('.compare .stage{height:220px}', '.compare .stage{height:330px}');
replace('.compare .preview{width:min(100%,340px)}', '.compare .preview{width:min(100%,205px)}');
replace('.states .stage{height:175px}', '.states .stage{height:280px}');
replace('.states .preview{width:min(100%,270px)}', '.states .preview{width:min(100%,170px)}');
replace('.compare .stage{height:240px}', '.compare .stage{height:330px}');
replace('Capacity, reserve, and mode follow.', 'Capacity and the gauge sit below it. Reserve and mode complete the stack.');
replace('Open is the selected direction for the primary design pass. Receiver and Dial remain reference alternatives.', 'Open is the selected direction. This vertical arrangement is a candidate; the horizontal study remains available.');
const first = html.indexOf(' function svgFor(');
const last = html.indexOf(' function draw(){', first);
if (first < 0 || last < 0) throw new Error('SVG renderer markers not found');
const verticalFunction = fs.readFileSync(path.join(directory, 'vertical-function.txt'), 'utf8');
html = html.slice(0, first) + verticalFunction + '\n' + html.slice(last);
fs.writeFileSync(path.join(directory, 'index.html'), html);
let renderer = fs.readFileSync(path.join(base, 'render-study.cjs'), 'utf8');
renderer = renderer.replace('.resize(720, 440)', '.resize(380, 556)').replace('.resize(540, 330)', '.resize(380, 556)');
renderer = renderer.replace("const panels = translucencies.map((t, i) => '<g transform=\"translate(' + (24 + i * 384) + ',100)\"><text x=\"0\" y=\"0\" fill=\"#e7f0e9\" font-size=\"23\" font-family=\"Segoe UI,sans-serif\">' + t + '% translucent</text><rect x=\"0\" y=\"20\" width=\"360\" height=\"260\" fill=\"url(#field)\"/><image x=\"0\" y=\"40\" width=\"360\" height=\"220\" href=\"data:image/png;base64,' + images[i].toString('base64') + '\"/><text x=\"0\" y=\"307\" fill=\"#a4b5b2\" font-size=\"14\" font-family=\"Segoe UI,sans-serif\">' + captions[i] + ' Â· ' + (100 - t) + '% opacity</text></g>').join('');",
"const panels = translucencies.map((t, i) => '<g transform=\"translate(' + (24 + i * 384) + ',100)\"><text x=\"0\" y=\"0\" fill=\"#e7f0e9\" font-size=\"23\" font-family=\"Segoe UI,sans-serif\">' + t + '% translucent</text><rect x=\"0\" y=\"20\" width=\"360\" height=\"350\" fill=\"url(#field)\"/><image x=\"78\" y=\"38\" width=\"205\" height=\"300\" href=\"data:image/png;base64,' + images[i].toString('base64') + '\"/><text x=\"0\" y=\"397\" fill=\"#a4b5b2\" font-size=\"14\" font-family=\"Segoe UI,sans-serif\">' + captions[i] + ' Â· ' + (100 - t) + '% opacity</text></g>').join('');");
renderer = renderer.replace('width="1200" height="480"', 'width="1200" height="570"').replace('height="480" fill="#101718"', 'height="570" fill="#101718"');
renderer = renderer.replace('y="454"', 'y="544"').replace('PRIMARY STUDY 02', 'PRIMARY STUDY 03').replace('Open Â· Variable background translucency', 'Open Â· Vertical candidate').replace('.resize(1800, 720)', '.resize(1800, 855)');
if (!renderer.includes('width="205" height="300"')) throw new Error('Vertical contact-sheet transform failed');
fs.writeFileSync(path.join(directory, 'render-study.cjs'), renderer);
console.log('Vertical candidate authored from the selected Open study.');
