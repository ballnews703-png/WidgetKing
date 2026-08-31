# WidgetKing tests

Playwright-driven checks for the single-file app (`web/index.html`).
They live in the repo on purpose: an earlier, larger battery lived only in a
session scratchpad and was lost when that container was reclaimed. Never
again — every new release check gets committed here.

## Running

```
cd tests && npm install     # once
sh run.sh                   # whole battery
node core.mjs               # or any single spec
```

Specs expect a Chromium binary at `/opt/pw-browsers/chromium` (the Claude
remote environment provides it). Elsewhere, install Chromium and adjust the
`executablePath` at the top of each spec.

## What's here

- `preflight.mjs` — hard template constraints: no backticks / `${` / `</scr`
  inside the embedded Scriptable template, placeholder counts exactly 2,
  web and generated-renderer versions match. Run before every release.
- `core.mjs` — broad boot smoke: tabs, version badge, templates, stock
  sticker library, AI schema/prompt/model coherence, editor insert, Page
  Studio, script build, welcome-tour art. Consolidates the lost
  smoke27–38 + check89–120 coverage at lower resolution.
- `check121.mjs` — AI cost cut: Sonnet default, two-option dropdown,
  prompt-cache request shape (stubbed fetch — no API calls), spend math.
- `check122.mjs` — Settings/Guides icon chips + persistent-UI emoji sweep.
- `check123.mjs` — welcome tour variety (7 distinct showcase heroes).

## Conventions for new checks

One `checkNNN.mjs` per release, named after the WK_VERSION it ships with.
Assert through the page's own globals (`normalizeDesign`, `AI_SCHEMA`, …),
collect booleans into one object, exit 1 on any non-true entry or page error.
Never call paid external APIs from tests — stub `window.fetch` instead
(see check121).
