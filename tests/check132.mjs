// check132 — native bridge: in a plain browser wkNativeSend is a silent
// no-op; with a WKWebView-style message handler present, every persist()
// posts the full library as JSON; the shell's boot flag is recognized.
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
  out.browserNoop = wkNativeSend('designs', { json: '[]' }) === false && isNativeShell() === false;
  const posted = [];
  window.webkit = { messageHandlers: { widgetking: { postMessage: m => posted.push(m) } } };
  window.wkNative = { platform: 'ios', version: 1 };
  out.nativeFlag = isNativeShell() === true;
  designs.push(normalizeDesign({ id: 'n1', name: 'Native One', kind: 'clock' }));
  persist();
  out.posted = posted.length === 1 && posted[0].type === 'designs' && typeof posted[0].json === 'string';
  const back = JSON.parse(posted[0].json);
  out.roundtrip = Array.isArray(back) && back.some(d => d.id === 'n1' && d.kind === 'clock');
  out.sameBytes = posted[0].json === localStorage.getItem('widgetking.designs');
  designs.length = 0; persist();
  out.postedEmpty = posted.length === 2 && posted[1].json === '[]';
  // a throwing handler never breaks saving
  window.webkit.messageHandlers.widgetking.postMessage = () => { throw new Error('boom'); };
  designs.push(normalizeDesign({ id: 'n2', name: 'Two', kind: 'clock' })); persist();
  out.throwSafe = JSON.parse(localStorage.getItem('widgetking.designs')).length === 1;
  designs.length = 0; persist();
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check132 FAILED', bad, errors); process.exit(1); }
console.log('check132 OK');
