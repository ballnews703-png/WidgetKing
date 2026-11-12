// Builds supabase/functions/ai-proxy/index.ts (one pasteable file) from
// index.src.ts + policy.js. Run after editing either: node tools/gen_ai_proxy.mjs
import { readFileSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const dir = join(dirname(fileURLToPath(import.meta.url)), '..', 'supabase', 'functions', 'ai-proxy');
const src = readFileSync(join(dir, 'index.src.ts'), 'utf8');
const policy = readFileSync(join(dir, 'policy.js'), 'utf8')
  .split('\n').filter(l => !/^\/\/ /.test(l) || /^\/\/ (usage|Returns|  reason|Only|What|\$ per)/.test(l)).join('\n')
  .replace(/^export /gm, '');
const out = src.replace('//__POLICY__', '// ---- policy.js (generated copy; edit policy.js, not this) ----\n' + policy.trim() + '\n// ---- end policy.js ----');
writeFileSync(join(dir, 'index.ts'), out);
console.log('wrote index.ts (' + out.length + ' chars)');
