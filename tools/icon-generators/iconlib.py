#!/usr/bin/env python3
"""Shared drawing toolkit for the widget icon library.

Everything lives on a 512x512 grid, centre (256,256), with ~56px of breathing
room so glows never clip. Icons are transparent, self-contained SVGs.
"""
import math, random, zlib

S = 512
C = 256.0
PAD = 56.0
BOX = S - 2 * PAD          # 400 usable

# ------------------------------------------------------------------ palette --
P = {
    "void":    "#0A0D16",
    "ink":     "#131A2A",
    "slate":   "#2B3446",
    "steel":   "#5B6B85",
    "mist":    "#8FA3BF",
    "fog":     "#C3D0E0",
    "paper":   "#F4F1EA",
    "white":   "#FFFFFF",

    "cyan":    "#3FE9FF",
    "aqua":    "#5EEAD4",
    "blue":    "#4C8DFF",
    "deepblue":"#1E4FD8",
    "indigo":  "#6C6CFF",
    "violet":  "#A66CFF",
    "magenta": "#FF4FA3",
    "rose":    "#FF6B8A",
    "coral":   "#FF8A5B",
    "amber":   "#FFB74D",
    "gold":    "#FFD76E",
    "cream":   "#FFF3D6",
    "green":   "#6EE7A8",
    "leaf":    "#3FBF7F",
    "moss":    "#2A8F63",
    "clay":    "#C46A4A",
    "wood":    "#8B5E3C",
    "plum":    "#5B3A6E",
}


def n(v):
    """Compact number formatting."""
    s = "%.2f" % v
    return s.rstrip("0").rstrip(".") if "." in s else s


def pts(seq):
    return " ".join("%s,%s" % (n(x), n(y)) for x, y in seq)


# ------------------------------------------------------------------- shapes --
def star_pts(cx, cy, ro, ri, points=5, rot=-90):
    out = []
    for i in range(points * 2):
        r = ro if i % 2 == 0 else ri
        a = math.radians(rot + i * 180.0 / points)
        out.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return out


def sparkle(cx, cy, r, waist=0.22):
    """Four-point 'twinkle' — the classic soft star."""
    w = r * waist
    return ("M %s %s C %s %s %s %s %s %s C %s %s %s %s %s %s "
            "C %s %s %s %s %s %s C %s %s %s %s %s %s Z" % (
                n(cx), n(cy - r),
                n(cx + w), n(cy - w), n(cx + w), n(cy - w), n(cx + r), n(cy),
                n(cx + w), n(cy + w), n(cx + w), n(cy + w), n(cx), n(cy + r),
                n(cx - w), n(cy + w), n(cx - w), n(cy + w), n(cx - r), n(cy),
                n(cx - w), n(cy - w), n(cx - w), n(cy - w), n(cx), n(cy - r)))


def blob(seed, cx, cy, r, amp=0.16, k=7):
    """Organic closed blob via Catmull-Rom."""
    rnd = random.Random(seed)
    p = []
    for i in range(k):
        a = 2 * math.pi * i / k + rnd.uniform(-0.12, 0.12)
        rr = r * (1 + rnd.uniform(-amp, amp))
        p.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return catmull(p)


def catmull(p):
    k = len(p)
    d = "M %s %s " % (n(p[0][0]), n(p[0][1]))
    for i in range(k):
        p0, p1, p2, p3 = p[(i - 1) % k], p[i], p[(i + 1) % k], p[(i + 2) % k]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        d += "C %s %s %s %s %s %s " % (n(c1[0]), n(c1[1]), n(c2[0]), n(c2[1]),
                                       n(p2[0]), n(p2[1]))
    return d + "Z"


def droplet(cx, cy, w, h):
    """Teardrop: pointed top, round bottom."""
    return ("M %s %s C %s %s %s %s %s %s C %s %s %s %s %s %s Z" % (
        n(cx), n(cy - h / 2),
        n(cx + w * 0.30), n(cy - h * 0.10), n(cx + w / 2), n(cy + h * 0.06),
        n(cx + w / 2), n(cy + h * 0.20),
        n(cx + w / 2), n(cy + h / 2), n(cx - w / 2), n(cy + h / 2),
        n(cx - w / 2), n(cy + h * 0.20)) +
        " C %s %s %s %s %s %s Z" % (
        n(cx - w / 2), n(cy + h * 0.06), n(cx - w * 0.30), n(cy - h * 0.10),
        n(cx), n(cy - h / 2)))


