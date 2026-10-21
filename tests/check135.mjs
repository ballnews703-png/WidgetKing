// check135 — lean mode: inside the native shell (html.wk-native + window.wkNative)
// every Scriptable-only control disappears, native copy replaces the
// Scriptable copy, the status card never nags about "Update phone", and the
// Wallpaper photo row posts the image over the bridge. In a plain browser
// nothing changes.
import { chromium } from 'playwright-core';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
async function run(native) {
  const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
  const errors = [];
  pg.on('pageerror', e => errors.push(String(e)));
  await pg.addInitScript(nat => {
    localStorage.setItem('widgetking.tourseen', '1');
    if (nat) {
      window.wkNative = { platform: 'ios', version: 1 };
      window.__posted = [];
      window.webkit = { messageHandlers: { widgetking: { postMessage: m => window.__posted.push(m) } } };
      // the real shell tags <html> at document start; here the element may not exist yet
      const tag = () => document.documentElement && document.documentElement.classList.add('wk-native');
      if (!tag()) document.addEventListener('readystatechange', tag, { once: true });
    }
  }, native);
  await pg.goto('file://' + join(root, 'web/index.html'));
  await pg.waitForTimeout(700);
  const r = await pg.evaluate(() => {
    const out = {};
    switchTab('settings'); // the install section is a settings pane; measure it while its tab is active
    const vis = id => { const n = document.getElementById(id); return !!n && getComputedStyle(n).display !== 'none'; };
    out.scriptButtons = ['pushUpdateBtn', 'copyScriptBtn', 'installScriptBtn', 'downloadScriptBtn'].map(vis);
    out.installSection = getComputedStyle(document.getElementById('installSection')).display;
    out.wallpaperRow = vis('wallpaperRow');
    out.backupVisible = vis('backupBtn') && vis('syncAllBtn');
    const lockHint = document.getElementById('fLock').textContent;
    out.lockMentionsScriptable = /Scriptable/.test([...document.querySelectorAll('#fLock .sc-only')].filter(n => getComputedStyle(n).display !== 'none').map(n => n.textContent).join(''));
    out.lockNativeShown = [...document.querySelectorAll('#fLock .nat-only')].some(n => getComputedStyle(n).display !== 'none');
    const guides = GUIDES.map(g => g.title + ' ' + g.steps.join(' ')).join('\n');
    out.guidesMentionScriptable = /Scriptable/.test(guides);
    out.guidesMentionWidgetKingAdd = /search <b>WidgetKing<\/b>/.test(guides);
    // status card never nags inside the app
    designs.push(normalizeDesign({ id: 's1', name: 'S', kind: 'clock' })); persist();
    localStorage.setItem('widgetking.lastcopy', '0');
    renderStatusCard();
    const card = document.getElementById('statusCard');
    out.statusNag = card.style.display !== 'none' && /phone update/.test(card.textContent);
    designs.length = 0; persist();
    // tour pane 3 rows
    const rows = [...document.querySelectorAll('.wt-pane[data-p="3"] .wt-rows > div')].filter(n => getComputedStyle(n).display !== 'none').map(n => n.textContent);
    out.tourRows = rows.join('|');
    // wallpaper bridge
    out.wallpaperReject = wkWallpaperChosen('not-an-image') === false;
    out.wallpaperSend = wkWallpaperChosen('data:image/png;base64,AAAA');
    out.posted = (window.__posted || []).filter(m => m.type === 'wallpaper').length;
    out.wallpaperVal = document.getElementById('wallpaperVal').textContent;
    return out;
  });
  await pg.close();
  return { r, errors };
}
const web = await run(false);
const app = await run(true);
await b.close();
const checks = {
  webButtonsVisible: web.r.scriptButtons.every(Boolean) && web.r.installSection !== 'none' && !web.r.wallpaperRow,
  appButtonsHidden: app.r.scriptButtons.every(v => v === false) && app.r.installSection === 'none' && app.r.wallpaperRow,
  bothKeepBackup: web.r.backupVisible && app.r.backupVisible,
  webLockCopy: web.r.lockMentionsScriptable && !web.r.lockNativeShown,
  appLockCopy: !app.r.lockMentionsScriptable && app.r.lockNativeShown,
  webGuides: web.r.guidesMentionScriptable,
  appGuides: !app.r.guidesMentionScriptable && app.r.guidesMentionWidgetKingAdd,
  webNags: web.r.statusNag === true,
  appNeverNags: app.r.statusNag === false,
  tourRowsWeb: /Scriptable shows it/.test(web.r.tourRows) && !/Save it/.test(web.r.tourRows),
  tourRowsApp: /Save it/.test(app.r.tourRows) && !/Scriptable/.test(app.r.tourRows),
  wallpaperWebNoop: web.r.wallpaperSend === false && web.r.wallpaperReject,
  wallpaperAppSends: app.r.wallpaperSend === true && app.r.posted === 1 && /^Set /.test(app.r.wallpaperVal),
  noErrors: web.errors.length === 0 && app.errors.length === 0,
};
console.log(JSON.stringify(checks), 'web:', JSON.stringify(web.r), 'app:', JSON.stringify(app.r));
const bad = Object.entries(checks).filter(([, v]) => v !== true);
if (bad.length) { console.error('check135 FAILED', bad, web.errors, app.errors); process.exit(1); }
console.log('check135 OK');
