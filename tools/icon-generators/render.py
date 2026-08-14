#!/usr/bin/env python3
import os, glob, base64
from playwright.sync_api import sync_playwright

OUT = "/home/claude/moon-packs"
SIZES = [512, 256, 128, 64]
PACKS = ["cute", "bad-ass", "watercolor", "cozy"]

HTML = """<!doctype html><html><head><meta charset="utf-8"><style>
html,body{{margin:0;padding:0;background:transparent}}
svg{{display:block;width:{s}px;height:{s}px}}
</style></head><body>{svg}</body></html>"""


def main():
    with sync_playwright() as p:
        br = p.chromium.launch(args=["--force-color-profile=srgb",
                                     "--disable-lcd-text"])
        for pack in PACKS:
            files = sorted(glob.glob(os.path.join(OUT, pack, "svg", "*.svg")))
            for s in SIZES:
                d = os.path.join(OUT, pack, "png", "%dpx" % s)
                os.makedirs(d, exist_ok=True)
                page = br.new_page(viewport={"width": s, "height": s},
                                   device_scale_factor=1)
                for fp in files:
                    svg = open(fp).read()
                    page.set_content(HTML.format(s=s, svg=svg))
                    page.wait_for_timeout(35)
                    name = os.path.basename(fp).replace(".svg", ".png")
                    page.screenshot(path=os.path.join(d, name),
                                    omit_background=True)
                page.close()
            print("rendered", pack)
        br.close()


if __name__ == "__main__":
    main()
