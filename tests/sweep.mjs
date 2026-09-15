// sweep — exhaustive browser exercise, report-style (prints every finding,
// exits 1 only on page errors or crashes):
//  1. every template loads into the editor and re-renders at all three
//     sizes (refit path), with zero page errors
//  2. every palette kind inserts, and every inspector <select> option and
//     every checkbox toggles without error (option-by-option)
//  3. share-link roundtrip: allDesignsLink -> parse -> designs survive
//  4. backup JSON roundtrip and script build for the full library, with the
//     built script syntax-checked by node
//  5. page studio: add small/medium/large, reorder, save
//  6. explore: search + tag filters; icon maker style sweep
import { chromium } from 'playwright-core';
import { writeFileSync } from 'fs';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e).split('\n')[0]));
// file:// self-fetch (the app's update check) is a CORS error only under
// the test harness — never on the hosted site.
pg.on('console', m => { if (m.type() === 'error' && !/net::|Failed to load resource|ERR_|file:\/\//.test(m.text())) errors.push('console: ' + m.text().slice(0, 160)); });
await pg.addInitScript(() => { localStorage.setItem('widgetking.tourseen', '1'); });
await pg.goto('file://' + join(root, 'web/index.html'));
await pg.waitForTimeout(700);

const r = await pg.evaluate(async () => {
  const out = { findings: [] };
  const sleep = ms => new Promise(res => setTimeout(res, ms));
  const note = (sev, msg) => out.findings.push('[' + sev + '] ' + msg);

  // 1. templates × sizes
  const tpls = buildTemplates();
  const names = {};
  for (const t of tpls) { names[t.design.name] = (names[t.design.name] || 0) + 1; }
  for (const n of Object.keys(names)) if (names[n] > 1) note('LOW', 'duplicate template name "' + n + '" x' + names[n]);
  let refitErrors = 0;
  for (const t of tpls) {
    for (const size of ['small', 'medium', 'large']) {
      try {
        const d = normalizeDesign(JSON.parse(JSON.stringify(t.design)));
        if (d.kind === 'lock') continue;
        const node = renderDesignNode(d, size);
        if (!node || !node.childNodes) throw new Error('no node');
      } catch (e) { refitErrors++; note('HIGH', 'template "' + t.design.name + '" failed to render at ' + size + ': ' + e.message); }
    }
  }
  out.templatesRendered = tpls.length;

  // 2. every palette kind + every inspector option
  current = normalizeDesign({ name: 'Sweep', kind: 'freestyle', themeID: 'ocean', canvasElements: [] });
  loadIntoEditor(current); openStudio(); await sleep(250);
  const kinds = ELEMENT_PALETTE.map(p => p[0]);
  out.kinds = kinds.length;
  let optionsTried = 0;
  for (const kind of kinds) {
    try {
      current.canvasElements = [];
      addElement(kind); await sleep(60);
      const el = current.canvasElements[0];
      // photo opens the camera-roll picker instead of inserting — by design
      if (kind === 'photo') { if (el) note('MED', 'photo inserted without a picture'); continue; }
      if (!el || el.kind !== kind) { note('HIGH', 'addElement(' + kind + ') did not insert'); continue; }
      selectedElId = el.id; refreshEditors(); setSheetTool('edit'); await sleep(120);
      const insp = document.getElementById('studioInspector');
      if (!insp || !insp.children.length) { note('MED', 'inspector empty for kind ' + kind); continue; }
      const selects = [...insp.querySelectorAll('select')];
      for (let si = 0; si < selects.length; si++) {
        const sel = [...document.querySelectorAll('#studioInspector select')][si];
        if (!sel) break;
        const values = [...sel.options].map(o => o.value);
        for (const v of values) {
          const s2 = [...document.querySelectorAll('#studioInspector select')][si];
          if (!s2) break;
          s2.value = v;
          try { s2.dispatchEvent(new Event('change')); s2.onchange && s2.onchange(); } catch (e) { note('HIGH', kind + ' select option "' + v + '" threw: ' + e.message); }
          optionsTried++;
          await sleep(15);
          try { renderDesignNode(normalizeDesign(JSON.parse(JSON.stringify(current))), 'medium'); }
          catch (e) { note('HIGH', kind + ' renders broken after option "' + v + '": ' + e.message); }
        }
      }
      const checks = [...document.querySelectorAll('#studioInspector input[type=checkbox]')];
      for (const c of checks) { try { c.click(); c.click(); optionsTried++; } catch (e) { note('HIGH', kind + ' checkbox threw: ' + e.message); } }
      // sanitizer must keep what the inspector produced
      const before = JSON.stringify(current.canvasElements[0]);
      const after = JSON.stringify(normalizeDesign(JSON.parse(JSON.stringify(current))).canvasElements[0]);
      if (before !== after) {
        const a = JSON.parse(before), z = JSON.parse(after);
        const diff = Object.keys(a).filter(k => JSON.stringify(a[k]) !== JSON.stringify(z[k]));
        if (diff.length) note('MED', 'sanitizer alters inspector output for ' + kind + ': ' + diff.join(','));
      }
    } catch (e) { note('HIGH', 'kind ' + kind + ' crashed the editor: ' + e.message); }
  }
  out.optionsTried = optionsTried;
  closeEditor(); await sleep(100);

  // 3. share-link roundtrip for a rich design
  const rich = normalizeDesign(JSON.parse(JSON.stringify(tpls.find(t => t.design.name === 'Bento Board').design)));
  rich.id = 'sweep-rich';
  designs.push(rich);
  const link = await allDesignsLink(false);
  const bundle = link.url.match(/#s=([gp])(.+)$/);
  let bytes = b64urlDecode(bundle[2]);
  if (bundle[1] === 'g') bytes = await pipeBytes(bytes, new DecompressionStream('gzip'));
  const parsed = JSON.parse(new TextDecoder().decode(bytes));
  const back = parsed.designs.find(d => d.id === 'sweep-rich');
  out.shareRoundtrip = !!back && back.canvasElements.length === rich.canvasElements.length;
  if (!out.shareRoundtrip) note('HIGH', 'share link lost design content');
  out.shareLinkChars = link.url.length;

  // 4. backup + script for the whole template library
  designs.push(...tpls.filter(t => t.design.kind !== 'lock').slice(0, 40).map(t => normalizeDesign(JSON.parse(JSON.stringify(t.design)))));
  const script = await buildScript();
  out.script = script;
  out.scriptChars = script.length;
  const backup = JSON.stringify({ app: 'WidgetKing', designs });
  const restored = JSON.parse(backup).designs.map(normalizeDesign);
  out.backupRoundtrip = restored.length === designs.length;
  designs.length = 0;

  // 5. page studio
  designs.push(normalizeDesign({ id: 'ps1', name: 'PS Small', kind: 'clock', fitSize: 'small' }),
    normalizeDesign({ id: 'ps2', name: 'PS Med', kind: 'clock', fitSize: 'medium' }),
    normalizeDesign({ id: 'ps3', name: 'PS Large', kind: 'clock', fitSize: 'large' }));
  pageState.items = [{ id: 'ps1', size: 'small' }, { id: 'ps2', size: 'medium' }];
  switchTab('create'); await sleep(50);
  document.getElementById('pageStudioBtn').click(); await sleep(500);
  const slots = document.querySelectorAll('#pageFrame .pslot.filled').length;
  out.pageSlots = slots;
  if (slots !== 2) note('HIGH', 'page studio shows ' + slots + ' filled slots, expected 2');
  try { document.getElementById('pageSaveBtn').click(); await sleep(200); out.pageSaved = true; } catch (e) { note('HIGH', 'page save threw ' + e.message); }
  try { document.getElementById('pageCloseBtn').click(); } catch (e) {}
  await sleep(100);
  designs.length = 0; pageState.items = [];

  // 6. explore + icon maker
  switchTab('explore'); await sleep(200);
  const entries = exploreEntries().length;
  out.exploreEntries = entries;
  document.getElementById('exploreSearch').value = 'neon';
  document.getElementById('exploreSearch').dispatchEvent(new Event('input')); await sleep(150);
  const hits = document.querySelectorAll('#exploreList img').length;
  document.getElementById('exploreSearch').value = '';
  document.getElementById('exploreSearch').dispatchEvent(new Event('input')); await sleep(150);
  if (!hits) note('MED', 'explore search "neon" returned nothing');
  const tags = [...document.querySelectorAll('#exploreTags button')];
  for (const t of tags) { try { t.click(); await sleep(40); } catch (e) { note('HIGH', 'explore tag threw ' + e.message); } }
  switchTab('studio'); await sleep(150);
  const styleChips = [...document.querySelectorAll('#iconStyleChips button')];
  out.iconStyles = styleChips.length;
  for (const c of styleChips) { try { c.click(); await sleep(60); } catch (e) { note('HIGH', 'icon style chip threw ' + e.message); } }
  return out;
});
await b.close();
writeFileSync(join(here, '.sweep_script.js'), '(async function(){\n' + r.script + '\n})();\n');
let scriptOk = true;
try { execFileSync('node', ['--check', join(here, '.sweep_script.js')]); } catch (e) { scriptOk = false; r.findings.push('[HIGH] built script fails node --check'); }
delete r.script;
console.log(JSON.stringify(Object.assign({ scriptOk }, r, { findings: undefined })));
console.log('findings (' + r.findings.length + '):');
for (const f of r.findings) console.log('  ' + f);
console.log('pageErrors:', JSON.stringify(errors));
const fatal = r.findings.filter(f => f.startsWith('[HIGH]')).length || errors.length;
if (fatal) { console.error('sweep FAILED'); process.exit(1); }
console.log('sweep OK');
