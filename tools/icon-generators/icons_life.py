#!/usr/bin/env python3
"""Time (10) + Nature (12) + Cozy (12)."""
import math, random
from iconlib import *

PACK_T = "time"
PACK_N = "nature"
PACK_Z = "cozy"
ICONS = []


def reg(fn):
    ICONS.append(fn)
    return fn


# ================================================================== TIME =====
def clock_face(ic, cx, cy, r, rim="#E7EDF7", rim2="#9EAFC6", face="#FFFFFF",
               face2="#DCE6F3"):
    g = ic.lin("rim", [("0%", rim), ("100%", rim2)])
    f = ic.rad("face", [("0%", face), ("100%", face2)], cx="38%", cy="32%", r="76%")
    ic.glow_shape('<circle cx="%s" cy="%s" r="%s" fill="#8FA8C8"/>'
                  % (n(cx), n(cy), n(r)), 20, 0.35)
    ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (n(cx), n(cy), n(r), g))
    ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>'
         % (n(cx), n(cy), n(r * 0.86), f))
    ticks = []
    for i in range(12):
        a = math.radians(i * 30 - 90)
        w = 0.80 if i % 3 == 0 else 0.84
        ticks.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke-width="%s"/>'
                     % (n(cx + r * w * math.cos(a)), n(cy + r * w * math.sin(a)),
                        n(cx + r * 0.70 * math.cos(a)), n(cy + r * 0.70 * math.sin(a)),
                        n(10 if i % 3 == 0 else 6)))
    ic.a('<g stroke="#7D8FA8" stroke-linecap="round">%s</g>' % "".join(ticks))


def hands(ic, cx, cy, r, hh, mm, color="#20293A", second="#FF4F6D"):
    ah = math.radians((hh % 12) * 30 + mm * 0.5 - 90)
    am = math.radians(mm * 6 - 90)
    ic.a('<g stroke-linecap="round">'
         '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="17"/>'
         '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="13"/>'
         '</g>'
         % (n(cx), n(cy), n(cx + r * .46 * math.cos(ah)), n(cy + r * .46 * math.sin(ah)),
            color,
            n(cx), n(cy), n(cx + r * .68 * math.cos(am)), n(cy + r * .68 * math.sin(am)),
            color))
    ic.a('<circle cx="%s" cy="%s" r="11" fill="%s"/>' % (n(cx), n(cy), second))


@reg
def clock():
    ic = Icon("clock", "Clock", PACK_T, ["time", "analog", "watch"])
    clock_face(ic, 256, 256, 190)
    hands(ic, 256, 256, 190, 10, 9)
    return ic


@reg
def alarm_clock():
    ic = Icon("alarm-clock", "Alarm Clock", PACK_T, ["wake", "morning", "bell"])
    bell = ic.lin("bl", [("0%", "#FF9E7A"), ("100%", "#E2523E")])
    ic.a('<g fill="%s">'
         '<path d="M 92 128 a 62 62 0 0 1 62 -62 a 62 62 0 0 0 -62 62 Z"/>'
         '<ellipse cx="126" cy="112" rx="56" ry="50" transform="rotate(-32 126 112)"/>'
         '<ellipse cx="386" cy="112" rx="56" ry="50" transform="rotate(32 386 112)"/>'
         '</g>' % bell)
    ic.a('<g stroke="%s" stroke-width="26" stroke-linecap="round">'
         '<line x1="128" y1="436" x2="94" y2="474"/>'
         '<line x1="384" y1="436" x2="418" y2="474"/></g>' % bell)
    clock_face(ic, 256, 268, 176)
    hands(ic, 256, 268, 176, 7, 5)
    return ic


@reg
def hourglass():
    ic = Icon("hourglass", "Hourglass", PACK_T, ["timer", "sand", "waiting"])
    glass = ic.lin("g", [("0%", "#DCEBFF", "0.55"), ("100%", "#8FB6E8", "0.45")])
    sand = ic.lin("s", [("0%", "#FFD76E"), ("100%", "#E29A2E")])
    frame = ic.lin("f", [("0%", "#C8A06A"), ("100%", "#8A5F35")])
    ic.a('<path d="M 148 92 L 364 92 L 268 256 L 364 420 L 148 420 L 244 256 Z" '
         'fill="%s"/>' % glass)
    ic.a('<path d="M 168 112 L 344 112 L 262 256 Z" fill="%s" opacity="0.35"/>' % sand)
    ic.a('<path d="M 190 400 L 322 400 L 256 300 Z" fill="%s"/>' % sand)
    ic.a('<path d="M 256 258 L 256 388" stroke="%s" stroke-width="9" '
         'stroke-linecap="round"/>' % sand)
    ic.a('<g fill="%s"><rect x="124" y="72" width="264" height="30" rx="15"/>'
         '<rect x="124" y="410" width="264" height="30" rx="15"/></g>' % frame)
    return ic


@reg
def stopwatch():
    ic = Icon("stopwatch", "Stopwatch", PACK_T, ["timer", "sport", "lap"])
    b = ic.lin("b", [("0%", "#8FA3BF"), ("100%", "#4B5C76")])
    ic.a('<g fill="%s"><rect x="212" y="42" width="88" height="42" rx="16"/>'
         '<rect x="380" y="96" width="72" height="34" rx="17" '
         'transform="rotate(42 416 113)"/></g>' % b)
    clock_face(ic, 256, 288, 178)
    ring = ic.lin("r", [("0%", "#3FE9FF"), ("100%", "#4C8DFF")])
    ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="20" '
         'stroke-linecap="round"/>' % (arc(256, 288, 152, -90, 130), ring))
    hands(ic, 256, 288, 178, 12, 22, second="#3FE9FF")
    return ic