def arc(cx, cy, r, a0, a1, sweep=1):
    x0, y0 = cx + r * math.cos(math.radians(a0)), cy + r * math.sin(math.radians(a0))
    x1, y1 = cx + r * math.cos(math.radians(a1)), cy + r * math.sin(math.radians(a1))
    large = 1 if abs(a1 - a0) > 180 else 0
    return "M %s %s A %s %s 0 %d %d %s %s" % (n(x0), n(y0), n(r), n(r),
                                              large, sweep, n(x1), n(y1))


def ring_seg(cx, cy, r, w, a0, a1):
    """Filled annulus segment as a path (avoids stroke-dash maths)."""
    ro, ri = r + w / 2, r - w / 2
    def pt(rr, a):
        return (cx + rr * math.cos(math.radians(a)), cy + rr * math.sin(math.radians(a)))
    large = 1 if abs(a1 - a0) > 180 else 0
    x0, y0 = pt(ro, a0); x1, y1 = pt(ro, a1)
    x2, y2 = pt(ri, a1); x3, y3 = pt(ri, a0)
    return ("M %s %s A %s %s 0 %d 1 %s %s L %s %s A %s %s 0 %d 0 %s %s Z"
            % (n(x0), n(y0), n(ro), n(ro), large, n(x1), n(y1),
               n(x2), n(y2), n(ri), n(ri), large, n(x3), n(y3)))


def arrow_head(cx, cy, r, ang, size, direction=1):
    """Triangle sitting on a circle at `ang`, pointing along the tangent."""
    a = math.radians(ang)
    px, py = cx + r * math.cos(a), cy + r * math.sin(a)
    tx, ty = -math.sin(a) * direction, math.cos(a) * direction
    nx, ny = math.cos(a), math.sin(a)
    return [(px + tx * size, py + ty * size),
            (px + nx * size * 0.85 - tx * size * 0.45,
             py + ny * size * 0.85 - ty * size * 0.45),
            (px - nx * size * 0.85 - tx * size * 0.45,
             py - ny * size * 0.85 - ty * size * 0.45)]


def rrect(x, y, w, h, r):
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s"' % (
        n(x), n(y), n(w), n(h), n(r))


def poly(seq):
    return '<polygon points="%s"' % pts(seq)


def bolt(cx, cy, w, h):
    """Lightning bolt polygon."""
    return [(cx + w * .10, cy - h / 2), (cx - w / 2, cy + h * .10),
            (cx - w * .06, cy + h * .10), (cx - w * .16, cy + h / 2),
            (cx + w / 2, cy - h * .08), (cx + w * .02, cy - h * .08)]


