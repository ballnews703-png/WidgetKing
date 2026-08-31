// check121 — AI cost cut: Sonnet 5 is the default ("High quality"), Haiku is
// "Fast", Opus is gone from the dropdown (legacy stored values normalize),
// and the system prompt is split so the stable doctrine block ships with a
// cache_control breakpoint while the shuffled style references ride after it.
// The API request body is verified by stubbing fetch — no network, no spend.
import { chromium } from 'playwright-core';
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
const pg = await b.newPage({ viewport: { width: 390, height: 800 }, hasTouch: true });
const errors = [];
pg.on('pageerror', e => errors.push(String(e)));
await pg.addInitScript(() => {
  localStorage.setItem('widgetking.tourseen', '1');
  // a pre-v121 device: Opus stored from the old dropdown
  localStorage.setItem('widgetking.aimodel', 'claude-opus-5');
});
await pg.goto('file:///home/user/WidgetKing/web/index.html');
await pg.waitForTimeout(700);
const r = await pg.evaluate(async () => {
  const out = {};

  // model roster + legacy normalization
  out.prices = JSON.stringify(PRICES['claude-sonnet-5']) === '[3,15]' &&
    JSON.stringify(PRICES['claude-haiku-4-5']) === '[1,5]';
  out.legacyNormalizes = aiModel() === 'claude-sonnet-5';
  localStorage.setItem('widgetking.aimodel', 'claude-haiku-4-5');
  out.haikuKept = aiModel() === 'claude-haiku-4-5';
  localStorage.removeItem('widgetking.aimodel');
  out.defaultSonnet = aiModel() === 'claude-sonnet-5';

  // dropdown: exactly the two approved options, Sonnet first
  const opts = [...document.getElementById('aiModel').options].map(o => o.value);
  out.dropdown = JSON.stringify(opts) === JSON.stringify(['claude-sonnet-5', 'claude-haiku-4-5']);
  out.dropdownShows = document.getElementById('aiModel').value === 'claude-sonnet-5';

  // prompt split: stable half is deterministic, variable half carries the
  // shuffled references, and the legacy joined form is byte-compatible
  const s1 = aiSystemPromptStable(), s2 = aiSystemPromptStable();
  out.stableIsStable = s1 === s2 && s1.length > 8000;
  out.stableNoRefs = !s1.includes('STYLE REFERENCES') && s1.includes('LIVE ART') && s1.includes('STICKERS');
  const v = aiSystemPromptVariable('a cozy moon widget');
  out.variableHasRefs = v.includes('STYLE REFERENCES') && v.includes('Reference [') && v.includes('Today is');
  out.joinedMatches = aiSystemPrompt('x').indexOf(s1) === 0;

  // the real request body: stub fetch, run callClaudeOnce, inspect
  localStorage.setItem('widgetking.spend', '0');
  const captured = [];
  const realFetch = window.fetch;
  window.fetch = function (url, init) {
    captured.push(JSON.parse(init.body));
    return Promise.resolve({
      ok: true,
      json: function () {
        return Promise.resolve({
          usage: { input_tokens: 1000, output_tokens: 1000, cache_read_input_tokens: 4000, cache_creation_input_tokens: 0 },
          stop_reason: 'end_turn',
          content: [{ type: 'text', text: '{"ok":true}' }]
        });
      }
    });
  };
  let parsed = null;
  try { parsed = await callClaudeOnce([{ role: 'user', content: 'test widget' }], 'sk-test'); }
  finally { window.fetch = realFetch; }
  const body = captured[0];
  out.callWorks = parsed && parsed.ok === true;
  out.bodyModel = body.model === 'claude-sonnet-5';
  out.bodySystemBlocks = Array.isArray(body.system) && body.system.length === 2;
  out.bodyCacheMark = body.system[0].cache_control && body.system[0].cache_control.type === 'ephemeral' &&
    !body.system[1].cache_control;
  out.bodyBlockOrder = body.system[0].text === aiSystemPromptStable() && body.system[1].text.includes('STYLE REFERENCES');

  // spend math prices Sonnet + discounted cache reads correctly:
  // 1000 in * $3/M + 1000 out * $15/M + 4000 cached * $0.3/M = $0.0192
  out.spendMath = Math.abs(getSpend() - 0.0192) < 1e-9;

  return out;
});
console.log(JSON.stringify(r), 'pageErrors:', JSON.stringify(errors));
await b.close();
const bad = Object.entries(r).filter(([, v]) => v !== true);
if (bad.length || errors.length) { console.error('check121 FAILED', JSON.stringify(bad)); process.exit(1); }
console.log('check121 OK');
