// check137 — the AI proxy. (1) The budget rules in policy.js do what
// MONETIZATION.md says; (2) the single-file Edge Function is generated from
// them; (3) the designer routes AI builds through the proxy when signed in
// (no key on the device), shows the allowance, explains a downshift, and
// still talks to the model directly when a developer key is pasted.
import { chromium } from 'playwright-core';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const { decide, LIMITS, MODELS, costOf, quotaFor, sanitizeBody } = await import('../supabase/functions/ai-proxy/policy.js');
const out = {};
const HIGH = MODELS.high, FAST = MODELS.fast;
const d = (pro, usage, model = HIGH) => decide({ pro, requestedModel: model, usage });

// --- policy
out.freeOk = (() => { const r = d(false, { userMonthBuilds: 2, deviceMonthBuilds: 1 }); return r.allow && r.model === HIGH && r.quota.freeLeft === 1; })();
out.freeWall = d(false, { userMonthBuilds: 1, deviceMonthBuilds: 3 }).reason === 'free';          // device cap wins
out.freeContinues = d(false, { userMonthBuilds: 3, deviceMonthBuilds: 3, buildCalls: 1 }).allow;  // a started build may finish its review
out.freeReplay = d(false, { userMonthBuilds: 1, userMonthCost: 0.61 }).reason === 'free';          // replayed build ids hit the cost ceiling
out.buildLoop = d(true, { buildCalls: 4 }).reason === 'build';
out.proHigh = (() => { const r = d(true, { userMonthHighCost: 1.0 }); return r.allow && r.model === HIGH && r.reason === 'ok' && r.quota.highLeft === Math.round(0.5 / 0.075); })();
out.proDownshift = (() => { const r = d(true, { userMonthHighCost: 1.5 }); return r.allow && r.model === FAST && r.reason === 'fast' && r.quota.fastMode === true; })();
out.proFastStaysFast = d(true, { userMonthHighCost: 1.5 }, FAST).reason === 'ok';
out.proCeiling = d(true, { userMonthCost: 3.0 }).reason === 'monthly';
out.proDaily = d(true, { userTodayBuilds: 30 }).reason === 'daily';
out.proDailyContinues = d(true, { userTodayBuilds: 30, buildCalls: 1 }).allow;
out.paused = d(true, { globalTodayCost: 25 }).reason === 'paused' && d(false, { globalTodayCost: 25 }).reason === 'paused';
out.cost = Math.abs(costOf(HIGH, { input_tokens: 10000, output_tokens: 2000 }) - 0.06) < 1e-9 && Math.abs(costOf(FAST, { input_tokens: 10000, output_tokens: 2000 }) - 0.02) < 1e-9;
out.sanitize = (() => {
  const b = sanitizeBody({ model: 'x', max_tokens: 99999, messages: [{ role: 'user', content: 'hi' }], system: 's', output_config: { a: 1 }, metadata: { user_id: 'leak' } }, FAST);
  return b.model === FAST && b.max_tokens === LIMITS.maxTokens && b.system === 's' && b.output_config.a === 1 && !('metadata' in b) && sanitizeBody({ messages: [] }, FAST) === null;
})();
out.limitsMatchDoc = LIMITS.freeBuilds === 3 && LIMITS.proHighCost === 1.5 && LIMITS.proMonthCost === 3 && LIMITS.proDailyBuilds === 30 && LIMITS.globalDailyCost === 25;

// --- generated function in sync with policy.js
const gen = readFileSync(join(root, 'supabase/functions/ai-proxy/index.ts'), 'utf8');
const policySrc = readFileSync(join(root, 'supabase/functions/ai-proxy/policy.js'), 'utf8');
out.genInSync = gen.includes('const LIMITS = {') && gen.includes('function decide(input)') && !/^export /m.test(gen) &&
  gen.includes('proHighCost: ' + String(LIMITS.proHighCost).replace(/^1\.5$/, '1.50')) && policySrc.includes('export function decide');
out.genGuards = gen.includes('x-wk-build') && gen.includes('ai_usage_summary') && gen.includes('api.anthropic.com/v1/messages') && gen.includes('ANTHROPIC_API_KEY') && !gen.includes('sk-ant');

