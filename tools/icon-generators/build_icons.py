#!/usr/bin/env python3
import os, json, shutil, glob
import icons_weather, icons_life, icons_ui

OUT = "/home/claude/widget-icons"
SIZES = [512, 256, 128, 64]

PACK_META = [
    ("weather",   "Weather",   "A complete condition set — the one you actually "
                               "need if a widget ever shows a forecast."),
    ("celestial", "Celestial", "Space and sky: planets, comets, auroras, "
                               "a black hole."),
    ("time",      "Time",      "Clocks, timers, progress rings, sunrise/sunset."),
    ("nature",    "Nature",    "Seasons and the outdoors."),
    ("cozy",      "Cozy",      "Warm objects — coffee, candles, vinyl, yarn."),
    ("system",    "System",    "Battery, connectivity, activity rings, alerts."),
    ("abstract",  "Abstract",  "Gradient orbs, meshes, waveforms — pure vibe, "
                               "good as widget backdrops."),
    ("retro",     "Retro",     "Synthwave, Y2K chrome, 8-bit, CRT green."),
]


def collect():
    icons = []
    for mod in (icons_weather, icons_life, icons_ui):
        for fn in mod.ICONS:
            icons.append(fn())
    slugs = [i.slug for i in icons]
    assert len(slugs) == len(set(slugs)), "duplicate slug"
    return icons


def write_svgs(icons):
    for ic in icons:
        d = os.path.join(OUT, ic.pack, "svg")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, ic.slug + ".svg"), "w") as fh:
            fh.write(ic.svg())


def render(icons):
    from playwright.sync_api import sync_playwright
    tpl = ('<!doctype html><html><head><meta charset="utf-8"><style>'
           'html,body{{margin:0;padding:0;background:transparent}}'
           'svg{{display:block;width:{s}px;height:{s}px}}</style></head>'
           '<body>{svg}</body></html>')
    with sync_playwright() as p:
        br = p.chromium.launch(args=["--force-color-profile=srgb"])
        for s in SIZES:
            page = br.new_page(viewport={"width": s, "height": s},
                               device_scale_factor=1)
            for ic in icons:
                d = os.path.join(OUT, ic.pack, "png", "%dpx" % s)
                os.makedirs(d, exist_ok=True)
                page.set_content(tpl.format(s=s, svg=ic.svg()))
                page.wait_for_timeout(28)
                page.screenshot(path=os.path.join(d, ic.slug + ".png"),
                                omit_background=True)
            page.close()
            print("rendered", s)
        br.close()


def manifest(icons):
    by = {}
    for ic in icons:
        by.setdefault(ic.pack, []).append(ic)
    return {
        "name": "Widget Icon Library",
        "version": "1.0.0",
        "viewBox": "0 0 512 512",
        "background": "transparent",
        "pngSizes": SIZES,
        "count": len(icons),
        "packs": [
            {"id": pid, "name": nm, "description": desc,
             "count": len(by.get(pid, [])),
             "icons": [{"slug": i.slug, "name": i.title, "tags": i.tags}
                       for i in by.get(pid, [])]}
            for pid, nm, desc in PACK_META],
    }


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    icons = collect()
    print("icons:", len(icons))
    write_svgs(icons)
    render(icons)
    with open(os.path.join(OUT, "manifest.json"), "w") as fh:
        json.dump(manifest(icons), fh, indent=2)
    print("png files:", len(glob.glob(os.path.join(OUT, "*/png/*/*.png"))))


if __name__ == "__main__":
    main()
