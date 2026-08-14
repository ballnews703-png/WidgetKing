#!/usr/bin/env python3
"""
Moon phase icon pack generator.
4 style packs x 8 principal phases, 512px viewBox, transparent, moon only.
"""
import math, os, random

W = H = 512
CX = CY = 256.0
R = 186.0

OUT = "/home/claude/moon-packs"

# ---------------------------------------------------------------- geometry ---
# Phase angle 0 = new, pi = full.  Illuminated fraction = (1-cos(a))/2
# Terminator is an ellipse of semi-axis rx = R*|cos(a)| sharing the poles.

PHASES = [
    # key, label, phase_angle_deg, waxing
    ("00-new",             "New Moon",          0,   True),
    ("01-waxing-crescent", "Waxing Crescent",   45,  True),
    ("02-first-quarter",   "First Quarter",     90,  True),
    ("03-waxing-gibbous",  "Waxing Gibbous",    135, True),
    ("04-full",            "Full Moon",         180, True),
    ("05-waning-gibbous",  "Waning Gibbous",    135, False),
    ("06-last-quarter",    "Last Quarter",      90,  False),
    ("07-waning-crescent", "Waning Crescent",   45,  False),
]


def f(v):
    return ("%.3f" % v).rstrip("0").rstrip(".")


def illum(deg):
    return (1.0 - math.cos(math.radians(deg))) / 2.0


def _arc_back(rx, cx, cy, r, k, waxing):
    """Terminator arc from bottom pole back up to top pole.

    Crescent (|illum| < 0.5) -> terminator bulges toward the LIT limb.
    Gibbous  (|illum| > 0.5) -> terminator bulges toward the DARK limb.
    Bottom->top through +x is sweep 0; through -x is sweep 1.
    """
    if abs(rx) < 0.02:
        return "L %s %s " % (f(cx), f(cy - r))
    crescent = k > 0                      # k = cos(phase); k>0 => under half lit
    bulge_right = crescent if waxing else (not crescent)
    sweep = 0 if bulge_right else 1
    return "A %s %s 0 0 %d %s %s " % (f(rx), f(r), sweep, f(cx), f(cy - r))


def lit_path(deg, waxing, cx=CX, cy=CY, r=R):
    """Path of the illuminated region. Empty string for new moon."""
    if deg <= 0.001:
        return ""
    if deg >= 179.999:
        return ("M %s %s A %s %s 0 1 1 %s %s A %s %s 0 1 1 %s %s Z"
                % (f(cx), f(cy - r), f(r), f(r), f(cx), f(cy + r),
                   f(r), f(r), f(cx), f(cy - r)))
    k = math.cos(math.radians(deg))
    rx = r * abs(k)
    outer = 1 if waxing else 0
    d = "M %s %s " % (f(cx), f(cy - r))
    d += "A %s %s 0 0 %d %s %s " % (f(r), f(r), outer, f(cx), f(cy + r))
    d += _arc_back(rx, cx, cy, r, k, waxing)
    return d + "Z"


def dark_path(deg, waxing, cx=CX, cy=CY, r=R):
    """Path of the shadowed region. Empty for full moon."""
    if deg >= 179.999:
        return ""
    if deg <= 0.001:
        return ("M %s %s A %s %s 0 1 1 %s %s A %s %s 0 1 1 %s %s Z"
                % (f(cx), f(cy - r), f(r), f(r), f(cx), f(cy + r),
                   f(r), f(r), f(cx), f(cy - r)))
    k = math.cos(math.radians(deg))
    rx = r * abs(k)
    outer = 0 if waxing else 1
    d = "M %s %s " % (f(cx), f(cy - r))
    d += "A %s %s 0 0 %d %s %s " % (f(r), f(r), outer, f(cx), f(cy + r))
    d += _arc_back(rx, cx, cy, r, k, waxing)
    return d + "Z"


def circle_path(cx=CX, cy=CY, r=R):
    return ("M %s %s A %s %s 0 1 1 %s %s A %s %s 0 1 1 %s %s Z"
            % (f(cx), f(cy - r), f(r), f(r), f(cx), f(cy + r),
               f(r), f(r), f(cx), f(cy - r)))


