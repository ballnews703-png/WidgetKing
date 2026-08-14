#!/usr/bin/env python3
"""System (12) + Abstract (10) + Retro (10)."""
import math, random
from iconlib import *

PACK_S = "system"
PACK_A = "abstract"
PACK_R = "retro"
ICONS = []


def reg(fn):
    ICONS.append(fn)
    return fn


# ================================================================ SYSTEM =====
def battery_shell(ic):
    sh = ic.lin("sh", [("0%", "#8FA3BF"), ("100%", "#46566F")])
    ic.a('%s fill="none" stroke="%s" stroke-width="22"/>'
         % (rrect(56, 168, 356, 176, 48), sh))
    ic.a('%s fill="%s"/>' % (rrect(424, 224, 34, 64, 17), sh))


def battery_fill(ic, frac, colors):
    g = ic.lin("f", [("0%", colors[0]), ("100%", colors[1])], x1="0%", x2="100%",
               y1="0%", y2="0%")
    w = 300 * frac
    ic.glow_shape('%s fill="%s"/>' % (rrect(84, 196, w, 120, 26), colors[0]),
                  16, 0.55)
    ic.a('%s fill="%s"/>' % (rrect(84, 196, w, 120, 26), g))


@reg
def battery_full():
    ic = Icon("battery-full", "Battery Full", PACK_S, ["charge", "power", "100"])
    battery_shell(ic)
    battery_fill(ic, 1.0, ("#6EE7A8", "#2E9B68"))
    return ic


@reg
def battery_half():
    ic = Icon("battery-half", "Battery Half", PACK_S, ["charge", "power", "50"])
    battery_shell(ic)
    battery_fill(ic, 0.5, ("#FFD76E", "#E2822E"))
    return ic


@reg
def battery_low():
    ic = Icon("battery-low", "Battery Low", PACK_S, ["charge", "power", "empty"])
    battery_shell(ic)
    battery_fill(ic, 0.18, ("#FF8A7A", "#D9291F"))
    return ic


@reg
def battery_charging():
    ic = Icon("battery-charging", "Charging", PACK_S, ["power", "plug", "bolt"])
    battery_shell(ic)
    battery_fill(ic, 0.72, ("#3FE9FF", "#2E6FD8"))
    ic.glow_shape(poly(bolt(236, 256, 120, 150)) + ' fill="#FFD76E"/>', 18, 0.9)
    ic.a(poly(bolt(236, 256, 110, 140)) + ' fill="#FFF3D6"/>')
    return ic


@reg
def wifi():
    ic = Icon("wifi", "Wi-Fi", PACK_S, ["signal", "network", "connect"])
    g = ic.lin("g", [("0%", "#3FE9FF"), ("100%", "#2E6FD8")])
    for i, r in enumerate((84, 152, 220)):
        op = ["1", "0.85", "0.65"][i]
        ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="34" '
             'stroke-linecap="round" opacity="%s"/>'
             % (arc(256, 372, r, 218, 322), g, op))
    ic.glow_shape('<circle cx="256" cy="372" r="30" fill="#3FE9FF"/>', 16, 0.8)
    ic.a('<circle cx="256" cy="372" r="28" fill="#EAFBFF"/>')
    return ic


@reg
def signal_bars():
    ic = Icon("signal", "Signal", PACK_S, ["cell", "bars", "reception"])
    g = ic.lin("g", [("0%", "#6EE7A8"), ("100%", "#2E9B68")])
    for i in range(4):
        h = 76 + i * 74
        x = 74 + i * 98
        fill = g if i < 3 else "#39445C"
        ic.a('%s fill="%s"/>' % (rrect(x, 412 - h, 68, h, 22), fill))
    return ic


@reg
def bluetooth():
    ic = Icon("bluetooth", "Bluetooth", PACK_S, ["pair", "wireless", "device"])
    g = ic.lin("g", [("0%", "#7FD0FF"), ("100%", "#2E6FD8")])
    ic.glow_shape('<path d="M 256 60 L 366 158 L 256 256 L 256 60 M 256 256 '
                  'L 366 354 L 256 452 L 256 256 M 146 158 L 366 354 '
                  'M 146 354 L 366 158" fill="none" stroke="#4C8DFF" '
                  'stroke-width="40" stroke-linejoin="round" '
                  'stroke-linecap="round"/>', 22, 0.6)
    ic.a('<path d="M 256 60 L 366 158 L 256 256 L 256 60 M 256 256 L 366 354 '
         'L 256 452 L 256 256 M 146 158 L 366 354 M 146 354 L 366 158" '
         'fill="none" stroke="%s" stroke-width="32" stroke-linejoin="round" '
         'stroke-linecap="round"/>' % g)
    return ic


