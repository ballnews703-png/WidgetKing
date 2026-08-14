#!/usr/bin/env python3
"""Weather (16) + Celestial (12)."""
import math, random
from iconlib import *

PACK_W = "weather"
PACK_C = "celestial"
ICONS = []


def reg(fn):
    ICONS.append(fn)
    return fn


# ------------------------------------------------------------------ helpers --
def sun_disc(ic, cx, cy, r, warm=True, rays=True, ray_len=1.0):
    if warm:
        stops = [("0%", P["cream"]), ("42%", P["gold"]), ("100%", "#F59A22")]
        halo = P["amber"]
    else:
        stops = [("0%", "#FFFFFF"), ("45%", "#DCEBFF"), ("100%", "#9EC0F0")]
        halo = "#BFD9FF"
    g = ic.rad("sun", stops, cx="36%", cy="30%", r="76%")
    if rays:
        rr = []
        for i in range(8):
            a = math.radians(i * 45)
            r0, r1 = r * 1.28, r * (1.28 + 0.34 * ray_len)
            rr.append('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                      % (n(cx + r0 * math.cos(a)), n(cy + r0 * math.sin(a)),
                         n(cx + r1 * math.cos(a)), n(cy + r1 * math.sin(a))))
        ic.glow_shape('<g stroke="%s" stroke-width="%s" stroke-linecap="round">'
                      '%s</g>' % (halo, n(r * 0.20), "".join(rr)), 16, 0.8)
        ic.a('<g stroke="%s" stroke-width="%s" stroke-linecap="round">%s</g>'
             % (halo, n(r * 0.17), "".join(rr)))
    ic.glow_shape('<circle cx="%s" cy="%s" r="%s" fill="%s"/>'
                  % (n(cx), n(cy), n(r * 1.05), halo), 26, 0.55)
    ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (n(cx), n(cy), n(r), g))
    return g


