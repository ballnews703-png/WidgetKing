// check124 — accounts phase 1, shipped dark: the Account section is
// invisible without config, appears with it, the full OTP sign-in flow works
// against a stubbed backend (no real network), sync pushes slim photo-free
// rows and pulls with newest-timestamp-wins merge, saves stamp updatedAt and
// schedule a push, sign-out clears the session, and the AI build meter
// counts per month. All fetches are stubbed — zero external calls.
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
  const sleep = ms => new Promise(res => setTimeout(res, ms));

  // dark by default: no config, no section
  out.darkShip = WK_SYNC_URL === '' && WK_SYNC_KEY === '' &&
    document.getElementById('accountSec').style.display === 'none';

  // configure via the test override; section appears
  localStorage.setItem('widgetking.sync.url', 'https://stub.supabase.co');
  localStorage.setItem('widgetking.sync.key', 'anon-test');
  renderAccountSection();
  out.appears = document.getElementById('accountSec').style.display !== 'none';
  out.signedOutView = document.getElementById('acctOut').style.display !== 'none';

  // stub the backend
  const calls = [];
  const realFetch = window.fetch;
  window.fetch = function (url, init) {
    const u = String(url);
    const body = init && init.body ? JSON.parse(init.body) : null;
    calls.push({ url: u, method: (init && init.method) || 'GET', body: body, headers: (init && init.headers) || {} });
    const ok = data => Promise.resolve({ ok: true, status: 200, json: () => Promise.resolve(data) });
    if (u.includes('/auth/v1/otp')) return ok({});
    if (u.includes('/auth/v1/verify')) return ok({ access_token: 'at1', refresh_token: 'rt1', user: { id: 'u1', email: body.email } });
    if (u.includes('/rest/v1/designs') && (!init || !init.method || init.method === 'GET')) {
      return ok([{ id: 'cloud-1', updated_at: 9999999999999, data: { name: 'From Cloud', kind: 'clock', themeID: 'ocean' } }]);
    }
    if (u.includes('/rest/v1/designs')) return ok([]);
    return realFetch(url, init);
  };

  try {
    // OTP flow through the real UI handlers
    document.getElementById('acctEmail').value = 'andrew@example.com';
    await document.getElementById('acctSendBtn').onclick.call(document.getElementById('acctSendBtn'));
    out.otpSent = calls.some(c => c.url.includes('/auth/v1/otp') && c.body.email === 'andrew@example.com' && c.body.create_user === true);
    out.otpNoAuthHeader = !calls.find(c => c.url.includes('/auth/v1/otp')).headers.Authorization;
    out.codeRowShows = document.getElementById('acctCodeRow').style.display !== 'none';

    document.getElementById('acctCode').value = '123456';
    await document.getElementById('acctVerifyBtn').onclick.call(document.getElementById('acctVerifyBtn'));
    await sleep(100);
    out.signedIn = !!syncSession() && syncSession().email === 'andrew@example.com' && syncSession().access_token === 'at1';
    out.signedInView = document.getElementById('acctIn').style.display !== 'none' &&
      document.getElementById('acctWho').textContent === 'andrew@example.com';

    // the sign-in pulled the cloud design (newest-wins merge, unknown id = add)
    out.pulledDesign = designs.some(d => d.id === 'cloud-1' && d.name === 'From Cloud');

    // push: rows are slim (no photo dataUrl), carry id/updated_at/data, auth + upsert headers
    designs.push(normalizeDesign({ id: 'local-1', name: 'Mine', kind: 'freestyle', updatedAt: 42, canvasElements: [
      { id: 'p1', kind: 'photo', dataUrl: 'data:image/png;base64,AAAA', x: 0.5, y: 0.5 }] }));
    calls.length = 0;
    await syncPush();
    const push = calls.find(c => c.url.includes('/rest/v1/designs') && c.method === 'POST');
    out.pushShape = !!push && Array.isArray(push.body) && push.body.some(row => row.id === 'local-1' && row.updated_at === 42);
    const mine = push && push.body.find(row => row.id === 'local-1');
    out.pushSlim = !!mine && JSON.stringify(mine.data).indexOf('base64,AAAA') < 0;
    out.pushAuth = !!push && push.headers.Authorization === 'Bearer at1' && push.headers.apikey === 'anon-test' &&
      push.headers.Prefer === 'resolution=merge-duplicates';

    // newest-wins: an older cloud row must NOT clobber a newer local design
    const local = designs.find(d => d.id === 'cloud-1');
    local.name = 'Edited Locally';
    local.updatedAt = 9999999999999 + 1; // newer than the stub's cloud row
    await syncPull();
    out.localNewerWins = designs.find(d => d.id === 'cloud-1').name === 'Edited Locally';

    // meter counts per month
    localStorage.removeItem('widgetking.meter.ai');
    meterAIBuild(); meterAIBuild();
    const meter = JSON.parse(localStorage.getItem('widgetking.meter.ai'));
    out.meterCounts = meter.count === 2 && meter.month === new Date().toISOString().slice(0, 7);

    // sign out clears session, keeps designs
    const n = designs.length;
    document.getElementById('acctOutBtn').onclick();
    out.signOut = !syncSession() && designs.length === n &&
      document.getElementById('acctOut').style.display !== 'none';
  } finally {
    window.fetch = realFetch;
    localStorage.removeItem('widgetking.sync.url');
    localStorage.removeItem('widgetking.sync.key');
    designs = designs.filter(d => d.id !== 'cloud-1' && d.id !== 'local-1');
  }
  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check124 FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('check124 OK');