@reg
def sync():
    ic = Icon("sync", "Sync", PACK_S, ["refresh", "reload", "update"])
    g = ic.lin("g", [("0%", "#A66CFF"), ("100%", "#3FE9FF")], x1="0", y1="60",
               x2="512", y2="452", user=True)
    R = 146
    body = []
    for rot in (0, 180):
        seg = ('<g transform="rotate(%d 256 256)">'
               '<path d="%s" fill="none" stroke="%%s" stroke-width="%%s" '
               'stroke-linecap="butt"/>%%s</g>'
               % (rot, arc(256, 256, R, -66, 106)))
        head = poly(arrow_head(256, 256, R, 106, 44, 1)) + ' fill="%s"/>'
        body.append((seg, head))
    for seg, head in body:
        ic.glow_shape(seg % ("#6C6CFF", "38", head % "#6C6CFF"), 22, 0.5)
    for seg, head in body:
        ic.a(seg % (g, "34", head % g))
    return ic


@reg
def cloud_sync():
    ic = Icon("cloud-sync", "Cloud", PACK_S, ["backup", "storage", "upload"])
    cloud(ic, "c", 256, 240, 250, top="#FFFFFF", bot="#A9C4E8")
    g = ic.lin("g", [("0%", "#3FE9FF"), ("100%", "#2E6FD8")])
    ic.glow_shape('<path d="M 256 300 L 256 448 M 256 300 L 200 358 M 256 300 '
                  'L 312 358" fill="none" stroke="#3FE9FF" stroke-width="34" '
                  'stroke-linecap="round" stroke-linejoin="round"/>', 18, 0.7)
    ic.a('<path d="M 256 300 L 256 448 M 256 300 L 200 358 M 256 300 L 312 358" '
         'fill="none" stroke="%s" stroke-width="28" stroke-linecap="round" '
         'stroke-linejoin="round"/>' % g)
    return ic


@reg
def lock():
    ic = Icon("lock", "Lock", PACK_S, ["secure", "private", "password"])
    b = ic.lin("b", [("0%", "#FFD76E"), ("100%", "#E2822E")])
    ic.a('<path d="M 160 226 v -46 a 96 96 0 0 1 192 0 v 46" fill="none" '
         'stroke="#8FA3BF" stroke-width="38" stroke-linecap="round"/>')
    ic.a('<g filter="%s">' % ic.shadow("sh", 10, 12, "#1B2740", 0.3))
    ic.a('%s fill="%s"/>' % (rrect(96, 220, 320, 234, 48), b))
    ic.a('</g>')
    ic.a('<circle cx="256" cy="318" r="34" fill="#7A4A12"/>')
    ic.a('%s fill="#7A4A12"/>' % rrect(240, 330, 32, 74, 16))
    return ic


@reg
def bell():
    ic = Icon("bell", "Notification", PACK_S, ["alert", "ring", "reminder"])
    g = ic.lin("g", [("0%", "#FFE9A8"), ("100%", "#F2A02E")])
    ic.a('<path d="M 256 58 a 34 34 0 0 1 34 34 v 10 h -68 v -10 a 34 34 0 0 1 '
         '34 -34 Z" fill="%s"/>' % g)
    ic.a('<path d="M 116 348 c 40 -26 34 -74 34 -132 a 106 106 0 0 1 212 0 '
         'c 0 58 -6 106 34 132 Z" fill="%s"/>' % g)
    ic.a('<path d="M 206 372 a 50 50 0 0 0 100 0 Z" fill="%s"/>' % g)
    ic.glow_shape('<circle cx="386" cy="132" r="52" fill="#FF4F6D"/>', 18, 0.8)
    ic.a('<circle cx="386" cy="132" r="44" fill="#FF4F6D"/>')
    ic.a('<circle cx="386" cy="132" r="44" fill="none" stroke="#FFFFFF" '
         'stroke-width="8" opacity="0.6"/>')
    return ic


