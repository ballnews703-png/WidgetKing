// check123 — welcome tour showcases VARIETY: seven art slots across three
// panes, every curated pick resolves to a real showcase template (never the
// plain fallback), and the picks span distinct heroes — photo, clock,
// countdown, bento dashboard, sports, astro, ring — not one widget recolored.
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
  const PICKS = ['Polaroid', 'Crown Jewel', 'New Year Sparkle', 'Bento Board',
    'Fantasy Command', 'Sun & Moon', 'Battery Ring'];
  const names = buildTemplates().map(t => t.design.name);
  out.picksReal = PICKS.every(n => names.includes(n));
  // the picks must not collapse into one hero type — count distinct
  // "signatures" (element kinds present) across the curated designs
  const sigs = new Set(PICKS.map(n => {
    const d = buildTemplates().find(t => t.design.name === n).design;
    return (d.canvasElements || []).map(e => e.kind).sort().join(',') || d.kind;
  }));
  out.heroVariety = sigs.size >= 6;

  showWelcomeTour();
  await sleep(400);
  const slots = ['wtArtL', 'wtArt0', 'wtArtR', 'wtArt1', 'wtArt4L', 'wtArt4C', 'wtArt4R'];
  out.allSlotsRender = slots.every(id => document.getElementById(id).childElementCount === 1);
  // last pane's fan is visible when we get there
  for (let i = 0; i < 4; i++) document.getElementById('wtNextBtn').click();
  await sleep(100);
  const pane4 = document.querySelector('.wt-pane[data-p="4"]');
  out.pane4Fan = getComputedStyle(pane4).display !== 'none' && !!pane4.querySelector('.wt-fan');
  out.wizardBtnAlive = !!document.getElementById('wtWizardBtn');
  document.getElementById('wtBrowseBtn').click();
  await sleep(100);
  out.tourCloses = !document.getElementById('welcomeTour').classList.contains('open');
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check123 FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('check123 OK');
