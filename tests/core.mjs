// core — broad boot-and-behave smoke: the app loads with zero page errors,
// every tab lands, the version badge matches, key surfaces render (templates,
// explore, icon maker, studio editor, page studio, settings), the stock
// sticker library is intact, the AI schema stays coherent with the prompt,
// and the generated Scriptable script builds with placeholders filled.
// (Successor to the pre-container-loss smoke battery, consolidated.)
import { chromium } from 'playwright-core';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const version = readFileSync(join(root, 'web/index.html'), 'utf8').match(/WK_VERSION = (\d+)/)[1];
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e)));
await pg.addInitScript(() => { localStorage.setItem('widgetking.tourseen', '1'); });
await pg.goto('file://' + join(root, 'web/index.html'));
await pg.waitForTimeout(700);
const r = await pg.evaluate(async ([ver]) => {
  const out = {};
  const sleep = ms => new Promise(res => setTimeout(res, ms));
  const visible = id => { const n = document.getElementById(id); return !!n && getComputedStyle(n).display !== 'none'; };

  // navigation + version
  const tabs = [...document.querySelectorAll('#tabbar button')].map(x => x.dataset.tab);
  out.tabSet = JSON.stringify(tabs) === JSON.stringify(['create', 'explore', 'widgets', 'studio', 'settings']);
  out.tabsLand = true;
  for (const t of tabs) {
    switchTab(t); await sleep(40);
    const panes = [...document.querySelectorAll('.pane-' + t)];
    if (!panes.length || panes.every(p => getComputedStyle(p).display === 'none')) out.tabsLand = t;
  }
  out.version = document.getElementById('appVersion').textContent.includes('v' + ver);

  // create surface + templates
  switchTab('create'); await sleep(40);
  out.homeCards = visible('newWidgetBtn') && visible('cloneBtn') && visible('builderBtn');
  out.templates = buildTemplates().length >= 60;
  const card = document.querySelector('#templateRow .tpl-card');
  out.templateCards = !!card;

  // stock library + sticker element
  out.stockArt = typeof STOCK_ART !== 'undefined' && STOCK_ART.length >= 129 && STOCK_ART_PACKS.length >= 12;
  out.stockUrls = stockArtUrl('clear-day') === 'stock/art/clear-day.png' && stockArtUrl('../evil') === '';
  const sd = normalizeDesign({ name: 'S', kind: 'freestyle', canvasElements: [
    { id: 't1', kind: 'sticker', stockId: 'galaxy', x: 0.5, y: 0.4 }] });
  const node = renderDesignNode(sd, 'small');
  document.body.appendChild(node);
  const img = node.querySelector('img');
  await new Promise(res => { if (!img || img.complete) res(); else { img.onload = res; img.onerror = res; } });
  out.stickerRenders = !!img && img.naturalWidth > 0;
  node.remove();

  // AI plumbing: schema coherent, prompt split intact, model roster sane
  const el = AI_SCHEMA.properties.canvasElements.items;
  out.schemaModes = ['now', 'hilo', 'cond', 'hourly', 'icon', 'sun', 'moonicon', 'next'].every(x => el.properties.mode.enum.includes(x));
  out.schemaSticker = el.properties.kind.enum.includes('sticker') && el.properties.stockId.enum.length === STOCK_ART.length + 1;
  out.promptCore = (s => s.includes('LIVE ART') && s.includes('STICKERS') && s.includes('STYLE REFERENCES'))(aiSystemPrompt('x'));
  out.promptSplit = aiSystemPrompt('x').indexOf(aiSystemPromptStable()) === 0 && !aiSystemPromptStable().includes('STYLE REFERENCES');
  out.models = JSON.stringify([...document.getElementById('aiModel').options].map(o => o.value)) ===
    JSON.stringify(['claude-sonnet-5', 'claude-haiku-4-5']) && aiModel() === 'claude-sonnet-5';

  // editor opens and inserts
  current = normalizeDesign({ name: 'CoreTest', kind: 'freestyle', themeID: 'ocean', canvasElements: [
    { id: 'c1', kind: 'text', text: 'Hello', x: 0.5, y: 0.3, size: 16 }] });
  loadIntoEditor(current); openStudio(); await sleep(250);
  out.studioOpens = document.getElementById('editorMode').classList.contains('open');
  out.railTools = document.querySelectorAll('#editorRail button').length === 9;
  const before = current.canvasElements.length;
  addElement('emoji'); await sleep(120);
  out.insertWorks = current.canvasElements.length === before + 1;
  closeEditor(); await sleep(100);

  // page studio opens with a live tile
  designs.push(current);
  pageState.items = [{ id: current.id, size: 'small' }];
  switchTab('create'); await sleep(40);
  document.getElementById('pageStudioBtn').click(); await sleep(500);
  out.pageStudio = !!document.querySelector('#pageFrame .pslot');
  document.getElementById('pageCloseBtn').click(); await sleep(80);
  pageState.items = []; designs.pop();

  // script build: placeholders filled, carries the version
  const script = await buildScript();
  out.scriptBuilds = script.includes('WK_VERSION = ' + ver) && !script.includes('__DESIGNS__') &&
    !script.includes('__PAGE_URL__');
  // welcome tour art
  showWelcomeTour(); await sleep(400);
  out.tourArt = ['wtArtL', 'wtArt0', 'wtArtR', 'wtArt1', 'wtArt4L', 'wtArt4C', 'wtArt4R']
    .every(id => document.getElementById(id).childElementCount === 1);
  document.getElementById('wtBrowseBtn').click(); await sleep(80);
  return out;
}, [version]);
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('core FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('core OK');
