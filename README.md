# WidgetKing 👑

Design your own iPhone Home Screen widgets in seconds — no code, no fuss.

WidgetKing is a widget **designer**: describe a widget in plain English (or
let the built-in AI design it for you), fine-tune it in a drag-and-drop
Studio, and put it on your Home Screen. It also restyles your app icons to
match, builds Lock Screen widgets, and generates matching wallpapers — so your
whole phone looks like one intentional design, not a collection of apps.

What makes it different:

- **🪄 An AI that's both a widget expert and a trained designer.** Describe a
  mood — "cozy", "elegant", "energetic" — and it makes real design decisions:
  typography hierarchy, color discipline, composition. It even reviews a
  picture of its own finished widget and fixes what falls short.
- **🎨 A full drag-and-drop editor** with live data (weather, calendar,
  reminders, news, stocks, world clocks, sun & moon, battery, sports), photos,
  a 129-piece sticker library, glass and see-through backgrounds, month grids,
  gauges, and 21 fonts.
- **☁️ Optional account sync** — sign in with an emailed code and your designs
  follow you between devices; nothing is required to use the app without it.
- **📱 App icon styling** — real App Store icons restyled into cohesive packs
  (pastel, line, noir, zen, neon, and more), plus custom icon packs.
- **👑 Everything matches** — widgets, icons, Lock Screen, and wallpaper come
  from one design language.

## Status

WidgetKing is a commercial product headed for the App Store. The hosted
designer at https://ballnews703-png.github.io/WidgetKing/ is the current way
to use it. A native iOS project lives in this repository; its status and the
open decisions around it are tracked in [`PUBLISHING.md`](PUBLISHING.md).

What's in here:

- `web/index.html` — the entire designer (single file) plus the embedded
  Scriptable renderer; `web/stock/art/` — the 129-sticker library
- `scriptable/WidgetKing.js` — the generated renderer reference copy
- `tests/` — the Playwright battery, including a Scriptable simulator that
  runs the real phone renderer in Node (`sh tests/run.sh`)
- `tools/icon-generators/` — the Python toolkit that draws the sticker library
- `MONETIZATION.md`, `ACCOUNTS_SETUP.md`, `SURFACES.md` — the plans
- `.github/workflows/pages.yml` — deploys `web/` to GitHub Pages

- Privacy policy: [`web/privacy.html`](web/privacy.html) (served on the
  hosted site as `privacy.html`)

## A note on this repository

The source here is published for transparency, not for reuse. **No permission
is granted to copy, redistribute, or ship derivative apps** — see
[`LICENSE`](LICENSE). If you'd like to use WidgetKing, use the official app.