def rain_drops(ic, cx, cy, cols=(-58, 0, 58), color=None, tilt=10, ln=44):
    color = color or ic.lin("rn", [("0%", "#7FC8FF", "0.25"),
                                   ("100%", "#3A8DFF")])
    out = []
    for i, dx in enumerate(cols):
        y0 = cy + (i % 2) * 18
        out.append('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                   % (n(cx + dx), n(y0), n(cx + dx - tilt), n(y0 + ln)))
    ic.a('<g stroke="%s" stroke-width="15" stroke-linecap="round">%s</g>'
         % (color, "".join(out)))


def snow_flake(cx, cy, r, arms=6):
    out = []
    for i in range(arms):
        a = math.radians(i * 360.0 / arms - 90)
        x, y = cx + r * math.cos(a), cy + r * math.sin(a)
        out.append('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                   % (n(cx), n(cy), n(x), n(y)))
        for s in (0.55, 0.82):
            bx, by = cx + r * s * math.cos(a), cy + r * s * math.sin(a)
            for d in (-38, 38):
                a2 = a + math.radians(d)
                out.append('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                           % (n(bx), n(by),
                              n(bx + r * 0.26 * math.cos(a2)),
                              n(by + r * 0.26 * math.sin(a2))))
    return "".join(out)


# =============================================================== WEATHER =====
@reg
def clear_day():
    ic = Icon("clear-day", "Clear Day", PACK_W, ["sun", "sunny", "hot"])
    sun_disc(ic, 256, 256, 108)
    return ic


@reg
def clear_night():
    ic = Icon("clear-night", "Clear Night", PACK_W, ["moon", "stars", "night"])
    g = ic.rad("m", [("0%", "#FFFFFF"), ("48%", "#E6EEFF"), ("100%", "#A9BEE8")],
               cx="34%", cy="28%", r="78%")
    ic.glow_shape('<circle cx="240" cy="252" r="118" fill="#8FB3FF"/>', 30, 0.5)
    # crescent via mask
    m = ic.mask("cm", '<rect width="512" height="512" fill="#000"/>'
                      '<circle cx="240" cy="252" r="112" fill="#fff"/>'
                      '<circle cx="172" cy="206" r="104" fill="#000"/>')
    ic.a('<g mask="%s"><circle cx="240" cy="252" r="112" fill="%s"/></g>'
         % (m, g))
    for (x, y, r, o) in ((372, 150, 15, 1), (404, 246, 10, .8), (330, 96, 9, .7)):
        ic.a('<path d="%s" fill="#FFF6C9" opacity="%s"/>'
             % (sparkle(x, y, r), o))
    return ic


@reg
def partly_cloudy_day():
    ic = Icon("partly-cloudy-day", "Partly Cloudy", PACK_W,
              ["sun", "cloud", "fair"])
    sun_disc(ic, 196, 190, 74, ray_len=0.75)
    cloud(ic, "c", 288, 300, 210)
    return ic


@reg
def partly_cloudy_night():
    ic = Icon("partly-cloudy-night", "Partly Cloudy Night", PACK_W,
              ["moon", "cloud", "night"])
    g = ic.rad("m", [("0%", "#FFFFFF"), ("100%", "#AFC4EA")], cx="35%", cy="30%")
    ic.glow_shape('<circle cx="196" cy="188" r="82" fill="#8FB3FF"/>', 24, 0.5)
    m = ic.mask("cm", '<rect width="512" height="512" fill="#000"/>'
                      '<circle cx="196" cy="188" r="76" fill="#fff"/>'
                      '<circle cx="150" cy="156" r="70" fill="#000"/>')
    ic.a('<g mask="%s"><circle cx="196" cy="188" r="76" fill="%s"/></g>' % (m, g))
    cloud(ic, "c", 288, 302, 208, top="#EDF3FB", bot="#9FB4CE")
    return ic


@reg
def cloudy():
    ic = Icon("cloudy", "Cloudy", PACK_W, ["cloud", "clouds"])
    cloud(ic, "b", 300, 196, 186, top="#C7D6E9", bot="#8FA6C4", shade=False)
    cloud(ic, "f", 236, 300, 226)
    return ic


@reg
def overcast():
    ic = Icon("overcast", "Overcast", PACK_W, ["cloud", "grey", "dull"])
    cloud(ic, "b", 316, 190, 178, top="#9FB0C8", bot="#61738F", shade=False)
    cloud(ic, "m", 176, 226, 168, top="#B6C5DA", bot="#7A8CA8", shade=False)
    cloud(ic, "f", 256, 312, 232, top="#E4EBF5", bot="#8FA2BC")
    return ic


@reg
def rain():
    ic = Icon("rain", "Rain", PACK_W, ["shower", "wet", "drizzle"])
    cloud(ic, "c", 256, 236, 214)
    rain_drops(ic, 256, 336)
    return ic


@reg
def heavy_rain():
    ic = Icon("heavy-rain", "Heavy Rain", PACK_W, ["downpour", "storm", "wet"])
    cloud(ic, "c", 256, 228, 218, top="#DCE6F3", bot="#8FA4C0")
    rain_drops(ic, 256, 322, cols=(-84, -28, 28, 84), ln=52)
    rain_drops(ic, 256, 356, cols=(-56, 0, 56), ln=44)
    return ic


@reg
def drizzle():
    ic = Icon("drizzle", "Drizzle", PACK_W, ["light rain", "mist"])
    cloud(ic, "c", 256, 238, 212)
    col = ic.lin("d", [("0%", "#8FD2FF", "0.3"), ("100%", "#4FA0FF")])
    o = []
    for i, dx in enumerate((-70, -24, 24, 70)):
        y = 332 + (i % 2) * 20
        o.append('<path d="%s" fill="%s"/>' % (droplet(256 + dx, y, 22, 34), col))
    ic.a("".join(o))
    return ic


@reg
def thunderstorm():
    ic = Icon("thunderstorm", "Thunderstorm", PACK_W,
              ["lightning", "storm", "thunder"])
    cloud(ic, "c", 256, 226, 216, top="#D5DFEE", bot="#7C8FAC")
    bg = ic.lin("bg", [("0%", P["cream"]), ("55%", P["gold"]), ("100%", "#FF9E2C")])
    b = poly(bolt(252, 350, 108, 148)) + ' fill="%s"/>' % bg
    ic.glow_shape(poly(bolt(252, 350, 118, 156)) + ' fill="#FFC24D"/>', 20, 0.85)
    ic.a(b)
    rain_drops(ic, 256, 338, cols=(-96, 96), ln=42)
    return ic


@reg
def snow():
    ic = Icon("snow", "Snow", PACK_W, ["snowing", "flakes", "cold"])
    cloud(ic, "c", 256, 232, 212)
    ic.glow_shape('<g stroke="#BFE6FF" stroke-width="11" stroke-linecap="round">'
                  '%s%s%s</g>' % (snow_flake(170, 350, 34),
                                  snow_flake(256, 380, 30),
                                  snow_flake(342, 350, 34)), 12, 0.7)
    ic.a('<g stroke="#FFFFFF" stroke-width="8" stroke-linecap="round">%s%s%s</g>'
         % (snow_flake(170, 350, 34), snow_flake(256, 380, 30),
            snow_flake(342, 350, 34)))
    return ic


@reg
def sleet():
    ic = Icon("sleet", "Sleet", PACK_W, ["wintry mix", "freezing rain"])
    cloud(ic, "c", 256, 232, 212)
    col = ic.lin("d", [("0%", "#9FD8FF", "0.3"), ("100%", "#4FA0FF")])
    ic.a('<g stroke="%s" stroke-width="15" stroke-linecap="round">'
         '<line x1="188" y1="322" x2="170" y2="368"/>'
         '<line x1="322" y1="322" x2="304" y2="368"/></g>' % col)
    ic.a('<g stroke="#FFFFFF" stroke-width="8" stroke-linecap="round">%s</g>'
         % snow_flake(256, 358, 32))
    return ic


@reg
def hail():
    ic = Icon("hail", "Hail", PACK_W, ["ice", "pellets"])
    cloud(ic, "c", 256, 230, 212)
    g = ic.rad("h", [("0%", "#FFFFFF"), ("70%", "#DCEEFF"), ("100%", "#94BEE8")],
               cx="34%", cy="30%")
    for (x, y, r) in ((186, 336, 22), (256, 372, 25), (326, 336, 22),
                      (222, 402, 16), (296, 402, 16)):
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (n(x), n(y), n(r), g))
    return ic