@reg
def activity_rings():
    ic = Icon("activity-rings", "Activity", PACK_S, ["fitness", "health", "goals"])
    specs = [(176, "#FF2F6E", "#FF7A4A", 300), (128, "#B6FF3C", "#3FE9FF", 250),
             (80, "#3FE9FF", "#6C6CFF", 200)]
    for i, (r, c1, c2, deg) in enumerate(specs):
        g = ic.lin("g%d" % i, [("0%", c1), ("100%", c2)], x1="0%", x2="100%",
                   y1="0%", y2="100%")
        ic.a('<circle cx="256" cy="256" r="%s" fill="none" stroke="%s" '
             'stroke-width="38" opacity="0.22"/>' % (n(r), c1))
        ic.glow_shape('<path d="%s" fill="%s"/>'
                      % (ring_seg(256, 256, r, 38, -90, -90 + deg), g), 14, 0.55)
        ic.a('<path d="%s" fill="%s"/>'
             % (ring_seg(256, 256, r, 38, -90, -90 + deg), g))
    return ic


@reg
def heart_pulse():
    ic = Icon("heart-pulse", "Heart Rate", PACK_S, ["health", "bpm", "pulse"])
    g = ic.lin("g", [("0%", "#FF7A9E"), ("100%", "#D31F52")], x1="0%", y1="0%",
               x2="100%", y2="100%")
    hp = ("M 256 434 C 120 340 62 268 62 190 a 108 108 0 0 1 194 -66 "
          "a 108 108 0 0 1 194 66 c 0 78 -58 150 -194 244 Z")
    ic.glow_shape('<path d="%s" fill="#FF4F6D"/>' % hp, 26, 0.55)
    ic.a('<path d="%s" fill="%s"/>' % (hp, g))
    ic.a('<path d="M 96 230 h 78 l 34 -74 l 44 148 l 40 -100 l 26 26 h 96" '
         'fill="none" stroke="#FFFFFF" stroke-width="20" stroke-linecap="round" '
         'stroke-linejoin="round"/>')
    return ic


# ============================================================== ABSTRACT =====
@reg
def orb_dawn():
    ic = Icon("orb-dawn", "Dawn Orb", PACK_A, ["gradient", "sphere", "warm"])
    g = ic.rad("g", [("0%", "#FFF3D6"), ("38%", "#FFB74D"), ("74%", "#FF5F8A"),
                     ("100%", "#8B3AA8")], cx="34%", cy="28%", r="86%")
    ic.glow_shape('<circle cx="256" cy="256" r="182" fill="#FF7A6E"/>', 34, 0.45)
    ic.a('<circle cx="256" cy="256" r="176" fill="%s"/>' % g)
    ic.a('<ellipse cx="196" cy="180" rx="66" ry="42" fill="#FFFFFF" '
         'opacity="0.30" transform="rotate(-28 196 180)"/>')
    ic.texture(ic.clip("c", '<circle cx="256" cy="256" r="176"/>'), 0.10, seed=3)
    return ic


@reg
def orb_deep():
    ic = Icon("orb-deep", "Deep Orb", PACK_A, ["gradient", "sphere", "cool"])
    g = ic.rad("g", [("0%", "#BFF6FF"), ("34%", "#3FE9FF"), ("70%", "#3B5BE0"),
                     ("100%", "#1B1E6E")], cx="34%", cy="28%", r="86%")
    ic.glow_shape('<circle cx="256" cy="256" r="182" fill="#3FE9FF"/>', 34, 0.5)
    ic.a('<circle cx="256" cy="256" r="176" fill="%s"/>' % g)
    ic.a('<ellipse cx="196" cy="180" rx="66" ry="42" fill="#FFFFFF" '
         'opacity="0.32" transform="rotate(-28 196 180)"/>')
    ic.texture(ic.clip("c", '<circle cx="256" cy="256" r="176"/>'), 0.10, seed=9)
    return ic