@reg
def calendar():
    ic = Icon("calendar", "Calendar", PACK_T, ["date", "day", "schedule"])
    body = ic.lin("b", [("0%", "#FFFFFF"), ("100%", "#DCE6F3")])
    head = ic.lin("h", [("0%", "#FF6B8A"), ("100%", "#E23F63")])
    ic.a('<g filter="%s">' % ic.shadow("sh", 12, 14, "#1B2740", 0.28))
    ic.a('%s fill="%s"/>' % (rrect(80, 108, 352, 328, 40), body))
    ic.a('</g>')
    ic.a('<path d="M 80 148 a 40 40 0 0 1 40 -40 h 272 a 40 40 0 0 1 40 40 '
         'v 48 h -352 Z" fill="%s"/>' % head)
    ic.a('<g fill="#F4F7FC"><rect x="140" y="60" width="30" height="76" rx="15"/>'
         '<rect x="342" y="60" width="30" height="76" rx="15"/></g>')
    ic.a('<text x="256" y="374" font-family="ui-sans-serif,Segoe UI,Helvetica,'
         'Arial,sans-serif" font-size="150" font-weight="700" fill="#26304A" '
         'text-anchor="middle">14</text>')
    return ic


@reg
def sunrise():
    ic = Icon("sunrise", "Sunrise", PACK_T, ["dawn", "morning", "am"])
    g = ic.rad("s", [("0%", "#FFF3D6"), ("55%", "#FFC85C"), ("100%", "#FF8A3C")],
               cx="42%", cy="30%", r="80%")
    ic.glow_shape('<circle cx="256" cy="300" r="120" fill="#FFB74D"/>', 30, 0.7)
    ic.a('<path d="M 256 190 a 110 110 0 0 1 110 110 h -220 a 110 110 0 0 1 '
         '110 -110 Z" fill="%s"/>' % g)
    ic.a('<g stroke="#FFC85C" stroke-width="16" stroke-linecap="round">'
         '<line x1="256" y1="72" x2="256" y2="132"/>'
         '<line x1="126" y1="126" x2="168" y2="168"/>'
         '<line x1="386" y1="126" x2="344" y2="168"/></g>')
    ic.a('<line x1="88" y1="330" x2="424" y2="330" stroke="#5B6B85" '
         'stroke-width="18" stroke-linecap="round"/>')
    ic.a('<g stroke="#8FA3BF" stroke-width="14" stroke-linecap="round" '
         'opacity="0.8"><line x1="120" y1="392" x2="212" y2="392"/>'
         '<line x1="264" y1="392" x2="392" y2="392"/></g>')
    return ic


@reg
def sunset():
    ic = Icon("sunset", "Sunset", PACK_T, ["dusk", "evening", "pm"])
    g = ic.rad("s", [("0%", "#FFE0B0"), ("50%", "#FF8A5B"), ("100%", "#E2461F")],
               cx="42%", cy="30%", r="80%")
    ic.glow_shape('<circle cx="256" cy="300" r="124" fill="#FF7A4A"/>', 32, 0.75)
    ic.a('<path d="M 256 190 a 110 110 0 0 1 110 110 h -220 a 110 110 0 0 1 '
         '110 -110 Z" fill="%s"/>' % g)
    ic.a('<g stroke="#FF9E5B" stroke-width="16" stroke-linecap="round">'
         '<line x1="256" y1="132" x2="256" y2="72"/>'
         '<line x1="146" y1="98" x2="188" y2="140"/>'
         '<line x1="366" y1="98" x2="324" y2="140"/></g>')
    ic.a('<path d="M 256 156 l 34 -46 h -68 Z" fill="#FF9E5B"/>')
    ic.a('<line x1="88" y1="330" x2="424" y2="330" stroke="#5B6B85" '
         'stroke-width="18" stroke-linecap="round"/>')
    ic.a('<g stroke="#8FA3BF" stroke-width="14" stroke-linecap="round" '
         'opacity="0.75"><line x1="120" y1="392" x2="212" y2="392"/>'
         '<line x1="264" y1="392" x2="392" y2="392"/></g>')
    return ic


@reg
def progress_ring():
    ic = Icon("progress-ring", "Day Progress", PACK_T, ["ring", "percent", "goal"])
    tr = ic.lin("t", [("0%", "#3FE9FF"), ("50%", "#6C6CFF"), ("100%", "#FF4FA3")],
                x1="0%", y1="0%", x2="100%", y2="100%")
    ic.a('<circle cx="256" cy="256" r="150" fill="none" stroke="#2B3446" '
         'stroke-width="42" opacity="0.35"/>')
    ic.glow_shape('<path d="%s" fill="%s"/>' % (ring_seg(256, 256, 150, 42, -90, 152), tr),
                  20, 0.7)
    ic.a('<path d="%s" fill="%s"/>' % (ring_seg(256, 256, 150, 42, -90, 152), tr))
    ic.a('<circle cx="256" cy="106" r="21" fill="#3FE9FF"/>')
    ic.a('<text x="256" y="292" font-family="ui-sans-serif,Segoe UI,Helvetica,'
         'Arial,sans-serif" font-size="104" font-weight="700" fill="#E9EEF8" '
         'text-anchor="middle">67%</text>')
    return ic


