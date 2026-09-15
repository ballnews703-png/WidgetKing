// check127 — "do them all": wallpaper-missing hint in the template, lockStyle
// honored on the phone, widget-count meter recorded at export, onyx bevel on
// the phone, last-synced stamp in the Account section, and the consolidated
// helpers (one App Store search, one link encoder, one DOM snapshot, one
// link upgrader) still behave.
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
  const tpl = document.getElementById('scriptableTemplate').textContent;
  out.tplHint = tpl.includes('function wallpaperMissing') && tpl.includes('WALLPAPER_HINT');
  out.tplLockStyle = tpl.includes('design.lockStyle === "circle"');
  out.tplOnyxNeu = /onyx:\s*\{[^}]*neu: true/.test(tpl) && tpl.includes('if (theme.neu) {');

  // widget meter written by an export, starters exempt
  designs.push(normalizeDesign({ id: 'm1', name: 'Mine', kind: 'clock' }), normalizeDesign({ id: 'm2', name: 'Starter', kind: 'clock', starter: true }));
  await buildScript();
  const meter = JSON.parse(localStorage.getItem('widgetking.meter.widgets') || '{}');
  out.widgetMeter = meter.count === 1 && meter.at > 0;
  designs.length = 0;

  // last-synced text
  localStorage.removeItem('widgetking.sync.at');
  out.notSynced = lastSyncedText() === 'Not synced yet';
  localStorage.setItem('widgetking.sync.at', String(Date.now()));
  out.syncedToday = /^Last synced \d/.test(lastSyncedText());
  localStorage.removeItem('widgetking.sync.at');

  // consolidated helpers
  out.searchShared = typeof searchAppsInto === 'function' && typeof searchAppStore === 'function' && typeof runTapSearch === 'function';
  const box = document.createElement('div');
  await searchAppsInto('   ', box, () => {});
  out.searchEmptyNoop = box.innerHTML === '';
  const d = normalizeDesign({ name: 'Linky', kind: 'clock', themeID: 'ocean' });
  const link = await designToLink(d);
  const m = link.url.match(/#d=([gp])(.+)$/);
  let bytes = b64urlDecode(m[2]);
  if (m[1] === 'g') bytes = await pipeBytes(bytes, new DecompressionStream('gzip'));
  out.linkRoundtrip = JSON.parse(new TextDecoder().decode(bytes)).name === 'Linky';
  // a raw (un-normalized) design: normalizeDesign already upgrades tapUrl
  const up = { name: 'U', kind: 'launcher', apps: [{ label: 'Spotify', url: 'shortcuts://run-shortcut?name=Open%20Spotify' }],
    tapUrl: 'shortcuts://run-shortcut?name=Open%20Instagram' };
  const n = upgradeAppLinks(up);
  out.upgradeShared = n === 2 && up.apps[0].url === 'spotify://' && up.tapUrl === 'instagram://';
  const img = await designToImage(d, 'small');
  out.snapshotShared = img instanceof Image && img.naturalWidth > 0;
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check127 FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('check127 OK');
