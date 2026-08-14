# Icon generator toolkit

The stock sticker library in `web/stock/art/` is generated, not hand-drawn:
these scripts (by the project owner) define every icon as a small drawing
function on a shared 512px grid with a shared palette.

- `iconlib.py` — drawing primitives, gradients, glows, grain, the palette
- `icons_weather.py` / `icons_life.py` / `icons_ui.py` — the 97 widget icons
- `build_icons.py` — collects icons, writes SVGs, builds the manifest
- `moongen.py` — the 4 moon-phase packs (8 geometrically accurate phases each)
- `render.py` — rasterizes SVGs through headless Chromium

To add icons in the same style: write a new icon function against iconlib,
regenerate, rasterize at 512 with transparency, drop the PNG into
`web/stock/art/<id>.png`, and add its entry between the STOCK-MANIFEST
markers in `web/index.html`.