@reg
def night_shift():
    ic = Icon("night-shift", "Night Mode", PACK_T, ["dark", "sleep", "dnd"])
    g = ic.lin("g", [("0%", "#BFD4FF"), ("100%", "#4C5CE0")], x1="0%", y1="0%",
               x2="100%", y2="100%")
    ic.glow_shape('<circle cx="238" cy="266" r="164" fill="#6C8CFF"/>', 32, 0.5)
    m = ic.mask("cm", '<rect width="512" height="512" fill="#000"/>'
                      '<circle cx="238" cy="266" r="158" fill="#fff"/>'
                      '<circle cx="150" cy="196" r="146" fill="#000"/>')
    ic.a('<g mask="%s"><circle cx="238" cy="266" r="158" fill="%s"/></g>'
         % (m, g))
    for (x, y, r) in ((392, 148, 20), (438, 240, 12), (346, 82, 11)):
        ic.a('<path d="%s" fill="#FFF3D6"/>' % sparkle(x, y, r))
    return ic


@reg
def countdown():
    ic = Icon("countdown", "Countdown", PACK_T, ["deadline", "timer", "urgent"])
    ic.a('<circle cx="256" cy="256" r="156" fill="none" stroke="#2B3446" '
         'stroke-width="36" opacity="0.4"/>')
    g = ic.lin("g", [("0%", "#FFD76E"), ("100%", "#FF5F4A")], x1="0%", x2="100%",
               y1="0%", y2="100%")
    ic.glow_shape('<path d="%s" fill="%s"/>' % (ring_seg(256, 256, 156, 36, -90, 62), g),
                  18, 0.75)
    ic.a('<path d="%s" fill="%s"/>' % (ring_seg(256, 256, 156, 36, -90, 62), g))
    ic.a('<text x="256" y="292" font-family="ui-sans-serif,Segoe UI,Helvetica,'
         'Arial,sans-serif" font-size="122" font-weight="700" fill="#FFE9B8" '
         'text-anchor="middle">3</text>')
    return ic


# ================================================================ NATURE =====
@reg
def leaf():
    ic = Icon("leaf", "Leaf", PACK_N, ["plant", "eco", "green"])
    g = ic.lin("g", [("0%", "#8FF0B4"), ("50%", "#3FBF7F"), ("100%", "#16714C")],
               x1="0%", y1="0%", x2="100%", y2="100%")
    ic.glow_shape('<path d="M 96 416 C 96 200 240 80 424 88 C 432 272 300 420 '
                  '96 416 Z" fill="#3FBF7F"/>', 22, 0.35)
    ic.a('<path d="M 96 416 C 96 200 240 80 424 88 C 432 272 300 420 96 416 Z" '
         'fill="%s"/>' % g)
    ic.a('<path d="M 120 400 C 220 300 320 200 412 100" fill="none" '
         'stroke="#E6FFF0" stroke-width="14" stroke-linecap="round" '
         'opacity="0.75"/>')
    ic.a('<g fill="none" stroke="#E6FFF0" stroke-width="8" stroke-linecap="round" '
         'opacity="0.5"><path d="M 200 320 q 40 -70 116 -84"/>'
         '<path d="M 268 252 q 24 -66 90 -92"/>'
         '<path d="M 160 366 q 22 -60 84 -84"/></g>')
    return ic


@reg
def maple_leaf():
    ic = Icon("maple-leaf", "Maple Leaf", PACK_N, ["autumn", "fall", "canada"])
    g = ic.lin("g", [("0%", "#FFB74D"), ("48%", "#F2622E"), ("100%", "#B32418")],
               x1="0%", y1="0%", x2="60%", y2="100%")
    # right-hand silhouette, mirrored — three big lobes, notches, then stem
    half = [(292, 158), (352, 118), (338, 202), (444, 176), (398, 246),
            (466, 292), (376, 302), (392, 362), (298, 320), (310, 448),
            (256, 448)]
    d = "M 256 44 " + "".join("L %s %s " % (n(x), n(y)) for x, y in half)
    d += "".join("L %s %s " % (n(512 - x), n(y))
                 for x, y in reversed(half[:-1])) + "Z"
    ic.glow_shape('<path d="%s" fill="#FF7A3C"/>' % d, 26, 0.35)
    ic.a('<path d="%s" fill="%s"/>' % (d, g))
    ic.a('<g stroke="#8A2C14" stroke-opacity="0.35" stroke-width="9" '
         'stroke-linecap="round" fill="none">'
         '<path d="M 256 452 L 256 150"/>'
         '<path d="M 256 250 L 176 190"/><path d="M 256 250 L 336 190"/>'
         '<path d="M 256 320 L 168 288"/><path d="M 256 320 L 344 288"/></g>')
    ic.a('<rect x="244" y="404" width="24" height="66" rx="12" fill="#8A2C14" '
         'opacity="0.85"/>')
    return ic


@reg
def snowflake():
    ic = Icon("snowflake", "Snowflake", PACK_N, ["winter", "cold", "ice"])
    g = ic.lin("g", [("0%", "#FFFFFF"), ("100%", "#7FC8FF")], x1="0%", y1="0%",
               x2="100%", y2="100%")
    o = []
    for i in range(6):
        a = math.radians(i * 60 - 90)
        x, y = 256 + 178 * math.cos(a), 256 + 178 * math.sin(a)
        o.append('<line x1="256" y1="256" x2="%s" y2="%s"/>' % (n(x), n(y)))
        for s in (0.42, 0.66, 0.88):
            bx, by = 256 + 178 * s * math.cos(a), 256 + 178 * s * math.sin(a)
            for d in (-40, 40):
                a2 = a + math.radians(d)
                L = 178 * 0.24 * (1.1 - s * 0.4)
                o.append('<line x1="%s" y1="%s" x2="%s" y2="%s"/>'
                         % (n(bx), n(by), n(bx + L * math.cos(a2)),
                            n(by + L * math.sin(a2))))
    sh = '<g stroke="%s" stroke-width="16" stroke-linecap="round">%s</g>'
    ic.glow_shape(sh % ("#8FD8FF", "".join(o)), 18, 0.8)
    ic.a(sh % (g, "".join(o)))
    ic.a('<circle cx="256" cy="256" r="22" fill="#FFFFFF"/>')
    return ic