def wobble_circle(seed, cx=CX, cy=CY, r=R, amp=0.035, n=14):
    """Hand-drawn closed circle via Catmull-Rom -> cubic bezier."""
    rnd = random.Random(seed)
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n
        rr = r * (1 + rnd.uniform(-amp, amp))
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d = "M %s %s " % (f(pts[0][0]), f(pts[0][1]))
    for i in range(n):
        p0 = pts[(i - 1) % n]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        d += "C %s %s %s %s %s %s " % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]),
                                       f(p2[0]), f(p2[1]))
    return d + "Z"


def craters(seed, count=7, rmin=10, rmax=34):
    """Craters placed inside the disc, deterministic per seed."""
    rnd = random.Random(seed)
    out = []
    tries = 0
    while len(out) < count and tries < 800:
        tries += 1
        a = rnd.uniform(0, 2 * math.pi)
        d = rnd.uniform(0, 0.80) ** 0.6 * R
        cr = rnd.uniform(rmin, rmax)
        x, y = CX + d * math.cos(a), CY + d * math.sin(a)
        if d + cr > R * 0.94:
            continue
        if any(math.hypot(x - o[0], y - o[1]) < cr + o[2] + 8 for o in out):
            continue
        out.append((x, y, cr))
    return out


def svg_wrap(defs, body, title):
    return ('<svg xmlns="http://www.w3.org/2000/svg" '
            'xmlns:xlink="http://www.w3.org/1999/xlink" '
            'viewBox="0 0 %d %d" width="%d" height="%d" '
            'role="img" aria-label="%s">\n<title>%s</title>\n'
            '<defs>\n%s</defs>\n%s\n</svg>\n'
            % (W, H, W, H, title, title, defs, body))


# ================================================================== CUTE =====
def pack_cute(key, label, deg, waxing, idx):
    lp = lit_path(deg, waxing)
    fr = illum(deg)
    uid = "c%d" % idx
    defs = f"""
  <radialGradient id="{uid}lit" cx="38%" cy="30%" r="78%">
    <stop offset="0%" stop-color="#FFFDF7"/>
    <stop offset="45%" stop-color="#FFE9F4"/>
    <stop offset="100%" stop-color="#FFC7E3"/>
  </radialGradient>
  <radialGradient id="{uid}dim" cx="38%" cy="30%" r="80%">
    <stop offset="0%" stop-color="#C9BCEA"/>
    <stop offset="100%" stop-color="#9B87C9"/>
  </radialGradient>
  <filter id="{uid}glow" x="-45%" y="-45%" width="190%" height="190%">
    <feGaussianBlur stdDeviation="16" result="b"/>
    <feComposite in="b" in2="SourceGraphic" operator="over"/>
  </filter>
"""
    # face colour follows the brighter surface it sits on
    ink = "#6B4B7E"
    body = []
    body.append('<g>')
    # soft outer glow
    body.append('<circle cx="256" cy="256" r="%s" fill="#FFD9EC" opacity="0.35" '
                'filter="url(#%sglow)"/>' % (f(R + 6), uid))
    # dim disc (always there so the moon stays a friendly circle)
    body.append('<circle cx="256" cy="256" r="%s" fill="url(#%sdim)"/>' % (f(R), uid))
    if lp:
        body.append('<path d="%s" fill="url(#%slit)"/>' % (lp, uid))
    # soft rim
    body.append('<circle cx="256" cy="256" r="%s" fill="none" stroke="#FFFFFF" '
                'stroke-opacity="0.55" stroke-width="4"/>' % f(R - 2))
    # ---- face ----
    sleeping = fr < 0.10
    eyx = 62.0
    ey = 246.0
    if sleeping:
        body.append('<path d="M %s %s q 22 22 44 0" fill="none" stroke="%s" '
                    'stroke-width="13" stroke-linecap="round"/>'
                    % (f(CX - eyx - 22), f(ey), ink))
        body.append('<path d="M %s %s q 22 22 44 0" fill="none" stroke="%s" '
                    'stroke-width="13" stroke-linecap="round"/>'
                    % (f(CX + eyx - 22), f(ey), ink))
    else:
        for sx in (-1, 1):
            body.append('<ellipse cx="%s" cy="%s" rx="14" ry="17" fill="%s"/>'
                        % (f(CX + sx * eyx), f(ey), ink))
            body.append('<circle cx="%s" cy="%s" r="5" fill="#FFFFFF" '
                        'opacity="0.9"/>' % (f(CX + sx * eyx - 4), f(ey - 6)))
    # cheeks
    for sx in (-1, 1):
        body.append('<ellipse cx="%s" cy="%s" rx="21" ry="13" fill="#FF9CC6" '
                    'opacity="0.55"/>' % (f(CX + sx * 104), f(ey + 40)))
    # mouth
    if sleeping:
        body.append('<path d="M 244 306 q 12 14 24 0" fill="none" stroke="%s" '
                    'stroke-width="11" stroke-linecap="round"/>' % ink)
    else:
        body.append('<path d="M 226 300 q 30 30 60 0" fill="none" stroke="%s" '
                    'stroke-width="12" stroke-linecap="round"/>' % ink)
    # sparkle highlight
    body.append('<path d="M 150 148 l 9 22 22 9 -22 9 -9 22 -9 -22 -22 -9 22 -9 Z" '
                'fill="#FFFFFF" opacity="0.85"/>')
    body.append('</g>')
    return svg_wrap(defs, "\n".join(body), "%s - cute" % label)