@reg
def fog():
    ic = Icon("fog", "Fog", PACK_W, ["mist", "haze", "low visibility"])
    cloud(ic, "c", 250, 206, 200, top="#EEF3FA", bot="#AFC0D6")
    # userSpaceOnUse: a horizontal line has a zero-height bbox, so an
    # objectBoundingBox gradient would collapse and render nothing.
    g = ic.lin("f", [("0%", "#DCE7F5", "0.25"), ("22%", "#E9F0F9"),
                     ("78%", "#B9C9DE"), ("100%", "#B9C9DE", "0.25")],
               x1="110", y1="0", x2="402", y2="0", user=True)
    for i, (x0, x1, y) in enumerate(((124, 388, 300), (150, 362, 348),
                                     (136, 376, 396))):
        ic.a('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" '
             'stroke-width="22" stroke-linecap="round" opacity="%s"/>'
             % (n(x0), n(y), n(x1), n(y), g, ["0.95", "0.8", "0.6"][i]))
    return ic


@reg
def wind():
    ic = Icon("wind", "Wind", PACK_W, ["breeze", "gust", "windy"])
    g = ic.lin("w", [("0%", "#BFE9FF", "0.15"), ("40%", "#7FD0FF"),
                     ("100%", "#3FA9FF")], x1="0%", x2="100%", y1="0%", y2="0%")
    ic.a('<g fill="none" stroke="%s" stroke-width="26" stroke-linecap="round">'
         '<path d="M 96 190 H 300 a 42 42 0 1 0 -42 -42"/>'
         '<path d="M 84 268 H 356 a 40 40 0 1 1 -40 40"/>'
         '<path d="M 120 346 H 258 a 34 34 0 1 0 -34 34"/></g>' % g)
    return ic