@reg
def flower():
    ic = Icon("flower", "Flower", PACK_N, ["bloom", "spring", "petal"])
    pg = ic.rad("p", [("0%", "#FFF0F6"), ("60%", "#FF9EC4"), ("100%", "#E85B96")],
                cx="42%", cy="34%", r="78%")
    cg = ic.rad("c", [("0%", "#FFF3D6"), ("100%", "#F2A82E")], cx="38%", cy="34%")
    ic.glow_shape('<circle cx="256" cy="256" r="150" fill="#FF9EC4"/>', 24, 0.35)
    for i in range(6):
        ic.a('<g transform="rotate(%d 256 256)">'
             '<ellipse cx="256" cy="140" rx="66" ry="106" fill="%s"/></g>'
             % (i * 60, pg))
    ic.a('<circle cx="256" cy="256" r="62" fill="%s"/>' % cg)
    rnd = random.Random(5)
    for _ in range(14):
        a = rnd.uniform(0, 6.283); d = rnd.uniform(0, 44)
        ic.a('<circle cx="%s" cy="%s" r="4" fill="#C97F14" opacity="0.5"/>'
             % (n(256 + d * math.cos(a)), n(256 + d * math.sin(a))))
    return ic


@reg
def mountain():
    ic = Icon("mountain", "Mountain", PACK_N, ["peak", "hike", "outdoors"])
    back = ic.lin("b", [("0%", "#8FA8CC"), ("100%", "#4E6389")])
    front = ic.lin("f", [("0%", "#5C7BA8"), ("100%", "#26364F")])
    sky = ic.rad("s", [("0%", "#FFD76E"), ("100%", "#FFD76E", "0")], r="50%")
    ic.a('<circle cx="352" cy="140" r="120" fill="%s"/>' % sky)
    ic.a('<circle cx="352" cy="140" r="46" fill="#FFE9A8"/>')
    ic.a('<path d="M 44 400 L 190 168 L 296 400 Z" fill="%s"/>' % back)
    ic.a('<path d="M 190 168 L 236 240 L 190 268 L 148 240 Z" fill="#EAF2FF"/>')
    ic.a('<path d="M 196 412 L 340 196 L 476 412 Z" fill="%s"/>' % front)
    ic.a('<path d="M 340 196 L 386 268 L 340 296 L 296 268 Z" fill="#F4F9FF"/>')
    ic.a('<rect x="32" y="396" width="448" height="26" rx="13" fill="#1B2740"/>')
    return ic


@reg
def wave():
    ic = Icon("wave", "Wave", PACK_N, ["ocean", "sea", "surf"])
    g = ic.lin("g", [("0%", "#7FE6FF"), ("55%", "#2E9BE8"), ("100%", "#15487F")],
               x1="0%", y1="0%", x2="30%", y2="100%")
    ic.a('<path d="M 64 330 C 64 158 220 78 336 140 C 428 190 424 300 344 330 '
         'C 288 350 236 314 244 262 C 250 222 300 208 324 238 C 300 226 '
         '272 240 272 268 C 272 302 316 316 352 300 C 412 274 412 190 '
         '344 158 C 244 112 136 190 136 330 Z" fill="%s"/>' % g)
    ic.a('<path d="M 64 330 C 64 158 220 78 336 140" fill="none" '
         'stroke="#DFF7FF" stroke-width="16" stroke-linecap="round" '
         'opacity="0.8"/>')
    ic.a('<g stroke="#BFEEFF" stroke-width="16" stroke-linecap="round" '
         'opacity="0.9"><path d="M 72 396 q 46 -26 92 0 t 92 0 t 92 0 t 92 0" '
         'fill="none"/><path d="M 96 440 q 46 -26 92 0 t 92 0 t 92 0" '
         'fill="none" opacity="0.6"/></g>')
    return ic


@reg
def fire():
    ic = Icon("fire", "Fire", PACK_N, ["flame", "hot", "streak"])
    outer = ic.lin("o", [("0%", "#FFE07A"), ("40%", "#FF8A2E"), ("100%", "#E2241F")])
    inner = ic.lin("i", [("0%", "#FFFBEA"), ("60%", "#FFD76E"), ("100%", "#FF8A2E")])
    ic.glow_shape('<path d="M 256 48 C 340 150 388 196 388 292 a 132 132 0 0 1 '
                  '-264 0 C 124 210 176 180 208 120 C 226 176 250 190 256 48 Z" '
                  'fill="#FF6A1F"/>', 30, 0.75)
    ic.a('<path d="M 256 48 C 340 150 388 196 388 292 a 132 132 0 0 1 -264 0 '
         'C 124 210 176 180 208 120 C 226 176 250 190 256 48 Z" fill="%s"/>' % outer)
    ic.a('<path d="M 262 220 C 306 268 322 292 322 322 a 66 66 0 0 1 -132 0 '
         'C 190 288 222 268 262 220 Z" fill="%s"/>' % inner)
    return ic


@reg
def tree():
    ic = Icon("tree", "Tree", PACK_N, ["forest", "pine", "woods"])
    g = ic.lin("g", [("0%", "#6EE7A8"), ("55%", "#2E9B68"), ("100%", "#125A3E")])
    tr = ic.lin("t", [("0%", "#A9713F"), ("100%", "#6A4222")])
    ic.a('<rect x="230" y="330" width="52" height="118" rx="16" fill="%s"/>' % tr)
    for (y, w, h) in ((156, 96, 96), (238, 128, 104), (322, 158, 104)):
        ic.a('<path d="M 256 %s L %s %s L %s %s Z" fill="%s"/>'
             % (n(y - h), n(256 - w), n(y + 22), n(256 + w), n(y + 22), g))
    ic.a('<circle cx="196" cy="250" r="10" fill="#FFD76E" opacity="0.75"/>')
    ic.a('<circle cx="318" cy="330" r="9" fill="#FFD76E" opacity="0.6"/>')
    return ic