@reg
def glass_orb():
    ic = Icon("glass-orb", "Glass Orb", PACK_A, ["glassmorphism", "bubble"])
    g = ic.rad("g", [("0%", "#FFFFFF", "0.85"), ("55%", "#A9D8FF", "0.35"),
                     ("100%", "#5B6BE8", "0.55")], cx="34%", cy="26%", r="90%")
    rim = ic.lin("r", [("0%", "#FFFFFF", "0.95"), ("50%", "#FFFFFF", "0.15"),
                       ("100%", "#FFFFFF", "0.7")], x1="0%", y1="0%",
                 x2="100%", y2="100%")
    ic.glow_shape('<circle cx="256" cy="256" r="176" fill="#8FB6FF"/>', 30, 0.4)
    # colour refracting through the glass
    cl = ic.clip("c", '<circle cx="256" cy="256" r="176"/>')
    ic.a('<g clip-path="%s">' % cl)
    for (cx, cy, r, c) in ((170, 348, 190, "#FF6BC4"), (356, 336, 170, "#3FE9FF"),
                           (300, 150, 150, "#FFD76E")):
        gg = ic.rad("t%d" % cx, [("0%", c, "0.85"), ("100%", c, "0")], r="50%")
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>'
             % (n(cx), n(cy), n(r), gg))
    ic.a('</g>')
    ic.a('<circle cx="256" cy="256" r="176" fill="%s"/>' % g)
    ic.a('<circle cx="256" cy="256" r="176" fill="none" stroke="%s" '
         'stroke-width="6"/>' % rim)
    ic.a('<ellipse cx="192" cy="164" rx="60" ry="36" fill="#FFFFFF" '
         'opacity="0.75" transform="rotate(-30 192 164)"/>')
    ic.a('<ellipse cx="326" cy="352" rx="42" ry="22" fill="#FFFFFF" '
         'opacity="0.28" transform="rotate(-30 326 352)"/>')
    return ic


@reg
def mesh_blob():
    ic = Icon("mesh-blob", "Mesh Blob", PACK_A, ["gradient", "organic", "shape"])
    cl = ic.clip("c", '<path d="%s"/>' % blob(21, 256, 256, 178, 0.14, 8))
    ic.a('<g clip-path="%s">' % cl)
    ic.a('<rect width="512" height="512" fill="#3FE9FF"/>')
    for (cx, cy, r, c) in ((150, 160, 230, "#A66CFF"), (380, 180, 210, "#FFD76E"),
                           (330, 400, 240, "#FF4FA3"), (120, 400, 200, "#5EEAD4")):
        gg = ic.rad("b%d" % cx, [("0%", c), ("100%", c, "0")], r="50%")
        ic.a('<circle cx="%s" cy="%s" r="%s" fill="%s"/>'
             % (n(cx), n(cy), n(r), gg))
    ic.a('</g>')
    ic.texture(cl, 0.14, seed=5)
    return ic


@reg
def halo_ring():
    ic = Icon("halo-ring", "Halo", PACK_A, ["ring", "circle", "loop"])
    g = ic.lin("g", [("0%", "#3FE9FF"), ("30%", "#6C6CFF"), ("62%", "#FF4FA3"),
                     ("100%", "#FFD76E")], x1="0%", y1="0%", x2="100%", y2="100%")
    ic.glow_shape('<circle cx="256" cy="256" r="160" fill="none" stroke="#A66CFF" '
                  'stroke-width="46"/>', 30, 0.6)
    ic.a('<circle cx="256" cy="256" r="160" fill="none" stroke="%s" '
         'stroke-width="40"/>' % g)
    ic.a('<circle cx="256" cy="256" r="160" fill="none" stroke="#FFFFFF" '
         'stroke-width="6" opacity="0.35"/>')
    return ic


@reg
def waveform():
    ic = Icon("waveform", "Waveform", PACK_A, ["audio", "sound", "music"])
    g = ic.lin("g", [("0%", "#3FE9FF"), ("50%", "#A66CFF"), ("100%", "#FF4FA3")],
               x1="50", y1="0", x2="462", y2="0", user=True)
    rnd = random.Random(3)
    bars = []
    for i in range(13):
        x = 50 + i * 33
        h = 60 + abs(math.sin(i * 0.85)) * 300 + rnd.uniform(-20, 20)
        h = max(56, min(344, h))
        bars.append(rrect(x, 256 - h / 2, 24, h, 12) + "/>")
    ic.glow_shape('<g fill="#6C6CFF">%s</g>' % "".join(bars), 20, 0.45)
    ic.a('<g fill="%s">%s</g>' % (g, "".join(bars)))
    return ic


