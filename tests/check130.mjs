// check130 — Home Screen look (iOS Clear / Tinted): the look persists, every
// drawn design (preview, library thumb, template gallery) is wrapped in the
// stencil-over-glass simulation when it's on, the readiness scorer ranks the
// obvious cases correctly, the Clear-look template pack exists and renders,
// the AI's variable prompt carries the stencil doctrine only when a look is
// set, and the Settings row cycles the looks.
import { chromium } from 'playwright-core';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e)));
await pg.addInitScript(() => { localStorage.setItem('widgetking.tourseen', '1'); });
await pg.goto('file://' + join(root, 'web/index.html'));
await pg.waitForTimeout(700);
const r = await pg.evaluate(async () => {
  const out = {};
  out.defaultLook = homeLook === 'default' && document.getElementById('lookVal').textContent === 'Default';
  // Readiness scorer on the obvious cases
  const dark = normalizeDesign({ name: 'D', kind: 'freestyle', themeID: 'custom', customColors: ['#050507', '#15151C'], textColorHex: '#FFFFFF',
    canvasElements: [{ kind: 'clock', x: .5, y: .5, size: 30, colorHex: '#FFFFFF', opacity: 1 }] });
  const light = normalizeDesign({ name: 'L', kind: 'clock', themeID: 'paper', textColorHex: '#333333' });
  const photo = normalizeDesign({ name: 'P', kind: 'freestyle', themeID: 'midnight', textColorHex: '#FFFFFF',
    canvasElements: [{ kind: 'photo', x: .5, y: .5, w: .9, h: .9, opacity: 1 }] });
  const glassLight = normalizeDesign({ name: 'G', kind: 'clock', background: 'glass', glassTint: 'light', textColorHex: '#FFFFFF' });
  out.readyDark = lookReadiness(dark).level === 'ready';
  out.washedLight = lookReadiness(light).level === 'washed';
  out.washedPhoto = lookReadiness(photo).level === 'washed' && /photo/.test(lookReadiness(photo).note);
  out.washedGlassLight = lookReadiness(glassLight).level === 'washed';
  out.lockNull = lookReadiness(normalizeDesign({ name: 'K', kind: 'lock' })) === null;
  // Clear-look pack: 6 templates, all score ready, all render as nodes
  const pack = buildTemplates().filter(t => t.pack === 'ClearLook');
  out.packSize = pack.length === 6;
  out.packReady = pack.every(t => lookReadiness(normalizeDesign(JSON.parse(JSON.stringify(t.design)))).level === 'ready');
  out.packChip = PACK_CHIPS.some(p => p[0] === 'ClearLook');
  out.packRenders = pack.every(t => renderDesignNode(normalizeDesign(JSON.parse(JSON.stringify(t.design))), t.size).childNodes.length > 0);
  // Default look: nothing is wrapped, no doctrine
  renderPreview();
  out.noWrapDefault = !document.querySelector('#canvas .look-wrap');
  out.noDoctrineDefault = !/HOME SCREEN LOOK/.test(aiSystemPromptVariable('a clock'));
  out.thumbPlainDefault = !makeThumb(dark, 0.5).querySelector('.look-wrap');
  // Switch to Clear via the Settings row (cycles default -> clear)
  document.getElementById('lookRow').click();
  out.clearSet = homeLook === 'clear' && localStorage.getItem('widgetking.look') === 'clear' &&
    document.getElementById('lookVal').textContent === 'Clear';
  out.previewWrapped = !!document.querySelector('#canvas .look-wrap.look-clear .look-layer') && !document.querySelector('#canvas .look-tint');
  out.lookButtons = [...document.querySelectorAll('#lookButtons button')].map(b => b.textContent).join(',') === 'Default,Clear,Tinted' &&
    document.querySelector('#lookButtons button.active').textContent === 'Clear';
  out.hintShown = document.getElementById('lookHint').style.display === 'block' && document.getElementById('lookHint').textContent.length > 20;
  out.doctrineClear = /HOME SCREEN LOOK: .*Clear look/.test(aiSystemPromptVariable('a clock'));
  out.magicHint = /Clear Home Screen look/.test(document.getElementById('magicHint').textContent);
  out.thumbWrapped = !!makeThumb(dark, 0.5).querySelector('.look-wrap');
  // Template gallery: thumbs wrapped and readiness badges on the cards
  renderTemplates();
  const cards = [...document.querySelectorAll('#templateRow .tpl-card')];
  out.galleryWrapped = cards.length > 0 && cards.every(c => c.querySelector('.look-wrap'));
  out.galleryBadges = cards.some(c => /Clear-ready/.test(c.querySelector('.tpl-cat').textContent)) &&
    cards.some(c => /washes out|fades/.test(c.querySelector('.tpl-cat').textContent));
  // Tinted adds the accent multiply layer; the dock buttons switch too
  [...document.querySelectorAll('#lookButtons button')].find(b => b.textContent === 'Tinted').click();
  out.tintedSet = homeLook === 'tinted' && !!document.querySelector('#canvas .look-wrap.look-tinted .look-tint');
  out.doctrineTinted = /Tinted look/.test(aiSystemPromptVariable('a clock'));
  // Playlist preview respects the look; lock designs never get wrapped
  const lock = normalizeDesign({ name: 'Lk', kind: 'lock' });
  out.lockThumbPlain = !makeThumb(lock, 0.5).querySelector('.look-wrap');
  // Studio peek: freestyle designs edit on the Studio canvas (dock hidden);
  // the corner button shows the stencil overlay and a tap on it dismisses.
  const tpl = buildTemplates().find(t => t.design.name === 'Stencil Clock');
  const copy = normalizeDesign(JSON.parse(JSON.stringify(tpl.design))); copy.id = uid();
  previewSize = 'small'; loadIntoEditor(copy); switchTab('editor');
  const peekBtn = document.getElementById('studioLookBtn');
  out.peekBtnShown = peekBtn.style.display !== 'none' && /See it on Tinted/.test(peekBtn.textContent);
  peekBtn.click();
  const ov = document.getElementById('studioLookOverlay');
  out.peekOverlay = !!ov && !!ov.querySelector('.look-wrap.look-tinted') && ov.style.width === document.getElementById('studioCanvas').style.width;
  out.peekLabel = /Back to editing/.test(peekBtn.textContent);
  ov.click();
  out.peekDismissed = !document.getElementById('studioLookOverlay') && /See it on/.test(peekBtn.textContent);
  closeEditor();
  // Back to default via the dock
  [...document.querySelectorAll('#lookButtons button')].find(b => b.textContent === 'Default').click();
  out.backToDefault = homeLook === 'default' && !document.querySelector('#canvas .look-wrap') &&
    document.getElementById('lookHint').style.display === 'none' && document.getElementById('studioLookBtn').style.display === 'none';
  // Persistence survives a reload (read back below)
  localStorage.setItem('widgetking.look', 'tinted');
  return out;
});
await pg.reload();
await pg.waitForTimeout(600);
r.persisted = await pg.evaluate(() => homeLook === 'tinted' && document.querySelector('#lookButtons button.active').textContent === 'Tinted');
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check130 FAILED', bad, errors); process.exit(1); }
console.log('check130 OK');