@reg
def tornado():
    ic = Icon("tornado", "Tornado", PACK_W, ["twister", "cyclone", "severe"])
    g = ic.lin("t", [("0%", "#E4ECF8"), ("45%", "#93A9C8"), ("100%", "#3E5070")])
    funnel = ("M 74 118 C 128 88 384 88 438 118 C 424 172 330 202 314 250 "
              "C 298 298 286 356 270 442 C 266 460 246 460 242 442 "
              "C 226 356 214 298 198 250 C 182 202 88 172 74 118 Z")
    ic.glow_shape('<path d="%s" fill="#8FA8CC"/>' % funnel, 22, 0.4)
    ic.a('<path d="%s" fill="%s"/>' % (funnel, g))
    cl = ic.clip("c", '<path d="%s"/>' % funnel)
    ic.a('<g clip-path="%s" fill="none" stroke="#FFFFFF" stroke-opacity="0.4" '
         'stroke-linecap="round">' % cl)
    for i, (y, rx, w) in enumerate(((124, 190, 13), (176, 140, 12),
                                    (228, 104, 11), (278, 76, 9),
                                    (330, 52, 8), (382, 32, 7))):
        ic.a('<path d="M %s %s a %s 26 0 0 0 %s 0" stroke-width="%s"/>'
             % (n(256 - rx), n(y), n(rx), n(rx * 2), n(w)))
    ic.a('</g>')
    ic.a('<g fill="#C3D3E8" opacity="0.55">'
         '<ellipse cx="118" cy="132" rx="34" ry="12"/>'
         '<ellipse cx="404" cy="146" rx="26" ry="10"/></g>')
    return ic


@reg
def rainbow():
    ic = Icon("rainbow", "Rainbow", PACK_W, ["colors", "after rain", "pride"])
    cols = ["#FF5F6D", "#FF9E4A", "#FFD84A", "#5FD98A", "#4FA8FF", "#8B6BFF"]
    for i, c in enumerate(cols):
        r = 186 - i * 26
        ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="24" '
             'stroke-linecap="round"/>' % (arc(256, 366, r, 180, 360), c))
    ic.glow_shape('<path d="%s" fill="none" stroke="#FFFFFF" stroke-width="16"/>'
                  % arc(256, 366, 186, 180, 360), 18, 0.35)
    cloud(ic, "l", 124, 356, 132, top="#FFFFFF", bot="#C6D5E8", shade=False)
    cloud(ic, "r", 392, 356, 132, top="#FFFFFF", bot="#C6D5E8", shade=False)
    return ic


# ============================================================= CELESTIAL =====
@reg
def sun_flare():
    ic = Icon("sun-flare", "Solar Flare", PACK_C, ["sun", "star", "energy"])
    g = ic.rad("s", [("0%", "#FFFFFF"), ("30%", "#FFE07A"), ("70%", "#FF9A2E"),
                     ("100%", "#E2461F")], cx="40%", cy="34%", r="72%")
    ic.glow_shape('<circle cx="256" cy="256" r="150" fill="#FF7A2E"/>', 34, 0.7)
    ic.a('<circle cx="256" cy="256" r="128" fill="%s"/>' % g)
    ic.a('<path d="M 256 128 a 128 128 0 0 1 0 256 a 96 96 0 0 0 0 -256 Z" '
         'fill="#FFD98A" opacity="0.30"/>')
    # coronal prominences: plasma loops with BOTH feet planted on the limb
    loops = ('<path d="M 337 159 C 396 116 448 176 380 234"/>'
             '<path d="M 147 319 C 84 330 62 268 132 234"/>')
    ic.glow_shape('<g fill="none" stroke="#FF7A1F" stroke-width="18" '
                  'stroke-linecap="round">%s</g>' % loops, 18, 0.95)
    ic.a('<g fill="none" stroke="#FFCB78" stroke-width="11" '
         'stroke-linecap="round">%s</g>' % loops)
    rnd = random.Random(4)
    for _ in range(10):
        a = rnd.uniform(0, 6.283)
        d = rnd.uniform(30, 108)
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#FFF3D6" opacity="0.28"/>'
             % (n(256 + d * math.cos(a)), n(256 + d * math.sin(a)),
                n(rnd.uniform(8, 22))))
    return ic