@reg
def cactus():
    ic = Icon("cactus", "Cactus", PACK_N, ["desert", "plant", "succulent"])
    g = ic.lin("g", [("0%", "#7FDCA0"), ("100%", "#1F7A52")], x1="0%", x2="100%",
               y1="0%", y2="0%")
    pot = ic.lin("p", [("0%", "#F0A464"), ("100%", "#B4552E")])
    ic.a('<path d="M 256 96 a 44 44 0 0 1 44 44 v 232 h -88 v -232 a 44 44 0 0 1 '
         '44 -44 Z" fill="%s"/>' % g)
    ic.a('<path d="M 212 200 h -34 a 40 40 0 0 0 -40 40 v 40 a 40 40 0 0 0 40 40 '
         'h 34 Z" fill="%s"/>' % g)
    ic.a('<path d="M 300 168 h 30 a 40 40 0 0 1 40 40 v 68 a 40 40 0 0 1 -40 40 '
         'h -30 Z" fill="%s"/>' % g)
    ic.a('<g stroke="#DDFBE9" stroke-width="7" stroke-linecap="round" '
         'opacity="0.55"><line x1="256" y1="132" x2="256" y2="340"/>'
         '<line x1="168" y1="228" x2="168" y2="288"/>'
         '<line x1="344" y1="200" x2="344" y2="264"/></g>')
    ic.a('<path d="M 158 372 h 196 l -22 88 a 24 24 0 0 1 -24 20 h -104 '
         'a 24 24 0 0 1 -24 -20 Z" fill="%s"/>' % pot)
    ic.a('<rect x="148" y="352" width="216" height="34" rx="17" fill="%s"/>' % pot)
    ic.a('<path d="%s" fill="#FF9EC4"/>' % sparkle(300, 150, 26))
    return ic


@reg
def mushroom():
    ic = Icon("mushroom", "Mushroom", PACK_N, ["fungi", "forest", "cottagecore"])
    cap = ic.rad("c", [("0%", "#FF9E8A"), ("55%", "#E8442E"), ("100%", "#A81E1E")],
                 cx="36%", cy="24%", r="86%")
    st = ic.lin("s", [("0%", "#FFF6E2"), ("100%", "#E0CBA8")], x1="0%", x2="100%",
                y1="0%", y2="0%")
    ic.a('<path d="M 202 260 h 108 v 132 a 54 54 0 0 1 -108 0 Z" fill="%s"/>' % st)
    ic.a('<path d="M 66 268 C 66 148 152 76 256 76 C 360 76 446 148 446 268 '
         'a 26 26 0 0 1 -26 26 h -328 a 26 26 0 0 1 -26 -26 Z" fill="%s"/>' % cap)
    for (x, y, r) in ((150, 194, 30), (256, 148, 24), (352, 200, 26),
                      (208, 250, 17), (322, 254, 15)):
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="#FFF3E2" opacity="0.92"/>'
             % (n(x), n(y), n(r)))
    ic.a('<path d="M 202 300 q 54 22 108 0" fill="none" stroke="#D3B98F" '
         'stroke-width="9" stroke-linecap="round" opacity="0.7"/>')
    return ic


@reg
def feather():
    ic = Icon("feather", "Feather", PACK_N, ["light", "bird", "quill"])
    g = ic.lin("g", [("0%", "#A9E8FF"), ("50%", "#6C8CFF"), ("100%", "#5B3A9E")],
               x1="0%", y1="0%", x2="100%", y2="100%")
    ic.a('<g transform="rotate(-18 256 256)">')
    ic.a('<path d="M 256 56 C 356 132 372 268 316 372 C 288 424 224 424 196 372 '
         'C 140 268 156 132 256 56 Z" fill="%s"/>' % g)
    ic.a('<line x1="256" y1="70" x2="256" y2="456" stroke="#F1F6FF" '
         'stroke-width="11" stroke-linecap="round" opacity="0.85"/>')
    o = []
    for i in range(9):
        y = 110 + i * 30
        w = 90 - abs(i - 3) * 9
        o.append('<line x1="256" y1="%s" x2="%s" y2="%s"/>' % (n(y), n(256 - w), n(y + 26)))
        o.append('<line x1="256" y1="%s" x2="%s" y2="%s"/>' % (n(y), n(256 + w), n(y + 26)))
    ic.a('<g stroke="#F1F6FF" stroke-width="5" stroke-linecap="round" '
         'opacity="0.45">%s</g>' % "".join(o))
    ic.a('</g>')
    return ic


@reg
def crystal():
    ic = Icon("crystal", "Crystal", PACK_N, ["gem", "quartz", "magic"])
    a = ic.lin("a", [("0%", "#E9D5FF"), ("100%", "#8B5CF6")])
    b = ic.lin("b", [("0%", "#C4B5FD"), ("100%", "#5B21B6")])
    c = ic.lin("c", [("0%", "#FBF5FF"), ("100%", "#A78BFA")])
    ic.glow_shape('<path d="M 256 46 L 396 236 L 256 466 L 116 236 Z" '
                  'fill="#A66CFF"/>', 30, 0.6)
    ic.a('<path d="M 256 46 L 396 236 L 256 466 Z" fill="%s"/>' % b)
    ic.a('<path d="M 256 46 L 116 236 L 256 466 Z" fill="%s"/>' % a)
    ic.a('<path d="M 256 46 L 316 236 L 256 466 L 196 236 Z" fill="%s" '
         'opacity="0.85"/>' % c)
    ic.a('<path d="M 116 236 L 396 236" stroke="#FFFFFF" stroke-width="5" '
         'opacity="0.4"/>')
    ic.a('<path d="%s" fill="#FFFFFF" opacity="0.9"/>' % sparkle(360, 120, 30))
    return ic