// --- browser
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e)));
const PROXY = 'https://wk-test.local';
const seen = [];
let mode = 'ok';
const fakeSpec = { kind: 'note', name: 'Proxy note', size: 'small', themeID: 'royal', fontStyle: 'rounded', textColorHex: '#FFFFFF', primaryText: 'hello' };
const CORS = { 'access-control-allow-origin': '*', 'access-control-allow-headers': '*', 'access-control-expose-headers': 'x-wk-model, x-wk-tier, x-wk-high-left, x-wk-high-total, x-wk-free-left, x-wk-free-total, x-wk-reason' };
await pg.route(PROXY + '/**', async route => {
  const req = route.request();
  if (req.method() === 'OPTIONS') return route.fulfill({ status: 204, headers: CORS });
  seen.push({ method: req.method(), url: req.url(), headers: req.headers(), body: req.postData() });
  if (req.method() === 'GET') return route.fulfill({ status: 200, headers: { ...CORS, 'content-type': 'application/json' }, body: JSON.stringify({ quota: { tier: 'pro', highLeft: 12, highTotal: 20, fastMode: false } }) });
  if (mode === 'free') return route.fulfill({ status: 402, headers: { ...CORS, 'content-type': 'application/json', 'x-wk-tier': 'free', 'x-wk-free-left': '0', 'x-wk-free-total': '3', 'x-wk-reason': 'free' }, body: JSON.stringify({ error: { message: "You've used your 3 free AI builds this month — Pro unlocks unlimited builds", code: 'free' } }) });
  const fast = mode === 'fast';
  return route.fulfill({ status: 200, headers: { ...CORS, 'content-type': 'application/json', 'x-wk-model': fast ? FAST : HIGH, 'x-wk-tier': 'pro', 'x-wk-high-left': fast ? '0' : '11', 'x-wk-high-total': '20', 'x-wk-reason': fast ? 'fast' : 'ok' },
    body: JSON.stringify({ content: [{ type: 'text', text: JSON.stringify(fakeSpec) }], usage: { input_tokens: 10, output_tokens: 5 }, stop_reason: 'end_turn' }) });
});
let directCalls = 0;
await pg.route('https://api.anthropic.com/**', async route => {
  directCalls++;
  return route.fulfill({ status: 200, headers: { ...CORS, 'content-type': 'application/json' }, body: JSON.stringify({ content: [{ type: 'text', text: JSON.stringify(fakeSpec) }], usage: { input_tokens: 10, output_tokens: 5 }, stop_reason: 'end_turn' }) });
});
await pg.addInitScript(([proxy]) => {
  localStorage.setItem('widgetking.tourseen', '1');
  localStorage.setItem('widgetking.sync.url', proxy);
  localStorage.setItem('widgetking.sync.key', 'anon-test');
  localStorage.setItem('widgetking.aieyes', '0');
}, [PROXY]);
await pg.goto('file://' + join(root, 'web/index.html'));
await pg.waitForTimeout(700);

// signed out, no key: AI entry points are hidden and the way in is sign-in
const so = await pg.evaluate(() => {
  const o = {};
  o.access = aiAccess() === '';
  o.hint = /Sign in to start/.test(document.getElementById('aiAccessHint').textContent);
  o.signInRow = document.getElementById('aiSignInRow').style.display === 'flex';
  o.keyHidden = !document.getElementById('devKeySec').open && document.getElementById('apiKeyInput').closest('details') === document.getElementById('devKeySec');
  openDesignerSetup();
  o.setupOpensAccount = document.getElementById('accountSec').open === true && document.activeElement === document.getElementById('acctEmail');
  return o;
});
Object.assign(out, so);

