/* Showcase controls only. Rendering and approved instrument geometry remain in study.js. */
'use strict';
(() => {
  const get = id => document.getElementById(id);
  const presets = {
    chamber: {family:'magazine', state:'chamber', readoutView:'combat'},
    charge: {family:'charge', state:'ready', readoutView:'inspect'},
    settings: {family:'stress', state:'ready', readoutView:'inspect'},
    spent: {family:'expendable', state:'empty', readoutView:'combat'}
  };
  const system = window.UniversalStudy;
  const familyKeys = Object.keys(system.samples);
  const controlEvent = id => get(id).dispatchEvent(new Event('input', {bubbles:true}));
  const readingNotes = {
    magazine:'Rounds take priority. Spare magazines sit in their own pod, fire select stays to the right, and a chambered round has its own status.',
    belt:'Three digits, a proportion gauge, and spare belts. The selected fire rate stays one glance away from the main count.',
    shells:'Count the shells in the weapon and the loose shells in reserve. Each reading keeps its own clear unit.',
    heat:'Read heat as a percentage. Spare sinks sit separately; HOT and VENTING spell out the state.',
    charge:'The charge reading takes priority while a shot builds. The loaded round, spare shots, and safety setting remain separate.',
    ammo:'A compact ammunition node makes the selected payload clear. The loaded shot stays prominent and reserve supply stays to the left.',
    expendable:'One loaded shot. SINGLE USE marks the supply; SPENT makes the result of firing unmistakable.',
    fuel:'Fuel gets a precise reading and an immediate proportion gauge. Spare tanks remain a separate supply.',
    infinite:'Continuous energy gets its own symbol. The instrument stays open without an unnecessary ammunition or reserve count.',
    stress:'An illustrative mixed-settings example: fire select, rate, ammunition, and safety remain four independent readings. Inspect reveals their names.'
  };
  function fitCards() {
    const [width] = system.layoutSize('split',system.options());
    get('familyGrid').querySelectorAll('.family-card').forEach(card => {
      card.style.setProperty('--card-scale',Math.min(.72,(card.clientWidth-22)/width));
    });
  }
  function fitBench() {
    const button = document.querySelector('[data-view="inspect"]');
    if (!button.classList.contains('active')) return;
    const viewport = get('sceneViewport'), world = get('world'), instrument = get('instrument');
    const [width,height] = system.layoutSize('split',system.options());
    const size = +get('scale').value / 100;
    const zoom = Math.min(3,(viewport.clientWidth-54)/(width*size),(viewport.clientHeight-76)/(height*size));
    if (!(zoom > 0)) return;
    world.style.setProperty('--scene-scale',zoom);
    world.style.left = (viewport.clientWidth/2-parseFloat(instrument.style.left)*zoom)+'px';
    world.style.top = (viewport.clientHeight/2-parseFloat(instrument.style.top)*zoom)+'px';
    button.textContent = `Bench ×${Number(zoom.toFixed(1))}`;
    get('stageLabel').textContent = 'BENCH VIEW · DRAG TO PLACE';
  }
  function decorateCards() {
    get('familyGrid').querySelectorAll('.family-card').forEach((card,index) => {
      const key = familyKeys[index];
      card.dataset.family = key;
      card.tabIndex = 0;
      card.setAttribute('role','button');
      card.setAttribute('aria-label',`Preview ${system.samples[key].title}: ${system.samples[key].name}`);
      card.setAttribute('aria-pressed',String(key === get('family').value));
      card.classList.toggle('active',key === get('family').value);
      const number = document.createElement('span');
      number.className = 'family-number';
      number.setAttribute('aria-hidden','true');
      number.textContent = String(index + 1).padStart(2,'0');
      card.appendChild(number);
    });
    fitCards();
  }
  function reflectControls() {
    const family = get('family').value, state = get('state').value;
    document.querySelectorAll('[data-preset]').forEach(button => {
      const p = presets[button.dataset.preset];
      const active = family === p.family && state === p.state && get('readoutView').value === p.readoutView;
      button.classList.toggle('active',active);
      button.setAttribute('aria-pressed',String(active));
    });
    const m = system.display(system.samples[family],state);
    get('readingExplanation').textContent = readingNotes[family];
    get('readingState').textContent = m.status || 'READY';
    get('readingState').classList.toggle('is-empty',state === 'empty');
    const field = get('angle').value !== 'neutral';
    get('sceneViewport').classList.toggle('is-field',field);
    document.querySelectorAll('[data-environment]').forEach(button => {
      const active = button.dataset.environment === (field ? 'field' : 'bench');
      button.classList.toggle('active',active);
      button.setAttribute('aria-pressed',String(active));
    });
    document.querySelectorAll('[data-view]').forEach(button => button.setAttribute('aria-pressed',String(button.classList.contains('active'))));
    fitBench();
  }
  function chooseFamily(key) {
    if (!Object.hasOwn(system.samples,key)) return;
    get('family').value = key;
    get('state').value = 'ready';
    controlEvent('family');
    reflectControls();
  }
  document.querySelectorAll('[data-preset]').forEach(button => button.addEventListener('click',() => {
    const preset = presets[button.dataset.preset];
    chooseFamily(preset.family);
    get('state').value = preset.state;
    get('readoutView').value = preset.readoutView;
    controlEvent('state');
    reflectControls();
  }));
  document.querySelectorAll('[data-environment]').forEach(button => button.addEventListener('click',() => {
    const field = button.dataset.environment === 'field';
    get('angle').value = field ? '0' : 'neutral';
    get('angle').dispatchEvent(new Event('change',{bubbles:true}));
    document.querySelector(`[data-view="${field ? 'fit' : 'inspect'}"]`).click();
    reflectControls();
  }));
  get('familyGrid').addEventListener('click',event => {
    const card = event.target.closest('[data-family]');
    if (card) chooseFamily(card.dataset.family);
  });
  get('familyGrid').addEventListener('keydown',event => {
    if (event.key !== 'Enter' && event.key !== ' ') return;
    const card = event.target.closest('[data-family]');
    if (card) {event.preventDefault(); const key=card.dataset.family; chooseFamily(key); queueMicrotask(() => get('familyGrid').querySelector(`[data-family="${key}"]`)?.focus());}
  });
  get('workbench').addEventListener('input',reflectControls);
  get('angle').addEventListener('change',reflectControls);
  document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click',reflectControls));
  get('reset').addEventListener('click',reflectControls);
  get('recenter').addEventListener('click',reflectControls);
  new MutationObserver(decorateCards).observe(get('familyGrid'),{childList:true});
  new ResizeObserver(fitBench).observe(get('sceneViewport'));
  new ResizeObserver(fitCards).observe(get('familyGrid'));
  decorateCards();
  document.querySelector('[data-view="inspect"]').click();
  reflectControls();
})();
