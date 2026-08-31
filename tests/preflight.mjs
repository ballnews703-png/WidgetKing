// preflight — the hard template constraints that MUST hold before any
// release. The Scriptable template lives inside a <script type="text/plain">
// block, so backticks, template literals, and </scr sequences inside it
// corrupt the page; the __DESIGNS__/__PAGE_URL__ placeholders must appear
// exactly twice file-wide (template + buildScript replacement site).
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(root, 'web/index.html'), 'utf8');
const m = html.match(/<script type="text\/plain" id="scriptableTemplate">\n?([\s\S]*?)<\/script>/);
const tpl = m && m[1];
const fail = msg => { console.error('preflight FAILED:', msg); process.exit(1); };
if (!tpl) fail('template block not found');
if (tpl.includes('`')) fail('backtick inside template');
if (tpl.includes('${')) fail('template literal inside template');
if (tpl.includes('</scr')) fail('</scr inside template');
const count = re => (html.match(re) || []).length;
if (count(/"__DESIGNS__"/g) !== 2) fail('__DESIGNS__ count != 2');
if (count(/"__PAGE_URL__"/g) !== 2) fail('__PAGE_URL__ count != 2');
const web = html.match(/WK_VERSION = (\d+)/);
const gen = readFileSync(join(root, 'scriptable/WidgetKing.js'), 'utf8').match(/WK_VERSION = (\d+)/);
if (!web || !gen || web[1] !== gen[1]) fail('WK_VERSION mismatch web=' + (web && web[1]) + ' generated=' + (gen && gen[1]));
console.log('preflight OK (v' + web[1] + ')');