@reg
def ringed_planet():
    ic = Icon("ringed-planet", "Ringed Planet", PACK_C,
              ["saturn", "space", "planet"])
    g = ic.rad("p", [("0%", "#FFE2B0"), ("40%", "#F0A85C"), ("100%", "#9A4B2E")],
               cx="34%", cy="28%", r="80%")
    rg = ic.lin("r", [("0%", "#FFD9A0", "0.95"), ("50%", "#C98A55", "0.55"),
                      ("100%", "#FFE7C2", "0.9")], x1="0%", x2="100%",
                y1="0%", y2="0%")
    ic.glow_shape('<circle cx="256" cy="252" r="120" fill="#FFA85C"/>', 30, 0.45)
    ic.a('<g transform="rotate(-22 256 256)">'
         '<ellipse cx="256" cy="256" rx="212" ry="56" fill="none" stroke="%s" '
         'stroke-width="20" opacity="0.55"/></g>' % rg)
    ic.a('<circle cx="256" cy="252" r="112" fill="%s"/>' % g)
    ic.a('<g opacity="0.28" fill="#7A3A22">'
         '<ellipse cx="256" cy="212" rx="106" ry="12"/>'
         '<ellipse cx="256" cy="262" rx="110" ry="9"/>'
         '<ellipse cx="256" cy="300" rx="92" ry="8"/></g>')
    ic.a('<g transform="rotate(-22 256 256)">'
         '<path d="M 44 256 a 212 56 0 0 0 424 0" fill="none" stroke="%s" '
         'stroke-width="20" opacity="0.95"/></g>' % rg)
    return ic


@reg
def comet():
    ic = Icon("comet", "Comet", PACK_C, ["space", "tail", "meteor"])
    t = ic.lin("t", [("0%", "#3FE9FF", "0"), ("55%", "#5FC8FF", "0.65"),
                     ("100%", "#FFFFFF", "0.95")], x1="0%", y1="0%",
               x2="100%", y2="100%")
    ic.a('<path d="M 72 92 L 300 300 L 262 352 Z" fill="%s"/>' % t)
    ic.a('<path d="M 118 60 L 322 268 L 300 316 Z" fill="%s" opacity="0.55"/>' % t)
    g = ic.rad("h", [("0%", "#FFFFFF"), ("40%", "#B9F3FF"), ("100%", "#2FB6E8")],
               cx="36%", cy="32%")
    ic.glow_shape('<circle cx="330" cy="330" r="86" fill="#3FE9FF"/>', 28, 0.75)
    ic.a('<circle cx="330" cy="330" r="62" fill="%s"/>' % g)
    return ic


@reg
def shooting_star():
    ic = Icon("shooting-star", "Shooting Star", PACK_C,
              ["wish", "meteor", "night"])
    t = ic.lin("t", [("0%", "#FFD76E", "0"), ("100%", "#FFF3D6", "0.95")],
               x1="0%", y1="0%", x2="100%", y2="100%")
    for (x0, y0, w) in ((96, 118, 22), (150, 92, 13), (86, 190, 12)):
        ic.a('<path d="M %s %s L 318 316 L %s %s Z" fill="%s"/>'
             % (n(x0), n(y0), n(x0 + w), n(y0 + w), t))
    ic.glow_shape('<path d="%s" fill="#FFD76E"/>' % sparkle(340, 336, 110),
                  26, 0.8)
    ic.a('<path d="%s" fill="#FFF6D8"/>' % sparkle(340, 336, 96))
    ic.a('<path d="%s" fill="#FFFFFF"/>' % sparkle(340, 336, 48, 0.3))
    return ic


@reg
def constellation():
    ic = Icon("constellation", "Constellation", PACK_C,
              ["stars", "zodiac", "night sky"])
    nodes = [(120, 150), (206, 232), (300, 176), (386, 250), (334, 356),
             (208, 372), (140, 300)]
    lines = "".join('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                    % (n(nodes[i][0]), n(nodes[i][1]),
                       n(nodes[i + 1][0]), n(nodes[i + 1][1]))
                    for i in range(len(nodes) - 1))
    lines += '<line x1="206" y1="232" x2="334" y2="356"/>'
    ic.a('<g stroke="#7FA8FF" stroke-width="5" stroke-opacity="0.7" '
         'stroke-linecap="round">%s</g>' % lines)
    for i, (x, y) in enumerate(nodes):
        r = 20 if i in (1, 3) else 13
        ic.glow_shape('<circle cx="%s" cy="%s" r="%s" fill="#9FD4FF"/>'
                      % (n(x), n(y), n(r * 1.5)), 12, 0.8)
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>' % (n(x), n(y), n(r)))
    for (x, y, r) in ((432, 128, 7), (96, 400, 6), (420, 400, 5), (160, 96, 5)):
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#DDEBFF" opacity="0.75"/>'
             % (n(x), n(y), n(r)))
    return ic