# ================================================================== COZY =====
@reg
def coffee():
    ic = Icon("coffee", "Coffee", PACK_Z, ["cup", "mug", "morning", "caffeine"])
    mug = ic.lin("m", [("0%", "#FFFFFF"), ("100%", "#D8E2EF")], x1="0%", x2="100%",
                 y1="0%", y2="0%")
    br = ic.lin("b", [("0%", "#8B5E3C"), ("100%", "#4A2C1A")])
    ic.a('<g stroke="#E9D8C4" stroke-width="16" stroke-linecap="round" '
         'opacity="0.85" fill="none">'
         '<path d="M 214 148 q 26 -30 0 -60 q -26 -30 0 -58"/>'
         '<path d="M 298 148 q 26 -30 0 -60 q -26 -30 0 -58"/></g>')
    ic.a('<path d="M 356 218 h 34 a 62 62 0 0 1 0 124 h -34" fill="none" '
         'stroke="#D8E2EF" stroke-width="30" stroke-linecap="round"/>')
    ic.a('<path d="M 116 196 h 248 v 148 a 84 84 0 0 1 -84 84 h -80 '
         'a 84 84 0 0 1 -84 -84 Z" fill="%s"/>' % mug)
    ic.a('<ellipse cx="240" cy="200" rx="124" ry="30" fill="%s"/>' % br)
    ic.a('<ellipse cx="240" cy="196" rx="104" ry="21" fill="#A56F45" '
         'opacity="0.65"/>')
    ic.a('<rect x="116" y="188" width="248" height="18" rx="9" fill="#EEF3FA"/>')
    return ic


@reg
def tea():
    ic = Icon("tea", "Tea", PACK_Z, ["cup", "herbal", "calm"])
    cup = ic.lin("c", [("0%", "#FFF8F0"), ("100%", "#E4D5C2")], x1="0%", x2="100%",
                 y1="0%", y2="0%")
    ic.a('<g stroke="#CBD9CB" stroke-width="14" stroke-linecap="round" '
         'opacity="0.8" fill="none">'
         '<path d="M 228 150 q 24 -28 0 -54"/>'
         '<path d="M 292 150 q 24 -28 0 -54"/></g>')
    ic.a('<path d="M 120 210 h 240 v 96 a 120 120 0 0 1 -240 0 Z" fill="%s"/>' % cup)
    ic.a('<ellipse cx="240" cy="212" rx="120" ry="28" fill="#C8E0B4"/>')
    ic.a('<ellipse cx="240" cy="210" rx="98" ry="19" fill="#8FBF6E" opacity="0.6"/>')
    ic.a('<path d="M 356 232 h 26 a 54 54 0 0 1 0 108 h -20" fill="none" '
         'stroke="#E4D5C2" stroke-width="26" stroke-linecap="round"/>')
    ic.a('<rect x="96" y="420" width="288" height="26" rx="13" fill="#D8C6B0"/>')
    ic.a('<path d="M 300 148 q 34 -22 56 6 q -42 26 -56 -6 Z" fill="#6EA84C"/>')
    return ic


@reg
def candle():
    ic = Icon("candle", "Candle", PACK_Z, ["light", "calm", "flame"])
    wax = ic.lin("w", [("0%", "#FFF6E6"), ("100%", "#E9D3B4")], x1="0%", x2="100%",
                 y1="0%", y2="0%")
    fl = ic.rad("f", [("0%", "#FFFBEA"), ("40%", "#FFD76E"), ("100%", "#FF8A2E")],
                cy="62%", r="70%")
    ic.glow_shape('<ellipse cx="256" cy="150" rx="80" ry="110" fill="#FFB74D"/>',
                  34, 0.75)
    ic.a('<path d="M 256 62 C 300 122 314 152 314 182 a 58 58 0 0 1 -116 0 '
         'C 198 152 212 122 256 62 Z" fill="%s"/>' % fl)
    ic.a('<path d="M 256 136 C 274 166 280 178 280 192 a 24 24 0 0 1 -48 0 '
         'C 232 178 238 166 256 136 Z" fill="#FFFDF4" opacity="0.85"/>')
    ic.a('<line x1="256" y1="238" x2="256" y2="258" stroke="#3A2C1E" '
         'stroke-width="9" stroke-linecap="round"/>')
    ic.a('<path d="M 170 258 h 172 v 172 a 26 26 0 0 1 -26 26 h -120 '
         'a 26 26 0 0 1 -26 -26 Z" fill="%s"/>' % wax)
    ic.a('<ellipse cx="256" cy="258" rx="86" ry="22" fill="#FFFBF0"/>')
    ic.a('<ellipse cx="256" cy="260" rx="60" ry="13" fill="#E9D3B4" opacity="0.8"/>')
    return ic