# =============================================================== BAD ASS =====
def pack_badass(key, label, deg, waxing, idx):
    lp = lit_path(deg, waxing)
    uid = "b%d" % idx
    cra = craters(1000 + idx, count=8, rmin=12, rmax=36)
    defs = f"""
  <radialGradient id="{uid}lit" cx="34%" cy="26%" r="82%">
    <stop offset="0%" stop-color="#FFFFFF"/>
    <stop offset="34%" stop-color="#D6FBFF"/>
    <stop offset="72%" stop-color="#3FD8F0"/>
    <stop offset="100%" stop-color="#0B7FBF"/>
  </radialGradient>
  <radialGradient id="{uid}body" cx="42%" cy="34%" r="80%">
    <stop offset="0%" stop-color="#191F2E"/>
    <stop offset="100%" stop-color="#05070C"/>
  </radialGradient>
  <filter id="{uid}bloom" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="26"/>
  </filter>
  <filter id="{uid}bloom2" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="9"/>
  </filter>
  <clipPath id="{uid}clipLit">{'<path d="%s"/>' % lp if lp else '<path d=""/>'}</clipPath>
  <clipPath id="{uid}clipAll"><path d="{circle_path()}"/></clipPath>
"""
    b = ['<g>']
    # magenta outer bloom + cyan bloom
    if lp:
        b.append('<path d="%s" fill="#FF2FA0" opacity="0.55" '
                 'filter="url(#%sbloom)"/>' % (lp, uid))
        b.append('<path d="%s" fill="#3FE9FF" opacity="0.75" '
                 'filter="url(#%sbloom2)"/>' % (lp, uid))
    else:
        b.append('<circle cx="256" cy="256" r="%s" fill="none" stroke="#FF2FA0" '
                 'stroke-width="10" opacity="0.65" filter="url(#%sbloom)"/>'
                 % (f(R), uid))
    # dark body
    b.append('<circle cx="256" cy="256" r="%s" fill="url(#%sbody)"/>' % (f(R), uid))
    # body craters (subtle)
    b.append('<g clip-path="url(#%sclipAll)" opacity="0.6">' % uid)
    for (x, y, cr) in cra:
        b.append('<circle cx="%s" cy="%s" r="%s" fill="#39445C" opacity="0.55"/>'
                 % (f(x), f(y), f(cr)))
        b.append('<circle cx="%s" cy="%s" r="%s" fill="#04060B" opacity="0.85"/>'
                 % (f(x + cr * 0.16), f(y + cr * 0.16), f(cr * 0.84)))
    b.append('</g>')
    # lit region
    if lp:
        b.append('<path d="%s" fill="url(#%slit)"/>' % (lp, uid))
        # craters inside lit region
        # craters: lit rim on the sun side, dark floor offset away from it
        b.append('<g clip-path="url(#%sclipLit)" opacity="0.62">' % uid)
        for (x, y, cr) in cra:
            b.append('<circle cx="%s" cy="%s" r="%s" fill="#E8FCFF" opacity="0.55"/>'
                     % (f(x), f(y), f(cr)))
            b.append('<circle cx="%s" cy="%s" r="%s" fill="#0A5C82" opacity="0.5"/>'
                     % (f(x + cr * 0.17), f(y + cr * 0.17), f(cr * 0.82)))
            b.append('<circle cx="%s" cy="%s" r="%s" fill="#0A3E5C" opacity="0.28"/>'
                     % (f(x + cr * 0.30), f(y + cr * 0.30), f(cr * 0.52)))
        b.append('</g>')
        # hot white edge along the lit outline
        b.append('<path d="%s" fill="none" stroke="#FFFFFF" stroke-width="4.5" '
                 'stroke-opacity="0.95" stroke-linejoin="round"/>' % lp)
    # limb rim light
    b.append('<circle cx="256" cy="256" r="%s" fill="none" stroke="#3FE9FF" '
             'stroke-width="3.5" opacity="%s"/>'
             % (f(R - 1), "0.95" if not lp else "0.45"))
    b.append('</g>')
    return svg_wrap(defs, "\n".join(b), "%s - bad ass" % label)