@reg
def equalizer():
    ic = Icon("equalizer", "Equalizer", PACK_A, ["music", "levels", "bars"])
    cols = ["#3FE9FF", "#5EEAD4", "#6EE7A8", "#FFD76E", "#FF8A5B", "#FF4FA3"]
    for i, c in enumerate(cols):
        x = 56 + i * 68
        h = [180, 300, 120, 380, 220, 300][i]
        g = ic.lin("g%d" % i, [("0%", "#FFFFFF"), ("18%", c), ("100%", c)],
                   x1="0", y1=n(436 - h), x2="0", y2="436", user=True)
        ic.a('%s fill="#2B3446" opacity="0.45"/>' % rrect(x, 76, 48, 360, 24))
        ic.glow_shape('%s fill="%s"/>' % (rrect(x, 436 - h, 48, h, 24), c),
                      14, 0.45)
        ic.a('%s fill="%s"/>' % (rrect(x, 436 - h, 48, h, 24), g))
    return ic


@reg
def spiral():
    ic = Icon("spiral", "Spiral", PACK_A, ["hypnotic", "swirl", "loop"])
    g = ic.lin("g", [("0%", "#FFD76E"), ("50%", "#FF4FA3"), ("100%", "#6C6CFF")],
               x1="0%", y1="0%", x2="100%", y2="100%")
    pth = "M 256 256 "
    for i in range(1, 260):
        t = i * 0.09
        r = 2.6 + t * 11.2
        if r > 190:
            break
        pth += "L %s %s " % (n(256 + r * math.cos(t)), n(256 + r * math.sin(t)))
    ic.glow_shape('<path d="%s" fill="none" stroke="#A66CFF" stroke-width="26" '
                  'stroke-linecap="round"/>' % pth, 22, 0.55)
    ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="22" '
         'stroke-linecap="round"/>' % (pth, g))
    return ic


@reg
def prism():
    ic = Icon("prism", "Prism", PACK_A, ["light", "rainbow", "refraction"])
    ic.a('<path d="M 60 300 L 214 214" stroke="#FFFFFF" stroke-width="14" '
         'stroke-linecap="round"/>')
    cols = ["#FF4F6D", "#FF9E4A", "#FFD84A", "#5FD98A", "#4FA8FF", "#8B6BFF"]
    for i, c in enumerate(cols):
        ic.a('<line x1="286" y1="240" x2="472" y2="%s" stroke="%s" '
             'stroke-width="16" stroke-linecap="round" opacity="0.95"/>'
             % (n(196 + i * 42), c))
    g = ic.lin("g", [("0%", "#FFFFFF", "0.9"), ("100%", "#9FC8FF", "0.55")])
    ic.a('<path d="M 256 96 L 386 340 L 126 340 Z" fill="%s"/>' % g)
    ic.a('<path d="M 256 96 L 386 340 L 126 340 Z" fill="none" stroke="#FFFFFF" '
         'stroke-width="7" opacity="0.9" stroke-linejoin="round"/>')
    return ic


@reg
def portal():
    ic = Icon("portal", "Portal", PACK_A, ["gate", "vortex", "sci-fi"])
    for i, (r, c, w) in enumerate(((172, "#6C6CFF", 30), (138, "#A66CFF", 26),
                                   (106, "#FF4FA3", 22), (76, "#FFD76E", 18))):
        ic.glow_shape('<ellipse cx="256" cy="256" rx="%s" ry="%s" fill="none" '
                      'stroke="%s" stroke-width="%s"/>'
                      % (n(r), n(r * 1.18), c, n(w)), 20, 0.5)
        ic.a('<ellipse cx="256" cy="256" rx="%s" ry="%s" fill="none" stroke="%s" '
             'stroke-width="%s" opacity="0.95"/>' % (n(r), n(r * 1.18), c, n(w)))
    ic.a('<ellipse cx="256" cy="256" rx="52" ry="62" fill="#FFF6D8"/>')
    return ic