@reg
def galaxy():
    ic = Icon("galaxy", "Galaxy", PACK_C, ["spiral", "space", "cosmos"])
    ic.glow_shape('<ellipse cx="256" cy="256" rx="180" ry="150" fill="#6C3AD8"/>',
                  40, 0.5)
    arm = ("M 256 256 C 344 238 412 292 400 358 C 388 428 300 456 216 428")
    ag = ic.lin("ag", [("0%", "#FFE9C8"), ("35%", "#FF7ACF"), ("72%", "#6C6CFF"),
                       ("100%", "#3B3B9E", "0")],
                x1="256", y1="256", x2="216", y2="428", user=True)
    for rot in (0, 180):
        ic.a('<g transform="rotate(%d 256 256)">' % rot)
        ic.glow_shape('<path d="%s" fill="none" stroke="#8F6CFF" '
                      'stroke-width="46" stroke-linecap="round"/>' % arm, 24, 0.55)
        ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="40" '
             'stroke-linecap="round"/>' % (arm, ag))
        ic.a('<path d="%s" fill="none" stroke="#FFE9F8" stroke-width="12" '
             'stroke-linecap="round" opacity="0.5"/>' % arm)
        ic.a('</g>')
    core = ic.rad("c", [("0%", "#FFFFFF"), ("26%", "#FFE9B0"),
                        ("58%", "#FFAE6E", "0.7"), ("100%", "#FF7ACF", "0")],
                  r="55%")
    ic.glow_shape('<ellipse cx="256" cy="256" rx="70" ry="62" fill="#FFD9A0"/>',
                  22, 0.9)
    ic.a('<ellipse cx="256" cy="256" rx="112" ry="100" fill="%s"/>' % core)
    rnd = random.Random(11)
    for _ in range(28):
        a = rnd.uniform(0, 6.283); d = rnd.uniform(70, 210)
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF" opacity="%s"/>'
             % (n(256 + d * math.cos(a)), n(256 + d * math.sin(a) * 0.86),
                n(rnd.uniform(2, 5)), n(rnd.uniform(.4, .95))))
    return ic


@reg
def aurora():
    ic = Icon("aurora", "Aurora", PACK_C, ["northern lights", "sky", "glow"])
    ic.a('<g fill="#FFFFFF">'
         '<circle cx="106" cy="112" r="5" opacity="0.85"/>'
         '<circle cx="418" cy="142" r="4" opacity="0.7"/>'
         '<circle cx="352" cy="74" r="6" opacity="0.9"/>'
         '<circle cx="152" cy="188" r="3" opacity="0.6"/>'
         '<circle cx="256" cy="62" r="4" opacity="0.75"/></g>')
    # curtains: narrow at the top, flaring and swaying toward the horizon
    bands = [("#5EEAD4", 108, 150, 10, 40, 0.90), ("#3FE9FF", 158, 194, 8, 32, 0.80),
             ("#6C6CFF", 212, 250, 12, 44, 0.88), ("#A66CFF", 268, 300, 8, 30, 0.75),
             ("#FF4FA3", 316, 358, 11, 38, 0.82), ("#FF8A5B", 366, 396, 7, 26, 0.62)]
    for i, (c, xt, xb, wt, wb, op) in enumerate(bands):
        g = ic.lin("a%d" % i, [("0%", c, "0"), ("22%", c, "0.9"),
                               ("72%", c, "0.8"), ("100%", c, "0")],
                   x1="0", y1="88", x2="0", y2="432", user=True)
        sway = 30 if i % 2 == 0 else -24
        d = ("M %s 92 C %s 200 %s 320 %s 428 L %s 428 C %s 320 %s 200 %s 92 Z"
             % (n(xt - wt), n(xt - wt + sway), n(xb - wb - sway * .5), n(xb - wb),
                n(xb + wb), n(xb + wb - sway * .5), n(xt + wt + sway), n(xt + wt)))
        ic.glow_shape('<path d="%s" fill="%s"/>' % (d, c), 26, op * 0.5)
        ic.a('<path d="%s" fill="%s" opacity="%s"/>' % (d, g, n(op)))
    ic.glow_shape('<ellipse cx="256" cy="424" rx="190" ry="16" fill="#5EEAD4"/>',
                  24, 0.5)
    return ic