// sign in (session planted) → proxy path
await pg.evaluate(() => { setSyncSession({ access_token: 'tok-1', refresh_token: 'r', email: 'a@b.c', user_id: 'u1' }); });
const quota = await pg.evaluate(async () => { const q = await refreshAIQuota(); return { q, hint: document.getElementById('aiAccessHint').textContent }; });
out.quotaFetched = !!quota.q && quota.q.tier === 'pro' && quota.q.highLeft === 12 && /about 12 High-quality builds left/.test(quota.hint);
const si = await pg.evaluate(() => ({ access: aiAccess() === 'proxy', signInRowHidden: document.getElementById('aiSignInRow').style.display === 'none' }));
Object.assign(out, si);
seen.length = 0;
const built = await pg.evaluate(async () => {
  const design = await callClaude([{ role: 'user', content: 'a note' }], aiAccess());
  return { kind: design.kind, name: design.name, quota: getAIQuota() };
});
const post = seen.find(r => r.method === 'POST');
const body = post && JSON.parse(post.body);
out.proxyCalled = !!post && post.url === PROXY + '/functions/v1/ai-proxy' && built.kind === 'note' && built.name === 'Proxy note';
out.proxyHeaders = !!post && post.headers['authorization'] === 'Bearer tok-1' && post.headers['apikey'] === 'anon-test' && /^[0-9a-f-]{20,}$/.test(post.headers['x-wk-build'] || '') && (post.headers['x-wk-device'] || '').length > 8 && !('x-api-key' in post.headers);
out.proxyBody = !!body && body.model === HIGH && Array.isArray(body.system) && body.system.length === 2 && body.output_config && body.output_config.format.type === 'json_schema' && body.messages.length === 1;
out.quotaUpdated = built.quota && built.quota.highLeft === 11 && /about 11 High-quality/.test(await pg.evaluate(() => document.getElementById('aiAccessHint').textContent));
out.noDirect = directCalls === 0;
out.buildIdPerBuild = (() => { const ids = seen.filter(r => r.method === 'POST').map(r => r.headers['x-wk-build']); return new Set(ids).size === 1; })();

// downshift → one toast, Fast mode readout
mode = 'fast';
const ds = await pg.evaluate(async () => {
  const toasts = [];
  const orig = window.toast; window.toast = m => { toasts.push(m); orig(m); };
  await callClaude([{ role: 'user', content: 'another' }], aiAccess());
  window.toast = orig;
  return { toasts, hint: document.getElementById('aiAccessHint').textContent, fastMode: getAIQuota().fastMode };
});
out.downshiftToast = ds.toasts.filter(t => /Fast mode until the 1st/.test(t)).length === 1 && ds.fastMode === true && /Fast mode until the 1st/.test(ds.hint);

// free wall → the proxy's message reaches the user
mode = 'free';
const fw = await pg.evaluate(async () => {
  try { await callClaude([{ role: 'user', content: 'x' }], aiAccess()); return { threw: false }; }
  catch (e) { return { threw: true, msg: e.message, quota: getAIQuota() }; }
});
out.freeWallMessage = fw.threw && /3 free AI builds/.test(fw.msg) && fw.quota.tier === 'free' && fw.quota.freeLeft === 0 && /0 of 3 free AI builds left/.test(await pg.evaluate(() => document.getElementById('aiAccessHint').textContent));

// sign out clears the readout
await pg.evaluate(() => { document.getElementById('acctOutBtn').onclick(); });
out.signOutClears = await pg.evaluate(() => getAIQuota() === null && aiAccess() === '' && document.getElementById('aiSignInRow').style.display === 'flex');

// developer key → direct call, no proxy
mode = 'ok'; seen.length = 0;
const dev = await pg.evaluate(async () => {
  const input = document.getElementById('apiKeyInput');
  input.value = 'dev-key-123'; input.oninput();
  const o = { access: aiAccess() === 'dev-key-123', devOpen: document.getElementById('devKeySec').open === true, hint: document.getElementById('aiAccessHint').textContent };
  const design = await callClaude([{ role: 'user', content: 'direct' }], aiAccess());
  o.kind = design.kind;
  return o;
});
out.devKeyDirect = dev.access && dev.devOpen && /own access key/.test(dev.hint) && dev.kind === 'note' && directCalls === 1 && seen.filter(r => r.method === 'POST').length === 0;

// the home status card asks for sign-in, not a key
await pg.evaluate(() => { localStorage.removeItem('widgetking.apikey'); document.getElementById('apiKeyInput').value = ''; });
out.statusCopy = await pg.evaluate(() => {
  designs.length = 0; designs.push(normalizeDesign({ name: 'S', kind: 'clock' }));
  localStorage.setItem('widgetking.lastcopy', String(Date.now() + 1000));
  renderStatusCard();
  const card = document.body.innerHTML;
  return /Sign in to use the AI designer — 3 free builds a month/.test(card) && !/isn't set up on this device/.test(card);
});
out.noPasteCopy = !(await pg.content()).includes('Paste the access key to unlock');
await b.close();

const failed = Object.entries(out).filter(([, v]) => !v);
console.log(JSON.stringify(out), 'pageErrors:', JSON.stringify(errors));
if (failed.length || errors.length) { console.log('check137 FAILED', JSON.stringify(failed)); process.exit(1); }
console.log('check137 OK');
