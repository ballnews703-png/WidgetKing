# Icon generator toolkit

The stock sticker library in `web/stock/art/` is generated, not hand-drawn:
these scripts (by the project owner) define every icon as a small drawing
function on a shared 512px grid with a shared palette.

- `iconlib.py` — drawing primitives, gradients, glows, grain, the palette
- `icons_weather.py` / `icons_life.py` / `icons_ui.py` — the 97 widget icons
- `build_icons.py` — collects the widget icons, writes their SVGs, rasterizes
  them through headless Chromium, and writes a `manifest.json` (a different
  shape from the app's manifest — see below)
- `moongen.py` — the 4 moon-phase packs (8 geometrically accurate phases each)
- `render.py` — re-rasterizes the moon packs through headless Chromium

Requirements: Python 3 (stdlib only for drawing) plus `playwright` with a
headless Chromium for rasterizing.

Two things to know before running them:

1. **They write to a scratch directory, not the repo.** `build_icons.py` and
   `moongen.py`/`render.py` hardcode an `OUT` path (and `build_icons.py`
   deletes it first). Set `OUT` to a scratch folder, then copy the 512px PNGs
   you want into `web/stock/art/<id>.png`.
2. **The app's manifest is hand-maintained.** The app reads the `STOCK_ART`
   and `STOCK_ART_PACKS` arrays between the `STOCK-MANIFEST-START` /
   `STOCK-MANIFEST-END` markers in `web/index.html` (`id`, `pack`, `name`,
   `tags`). The generator's `manifest.json` is not consumed by the app.

To add icons in the same style: write a new icon function against iconlib,
regenerate, copy the 512px transparent PNG to `web/stock/art/<id>.png`, and
add its entry between the manifest markers.