@reg
def eclipse():
    ic = Icon("eclipse", "Eclipse", PACK_C, ["corona", "solar", "rare"])
    ic.glow_shape('<circle cx="256" cy="256" r="132" fill="#FFB74D"/>', 40, 0.9)
    ic.glow_shape('<circle cx="256" cy="256" r="120" fill="#FFFFFF"/>', 16, 0.9)
    ic.a('<circle cx="256" cy="256" r="118" fill="none" stroke="#FFE6A8" '
         'stroke-width="8" opacity="0.9"/>')
    g = ic.rad("d", [("0%", "#15192A"), ("100%", "#05070E")], cx="38%", cy="32%")
    ic.a('<circle cx="256" cy="256" r="112" fill="%s"/>' % g)
    ic.a('<circle cx="256" cy="256" r="112" fill="none" stroke="#FF9E4A" '
         'stroke-width="3" opacity="0.6"/>')
    return ic


@reg
def black_hole():
    ic = Icon("black-hole", "Black Hole", PACK_C, ["space", "gravity", "void"])
    d = ic.lin("d", [("0%", "#FFD76E"), ("45%", "#FF6B8A"), ("100%", "#6C6CFF")],
               x1="0%", x2="100%", y1="0%", y2="100%")
    ic.glow_shape('<ellipse cx="256" cy="256" rx="196" ry="62" fill="#A66CFF"/>',
                  34, 0.55)
    ic.a('<g transform="rotate(-18 256 256)">'
         '<ellipse cx="256" cy="256" rx="190" ry="58" fill="none" stroke="%s" '
         'stroke-width="26"/>'
         '<ellipse cx="256" cy="256" rx="150" ry="40" fill="none" stroke="%s" '
         'stroke-width="14" opacity="0.7"/></g>' % (d, d))
    ic.a('<circle cx="256" cy="256" r="92" fill="#05060C"/>')
    ic.a('<circle cx="256" cy="256" r="92" fill="none" stroke="#FFD76E" '
         'stroke-width="5" opacity="0.85"/>')
    ic.a('<g transform="rotate(-18 256 256)"><path d="M 66 256 a 190 58 0 0 0 '
         '380 0" fill="none" stroke="%s" stroke-width="26"/></g>' % d)
    return ic


@reg
def satellite():
    ic = Icon("satellite", "Satellite", PACK_C, ["orbit", "signal", "space"])
    p = ic.lin("p", [("0%", "#6FD8FF"), ("100%", "#2E6FD8")], x1="0%", x2="100%",
               y1="0%", y2="100%")
    b = ic.lin("b", [("0%", "#E8EEF8"), ("100%", "#9EAEC6")])
    ic.a('<g transform="rotate(-20 256 256)">')
    for dx in (-146, 92):
        ic.a('%s fill="%s"/>' % (rrect(256 + dx, 200, 126, 112, 10), p))
        ic.a('<g stroke="#0E2A52" stroke-width="4" opacity="0.55">'
             '<line x1="%s" y1="200" x2="%s" y2="312"/>'
             '<line x1="%s" y1="200" x2="%s" y2="312"/>'
             '<line x1="%s" y1="256" x2="%s" y2="256"/></g>'
             % (n(256 + dx + 42), n(256 + dx + 42), n(256 + dx + 84),
                n(256 + dx + 84), n(256 + dx), n(256 + dx + 126)))
    ic.a('<line x1="150" y1="256" x2="362" y2="256" stroke="#9EAEC6" '
         'stroke-width="12"/>')
    ic.a('%s fill="%s"/>' % (rrect(212, 208, 88, 96, 16), b))
    ic.a('<circle cx="256" cy="256" r="22" fill="#3FE9FF" opacity="0.9"/>')
    ic.a('</g>')
    ic.a('<g fill="none" stroke="#3FE9FF" stroke-width="9" stroke-linecap="round" '
         'opacity="0.85"><path d="M 356 372 a 46 46 0 0 1 -46 46"/>'
         '<path d="M 402 372 a 92 92 0 0 1 -92 92"/></g>')
    return ic


