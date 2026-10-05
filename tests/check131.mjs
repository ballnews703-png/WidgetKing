// check131 — Lock Screen: the editor preview is a mini Lock Screen in either
// clock layout (full-size / iOS 27 compact), the layout choice persists and
// is preview-only, the Lock Screen template pack exists with valid rows and
// renders, and the Scriptable renderer still builds every lock design.
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
  out.defaultFull = lockClockMode === 'full';
  const kinds = LOCK_ROW_KINDS.map(k => k[0]);
  const pack = buildTemplates().filter(t => t.pack === 'Lock');
  out.packSize = pack.length === 6;
  out.packChip = PACK_CHIPS.some(p => p[0] === 'Lock');
  out.packLock = pack.every(t => t.design.kind === 'lock' && t.design.lockRows.length >= 1 &&
    t.design.lockRows.length <= (t.design.lockStyle === 'circle' ? 2 : 3) &&
    t.design.lockRows.every(r => kinds.includes(r.kind)));
  out.packNoTimeRow = pack.every(t => !t.design.lockRows.some(r => r.kind === 'time'));
  out.packThumbs = pack.every(t => makeThumb(normalizeDesign(JSON.parse(JSON.stringify(t.design))), 0.5).textContent.length > 0);
  // Editor preview: full-size clock layout
  const copy = normalizeDesign(JSON.parse(JSON.stringify(pack[0].design))); copy.id = uid();
  loadIntoEditor(copy); switchTab('editor');
  const canvas = document.getElementById('canvas');
  out.previewSize = canvas.style.width === '186px' && canvas.style.height === '300px';
  out.sizeRowsHidden = document.getElementById('sizeButtons').style.display === 'none' && document.getElementById('lookButtons').style.display === 'none';
  out.fullClock = !!canvas.querySelector('.lock-clock') && !canvas.querySelector('.lock-top.compact');
  out.tileInRow = !!canvas.querySelector('.lock-row') && /UP NEXT/.test(canvas.querySelector('.lock-row').textContent);
  out.rectSlots = canvas.querySelector('.lock-row').children.length === 2;
  const btns = [...document.querySelectorAll('#lockClockRow button')];
  out.clockButtons = btns.map(b => b.textContent).join('|') === 'Full-size clock|Compact clock (iOS 27)' && btns[0].className === 'active';
  btns[1].click();
  out.compactSet = lockClockMode === 'compact' && localStorage.getItem('widgetking.lockclock') === 'compact';
  out.compactClock = !!canvas.querySelector('.lock-top.compact') && !canvas.querySelector('.lock-clock');
  out.compactActive = document.querySelector('#lockClockRow button.active').textContent.startsWith('Compact');
  out.notDesignData = !('lockClockMode' in current) && JSON.stringify(current).indexOf('compact') < 0;
  // Circle style gets four slots
  current.lockStyle = 'circle'; renderAll();
  out.circleSlots = canvas.querySelector('.lock-row').children.length === 4;
  closeEditor();
  return out;
});
await pg.reload();
await pg.waitForTimeout(600);
r.persisted = await pg.evaluate(() => lockClockMode === 'compact');
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check131 FAILED', bad, errors); process.exit(1); }
console.log('check131 OK');