# -------------------------------------------------------------------- Icon ---
class Icon:
    """Accumulates <defs> and body markup for one icon."""

    def __init__(self, slug, title, pack, tags=()):
        self.slug, self.title, self.pack = slug, title, pack
        self.tags = list(tags)
        # deterministic across runs (plain hash() is salted per process)
        self.uid = "i%05d%s" % (zlib.crc32(slug.encode()) % 100000,
                                slug.replace("-", "")[:6])
        self._defs, self._body = [], []

    # ---- ids
    def gid(self, name):
        return "%s_%s" % (self.uid, name)

    def url(self, name):
        return "url(#%s)" % self.gid(name)

    # ---- defs
    def lin(self, name, stops, x1="0%", y1="0%", x2="0%", y2="100%", user=False):
        s = "".join(self._stop(t) for t in stops)
        u = ' gradientUnits="userSpaceOnUse"' if user else ""
        self._defs.append('<linearGradient id="%s"%s x1="%s" y1="%s" x2="%s" '
                          'y2="%s">%s</linearGradient>'
                          % (self.gid(name), u, x1, y1, x2, y2, s))
        return self.url(name)

    def rad(self, name, stops, cx="50%", cy="50%", r="60%", fx=None, fy=None):
        s = "".join(self._stop(t) for t in stops)
        extra = ""
        if fx is not None:
            extra = ' fx="%s" fy="%s"' % (fx, fy)
        self._defs.append('<radialGradient id="%s" cx="%s" cy="%s" r="%s"%s>%s'
                          '</radialGradient>'
                          % (self.gid(name), cx, cy, r, extra, s))
        return self.url(name)

    @staticmethod
    def _stop(t):
        if len(t) == 3:
            return ('<stop offset="%s" stop-color="%s" stop-opacity="%s"/>'
                    % (t[0], t[1], t[2]))
        return '<stop offset="%s" stop-color="%s"/>' % (t[0], t[1])

    def blur(self, name, std):
        self._defs.append('<filter id="%s" x="-70%%" y="-70%%" width="240%%" '
                          'height="240%%"><feGaussianBlur stdDeviation="%s"/>'
                          '</filter>' % (self.gid(name), n(std)))
        return self.url(name)

    def shadow(self, name, dy=10, std=12, color="#000000", op=0.30):
        self._defs.append(
            '<filter id="%s" x="-60%%" y="-60%%" width="220%%" height="220%%">'
            '<feDropShadow dx="0" dy="%s" stdDeviation="%s" flood-color="%s" '
            'flood-opacity="%s"/></filter>'
            % (self.gid(name), n(dy), n(std), color, op))
        return self.url(name)

    def grain(self, name, freq=0.85, octaves=3, seed=4):
        self._defs.append(
            '<filter id="%s" x="0%%" y="0%%" width="100%%" height="100%%">'
            '<feTurbulence type="fractalNoise" baseFrequency="%s" '
            'numOctaves="%d" seed="%d"/><feColorMatrix type="saturate" '
            'values="0"/></filter>' % (self.gid(name), freq, octaves, seed))
        return self.url(name)

    def rough(self, name, freq=0.02, scale=10, seed=3, octaves=3):
        self._defs.append(
            '<filter id="%s" x="-30%%" y="-30%%" width="160%%" height="160%%">'
            '<feTurbulence type="fractalNoise" baseFrequency="%s" '
            'numOctaves="%d" seed="%d" result="n"/><feDisplacementMap '
            'in="SourceGraphic" in2="n" scale="%s" xChannelSelector="R" '
            'yChannelSelector="G"/></filter>'
            % (self.gid(name), freq, octaves, seed, n(scale)))
        return self.url(name)

    def clip(self, name, markup):
        self._defs.append('<clipPath id="%s">%s</clipPath>'
                          % (self.gid(name), markup))
        return self.url(name)

    def mask(self, name, markup):
        self._defs.append('<mask id="%s">%s</mask>' % (self.gid(name), markup))
        return self.url(name)

    def raw(self, markup):
        self._defs.append(markup)

    # ---- body
    def a(self, markup):
        self._body.append(markup)

    def glow_shape(self, markup_fill, std=22, op=0.55):
        """Emissive halo: blurred copy of a shape behind it."""
        fid = self.blur("gl%d" % len(self._defs), std)
        self.a('<g filter="%s" opacity="%s">%s</g>' % (fid, n(op), markup_fill))

    def texture(self, clip_url, op=0.10, freq=0.85, seed=7):
        gid = self.grain("gr%d" % len(self._defs), freq=freq, seed=seed)
        self.a('<g clip-path="%s" opacity="%s" style="mix-blend-mode:overlay">'
               '<rect width="512" height="512" filter="%s"/></g>'
               % (clip_url, n(op), gid))

    # ---- output
    def svg(self):
        return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" '
                'width="512" height="512" role="img" aria-label="%s">'
                '<title>%s</title><defs>%s</defs>%s</svg>\n'
                % (self.title, self.title,
                   "".join(self._defs), "".join(self._body)))


# --------------------------------------------------------------- primitives --
def cloud_shapes(cx, cy, w, lift=1.0):
    """Circles + base rect whose union is a friendly cloud. Returns markup."""
    u = w / 200.0
    return ("".join([
        '<circle cx="%s" cy="%s" r="%s"/>' % (n(cx - 46 * u), n(cy - 2 * u * lift), n(40 * u)),
        '<circle cx="%s" cy="%s" r="%s"/>' % (n(cx - 6 * u), n(cy - 26 * u * lift), n(52 * u)),
        '<circle cx="%s" cy="%s" r="%s"/>' % (n(cx + 50 * u), n(cy - 6 * u * lift), n(44 * u)),
        '<rect x="%s" y="%s" width="%s" height="%s" rx="%s"/>'
        % (n(cx - 88 * u), n(cy - 2 * u), n(176 * u), n(42 * u), n(21 * u)),
    ]))


def cloud(ic, name, cx, cy, w, top="#FFFFFF", bot="#B9C9DE", shade=True,
          lift=1.0):
    """Draw a soft gradient cloud. Returns the clip url for extras."""
    cl = ic.clip(name + "c", cloud_shapes(cx, cy, w, lift))
    g = ic.lin(name + "g", [("0%", top), ("58%", top), ("100%", bot)],
               y1="0%", y2="100%")
    ic.a('<g clip-path="%s"><rect x="0" y="0" width="512" height="512" '
         'fill="%s"/>' % (cl, g))
    if shade:
        bl = ic.blur(name + "b", 14)
        ic.a('<g filter="%s" opacity="0.42"><rect x="0" y="%s" width="512" '
             'height="%s" fill="%s"/></g>'
             % (bl, n(cy + w * 0.10), n(w), bot))
    ic.a('</g>')
    return cl