@reg
def rocket():
    ic = Icon("rocket", "Rocket", PACK_C, ["launch", "ship", "boost"])
    body = ic.lin("b", [("0%", "#FFFFFF"), ("55%", "#E4EBF6"), ("100%", "#A9B9CE")],
                  x1="0%", x2="100%", y1="0%", y2="0%")
    fin = ic.lin("f", [("0%", "#FF6B8A"), ("100%", "#D9304F")])
    fl = ic.lin("l", [("0%", "#FFF3D6"), ("45%", "#FFB74D"), ("100%", "#FF5F2E", "0")])
    ic.glow_shape('<ellipse cx="256" cy="410" rx="42" ry="72" fill="#FF9E4A"/>',
                  22, 0.8)
    ic.a('<path d="M 256 348 C 300 386 300 424 256 468 C 212 424 212 386 256 348 Z" '
         'fill="%s"/>' % fl)
    ic.a('<path d="M 196 300 L 148 366 L 196 350 Z" fill="%s"/>' % fin)
    ic.a('<path d="M 316 300 L 364 366 L 316 350 Z" fill="%s"/>' % fin)
    ic.a('<path d="M 256 44 C 316 106 322 200 322 286 L 322 348 L 190 348 '
         'L 190 286 C 190 200 196 106 256 44 Z" fill="%s"/>' % body)
    ic.a('<path d="M 256 44 C 286 76 302 122 310 172 L 202 172 C 210 122 '
         '226 76 256 44 Z" fill="%s"/>' % fin)
    ic.a('<circle cx="256" cy="228" r="40" fill="#1B2740"/>')
    ic.a('<circle cx="256" cy="228" r="30" fill="#3FE9FF" opacity="0.85"/>')
    ic.a('<circle cx="244" cy="216" r="10" fill="#FFFFFF" opacity="0.7"/>')
    return ic


@reg
def telescope():
    ic = Icon("telescope", "Telescope", PACK_C, ["stargazing", "observe"])
    tube = ic.lin("t", [("0%", "#DDE6F2"), ("100%", "#7C8DA8")])
    band = ic.lin("b", [("0%", "#6C6CFF"), ("100%", "#3B3BD8")])
    ic.a('<g transform="rotate(-32 256 256)">')
    ic.a('%s fill="%s"/>' % (rrect(128, 214, 268, 86, 43), tube))
    ic.a('%s fill="%s"/>' % (rrect(360, 200, 56, 114, 20), band))
    ic.a('%s fill="%s" opacity="0.8"/>' % (rrect(206, 214, 30, 86, 15), band))
    ic.a('</g>')
    ic.a('<path d="M 216 348 L 256 300 L 296 348 Z" fill="#5B6B85"/>')
    ic.a('<path d="M 168 452 L 256 330 L 344 452" fill="none" stroke="#5B6B85" '
         'stroke-width="22" stroke-linecap="round"/>')
    for (x, y, r) in ((404, 118, 16), (444, 186, 10), (356, 76, 9)):
        ic.a('<path d="%s" fill="#FFE9A8"/>' % sparkle(x, y, r))
    return ic


@reg
def meteor_shower():
    ic = Icon("meteor-shower", "Meteor Shower", PACK_C, ["perseids", "streaks"])
    for k, (x, y, L, w, c) in enumerate((
            (60, 62, 186, 26, "#A66CFF"), (184, 34, 232, 32, "#3FE9FF"),
            (318, 104, 158, 22, "#FF4FA3"), (112, 214, 196, 26, "#7FB8FF"),
            (286, 258, 148, 20, "#FFD76E"))):
        t = ic.lin("t%d" % k, [("0%", c, "0"), ("48%", c, "0.9"),
                               ("100%", "#FFFFFF", "1")],
                   x1=n(x), y1=n(y), x2=n(x + L), y2=n(y + L), user=True)
        tri = ('<path d="M %s %s L %s %s L %s %s Z"'
               % (n(x), n(y), n(x + L), n(y + L), n(x + w), n(y + w + 10)))
        ic.glow_shape(tri + ' fill="%s"/>' % c, 16, 0.95)
        ic.a(tri + ' fill="%s"/>' % t)
        ic.glow_shape('<circle cx="%s" cy="%s" r="%s" fill="%s"/>'
                      % (n(x + L), n(y + L), n(w * 1.2), c), 14, 1.0)
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#FFFFFF"/>'
             % (n(x + L), n(y + L), n(w * 0.5)))
    for (x, y, r) in ((104, 396, 5), (420, 380, 6), (60, 300, 4), (452, 208, 4)):
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#CFE2FF" opacity="0.8"/>'
             % (n(x), n(y), n(r)))
    return ic