@reg
def books():
    ic = Icon("books", "Books", PACK_Z, ["read", "library", "stack"])
    cols = [("#FF6B8A", "#D9304F"), ("#4C8DFF", "#1E4FD8"), ("#FFB74D", "#E2822E"),
            ("#6EE7A8", "#2E9B68")]
    y = 400
    for i, (a, b) in enumerate(cols):
        g = ic.lin("b%d" % i, [("0%", a), ("100%", b)], x1="0%", x2="100%",
                   y1="0%", y2="0%")
        w = 300 - i * 14
        h = 62 - i * 3
        x = 256 - w / 2 + (i % 2) * 12 - 6
        ic.a('%s fill="%s"/>' % (rrect(x, y - h, w, h, 14), g))
        ic.a('<rect x="%s" y="%s" width="18" height="%s" fill="#FFFFFF" '
             'opacity="0.30"/>' % (n(x + 22), n(y - h), n(h)))
        y -= h + 8
    ic.a('<path d="%s" fill="#FFE9A8"/>' % sparkle(392, 132, 26))
    return ic


@reg
def vinyl():
    ic = Icon("vinyl", "Vinyl Record", PACK_Z, ["music", "record", "retro"])
    d = ic.rad("d", [("0%", "#3A4152"), ("100%", "#0D1119")], cx="36%", cy="30%",
               r="80%")
    lab = ic.rad("l", [("0%", "#FFB74D"), ("100%", "#E2523E")], cx="38%", cy="32%")
    ic.glow_shape('<circle cx="256" cy="256" r="190" fill="#6C6CFF"/>', 24, 0.28)
    ic.a('<circle cx="256" cy="256" r="190" fill="%s"/>' % d)
    for r in range(70, 186, 16):
        ic.a('<circle cx="256" cy="256" r="%d" fill="none" stroke="#7F8CA6" '
             'stroke-width="2" opacity="0.28"/>' % r)
    ic.a('<path d="M 256 66 a 190 190 0 0 1 134 56 L 256 256 Z" fill="#FFFFFF" '
         'opacity="0.07"/>')
    ic.a('<circle cx="256" cy="256" r="62" fill="%s"/>' % lab)
    ic.a('<circle cx="256" cy="256" r="13" fill="#161B26"/>')
    return ic


@reg
def cassette():
    ic = Icon("cassette", "Cassette", PACK_Z, ["mixtape", "retro", "music"])
    shell = ic.lin("s", [("0%", "#41506B"), ("100%", "#1B2334")])
    ic.a('<g filter="%s">' % ic.shadow("sh", 12, 14, "#05070E", 0.4))
    ic.a('%s fill="%s"/>' % (rrect(52, 120, 408, 272, 34), shell))
    ic.a('</g>')
    ic.a('%s fill="#0D121C"/>' % rrect(92, 158, 328, 118, 18))
    lg = ic.lin("l", [("0%", "#FF4FA3"), ("50%", "#A66CFF"), ("100%", "#3FE9FF")],
                x1="0%", x2="100%", y1="0%", y2="0%")
    ic.a('%s fill="%s"/>' % (rrect(108, 174, 296, 20, 10), lg))
    ic.a('%s fill="#2A3346"/>' % rrect(108, 210, 296, 50, 12))
    ic.a('%s fill="#111726"/>' % rrect(112, 300, 288, 62, 16))
    for x in (186, 326):
        ic.a('<circle cx="%s" cy="331" r="30" fill="#E6ECF7"/>' % n(x))
        ic.a('<circle cx="%s" cy="331" r="14" fill="#1B2334"/>' % n(x))
        for i in range(6):
            a = math.radians(i * 60)
            ic.a('<circle cx="%s" cy="%s" r="4" fill="#1B2334"/>'
                 % (n(x + 21 * math.cos(a)), n(331 + 21 * math.sin(a))))
    ic.a('<rect x="216" y="316" width="80" height="30" fill="#4A3A2E"/>')
    return ic


@reg
def headphones():
    ic = Icon("headphones", "Headphones", PACK_Z, ["music", "audio", "listen"])
    band = ic.lin("b", [("0%", "#8FA3BF"), ("100%", "#3E4C64")])
    cup = ic.lin("c", [("0%", "#FF6B8A"), ("100%", "#B32752")])
    ic.a('<path d="M 108 320 v -52 a 148 148 0 0 1 296 0 v 52" fill="none" '
         'stroke="%s" stroke-width="42" stroke-linecap="round"/>' % band)
    for x in (108, 404):
        ic.a('%s fill="%s"/>' % (rrect(x - 46, 286, 92, 152, 44), cup))
        ic.a('%s fill="#FFFFFF" opacity="0.22"/>' % rrect(x - 30, 306, 60, 52, 26))
    ic.a('<g stroke="#3FE9FF" stroke-width="11" stroke-linecap="round" '
         'opacity="0.9" fill="none"><path d="M 200 196 q 56 -34 112 0"/></g>')
    return ic


@reg
def desk_lamp():
    ic = Icon("desk-lamp", "Desk Lamp", PACK_Z, ["light", "study", "work"])
    m = ic.lin("m", [("0%", "#7FF0BC"), ("100%", "#177A50")])
    beam = ic.lin("bm", [("0%", "#FFE9A8", "0.55"), ("100%", "#FFE9A8", "0")],
                  x1="0", y1="250", x2="0", y2="470", user=True)
    ic.a('<path d="M 272 254 L 392 254 L 466 468 L 198 468 Z" fill="%s"/>' % beam)
    # base + post + elbow
    ic.a('<ellipse cx="180" cy="440" rx="98" ry="22" fill="#3E4C64"/>')
    ic.a('%s fill="#4E5F7C"/>' % rrect(102, 416, 156, 26, 13))
    ic.a('<path d="M 180 420 L 180 214 Q 180 156 240 156 L 302 156" '
         'fill="none" stroke="#5B6B85" stroke-width="22" '
         'stroke-linecap="round"/>')
    ic.a('<circle cx="180" cy="214" r="16" fill="#8FA3BF"/>')
    # shade
    ic.a('<path d="M 300 148 h 62 l 68 108 h -198 Z" fill="%s"/>' % m)
    ic.a('<ellipse cx="331" cy="256" rx="99" ry="18" fill="#FFF3D6"/>')
    ic.glow_shape('<ellipse cx="331" cy="262" rx="72" ry="26" fill="#FFD76E"/>',
                  26, 0.85)
    ic.a('<ellipse cx="331" cy="262" rx="44" ry="14" fill="#FFF8E2"/>')
    return ic


