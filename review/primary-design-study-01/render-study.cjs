const fs = require('fs');
const path = require('path');
const vm = require('vm');
const sharp = require('../../tools/runtime_dependencies.cjs').getSharp();
const directory = __dirname;
const html = fs.readFileSync(path.join(directory, 'index.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const svgSources = [...html.matchAll(/<svg\b[\s\S]*?<\/svg>/g)].map(match => match[0]);
const nodes = new Map();
function node(id) {
  if (!nodes.has(id)) nodes.set(id, {
    textContent: '', value: id === 'mode' ? 'AUTO' : id === 'state' ? 'ready' : 'dark',
    attributes: {}, children: [], listeners: {}, disabled: false,
    classList: { toggle() {} },
    setAttribute(key, value) { this.attributes[key] = value; },
    addEventListener(event, callback) { this.listeners[event] = callback; },
    replaceChildren() { this.children = []; },
    appendChild(child) { this.children.push(child); }
  });
  return nodes.get(id);
}
const document = {
  getElementById: node,
  querySelectorAll: () => [node('stage-a'), node('stage-b'), node('stage-c')],
  createElementNS: () => ({ attributes: {}, setAttribute(key, value) { this.attributes[key] = value; } })
};
vm.runInNewContext(script, { document }, { filename: 'index.html inline script' });
function expect(condition, message) { if (!condition) throw new Error(message); }
function change(id, value) { const control = node(id); control.value = value; control.listeners.change.call(control); }
function click(id) { node(id).listeners.click(); }
expect(node('sample').textContent === '27 / 45 Â· 6 spare magazines', 'Initial sample');
click('fire'); expect(node('a-count').textContent === '26', 'Fire decrements one round');
change('state', 'low'); expect(node('b-status').textContent === 'LOW AMMO', 'Low warning');
change('state', 'empty'); expect(node('fire').disabled && node('c-status').textContent === 'EMPTY', 'Empty state');
click('reload'); expect(node('a-count').textContent === '45' && node('a-reserve').textContent === '5', 'Reload consumes one spare');
change('mode', 'BURST'); expect(node('c-mode').textContent === 'BURST', 'Mode shared across concepts');
change('state', 'unknown'); expect(node('a-count').textContent === 'â€”' && node('b-status').textContent === 'NO DATA' && node('fire').disabled && node('reload').disabled, 'Unknown stays unknown');
change('field', 'light');
click('reset'); expect(node('b-count').textContent === '27' && node('c-mode').textContent === 'AUTO', 'Reset restores sample');
const css = '.hud-label{font:11px Consolas,monospace;letter-spacing:.08em}.hud-count{font-family:Segoe UI,sans-serif;font-weight:600;letter-spacing:-.06em}.hud-mono{font-family:Consolas,monospace}.stroke{vector-effect:non-scaling-stroke}';
function preview(source) {
  source = source.replace(/<svg\b[^>]*>/, '<svg xmlns="http://www.w3.org/2000/svg" width="360" height="220" viewBox="0 0 360 220"><style>' + css + '</style>');
  source = source.replace('<g id="a-pips" fill="#d5c487"></g>', '<g fill="#d5c487">' + Array.from({ length: 6 }, (_, i) => '<rect x="' + (222 + i * 12) + '" y="139" width="7" height="12" opacity=".8"/>').join('') + '</g>');
  return source;
}
const names = ['Receiver', 'Open', 'Dial'];
const notes = ['Loaded / reserve block / mode', 'Loaded / reserve number / mode', 'Loaded + arc / supply tab / mode'];
async function main() {
  const images = [];
  for (let index = 0; index < svgSources.length; index++) {
    const svg = preview(svgSources[index]);
    fs.writeFileSync(path.join(directory, names[index].toLowerCase() + '.svg'), svg);
    const png = await sharp(Buffer.from(svg)).resize(720, 440).png().toBuffer();
    fs.writeFileSync(path.join(directory, names[index].toLowerCase() + '.png'), png);
    images.push(png);
  }
  const panels = names.map((name, i) => '<g transform="translate(' + (24 + i * 384) + ',92)"><text x="0" y="0" fill="#edece5" font-size="22" font-family="Segoe UI,sans-serif">' + String.fromCharCode(65 + i) + ' / ' + name + '</text><rect x="0" y="20" width="360" height="260" fill="url(#field)"/><image x="0" y="40" width="360" height="220" href="data:image/png;base64,' + images[i].toString('base64') + '"/><text x="0" y="304" fill="#afbab7" font-size="13" font-family="Segoe UI,sans-serif">' + notes[i] + '</text></g>').join('');
  const contact = '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="470"><defs><linearGradient id="field" x2=".7" y2="1"><stop stop-color="#26352e"/><stop offset=".6" stop-color="#182b28"/><stop offset="1" stop-color="#172329"/></linearGradient></defs><rect width="1200" height="470" fill="#101416"/><text x="24" y="30" fill="#d5c487" font-size="12" letter-spacing="2" font-family="Consolas,monospace">DBF / PRIMARY STUDY 01</text><text x="24" y="58" fill="#ecede7" font-size="23" font-family="Segoe UI,sans-serif">AR-23 Liberator Â· Three fresh directions</text>' + panels + '<text x="24" y="444" fill="#a2acae" font-size="12" font-family="Segoe UI,sans-serif">Flat concept studies Â· Illustrative sample state Â· Existing designs preserved as fallback</text></svg>';
  fs.writeFileSync(path.join(directory, 'contact.svg'), contact);
  await sharp(Buffer.from(contact)).resize(1800, 705).png().toFile(path.join(directory, 'contact.png'));
  fs.writeFileSync(path.join(directory, 'CHECKS.json'), JSON.stringify({ javascript_syntax: true, initial_state: true, fire: true, low: true, empty: true, reload: true, fire_mode: true, unknown: true, reset: true, svg_renders: images.length, browser_reviewed: false, live_game_verified: false }, null, 2));
  console.log('Three SVG previews rendered; sample state transitions passed. Browser and game appearance unverified.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