# ================================================================= RETRO =====
@reg
def synth_sun():
    ic = Icon("synth-sun", "Synthwave Sun", PACK_R, ["retro", "80s", "grid"])
    g = ic.lin("g", [("0%", "#FFE96E"), ("45%", "#FF6BA8"), ("100%", "#8B2AC8")])
    cl = ic.clip("c", '<circle cx="256" cy="230" r="164"/>')
    ic.glow_shape('<circle cx="256" cy="230" r="170" fill="#FF4FA3"/>', 34, 0.6)
    ic.a('<g clip-path="%s"><circle cx="256" cy="230" r="164" fill="%s"/>' % (cl, g))
    for i in range(7):
        y = 246 + i * 24
        ic.a('<rect x="80" y="%s" width="352" height="%s" fill="#160A2A" '
             'opacity="0.92"/>' % (n(y), n(4 + i * 2.6)))
    ic.a('</g>')
    grid = ic.lin("gr", [("0%", "#3FE9FF", "0.35"), ("100%", "#FF4FA3", "1")],
                  x1="0", y1="400", x2="0", y2="482", user=True)
    o = []
    for i in range(11):
        x = 256 + (i - 5) * 150
        o.append('<line x1="256" y1="398" x2="%s" y2="486"/>' % n(x))
    for y in (404, 416, 432, 452, 478):
        o.append('<line x1="4" y1="%s" x2="508" y2="%s"/>' % (n(y), n(y)))
    ic.glow_shape('<g stroke="#FF4FA3" stroke-width="7" '
                  'stroke-linecap="round">%s</g>' % "".join(o), 14, 0.55)
    ic.a('<g stroke="%s" stroke-width="5" stroke-linecap="round">%s</g>'
         % (grid, "".join(o)))
    return ic


@reg
def lightning():
    ic = Icon("lightning", "Lightning", PACK_R, ["bolt", "power", "fast"])
    g = ic.lin("g", [("0%", "#FFF9D6"), ("45%", "#FFD76E"), ("100%", "#FF7A2E")])
    ic.glow_shape(poly(bolt(256, 256, 250, 400)) + ' fill="#FFB74D"/>', 30, 0.9)
    ic.a(poly(bolt(256, 256, 236, 384)) + ' fill="%s"/>' % g)
    ic.a(poly(bolt(256, 256, 236, 384)) + ' fill="none" stroke="#FFFFFF" '
         'stroke-width="6" stroke-linejoin="round" opacity="0.65"/>')
    return ic


@reg
def skull():
    ic = Icon("skull", "Skull", PACK_R, ["badass", "danger", "punk"])
    g = ic.lin("g", [("0%", "#FFFFFF"), ("100%", "#B9C4D6")])
    ic.glow_shape('<circle cx="256" cy="240" r="164" fill="#A66CFF"/>', 30, 0.35)
    ic.a('<path d="M 256 52 C 366 52 442 128 442 236 c 0 62 -26 106 -66 134 '
         'l -6 62 a 24 24 0 0 1 -24 22 h -180 a 24 24 0 0 1 -24 -22 l -6 -62 '
         'C 96 342 70 298 70 236 C 70 128 146 52 256 52 Z" fill="%s"/>' % g)
    for (x, r) in ((178, 52), (334, 52)):
        ic.a('<ellipse cx="%s" cy="238" rx="%s" ry="%s" fill="#10131E"/>'
             % (n(x), n(r), n(r * 1.08)))
        ic.a('<circle cx="%s" cy="222" r="16" fill="#FF2F6E"/>' % n(x + 8))
    ic.a('<path d="M 256 292 l -28 46 h 56 Z" fill="#10131E"/>')
    ic.a('<g fill="#10131E"><rect x="196" y="392" width="26" height="56" rx="9"/>'
         '<rect x="242" y="392" width="26" height="56" rx="9"/>'
         '<rect x="288" y="392" width="26" height="56" rx="9"/></g>')
    return ic


@reg
def glitch():
    ic = Icon("glitch", "Glitch", PACK_R, ["error", "cyber", "distort"])
    base = ic.lin("b", [("0%", "#2B3446"), ("100%", "#0E1420")])
    ic.a('%s fill="#FF2F6E" opacity="0.85"/>' % rrect(88, 118, 336, 276, 26))
    ic.a('%s fill="#3FE9FF" opacity="0.85"/>' % rrect(104, 130, 336, 276, 26))
    ic.a('%s fill="%s"/>' % (rrect(96, 124, 336, 276, 26), base))
    rnd = random.Random(8)
    for i in range(9):
        y = 132 + i * 30
        w = rnd.uniform(70, 300)
        x = 96 + rnd.uniform(0, 336 - w)
        c = ["#FF2F6E", "#3FE9FF", "#FFD76E", "#A66CFF"][i % 4]
        ic.a('<rect x="%s" y="%s" width="%s" height="%s" fill="%s" '
             'opacity="%s"/>' % (n(x), n(y), n(w), n(rnd.uniform(6, 18)), c,
                                 n(rnd.uniform(.5, .95))))
    ic.a('%s fill="none" stroke="#FFFFFF" stroke-width="5" opacity="0.35"/>'
         % rrect(96, 124, 336, 276, 26))
    return ic


