// check136 — M4 full-page widget: the XL size exists everywhere a size can be
// picked, the AI knows it, Page Studio turns a page into one XL design with
// every piece re-mapped into its slot, and the Scriptable template keys an
// XL layout correctly.
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
const r = await pg.evaluate(() => {
  const out = {};
  out.size = SIZES.xl[0] === 338 && SIZES.xl[1] === 540 && SIZE_LABELS.xl.indexOf('XL') === 0;
  out.schema = AI_SCHEMA.properties.size.enum.includes('xl') && /xl 338x540/.test(aiSystemPromptStable());
  out.tplAlias = document.getElementById('scriptableTemplate').textContent.includes('if (family === "extraLargePortrait") family = "xl";');
  // dock buttons on a simple design
  loadIntoEditor(normalizeDesign({ name: 'C', kind: 'clock' })); switchTab('editor');
  const dock = [...document.querySelectorAll('#sizeButtons button')].map(x => x.textContent);
  out.dockButtons = dock.length === 4 && dock[3] === 'XL · full page';
  document.querySelectorAll('#sizeButtons button')[3].click();
  out.dockXl = previewSize === 'xl' && current.fitSize === 'xl' && document.getElementById('canvas').style.height === '540px' &&
    document.getElementById('xlHint').style.display === 'block';
  // studio buttons on a freestyle design; switching to XL keeps every piece in bounds
  const fs = normalizeDesign({ name: 'F', kind: 'freestyle', fitSize: 'small', canvasElements: [
    { kind: 'clock', x: 0.5, y: 0.4, size: 30 }, { kind: 'date', x: 0.5, y: 0.7, size: 12 }] });
  loadIntoEditor(fs);
  const studio = [...document.querySelectorAll('#studioSizeButtons button')].map(x => x.textContent);
  out.studioButtons = studio.join('') === 'SMLXL';
  document.querySelectorAll('#studioSizeButtons button')[3].click();
  out.studioXl = studioSize === 'xl' && current.fitSize === 'xl' && current.canvasElements.every(e => e.x > 0 && e.x < 1 && e.y > 0 && e.y < 1);
  closeEditor();
  // Page Studio export: two designs on a page -> one XL design
  designs.length = 0;
  const a = normalizeDesign({ id: 'pa', name: 'Clock A', kind: 'freestyle', themeID: 'ocean', fitSize: 'small',
    canvasElements: [{ kind: 'clock', x: 0.5, y: 0.5, size: 30, colorHex: '#FFFFFF' }] });
  const bb = normalizeDesign({ id: 'pb', name: 'Weather B', kind: 'freestyle', themeID: 'sunset', fitSize: 'medium',
    canvasElements: [{ kind: 'weather', wmode: 'now', x: 0.3, y: 0.5, size: 24, colorHex: '#FFFFFF' }, { kind: 'ring', source: 'day', x: 0.8, y: 0.5, w: 0.6 }] });
  const c = normalizeDesign({ id: 'pc', name: 'Simple C', kind: 'countdown', themeID: 'berry', targetDate: '2027-01-01' });
  designs.push(a, bb, c);
  pageState.items = [{ id: 'pa', size: 'small' }, { id: 'pc', size: 'small' }, { id: 'pb', size: 'medium' }];
  const page = exportPageAsWidget();
  out.pageMade = !!page && page.kind === 'freestyle' && page.fitSize === 'xl' && page.background === 'clear';
  const kinds = page.canvasElements.map(e => e.kind);
  out.pageHasCards = kinds.filter(k => k === 'shape').length >= 3 && kinds.includes('clock') && kinds.includes('weather') && kinds.includes('ring') && kinds.includes('countdown');
  out.pageInBounds = page.canvasElements.every(e => e.x >= 0 && e.x <= 1 && e.y >= 0 && e.y <= 1 && (e.w == null || e.w <= 1) && (e.h == null || e.h <= 1));
  const clock = page.canvasElements.find(e => e.kind === 'clock');
  out.clockKeepsSize = clock && Math.abs(clock.size - 30 * (0.4029 * 338 / 158) / (338 / 158)) < 2 && clock.y < 0.4;
  out.pageRenders = renderDesignNode(page, 'xl').querySelectorAll('.cel').length === page.canvasElements.length;
  out.emptyPage = (pageState.items = [], exportPageAsWidget()) === null;
  designs.length = 0; persist();
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check136 FAILED', bad, errors); process.exit(1); }
console.log('check136 OK');
