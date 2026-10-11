const fs = require('fs');
const path = require('path');
const vm = require('vm');
const sharp = require('../../tools/runtime_dependencies.cjs').getSharp();
const directory = __dirname;
const html = fs.readFileSync(path.join(directory, 'index.html'), 'utf8');
const nodes = new Map();
function node(id) {
  if (!nodes.has(id)) nodes.set(id, {
    textContent: '', innerHTML: '', disabled: false,
    value: ({ mode: 'AUTO', state: 'ready', field: 'dark', translucency: '75' })[id] || '',
    listeners: {}, classList: { toggle() {} },
    addEventListener(type, callback) { this.listeners[type] = callback; }
  });
  return nodes.get(id);
}
const context = { document: { getElementById: node, querySelectorAll: () => [node('stage-a'), node('stage-b')] } };
vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1], context, { filename: 'index.html inline script' });
function expect(test, message) { if (!test) throw new Error(message); }
function change(id, value, event = 'change') { const control = node(id); control.value = String(value); control.listeners[event].call(control); }
function click(id) { node(id).listeners.click(); }
function foreground(svg) { return svg.replace(/<path data-backing="true"[^>]*\/>/, ''); }
expect(node('sample').textContent === '27 / 45 Â· 6 spare magazines', 'Initial sample');
const initialForeground = foreground(node('main-preview').innerHTML);
change('translucency', 100, 'input');
expect(/data-backing="true"[^>]*opacity="0.00"/.test(node('main-preview').innerHTML), '100% translucent removes backing');
expect(foreground(node('main-preview').innerHTML) === initialForeground, 'Foreground unchanged at transparent endpoint');
change('translucency', 0, 'input');
expect(/data-backing="true"[^>]*opacity="1.00"/.test(node('main-preview').innerHTML), '0% translucent has solid backing');
expect(foreground(node('main-preview').innerHTML) === initialForeground, 'Foreground unchanged at opaque endpoint');
expect(node('compare-open').innerHTML.includes('opacity="0.00"'), 'Fixed open example remains open');
change('translucency', 75, 'input');
click('fire'); expect(node('sample').textContent.startsWith('26 / 45'), 'Fire removes one round');
change('state', 'low'); expect(node('main-preview').innerHTML.includes('LOW AMMO'), 'Low warning');
change('state', 'empty'); expect(node('fire').disabled && node('main-preview').innerHTML.includes('EMPTY'), 'Empty state');
click('reload'); expect(node('sample').textContent === '45 / 45 Â· 5 spare magazines', 'Reload consumes a spare magazine');
change('mode', 'BURST'); expect(node('main-preview').innerHTML.includes('BURST'), 'Mode selection');
change('state', 'unknown'); expect(node('main-preview').innerHTML.includes('NO DATA') && node('main-preview').innerHTML.includes('>â€”</text>') && node('fire').disabled && node('reload').disabled, 'Unknown state stays unknown');
change('field', 'light'); click('reset');
const study = context.OpenStudy;
async function main() {
  const translucencies = [100, 75, 40];
  const images = [];
  for (const t of translucencies) {
    const svg = study.svgFor({ ...study.initial, mode: 'AUTO' }, t, 'export-' + t);
    fs.writeFileSync(path.join(directory, 'open-translucency-' + t + '.svg'), svg);
    const png = await sharp(Buffer.from(svg)).resize(380, 556).png().toBuffer();
    fs.writeFileSync(path.join(directory, 'open-translucency-' + t + '.png'), png);
    images.push(png);
  }
  for (const [name, count] of [['low', 5], ['empty', 0], ['unknown', null]]) {
    const svg = study.svgFor({ ...study.initial, count, mode: 'AUTO' }, 75, 'state-' + name);
    fs.writeFileSync(path.join(directory, 'open-' + name + '.svg'), svg);
    await sharp(Buffer.from(svg)).resize(380, 556).png().toFile(path.join(directory, 'open-' + name + '.png'));
  }
  const captions = ['No backing', 'Light backing', 'Stronger backing'];
  const panels = translucencies.map((t, i) => '<g transform="translate(' + (24 + i * 384) + ',100)"><text x="0" y="0" fill="#e7f0e9" font-size="23" font-family="Segoe UI,sans-serif">' + t + '% translucent</text><rect x="0" y="20" width="360" height="350" fill="url(#field)"/><image x="78" y="38" width="205" height="300" href="data:image/png;base64,' + images[i].toString('base64') + '"/><text x="0" y="397" fill="#a4b5b2" font-size="14" font-family="Segoe UI,sans-serif">' + captions[i] + ' Â· ' + (100 - t) + '% opacity</text></g>').join('');
  const contact = '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="570"><defs><linearGradient id="field" x2=".7" y2="1"><stop stop-color="#304939"/><stop offset=".65" stop-color="#19362f"/><stop offset="1" stop-color="#1b2a30"/></linearGradient></defs><rect width="1200" height="570" fill="#101718"/><text x="24" y="30" fill="#afd8d1" font-size="12" letter-spacing="2" font-family="Consolas,monospace">DBF / PRIMARY STUDY 03</text><text x="24" y="61" fill="#ecf0e8" font-size="26" font-family="Segoe UI,sans-serif">Open Â· Vertical candidate</text>' + panels + '<text x="24" y="544" fill="#a4b5b2" font-size="13" font-family="Segoe UI,sans-serif">Same foreground at every setting Â· Illustrative readings Â· Flat design preview</text></svg>';
  fs.writeFileSync(path.join(directory, 'contact.svg'), contact);
  await sharp(Buffer.from(contact)).resize(1800, 855).png().toFile(path.join(directory, 'contact.png'));
  fs.writeFileSync(path.join(directory, 'CHECKS.json'), JSON.stringify({ javascript_syntax: true, opacity_endpoints: true, foreground_independent: true, fixed_comparisons: true, fire: true, low: true, empty: true, reload: true, mode: true, unknown: true, reset: true, svg_renders: 6, browser_reviewed: false, live_game_verified: false }, null, 2));
  console.log('Open previews rendered at three backing levels and low/empty/unknown states. Translucency endpoints leave foreground unchanged.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
