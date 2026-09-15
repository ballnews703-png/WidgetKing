// renderer — executes the REAL Scriptable renderer (extracted from
// web/index.html's template) inside the Scriptable shim, for every template
// design at every widget family plus synthetic designs covering every
// element kind and mode. Network is stubbed with realistic fixtures; a
// second pass runs with the network DOWN to prove every fetch degrades
// gracefully. Any thrown error, empty drawing, or NaN geometry is a finding.
//
// Usage: node renderer.mjs            (uses tests/fixtures/designs.json if present,
//                                      else dumps templates from the app first)
import { readFileSync, existsSync, writeFileSync, mkdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import vm from 'vm';
import { makeScriptableEnv } from './scriptable-shim.mjs';
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');
const html = readFileSync(join(root, 'web/index.html'), 'utf8');
const tpl = html.match(/<script type="text\/plain" id="scriptableTemplate">\n?([\s\S]*?)<\/script>/)[1];

// ---- designs under test -------------------------------------------------
const fixturePath = join(here, 'fixtures/designs.json');
let templates;
if (existsSync(fixturePath)) templates = JSON.parse(readFileSync(fixturePath, 'utf8'));
else {
  const { chromium } = await import('playwright-core');
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const pg = await b.newPage();
  await pg.addInitScript(() => { localStorage.setItem('widgetking.tourseen', '1'); });
  await pg.goto('file://' + join(root, 'web/index.html'));
  await pg.waitForTimeout(500);
  templates = await pg.evaluate(() => buildTemplates().map(t => normalizeDesign(JSON.parse(JSON.stringify(t.design)))));
  await b.close();
  mkdirSync(join(here, 'fixtures'), { recursive: true });
  writeFileSync(fixturePath, JSON.stringify(templates));
}
const el = (kind, extra) => Object.assign({ id: 'e' + Math.random().toString(36).slice(2, 7), kind, x: 0.5, y: 0.5, size: 14, colorHex: '#FFFFFF', opacity: 1 }, extra || {});
const free = (name, els, extra) => Object.assign({ id: 'syn-' + name.replace(/\W+/g, '-').toLowerCase(), name, kind: 'freestyle', themeID: 'midnight', fontStyle: 'rounded', textColorHex: '#FFFFFF', background: 'gradient', fitSize: 'small', canvasElements: els, apps: [] }, extra || {});
const synthetic = [
  free('Syn Weather', ['now', 'hilo', 'full', 'cond', 'rain', 'tomorrow', 'hourly', 'icon'].map((m, i) => el('weather', { wmode: m, y: 0.1 + i * 0.11, size: 10 }))),
  free('Syn Astro', ['sun', 'sunrise', 'sunset', 'moon', 'next'].map((m, i) => el('astro', { mode: m, y: 0.1 + i * 0.15, size: 10 })).concat([el('astro', { mode: 'moonicon', y: 0.9, size: 30 }), el('astro', { mode: 'moonicon', moonPack: 'moon-cozy', x: 0.8, y: 0.85, size: 30 })])),
  free('Syn Battery', [el('battery', { y: 0.3 }), el('battery', { mode: 'icon', y: 0.7, size: 30 })]),
  free('Syn Rings', ['day', 'year', 'battery', 'countdown'].map((s, i) => el('ring', { source: s, x: 0.2 + i * 0.2, w: 0.3, size: 6, dateISO: '2027-01-01' }))),
  free('Syn Art', [el('art', { mode: 'arc', text: 'CURVED TEXT', w: 0.7, size: 12 }), el('art', { mode: 'rotated', text: 'tilted', angle: -20, y: 0.7 }), el('art', { mode: 'gradshape', shape: 'circle', colorHex: '#FF00AA', borderHex: '#00AAFF', w: 0.4, h: 0.4, angle: 45 })]),
  free('Syn Shapes', [el('shape', { shape: 'rect', w: 0.6, h: 0.3, radius: 12, border: 2, borderHex: '#FFAA00', opacity: 0.3 }), el('shape', { shape: 'pill', w: 0.5, h: 0.2, y: 0.8 }), el('shape', { shape: 'circle', w: 0.3, h: 0.3, y: 0.2, opacity: 0, border: 3 })]),
  free('Syn Data', [el('calendar', { count: 3, y: 0.2, size: 9 }), el('reminders', { count: 3, y: 0.55, size: 9 }), el('news', { count: 2, y: 0.85, size: 9 })]),
  free('Syn Market', [el('stock', { text: 'AAPL', symbol: 'AAPL', y: 0.3 }), el('worldclock', { text: 'Tokyo', city: 'Tokyo', y: 0.5 }), el('greeting', { y: 0.7 }), el('week', { y: 0.9 })]),
  free('Syn Month', [el('month', { x: 0.27, w: 0.46, size: 8, accentHex: '#F0C445' }), el('text', { text: 'Side', x: 0.75, y: 0.3 })]),
  free('Syn Basics', [el('text', { text: 'Wrapped text that is long enough to wrap around the widget', w: 0.8, y: 0.2, size: 10 }), el('clock', { y: 0.45, size: 30 }), el('date', { y: 0.65 }), el('countdown', { dateISO: '2027-12-25', y: 0.8 }), el('emoji', { text: '🎉', x: 0.15, y: 0.15 }), el('icon', { text: '★', x: 0.85, y: 0.15 }), el('progress', { source: 'day', w: 0.6, y: 0.93, size: 6 })]),
  free('Syn Sticker', [el('sticker', { stockId: 'galaxy', w: 0.4 }), el('sticker', { stockId: 'does-not-exist', w: 0.2, x: 0.2, y: 0.2 })]),
  free('Syn Photo', [el('photo', { w: 0.6, h: 0.6, frame: 'polaroid' }), el('photo', { w: 0.3, h: 0.3, x: 0.2, y: 0.2, frame: 'film', dataUrl: 'data:image/png;base64,iVBORw0KGgo=' })]),
  free('Syn Apps', [el('app', { label: 'Music', url: 'music://', x: 0.3 }), el('app', { label: 'Maps', url: 'maps://', x: 0.7, iconUrl: 'https://example.com/icon.png' })]),
  free('Syn Sleeper', [el('sleeper', { leagueID: 'L1', userID: 'U1', y: 0.3, size: 22 }), el('sleeper', { mode: 'record', leagueID: 'L1', userID: 'U1', y: 0.5 }), el('sleeper', { mode: 'myteam', leagueID: 'L1', userID: 'U1', y: 0.65 }), el('sleeper', { mode: 'opponent', leagueID: 'L1', userID: 'U1', y: 0.8 }), el('sleeperlogo', { mode: 'myteam', leagueID: 'L1', userID: 'U1', x: 0.2, y: 0.15, size: 30 }), el('sleeperlogo', { mode: 'opponent', leagueID: 'L1', userID: 'U1', x: 0.8, y: 0.15, size: 30 })]),
  free('Syn Sleeper Empty', [el('sleeper', { y: 0.5, size: 22 }), el('sleeperlogo', { x: 0.2, y: 0.15, size: 30 })]),
  free('Syn Backgrounds Mesh', [el('text', { text: 'mesh' })], { gradientDir: 'mesh', bgPattern: 'grain' }),
  free('Syn Backgrounds Clear', [el('text', { text: 'clear' })], { background: 'clear', position: 'top-left' }),
  free('Syn Backgrounds Glass', [el('text', { text: 'glass' })], { background: 'glass', glassTint: 'light', bgOpacity: 0.5 }),
  free('Syn Custom Colors', [el('text', { text: 'custom' })], { themeID: 'custom', customColors: ['#112233', '#445566'], gradientDir: 'horizontal', bgPattern: 'waves' }),
  free('Syn Every Pattern', ['dots', 'grid', 'stripes', 'paper', 'blobs'].map((p, i) => el('text', { text: p, y: 0.1 + i * 0.2 })), { bgPattern: 'dots' }),
  free('Syn Fonts', Object.keys({}).length ? [] : ['classic', 'rounded', 'serif', 'mono', 'didot', 'bodoni', 'futura', 'marker', 'copperplate', 'zapfino', 'avenir', 'optima', 'cochin', 'hoefler', 'script', 'notreal'].map((f, i) => el('text', { text: f, font: f, y: 0.05 + i * 0.06, size: 8 }))),
  { id: 'syn-clock', name: 'Syn Clock', kind: 'clock', themeID: 'royal', fontStyle: 'serif' },
  { id: 'syn-date', name: 'Syn Date', kind: 'date', themeID: 'paper', fontStyle: 'mono' },
  { id: 'syn-countdown', name: 'Syn Countdown', kind: 'countdown', themeID: 'ocean', targetDate: '2027-06-01', primaryText: 'Trip' },
  { id: 'syn-quote', name: 'Syn Quote', kind: 'quote', themeID: 'sage', primaryText: 'Keep going', secondaryText: 'Me' },
  { id: 'syn-note', name: 'Syn Note', kind: 'note', themeID: 'mint', primaryText: 'Drink water' },
  { id: 'syn-battery', name: 'Syn Battery Kind', kind: 'battery', themeID: 'lava' },
  { id: 'syn-launcher', name: 'Syn Launcher', kind: 'launcher', themeID: 'midnight', iconTheme: 'candy', apps: [{ emoji: '🎵', label: 'Music', url: 'music://' }, { emoji: '🗺', label: 'Maps', url: 'maps://' }, { emoji: '📷', label: 'Cam', url: 'camera://', iconUrl: 'https://example.com/i.png' }, { emoji: '🌐', label: 'Web', shortcut: 'Open Web' }] },
  { id: 'syn-launcher-real', name: 'Syn Launcher Real', kind: 'launcher', themeID: 'midnight', iconTheme: 'original', launcherStyle: 'grid', apps: [{ emoji: '🎵', label: 'Music', url: 'music://', iconUrl: 'https://example.com/i.png' }] },
  { id: 'syn-lock', name: 'Syn Lock', kind: 'lock', lockRows: [{ kind: 'time' }, { kind: 'countdown', dateISO: '2027-01-01', label: 'NY' }, { kind: 'text', text: 'hello' }] },
  { id: 'syn-playlist', name: 'Syn Playlist', kind: 'playlist', playlist: { morning: 'syn-clock', night: 'syn-date' } },
  { id: 'syn-playlist-empty', name: 'Syn Playlist Empty', kind: 'playlist', playlist: {} }
];
// ---- fixtures -------------------------------------------------------------
const hourly = Array.from({ length: 48 }, (_, i) => 60 + (i % 12));
const weatherJson = { current: { temperature_2m: 72.4, weather_code: 2 },
  daily: { temperature_2m_max: [80, 78], temperature_2m_min: [60, 58], precipitation_probability_max: [20, 40], weather_code: [2, 61], sunrise: ['2026-09-15T06:44'], sunset: ['2026-09-15T19:12'] },
  hourly: { temperature_2m: hourly, weather_code: hourly.map(() => 2) } };
const netUp = {
  'api.open-meteo.com': weatherJson,
  'query1.finance.yahoo.com': { chart: { result: [{ meta: { regularMarketPrice: 229.1, chartPreviousClose: 226.4 } }] } },
  'api.sleeper.app/v1/state/nfl': { week: 3, display_week: 3 },
  '/league/L1/rosters': [{ roster_id: 1, owner_id: 'U1', settings: { wins: 2, losses: 1, fpts: 300 } }, { roster_id: 2, owner_id: 'U2', settings: { wins: 1, losses: 2, fpts: 250 } }],
  '/league/L1/users': [{ user_id: 'U1', display_name: 'Andrew', metadata: { team_name: 'Birds of Prey' }, avatar: 'abc' }, { user_id: 'U2', display_name: 'Opp', metadata: {} }],
  '/league/L1/matchups/3': [{ roster_id: 1, matchup_id: 7, points: 112.4 }, { roster_id: 2, matchup_id: 7, points: 98.7 }],
  'news.google.com': '<rss><channel><title>Google News</title><item><title><![CDATA[Headline One &amp; More]]></title></item><item><title>Headline Two</title></item><item><title>Headline Three</title></item></channel></rss>',
  'sleepercdn.com': 'img', 'example.com': 'img', 'ballnews703-png.github.io': 'img'
};
const events = [{ identifier: 'ev1', title: 'Dentist appointment downtown', startDate: new Date(Date.now() + 3600e3), endDate: new Date(Date.now() + 7200e3), isAllDay: false }];
const reminders = [{ title: 'Buy milk and eggs for the weekend', dueDate: new Date(Date.now() + 86400e3) }, { title: 'Call mom' }];

// ---- runner ---------------------------------------------------------------
const hostileNames = ['Hostile Types', 'Hostile Geometry', 'Hostile Empty', 'Hostile Launcher'];
const all = templates.concat(synthetic);
const designsJson = JSON.stringify(all.concat([
  // hostile designs ride in DESIGNS too so the parameter lookup finds them
  { id: 'h1', name: 'Hostile Types', kind: 'freestyle', themeID: 'midnight', canvasElements: [
    { id: 'a', kind: 'text', text: 42, x: 0.5, y: 0.5 }, { id: 'b', kind: 'shape', w: 'wide', h: null, x: 0.5, y: 0.5 },
    { id: 'c', kind: 'ring', source: 'nope', w: -1, x: 0.5, y: 0.5 }, { id: 'd', kind: 'countdown', dateISO: 'not-a-date', x: 0.5, y: 0.5 },
    { id: 'e', kind: 'weather', wmode: 'bogus', x: 0.5, y: 0.5 }, { id: 'f', kind: 'astro', mode: 'bogus', x: 0.5, y: 0.5 },
    { id: 'g', kind: 'progress', source: 'x', w: 0, x: 0.5, y: 0.5 }] },
  { id: 'h2', name: 'Hostile Geometry', kind: 'freestyle', themeID: 'midnight', canvasElements: [
    { id: 'a', kind: 'text', text: 'off', x: 5, y: -3, size: 0 }, { id: 'b', kind: 'emoji', text: '', size: null, x: 0.5, y: 0.5 },
    { id: 'c', kind: 'photo', w: 0, h: 0, x: 0.5, y: 0.5 }] },
  { id: 'h3', name: 'Hostile Empty', kind: 'freestyle', themeID: 'nonexistent-theme', fontStyle: 'nope', textColorHex: 'purple', canvasElements: [] },
  { id: 'h4', name: 'Hostile Launcher', kind: 'launcher', apps: [{}, { label: null, url: 7 }], iconTheme: 'bogus' }
]), null, 0);
const program = tpl.replace('"__DESIGNS__"', designsJson).replace('"__PAGE_URL__"', '""');
if (program.includes('__DESIGNS__') || program.includes('__PAGE_URL__')) throw new Error('placeholders not replaced');
const familiesFor = d => d.kind === 'lock' ? ['accessoryRectangular', 'accessoryCircular', 'accessoryInline']
  : d.fitSize === 'large' ? ['large', 'medium', 'small'] : ['small', 'medium', 'large'];
const findings = [];
let runs = 0, warnTotal = 0;
async function runOne(design, family, net, label) {
  const { env, globals } = makeScriptableEnv({ family, parameter: design.name, net, events, reminders });
  const ctx = vm.createContext(Object.assign({ Date, Math, JSON, Promise, setTimeout, clearTimeout, Number, String, Array, Object, RegExp, Error, TypeError, encodeURIComponent, decodeURIComponent, isFinite, isNaN, parseInt, parseFloat, Intl }, globals));
  runs++;
  try {
    await vm.runInContext('(async () => {\n' + program + '\n})()', ctx, { timeout: 20000, filename: 'WidgetKing.js' });
    const blank = !env.widget;
    const drewNothing = design.kind === 'freestyle' && env.drawOps === 0;
    const isNotFound = env.widget && JSON.stringify(env.widget).includes('No design called');
    if (blank) findings.push({ sev: 'HIGH', design: design.name, family, label, msg: 'Script.setWidget never called — blank widget' });
    else if (isNotFound) findings.push({ sev: 'HIGH', design: design.name, family, label, msg: 'renderer could not find the design by name' });
    else if (drewNothing) findings.push({ sev: 'HIGH', design: design.name, family, label, msg: 'freestyle drew zero ops' });
    const nan = env.warnings.filter(w => w.startsWith('non-finite'));
    if (nan.length) findings.push({ sev: 'MED', design: design.name, family, label, msg: 'NaN geometry: ' + [...new Set(nan)].slice(0, 4).join(', ') });
    const other = env.warnings.filter(w => !w.startsWith('non-finite'));
    warnTotal += env.warnings.length;
    if (other.length) findings.push({ sev: 'LOW', design: design.name, family, label, msg: [...new Set(other)].slice(0, 3).join('; ') });
  } catch (e) {
    findings.push({ sev: 'CRASH', design: design.name, family, label, msg: String(e && e.message || e).split('\n')[0] });
  }
}
for (const d of all) {
  for (const fam of familiesFor(d)) {
    await runOne(d, fam, netUp, 'net-up');
    await runOne(d, fam, {}, 'net-down');
  }
}
// Parameter edge case: a wrong Parameter must render the explanatory
// "No design called …" note (never blank, never DESIGNS[0] silently).
{
  const { env, globals } = makeScriptableEnv({ family: 'small', parameter: 'Nonexistent Widget', net: netUp });
  const ctx = vm.createContext(Object.assign({ Date, Math, JSON, Promise, setTimeout, clearTimeout, Number, String, Array, Object, RegExp, Error, TypeError, encodeURIComponent, decodeURIComponent, isFinite, isNaN, parseInt, parseFloat, Intl }, globals));
  runs++;
  await vm.runInContext('(async () => {\n' + program + '\n})()', ctx, { timeout: 20000 });
  if (!env.widget || !JSON.stringify(env.widget).includes('No design called')) findings.push({ sev: 'HIGH', design: '(wrong parameter)', family: 'small', label: 'param-missing', msg: 'expected the explanatory not-found note' });
}
// Hostile input: wrong types and garbage must degrade, not crash. (Also
// proves the harness detects crashes at all — the shim is strict on types.)
const hostile = [
  free('Hostile Types', [el('text', { text: 42 }), el('shape', { w: 'wide', h: null }), el('ring', { source: 'nope', w: -1 }), el('countdown', { dateISO: 'not-a-date' }), el('weather', { wmode: 'bogus' }), el('astro', { mode: 'bogus' }), el('progress', { source: 'x', w: 0 })]),
  free('Hostile Geometry', [el('text', { text: 'off', x: 5, y: -3, size: 0 }), el('emoji', { text: '', size: NaN }), el('photo', { w: 0, h: 0 })]),
  Object.assign(free('Hostile Empty', []), { themeID: 'nonexistent-theme', fontStyle: 'nope', textColorHex: 'purple' }),
  { id: 'h-launch', name: 'Hostile Launcher', kind: 'launcher', apps: [{}, { label: null, url: 7 }], iconTheme: 'bogus' }
];
for (const name of hostileNames) await runOne({ name, kind: name === 'Hostile Launcher' ? 'launcher' : 'freestyle' }, 'small', netUp, 'hostile');
const sev = { CRASH: 0, HIGH: 1, MED: 2, LOW: 3 };
findings.sort((a, b) => sev[a.sev] - sev[b.sev]);
console.log('renderer: ' + runs + ' runs, ' + findings.length + ' findings (' + findings.filter(f => f.sev === 'CRASH').length + ' crashes, ' +
  findings.filter(f => f.sev === 'HIGH').length + ' high, ' + findings.filter(f => f.sev === 'MED').length + ' med)');
for (const f of findings) console.log(' [' + f.sev + '] ' + f.design + ' @' + f.family + ' (' + f.label + '): ' + f.msg);
const fatal = findings.filter(f => f.sev === 'CRASH' || f.sev === 'HIGH');
if (fatal.length) { console.error('renderer FAILED'); process.exit(1); }
console.log('renderer OK');