@reg
def potted_plant():
    ic = Icon("potted-plant", "Potted Plant", PACK_Z, ["monstera", "home", "green"])
    g = ic.lin("g", [("0%", "#6EE7A8"), ("100%", "#1F7A52")])
    pot = ic.lin("p", [("0%", "#E9A06A"), ("100%", "#A85433")])
    for (rot, sx) in ((-30, 1), (0, 1), (30, 1)):
        ic.a('<g transform="rotate(%d 256 320)">'
             '<path d="M 256 320 C 200 250 206 152 256 96 C 306 152 312 250 '
             '256 320 Z" fill="%s"/>'
             '<path d="M 256 300 L 256 120" stroke="#DFFBEC" stroke-width="7" '
             'stroke-linecap="round" opacity="0.6"/></g>' % (rot, g))
    ic.a('<path d="M 150 336 h 212 l -20 100 a 28 28 0 0 1 -28 22 h -116 '
         'a 28 28 0 0 1 -28 -22 Z" fill="%s"/>' % pot)
    ic.a('%s fill="#F0B27E"/>' % rrect(138, 312, 236, 38, 19))
    return ic


@reg
def yarn():
    ic = Icon("yarn", "Yarn", PACK_Z, ["knit", "craft", "hobby"])
    g = ic.rad("g", [("0%", "#FFB3CE"), ("60%", "#F2678F"), ("100%", "#B32752")],
               cx="36%", cy="30%", r="80%")
    ic.glow_shape('<circle cx="248" cy="272" r="156" fill="#FF6B8A"/>', 24, 0.3)
    cl = ic.clip("c", '<circle cx="248" cy="272" r="152"/>')
    ic.a('<circle cx="248" cy="272" r="152" fill="%s"/>' % g)
    ic.a('<g clip-path="%s" fill="none" stroke="#FFD9E6" stroke-width="9" '
         'opacity="0.55">' % cl)
    for k in range(-3, 4):
        ic.a('<ellipse cx="248" cy="272" rx="150" ry="60" '
             'transform="rotate(%d 248 272)"/>' % (k * 26))
    ic.a('</g>')
    ic.a('<path d="M 372 190 C 440 168 466 118 452 76" fill="none" '
         'stroke="#F2678F" stroke-width="14" stroke-linecap="round"/>')
    ic.a('<g stroke="#8FA3BF" stroke-width="12" stroke-linecap="round">'
         '<line x1="120" y1="120" x2="330" y2="330"/>'
         '<line x1="164" y1="104" x2="374" y2="314"/></g>')
    return ic


@reg
def campfire():
    ic = Icon("campfire", "Campfire", PACK_Z, ["camp", "warm", "night"])
    outer = ic.lin("o", [("0%", "#FFD76E"), ("45%", "#FF8A2E"), ("100%", "#D9291F")])
    inner = ic.lin("i", [("0%", "#FFFBEA"), ("100%", "#FFB74D")])
    wood = ic.lin("w", [("0%", "#A9713F"), ("100%", "#5E3A1E")])
    ic.glow_shape('<ellipse cx="256" cy="246" rx="120" ry="150" fill="#FF8A2E"/>',
                  34, 0.7)
    ic.a('<path d="M 256 62 C 330 156 366 200 366 268 a 110 110 0 0 1 -220 0 '
         'C 146 208 186 190 214 132 C 228 180 248 186 256 62 Z" fill="%s"/>' % outer)
    ic.a('<path d="M 262 216 C 298 258 310 278 310 300 a 54 54 0 0 1 -108 0 '
         'C 202 274 230 254 262 216 Z" fill="%s"/>' % inner)
    ic.a('<g stroke="%s" stroke-width="30" stroke-linecap="round">'
         '<line x1="130" y1="416" x2="382" y2="368"/>'
         '<line x1="130" y1="368" x2="382" y2="416"/></g>' % wood)
    return ic


@reg
def cocoa():
    ic = Icon("cocoa", "Hot Cocoa", PACK_Z, ["chocolate", "winter", "sweet"])
    mug = ic.lin("m", [("0%", "#FF8FA8"), ("100%", "#C2415F")], x1="0%", x2="100%",
                 y1="0%", y2="0%")
    ic.a('<g stroke="#E9D8C4" stroke-width="15" stroke-linecap="round" '
         'opacity="0.8" fill="none">'
         '<path d="M 216 142 q 26 -30 0 -58"/><path d="M 292 142 q 26 -30 0 -58"/></g>')
    ic.a('<path d="M 352 226 h 30 a 58 58 0 0 1 0 116 h -30" fill="none" '
         'stroke="#C2415F" stroke-width="28" stroke-linecap="round"/>')
    ic.a('<path d="M 116 200 h 240 v 154 a 82 82 0 0 1 -82 82 h -76 '
         'a 82 82 0 0 1 -82 -82 Z" fill="%s"/>' % mug)
    ic.a('<ellipse cx="236" cy="204" rx="120" ry="28" fill="#6A3B22"/>')
    for (x, y, r) in ((196, 198, 20), (250, 190, 24), (296, 204, 17)):
        ic.a('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#FFF8EE"/>'
             % (n(x), n(y), n(r), n(r * 0.72)))
    ic.a('<rect x="116" y="192" width="240" height="16" rx="8" fill="#FFAFC2"/>')
    return ic
