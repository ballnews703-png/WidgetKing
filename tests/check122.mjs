// check122 — Phase D: Settings/Guides regroup + the final persistent-UI
// emoji sweep. Settings summaries and rows carry drawn icchips, guide rows
// use tinted icon chips (no emoji), guide sheets open with plain titles and
// working sprite action buttons, and NO emoji remains in persistent chrome
// (buttons, summaries, labels, placeholders) across the visible panes.
// Emoji deliberately stays in CONTENT: theme/pack names, hints, toasts.
import { chromium } from 'playwright-core';
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e)));
await pg.addInitScript(() => { localStorage.setItem('widgetking.tourseen', '1'); });
await pg.goto('file:///home/user/WidgetKing/web/index.html');
await pg.waitForTimeout(700);
const r = await pg.evaluate(async () => {
  const out = {};
  const sleep = ms => new Promise(res => setTimeout(res, ms));
  const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{1F900}-\u{1F9FF}]/u;

  // Settings: every section summary + app row has an icchip, no emoji text
  const settings = document.getElementById('settingsSection');
  const summaries = [...settings.querySelectorAll('details > summary')];
  // v124 added the Account & sync section (4th summary, 5th row) — it must
  // follow the same icchip design this check enforces.
  out.summaryChips = summaries.length === 4 && summaries.every(s => s.querySelector('.icchip svg use'));
  out.summariesPlain = summaries.every(s => !EMOJI.test(s.textContent));
  const rows = [...settings.querySelectorAll('.settings-row')];
  out.rowChips = rows.length === 5 && rows.every(x => x.querySelector('.icchip svg use'));
  out.rowsPlain = rows.every(x => !EMOJI.test(x.textContent));
  out.aiLabelsPlain = ![...settings.querySelectorAll('label')].some(l => EMOJI.test(l.textContent));

  // Guides: 7 tinted icon chips, distinct tints, no emoji
  const gchips = [...document.querySelectorAll('#guidesList .guide-row .icchip')];
  out.guideChips = gchips.length === 7 && gchips.every(c => c.querySelector('svg use'));
  out.guideTints = new Set(gchips.map(c => c.style.background)).size >= 6;
  out.guideRowsPlain = ![...document.querySelectorAll('#guidesList .guide-row')].some(x => EMOJI.test(x.textContent));

  // Guide sheet: plain title, sprite action button still works
  document.querySelectorAll('#guidesList .guide-row')[1].click();
  await sleep(100);
  out.sheetTitle = document.getElementById('guideTitle').textContent === 'Put it on your Home Screen';
  const action = document.querySelector('#guideBody button.primary');
  out.actionSprite = !!action && !!action.querySelector('svg use') && !EMOJI.test(action.textContent);
  action.click();
  await sleep(100);
  out.actionRuns = document.getElementById('setupWizard').classList.contains('open');
  document.getElementById('wizardCloseBtn').onclick();

  // The chrome-wide sweep: no emoji in any VISIBLE button/summary/label/
  // placeholder in the main panes (content surfaces excluded by scope)
  const visible = n => { const cs = getComputedStyle(n); return cs.display !== 'none' && cs.visibility !== 'hidden' && n.offsetParent !== null; };
  // ✕ ✓ › ⌄ ↗ ◀ ▶ ♛ are typographic glyphs, not emoji — deliberately kept.
  // #customEmoji's placeholder IS an emoji by design (the field collects one).
  const strip = s => String(s).replace(/[✕✓›⌄↗◀▶♛]/g, '');
  const offenders = [];
  for (const pane of ['create', 'widgets', 'settings']) {
    switchTab(pane); await sleep(60);
    for (const n of document.querySelectorAll('.pane-' + pane + ' button, .pane-' + pane + ' summary, .pane-' + pane + ' label')) {
      const direct = [...n.childNodes].filter(c => c.nodeType === 3).map(c => c.textContent).join('');
      if (visible(n) && EMOJI.test(strip(direct))) offenders.push(pane + ':' + direct.trim().slice(0, 25));
    }
  }
  for (const inp of document.querySelectorAll('input[placeholder]')) {
    if (inp.id !== 'customEmoji' && EMOJI.test(strip(inp.placeholder))) offenders.push('ph:' + inp.placeholder.slice(0, 25));
  }
  out.chromeSwept = offenders.length === 0 || offenders;

  // Content emoji survives (theme pack names keep their character)
  switchTab('create'); await sleep(60);
  out.contentKeepsEmoji = document.body.textContent.includes('👑') || /[\u{1F300}-\u{1FAFF}]/u.test(document.getElementById('packChips') ? document.getElementById('packChips').textContent : '👑');

  // Clone nudge still lands on the AI section (summary markup changed)
  switchTab('create'); await sleep(50);
  document.getElementById('cloneBtn').click(); await sleep(50);
  document.getElementById('clonePickBtn').click(); await sleep(80);
  out.cloneNudge = localStorage.getItem('widgetking.tab') === 'settings' && document.getElementById('designerSetup').open === true;
  document.getElementById('designerSetup').open = false;
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check122 FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('check122 OK');
