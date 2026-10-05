// check133 — Lock Screen canvas mode: lock designs can be rows (simple) or a
// drag-and-drop canvas on a 172×76 / 76×76 tile; the Studio opens for canvas
// lock designs with Rect/Circle buttons; rows convert to pieces; previews and
// thumbnails draw the composition; the new template packs exist; the
// Scriptable template bakes canvas lock widgets as one image.
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
  out.sizes = SIZES.lockRect[0] === 172 && SIZES.lockRect[1] === 76 && SIZES.lockCircle[0] === 76;
  const rows = normalizeDesign({ name: 'R', kind: 'lock', lockStyle: 'circle', lockRows: [{ kind: 'time' }, { kind: 'battery' }] });
  out.defaultRows = rows.lockMode === 'rows' && rows.fitSize === 'lockCircle';
  // rows → canvas conversion keeps it a lock design and maps every row
  out.converted = convertLockToCanvas(rows) === true && rows.lockMode === 'canvas' && rows.kind === 'lock' &&
    rows.canvasElements.map(e => e.kind).join(',') === 'clock,battery' && rows.canvasElements.every(e => e.x === 0.5);
  out.convertIdempotent = convertLockToCanvas(rows) === false;
  // the template packs
  const tpls = buildTemplates();
  const lockCanvas = tpls.filter(t => t.pack === 'Lock' && t.design.lockMode === 'canvas');
  out.lockCanvasPack = lockCanvas.length === 8 && lockCanvas.every(t => t.design.canvasElements.length >= 2);
  const counts = {};
  for (const t of tpls) counts[t.pack] = (counts[t.pack] || 0) + 1;
  out.packsGrew = counts.Picks >= 11 && counts.Bento >= 7 && counts.Cute >= 9 && counts.Minimal >= 6 && counts.Zen >= 8 &&
    counts.Work >= 6 && counts.Neon >= 5 && counts.Live >= 7 && counts.Designer >= 9 && counts.Glass >= 7 && counts.Sports >= 7;
  const names = tpls.map(t => t.design.name);
  out.uniqueNames = new Set(names).size === names.length;
  // every template renders as a node (lock ones through the lock preview)
  out.allRender = tpls.every(t => renderDesignNode(normalizeDesign(JSON.parse(JSON.stringify(t.design))), t.size || 'small').childNodes.length > 0);
  // a canvas lock thumbnail carries the freestyle pieces, desaturated
  const ring = normalizeDesign(JSON.parse(JSON.stringify(lockCanvas.find(t => t.design.name === 'Ring Battery').design)));
  const thumb = makeThumb(ring, 0.5);
  out.thumbPieces = thumb.querySelectorAll('.cel').length === 2 && /grayscale/.test(thumb.innerHTML);
  // the editor: canvas lock designs open the Studio at the tile size
  const copy = JSON.parse(JSON.stringify(ring)); copy.id = uid();
  loadIntoEditor(copy); switchTab('editor');
  out.studioOpen = studioOpen === true && document.getElementById('studio').classList.contains('open') &&
    document.getElementById('previewDock').style.display === 'none';
  const sc = document.getElementById('studioCanvas');
  out.studioLockStyle = sc.classList.contains('lock-canvas') && sc.style.borderRadius === '50%' &&
    document.getElementById('studioStage').classList.contains('lock-stage');
  out.studioSize = studioSize === 'lockCircle' && Math.abs(sc.clientWidth - sc.clientHeight) <= 1 && sc.querySelectorAll('.cel').length === 2;
  const sizeBtns = [...document.querySelectorAll('#studioSizeButtons button')];
  out.sizeButtons = sizeBtns.map(x => x.textContent).join('') === '▭◯' && sizeBtns[1].className === 'active';
  sizeBtns[0].click();
  out.switchedRect = current.lockStyle === 'rect' && current.fitSize === 'lockRect' && studioSize === 'lockRect' &&
    sc.clientWidth > sc.clientHeight * 2;
  // lock-mode row in the Widget tool: back to rows hides the canvas
  const modeBtns = [...document.querySelectorAll('#lockModeRow button')];
  out.modeButtons = modeBtns.map(x => x.textContent).join('|') === 'Simple rows|Drag & drop canvas' && modeBtns[1].className === 'active';
  modeBtns[0].click();
  out.backToRows = current.lockMode === 'rows' && studioOpen === false && document.getElementById('previewDock').style.display === '' &&
    document.getElementById('lockRowsBox').style.display === '';
  out.previewTile = !!document.querySelector('#canvas .lock-row');
  // a plain design after a lock one never inherits a lock size
  loadIntoEditor(normalizeDesign({ name: 'Plain', kind: 'clock' }));
  out.previewSizeReset = previewSize === 'small' && current.fitSize === 'small';
  closeEditor();
  // the Scriptable template bakes canvas lock widgets
  const tpl = document.getElementById('scriptableTemplate').textContent;
  out.tplCanvas = tpl.includes('design.lockMode === "canvas"') && tpl.includes('accessoryRectangular: [172, 76]') &&
    tpl.includes('(accessory ? 76 : 158)') && tpl.includes('addAccessoryWidgetBackground = true');
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check133 FAILED', bad, errors); process.exit(1); }
console.log('check133 OK');