@reg
def chrome_star():
    ic = Icon("chrome-star", "Chrome Star", PACK_R, ["y2k", "shine", "sparkle"])
    g = ic.lin("g", [("0%", "#FFFFFF"), ("28%", "#BFE9FF"), ("52%", "#6C8CFF"),
                     ("74%", "#FF9EDC"), ("100%", "#FFF3D6")], x1="0%", y1="0%",
               x2="100%", y2="100%")
    ic.glow_shape('<path d="%s" fill="#8FB6FF"/>' % sparkle(256, 256, 210, 0.16),
                  28, 0.6)
    ic.a('<path d="%s" fill="%s"/>' % (sparkle(256, 256, 198, 0.16), g))
    ic.a('<path d="%s" fill="#FFFFFF" opacity="0.75"/>'
         % sparkle(256, 256, 92, 0.26))
    ic.a('<path d="%s" fill="#FFFFFF"/>' % sparkle(392, 128, 44, 0.18))
    return ic


@reg
def pixel_heart():
    ic = Icon("pixel-heart", "Pixel Heart", PACK_R, ["8bit", "game", "love"])
    grid = [
        "00110011000",
        "01111111100",
        "11111111110",
        "11111111110",
        "11111111110",
        "01111111100",
        "00111111000",
        "00011110000",
        "00001100000",
    ]
    cell = 40
    ox = 256 - len(grid[0]) * cell / 2
    oy = 256 - len(grid) * cell / 2
    g = ic.lin("g", [("0%", "#FF7A9E"), ("100%", "#C81E4E")])
    ic.glow_shape('<rect x="120" y="130" width="272" height="250" fill="#FF4F6D"/>',
                  30, 0.35)
    for r, row in enumerate(grid):
        for c, v in enumerate(row):
            if v == "1":
                ic.a('<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>'
                     % (n(ox + c * cell), n(oy + r * cell), n(cell), n(cell), g))
    ic.a('<g fill="#FFFFFF" opacity="0.85">'
         '<rect x="%s" y="%s" width="%s" height="%s"/>'
         '<rect x="%s" y="%s" width="%s" height="%s"/></g>'
         % (n(ox + 2 * cell), n(oy + 2 * cell), n(cell), n(cell),
            n(ox + 3 * cell), n(oy + 1 * cell), n(cell), n(cell)))
    return ic


@reg
def floppy():
    ic = Icon("floppy", "Floppy Disk", PACK_R, ["save", "retro", "disk"])
    sh = ic.lin("s", [("0%", "#3E4C64"), ("100%", "#1A2130")])
    ic.a('<g filter="%s">' % ic.shadow("sh", 12, 14, "#05070E", 0.4))
    ic.a('<path d="M 76 108 h 292 l 68 68 v 228 a 32 32 0 0 1 -32 32 h -296 '
         'a 32 32 0 0 1 -32 -32 v -264 a 32 32 0 0 1 32 -32 Z" fill="%s"/>' % sh)
    ic.a('</g>')
    ic.a('%s fill="#E6ECF7"/>' % rrect(148, 108, 216, 118, 6))
    ic.a('%s fill="#FF4F6D"/>' % rrect(288, 122, 44, 88, 6))
    ic.a('%s fill="#C9D5E5"/>' % rrect(120, 268, 272, 168, 10))
    ic.a('<g fill="#8FA0B8">'
         '<rect x="144" y="296" width="216" height="14" rx="7"/>'
         '<rect x="144" y="330" width="216" height="14" rx="7"/>'
         '<rect x="144" y="364" width="140" height="14" rx="7"/></g>')
    return ic