# ============================================================ WATERCOLOR =====
def pack_water(key, label, deg, waxing, idx):
    """Warm ochre wash for the lit face, dusty blue wash for the shadow,
    wobbly ink outline over the top."""
    lp = lit_path(deg, waxing)
    dp = dark_path(deg, waxing)
    uid = "w%d" % idx
    ink_d = wobble_circle(2000 + idx, amp=0.026)
    ink_d2 = wobble_circle(2500 + idx, amp=0.020, r=R * 0.99)
    defs = f"""
  <linearGradient id="{uid}lit" x1="14%" y1="6%" x2="86%" y2="94%">
    <stop offset="0%" stop-color="#FFFAEC"/>
    <stop offset="30%" stop-color="#F8E7B8"/>
    <stop offset="70%" stop-color="#E9C071"/>
    <stop offset="100%" stop-color="#C9933F"/>
  </linearGradient>
  <linearGradient id="{uid}dark" x1="10%" y1="10%" x2="90%" y2="92%">
    <stop offset="0%" stop-color="#C6D2DF"/>
    <stop offset="55%" stop-color="#93A4BA"/>
    <stop offset="100%" stop-color="#67788F"/>
  </linearGradient>
  <radialGradient id="{uid}bloom" cx="32%" cy="26%" r="55%">
    <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.75"/>
    <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/>
  </radialGradient>
  <filter id="{uid}rough" x="-25%" y="-25%" width="150%" height="150%">
    <feTurbulence type="fractalNoise" baseFrequency="0.013 0.017" numOctaves="4"
                  seed="{idx * 7 + 3}" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="22"
                       xChannelSelector="R" yChannelSelector="G"/>
  </filter>
  <filter id="{uid}rough2" x="-25%" y="-25%" width="150%" height="150%">
    <feTurbulence type="fractalNoise" baseFrequency="0.021" numOctaves="3"
                  seed="{idx * 11 + 5}" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="14"
                       xChannelSelector="R" yChannelSelector="G"/>
  </filter>
  <filter id="{uid}inkrough" x="-25%" y="-25%" width="150%" height="150%">
    <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2"
                  seed="{idx * 13 + 1}" result="n"/>
    <feDisplacementMap in="SourceGraphic" in2="n" scale="6"
                       xChannelSelector="R" yChannelSelector="G"/>
  </filter>
  <filter id="{uid}grainf" x="0%" y="0%" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="3"
                  seed="{idx * 3 + 9}"/>
    <feColorMatrix type="saturate" values="0"/>
  </filter>
  <filter id="{uid}soft" x="-30%" y="-30%" width="160%" height="160%">
    <feGaussianBlur stdDeviation="9"/>
  </filter>
  <clipPath id="{uid}clip"><path d="{ink_d}"/></clipPath>
"""
    b = ['<g>']
    # --- shadowed side: cool, thin, translucent wash -------------------------
    if dp:
        b.append('<g filter="url(#%srough)">' % uid)
        b.append('<path d="%s" fill="url(#%sdark)" opacity="0.72"/>' % (dp, uid))
        b.append('</g>')
        b.append('<g filter="url(#%srough2)" opacity="0.30">' % uid)
        b.append('<path d="%s" fill="#6E809A" transform="translate(5,-4)"/>' % dp)
        b.append('</g>')
    # --- lit side: warm ochre wash, two passes ------------------------------
    if lp:
        b.append('<g filter="url(#%srough)">' % uid)
        b.append('<path d="%s" fill="url(#%slit)" opacity="0.95"/>' % (lp, uid))
        b.append('</g>')
        b.append('<g filter="url(#%srough2)" opacity="0.38">' % uid)
        b.append('<path d="%s" fill="#E8C87E" transform="translate(-6,5)"/>' % lp)
        b.append('</g>')
        # pigment pooling along the wet edge
        b.append('<g filter="url(#%srough2)"><path d="%s" fill="none" '
                 'stroke="#B57D33" stroke-width="10" stroke-opacity="0.50" '
                 'stroke-linejoin="round"/></g>' % (uid, lp))
        # thin paint / lifted highlight where the brush started
        b.append('<g clip-path="url(#%sclip)"><path d="%s" '
                 'fill="url(#%sbloom)"/></g>' % (uid, lp, uid))
    # --- granulation: pigment settling into the paper tooth -----------------
    b.append('<g clip-path="url(#%sclip)" opacity="0.16" '
             'filter="url(#%ssoft)">' % (uid, uid))
    rnd = random.Random(3000 + idx)
    for _ in range(11):
        a = rnd.uniform(0, 6.283)
        d = rnd.uniform(10, R * 0.72)
        b.append('<circle cx="%s" cy="%s" r="%s" fill="#8A6636"/>'
                 % (f(CX + d * math.cos(a)), f(CY + d * math.sin(a)),
                    f(rnd.uniform(9, 22))))
    b.append('</g>')
    # --- paper grain --------------------------------------------------------
    b.append('<g clip-path="url(#%sclip)" opacity="0.14" '
             'style="mix-blend-mode:multiply">' % uid)
    b.append('<rect x="0" y="0" width="512" height="512" '
             'filter="url(#%sgrainf)"/>' % uid)
    b.append('</g>')
    # --- hand-drawn ink outline, double stroke, off-register ----------------
    b.append('<g filter="url(#%sinkrough)">' % uid)
    b.append('<path d="%s" fill="none" stroke="#3A342B" stroke-width="7.5" '
             'stroke-opacity="0.92" stroke-linecap="round"/>' % ink_d)
    b.append('<path d="%s" fill="none" stroke="#3A342B" stroke-width="3" '
             'stroke-opacity="0.30" stroke-linecap="round" '
             'transform="translate(5,-4)"/>' % ink_d2)
    # sketchy terminator line
    if lp and dp:
        b.append('<path d="%s" fill="none" stroke="#3A342B" stroke-width="3.5" '
                 'stroke-opacity="0.45" stroke-linecap="round" '
                 'stroke-dasharray="30 16 54 12"/>' % lp)
    b.append('</g>')
    b.append('</g>')
    return svg_wrap(defs, "\n".join(b), "%s - watercolor" % label)