@reg
def crt():
    ic = Icon("crt", "CRT Screen", PACK_R, ["tv", "terminal", "retro"])
    body = ic.lin("b", [("0%", "#E8DCC2"), ("100%", "#B49E76")])
    scr = ic.lin("s", [("0%", "#0E3A2E"), ("100%", "#041A15")])
    ic.a('<g filter="%s">' % ic.shadow("sh", 12, 14, "#1B1508", 0.35))
    ic.a('%s fill="%s"/>' % (rrect(56, 96, 400, 320, 44), body))
    ic.a('</g>')
    ic.a('%s fill="%s"/>' % (rrect(92, 130, 328, 236, 34), scr))
    cl = ic.clip("c", rrect(92, 130, 328, 236, 34) + "/>")
    ic.a('<g clip-path="%s">' % cl)
    ic.glow_shape('<g fill="#5FFFA8">'
                  '<rect x="122" y="166" width="180" height="16" rx="8"/>'
                  '<rect x="122" y="204" width="248" height="16" rx="8"/>'
                  '<rect x="122" y="242" width="140" height="16" rx="8"/>'
                  '<rect x="122" y="280" width="206" height="16" rx="8"/></g>',
                  12, 0.9)
    ic.a('<g fill="#8FFFC4">'
         '<rect x="122" y="166" width="180" height="16" rx="8"/>'
         '<rect x="122" y="204" width="248" height="16" rx="8"/>'
         '<rect x="122" y="242" width="140" height="16" rx="8"/>'
         '<rect x="122" y="280" width="206" height="16" rx="8"/></g>')
    for i in range(24):
        ic.a('<rect x="92" y="%s" width="328" height="4" fill="#000000" '
             'opacity="0.22"/>' % n(130 + i * 10))
    ic.a('</g>')
    ic.a('%s fill="#8E7A55"/>' % rrect(196, 424, 120, 30, 15))
    ic.a('<circle cx="392" cy="392" r="12" fill="#FF4F6D"/>')
    return ic


@reg
def arcade():
    ic = Icon("arcade", "Arcade Stick", PACK_R, ["game", "joystick", "play"])
    base = ic.lin("b", [("0%", "#3E4C64"), ("100%", "#161D2B")])
    ball = ic.rad("bl", [("0%", "#FF9EB4"), ("55%", "#E8244F"), ("100%", "#8E0E2E")],
                  cx="36%", cy="30%")
    ic.a('%s fill="%s"/>' % (rrect(60, 250, 392, 196, 40), base))
    ic.a('%s fill="#4E5F7C" opacity="0.6"/>' % rrect(76, 264, 360, 60, 26))
    ic.a('<path d="M 176 300 L 176 200" stroke="#C9D5E5" stroke-width="26" '
         'stroke-linecap="round"/>')
    ic.glow_shape('<circle cx="176" cy="164" r="56" fill="#FF4F6D"/>', 20, 0.55)
    ic.a('<circle cx="176" cy="164" r="50" fill="%s"/>' % ball)
    for i, (x, y, c) in enumerate(((320, 300, "#3FE9FF"), (392, 288, "#FFD76E"),
                                   (346, 372, "#6EE7A8"))):
        ic.a('<circle cx="%s" cy="%s" r="34" fill="#0E1420"/>' % (n(x), n(y)))
        ic.a('<circle cx="%s" cy="%s" r="28" fill="%s"/>' % (n(x), n(y - 4), c))
    return ic


@reg
def neon_arrow():
    ic = Icon("neon-arrow", "Neon Arrow", PACK_R, ["sign", "direction", "vegas"])
    g = ic.lin("g", [("0%", "#FF4FA3"), ("100%", "#FFD76E")], x1="0%", x2="100%",
               y1="0%", y2="0%")
    p = ("M 96 200 h 168 v -74 l 152 130 l -152 130 v -74 h -168 Z")
    ic.glow_shape('<path d="%s" fill="none" stroke="#FF4FA3" stroke-width="34" '
                  'stroke-linejoin="round"/>' % p, 28, 0.85)
    ic.a('<path d="%s" fill="none" stroke="%s" stroke-width="24" '
         'stroke-linejoin="round"/>' % (p, g))
    ic.a('<path d="%s" fill="none" stroke="#FFFFFF" stroke-width="8" '
         'stroke-linejoin="round" opacity="0.85"/>' % p)
    rnd = random.Random(2)
    for i in range(9):
        a = rnd.uniform(0, 6.283)
        ic.a('<circle cx="%s" cy="%s" r="6" fill="#FFF3D6" opacity="%s"/>'
             % (n(256 + 210 * math.cos(a)), n(256 + 150 * math.sin(a)),
                n(rnd.uniform(.35, .8))))
    return ic