# ================================================================= COZY ======
def pack_cozy(key, label, deg, waxing, idx):
    lp = lit_path(deg, waxing)
    uid = "z%d" % idx
    cra = craters(4000 + idx, count=6, rmin=14, rmax=38)
    defs = f"""
  <radialGradient id="{uid}lit" cx="36%" cy="28%" r="80%">
    <stop offset="0%" stop-color="#FFF6E2"/>
    <stop offset="52%" stop-color="#FFDFA6"/>
    <stop offset="100%" stop-color="#F0B26B"/>
  </radialGradient>
  <radialGradient id="{uid}dim" cx="36%" cy="28%" r="82%">
    <stop offset="0%" stop-color="#8C7768"/>
    <stop offset="100%" stop-color="#5E4E4E"/>
  </radialGradient>
  <filter id="{uid}glow" x="-60%" y="-60%" width="220%" height="220%">
    <feGaussianBlur stdDeviation="30"/>
  </filter>
  <filter id="{uid}soft" x="-30%" y="-30%" width="160%" height="160%">
    <feGaussianBlur stdDeviation="10"/>
  </filter>
  <filter id="{uid}grainf" x="0%" y="0%" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="4"
                  seed="{idx * 5 + 2}"/>
    <feColorMatrix type="saturate" values="0"/>
  </filter>
  <clipPath id="{uid}clipAll"><path d="{circle_path()}"/></clipPath>
  <clipPath id="{uid}clipLit">{'<path d="%s"/>' % lp if lp else '<path d=""/>'}</clipPath>
"""
    b = ['<g>']
    # warm ambient glow
    if lp:
        b.append('<path d="%s" fill="#FFB765" opacity="0.5" '
                 'filter="url(#%sglow)"/>' % (lp, uid))
    else:
        b.append('<circle cx="256" cy="256" r="%s" fill="#C98A52" opacity="0.30" '
                 'filter="url(#%sglow)"/>' % (f(R), uid))
    # dim body
    b.append('<circle cx="256" cy="256" r="%s" fill="url(#%sdim)"/>' % (f(R), uid))
    if lp:
        b.append('<path d="%s" fill="url(#%slit)"/>' % (lp, uid))
    # craters, soft and warm
    b.append('<g clip-path="url(#%sclipAll)" filter="url(#%ssoft)" opacity="0.30">'
             % (uid, uid))
    for (x, y, cr) in cra:
        b.append('<circle cx="%s" cy="%s" r="%s" fill="#B57C46"/>'
                 % (f(x), f(y), f(cr)))
        b.append('<circle cx="%s" cy="%s" r="%s" fill="#FFF0D2" opacity="0.55"/>'
                 % (f(x - cr * 0.16), f(y - cr * 0.16), f(cr * 0.78)))
    b.append('</g>')
    # soften the terminator a touch (cozy = no hard edges)
    if lp and 0.001 < illum(deg) < 0.999:
        b.append('<g clip-path="url(#%sclipAll)" opacity="0.5" '
                 'filter="url(#%ssoft)">' % (uid, uid))
        b.append('<path d="%s" fill="none" stroke="#C08A55" stroke-width="16" '
                 'stroke-opacity="0.55"/>' % lp)
        b.append('</g>')
    # grain
    b.append('<g clip-path="url(#%sclipAll)" opacity="0.10" '
             'style="mix-blend-mode:multiply">' % uid)
    b.append('<rect x="0" y="0" width="512" height="512" '
             'filter="url(#%sgrainf)"/>' % uid)
    b.append('</g>')
    # gentle warm rim
    b.append('<circle cx="256" cy="256" r="%s" fill="none" stroke="#FFD9A0" '
             'stroke-width="3" opacity="0.45"/>' % f(R - 1.5))
    b.append('</g>')
    return svg_wrap(defs, "\n".join(b), "%s - cozy" % label)


PACKS = [
    ("cute",       pack_cute),
    ("bad-ass",    pack_badass),
    ("watercolor", pack_water),
    ("cozy",       pack_cozy),
]


def main():
    for name, fn in PACKS:
        d = os.path.join(OUT, name, "svg")
        os.makedirs(d, exist_ok=True)
        for i, (key, label, deg, waxing) in enumerate(PHASES):
            svg = fn(key, label, deg, waxing, i)
            with open(os.path.join(d, "moon-%s.svg" % key), "w") as fh:
                fh.write(svg)
        print("wrote", name)


if __name__ == "__main__":
    main()
