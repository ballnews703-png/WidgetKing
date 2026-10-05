import UIKit
import CoreGraphics

// Native twin of the Scriptable template's drawing code: paints a WidgetKing
// design into a bitmap at a widget family's point size. Every design kind
// (clock, date, countdown, quote, note, launcher, battery, freestyle, lock,
// playlist) and every freestyle element kind the web designer knows.
// Milestone 1 bakes clocks and app tiles into the image; milestone 3 lifts
// clocks and tappable app tiles out as live WidgetKit views, exactly as the
// Scriptable template layers native overlays over its baked image.

enum WKFamily: String, CaseIterable {
    case small, medium, large, extraLargePortrait, extraLarge
    case accessoryRectangular, accessoryCircular, accessoryInline

    var isAccessory: Bool { rawValue.hasPrefix("accessory") }

    /// Generic point sizes (the template's fallback table); real devices
    /// supply exact frames through the extension's displaySize in M3.
    var points: CGSize {
        switch self {
        case .small: return CGSize(width: 155, height: 155)
        case .medium: return CGSize(width: 329, height: 155)
        case .large: return CGSize(width: 329, height: 345)
        case .extraLargePortrait: return CGSize(width: 329, height: 540)
        case .extraLarge: return CGSize(width: 676, height: 345)
        case .accessoryRectangular: return CGSize(width: 172, height: 76)
        case .accessoryCircular: return CGSize(width: 76, height: 76)
        case .accessoryInline: return CGSize(width: 172, height: 24)
        }
    }
}

struct WKRenderer {
    var live: WKLiveData = .offline
    var now: Date = Date()
    /// Pixels per point. Widgets render at the device scale (3 on every
    /// current iPhone); previews can go lower.
    var scale: CGFloat = 3
    /// Stock artwork lookup by slug (stickers, moon packs, live weather and
    /// battery art). The app bundle supplies it in M3; nil draws nothing —
    /// a decoration is never worth blanking a widget.
    var stickers: (String) -> UIImage? = { _ in nil }
    /// Playlist designs resolve to the design for the current time of day.
    var resolvePlaylist: (WKDesign, Date) -> WKDesign? = { _, _ in nil }
    /// Real App Store icons by URL (cached on device, M3). nil → emoji tile.
    var appIcons: (String) -> UIImage? = { _ in nil }
    /// Wallpaper slice for glass/clear backgrounds (M3); nil → placeholder.
    var wallpaper: ((WKFamily) -> UIImage?)? = nil

    static let wallpaperHint = "Set your wallpaper: open the WidgetKing script"

    // MARK: entry

    func render(_ designIn: WKDesign, family: WKFamily) -> UIImage {
        var design = designIn
        if family.isAccessory { return renderLock(design, family: family) }
        if design.kind == "playlist" {
            if let target = resolvePlaylist(design, now) { design = target }
            else {
                design = WKDesign(["name": design.name, "kind": "note", "themeID": design.themeID, "fontStyle": "rounded",
                                   "textColorHex": "#FFFFFF", "primaryText": "Pick a design for each time of day in the designer"])
            }
        }
        if design.kind == "lock" {
            design = WKDesign(["name": design.name, "kind": "note", "themeID": design.themeID, "fontStyle": "rounded",
                               "textColorHex": "#FFFFFF", "background": "gradient",
                               "primaryText": "“" + design.name + "” is a Lock Screen design.\nAdd it there: hold the Lock Screen → Customize → tap the widget strip."])
        }
        if design.kind == "freestyle" { design = design.applyingSizeLayout(family.rawValue) }
        let pts = family.points
        let W = (pts.width * scale).rounded(), H = (pts.height * scale).rounded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: W, height: H), format: format)
        return renderer.image { rc in
            let ctx = rc.cgContext
            paintBackground(ctx, design, family: family, W: W, H: H)
            switch design.kind {
            case "freestyle": drawFreestyle(ctx, design, W: W, H: H)
            case "launcher": drawLauncher(ctx, design, family: family, W: W, H: H)
            default: drawSimpleKind(ctx, design, W: W, H: H)
            }
            if wallpaperMissing(design, family: family) {
                let u = min(W, H) / 158
                drawText(ctx, Self.wallpaperHint, font: UIFont.systemFont(ofSize: (7 * u).rounded()), color: WKColor.color("#FFFFFF", 0.75),
                         rect: CGRect(x: 6 * u, y: H - 20 * u, width: W - 12 * u, height: 18 * u), align: .center)
            }
        }
    }

    // MARK: background

    func wallpaperMissing(_ design: WKDesign, family: WKFamily) -> Bool {
        guard design.background == "clear" || design.background == "glass" else { return false }
        return wallpaper?(family) == nil
    }

    func paintBackground(_ ctx: CGContext, _ design: WKDesign, family: WKFamily, W: CGFloat, H: CGFloat) {
        let colors = design.themeColors
        let op = design.bgOpacity
        let slice = wallpaper?(family)
        if design.background == "clear" || design.background == "glass" || (design.background == "gradient" && op < 1) {
            if let img = slice {
                img.draw(in: CGRect(x: 0, y: 0, width: W, height: H))
                if design.background == "glass" {
                    let light = design.glassTint == "light"
                    ctx.setFillColor(WKColor.color(light ? "#FFFFFF" : "#101018", (light ? 0.38 : 0.55) * op).cgColor)
                    ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
                } else if design.background == "gradient" {
                    drawGradient(ctx, colors, dir: design.gradientDir, alpha: op, W: W, H: H)
                    drawBgPattern(ctx, design, W: W, H: H)
                }
                return
            }
            if design.background == "clear" { return } // transparent: iOS shows what's behind
            if design.background == "glass" {
                // No wallpaper slice yet: frost over the theme, the designer's stand-in.
                drawGradient(ctx, colors, dir: "diagonal", alpha: 1, W: W, H: H)
                let light = design.glassTint == "light"
                ctx.setFillColor(WKColor.color(light ? "#FFFFFF" : "#101018", (light ? 0.38 : 0.55) * op).cgColor)
                ctx.fill(CGRect(x: 0, y: 0, width: W, height: H))
                return
            }
        }
        drawGradient(ctx, colors, dir: design.gradientDir, alpha: 1, W: W, H: H)
        if design.gradientDir == "mesh" {
            let c1 = colors[0], c2 = colors[1]
            let blobs: [(Double, Double, Double, String)] = [(0.2, 0.22, 0.6, c2), (0.85, 0.18, 0.5, c1), (0.68, 0.85, 0.65, c2)]
            for b in blobs {
                let R = max(W, H) * CGFloat(b.2)
                let glow = WKColor.lerp(b.3, "#FFFFFF", 0.45)
                let space = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: space, colors: [glow.withAlphaComponent(0.75).cgColor, glow.withAlphaComponent(0).cgColor] as CFArray, locations: [0, 1])!
                let center = CGPoint(x: CGFloat(b.0) * W, y: CGFloat(b.1) * H)
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: R, options: [])
            }
        }
        drawBgPattern(ctx, design, W: W, H: H)
    }

    func drawGradient(_ ctx: CGContext, _ colors: [String], dir: String, alpha: Double, W: CGFloat, H: CGFloat) {
        let space = CGColorSpaceCreateDeviceRGB()
        let a = WKColor.color(colors[0], alpha).cgColor, b = WKColor.color(colors[1], alpha).cgColor
        guard let gradient = CGGradient(colorsSpace: space, colors: [a, b] as CFArray, locations: [0, 1]) else { return }
        let end: CGPoint
        switch dir {
        case "vertical": end = CGPoint(x: 0, y: H)
        case "horizontal": end = CGPoint(x: W, y: 0)
        default: end = CGPoint(x: W, y: H)
        }
        ctx.drawLinearGradient(gradient, start: .zero, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    func drawBgPattern(_ ctx: CGContext, _ design: WKDesign, W: CGFloat, H: CGFloat) {
        let p = design.bgPattern
        if p.isEmpty { return }
        let u = min(W, H) / 158
        ctx.saveGState()
        switch p {
        case "dots":
            ctx.setFillColor(WKColor.color("#FFFFFF", 0.14).cgColor)
            let step = 14 * u
            var y = step / 2
            while y < H {
                var x = step / 2
                while x < W { ctx.fillEllipse(in: CGRect(x: x - 1.3 * u, y: y - 1.3 * u, width: 2.6 * u, height: 2.6 * u)); x += step }
                y += step
            }
        case "grid":
            ctx.setFillColor(WKColor.color("#FFFFFF", 0.08).cgColor)
            let step = 16 * u
            var x: CGFloat = 0
            while x < W { ctx.fill(CGRect(x: x, y: 0, width: u, height: H)); x += step }
            var y: CGFloat = 0
            while y < H { ctx.fill(CGRect(x: 0, y: y, width: W, height: u)); y += step }
        case "stripes":
            ctx.setStrokeColor(WKColor.color("#FFFFFF", 0.07).cgColor)
            ctx.setLineWidth(6 * u)
            let step = 18 * u
            var d: CGFloat = 0
            while d < W + H {
                ctx.move(to: CGPoint(x: d, y: 0)); ctx.addLine(to: CGPoint(x: d - H, y: H)); ctx.strokePath()
                d += step
            }
        case "waves":
            ctx.setStrokeColor(WKColor.color("#FFFFFF", 0.11).cgColor)
            ctx.setLineWidth(1.6 * u)
            for r in 1...6 {
                let baseY = H * CGFloat(r) / 7
                ctx.move(to: CGPoint(x: 0, y: baseY))
                var x: CGFloat = 0
                while x <= W {
                    ctx.addLine(to: CGPoint(x: x, y: baseY + sin((x / W) * .pi * 3 + CGFloat(r)) * 5 * u))
                    x += 6 * u
                }
                ctx.strokePath()
            }
        case "grain", "paper":
            var seed: Int64 = 7
            let n = min(700, Int((W * H) / (140 * u * u)))
            for i in 0..<max(0, n) {
                seed = (seed * 16807) % 2147483647
                let x = CGFloat(seed % Int64(max(1, Int(W))))
                seed = (seed * 16807) % 2147483647
                let y = CGFloat(seed % Int64(max(1, Int(H))))
                ctx.setFillColor(WKColor.color(i % 2 == 1 ? "#FFFFFF" : "#000000", 0.09).cgColor)
                ctx.fill(CGRect(x: x, y: y, width: u, height: u))
            }
            if p == "paper" {
                ctx.setFillColor(WKColor.color("#FFFFFF", 0.04).cgColor)
                var x: CGFloat = 0
                while x < W { ctx.fill(CGRect(x: x, y: 0, width: u * 0.7, height: H)); x += 5 * u }
            }
        case "blobs":
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.25, 0.3, 0.5), (0.78, 0.7, 0.42)]
            for sp in spots {
                let R = max(W, H) * sp.2
                let space = CGColorSpaceCreateDeviceRGB()
                if let g = CGGradient(colorsSpace: space, colors: [WKColor.color("#FFFFFF", 0.16).cgColor, WKColor.color("#FFFFFF", 0).cgColor] as CFArray, locations: [0, 1]) {
                    let c = CGPoint(x: sp.0 * W, y: sp.1 * H)
                    ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: R, options: [])
                }
            }
        default: break
        }
        ctx.restoreGState()
    }

    // MARK: fonts & text

    func font(_ style: String, _ size: CGFloat, bold: Bool) -> UIFont {
        let sz = max(1, size)
        if let names = WKData.fontNames[style], let f = UIFont(name: bold ? names[1] : names[0], size: sz) { return f }
        if style == "mono" { return UIFont.monospacedSystemFont(ofSize: sz, weight: bold ? .bold : .regular) }
        if style == "classic" { return UIFont.systemFont(ofSize: sz, weight: bold ? .bold : .regular) }
        let base = UIFont.systemFont(ofSize: sz, weight: bold ? .bold : .regular)
        if let d = base.fontDescriptor.withDesign(.rounded) { return UIFont(descriptor: d, size: sz) }
        return base
    }

    func drawText(_ ctx: CGContext, _ text: String, font: UIFont, color: UIColor, rect: CGRect, align: NSTextAlignment, lineBreak: NSLineBreakMode = .byWordWrapping) {
        let para = NSMutableParagraphStyle()
        para.alignment = align
        para.lineBreakMode = lineBreak
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: para]
        ctx.saveGState()
        ctx.clip(to: rect)
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        ctx.restoreGState()
    }

    func textSize(_ text: String, font: UIFont, width: CGFloat) -> CGSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let r = (text as NSString).boundingRect(with: CGSize(width: width, height: 10000), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        return CGSize(width: ceil(r.width), height: ceil(r.height))
    }

    /// A vertical, centered stack of lines — the non-freestyle kinds.
    struct Line { var text: String; var font: UIFont; var color: UIColor; var alpha: CGFloat = 1 }
    func drawStack(_ ctx: CGContext, _ lines: [Line], W: CGFloat, H: CGFloat, pad: CGFloat) {
        let width = W - 2 * pad
        var heights: [CGFloat] = []
        for l in lines { heights.append(textSize(l.text, font: l.font, width: width).height) }
        let total = heights.reduce(0, +)
        var y = max(pad, (H - total) / 2)
        for (i, l) in lines.enumerated() {
            drawText(ctx, l.text, font: l.font, color: l.color.withAlphaComponent(l.alpha), rect: CGRect(x: pad, y: y, width: width, height: heights[i] + 2), align: .center)
            y += heights[i]
        }
    }

    // MARK: simple kinds

    func drawSimpleKind(_ ctx: CGContext, _ design: WKDesign, W: CGFloat, H: CGFloat) {
        let s = min(W, H) / 155
        let tc = WKColor.color(design.textColorHex)
        let style = design.fontStyle
        var lines: [Line] = []
        switch design.kind {
        case "clock":
            lines = [Line(text: WKText.timeString(now), font: font(style, 40 * s, bold: true), color: tc),
                     Line(text: WKText.dateString(now, "EEEE, MMMM d"), font: font(style, 12 * s, bold: false), color: tc, alpha: 0.85)]
        case "date":
            lines = [Line(text: WKText.dateString(now, "EEEE").uppercased(), font: font(style, 13 * s, bold: true), color: tc, alpha: 0.85),
                     Line(text: String(Calendar.current.component(.day, from: now)), font: font(style, 50 * s, bold: true), color: tc),
                     Line(text: WKText.dateString(now, "MMMM"), font: font(style, 13 * s, bold: false), color: tc, alpha: 0.85)]
        case "countdown":
            let days = WKText.daysUntil(design.targetDate, now: now)
            let title = design.primaryText.isEmpty ? design.name : design.primaryText
            lines = [Line(text: title.isEmpty ? "Countdown" : title, font: font(style, 13 * s, bold: true), color: tc, alpha: 0.85),
                     Line(text: String(abs(days)), font: font(style, 44 * s, bold: true), color: tc),
                     Line(text: days >= 0 ? "days to go" : "days ago", font: font(style, 11 * s, bold: false), color: tc, alpha: 0.75)]
        case "quote":
            let q = WKText.activeQuote(design, now: now)
            lines = [Line(text: "“", font: font(style, 18 * s, bold: true), color: tc, alpha: 0.6),
                     Line(text: q.isEmpty ? "Add a quote" : q, font: font(style, 15 * s, bold: true), color: tc)]
            if !design.secondaryText.isEmpty {
                lines.append(Line(text: "— " + design.secondaryText, font: font(style, 11 * s, bold: false), color: tc, alpha: 0.75))
            }
        case "battery":
            let level = Int((live.batteryLevel * 100).rounded())
            lines = [Line(text: "🔋", font: UIFont.systemFont(ofSize: 22 * s), color: tc),
                     Line(text: "\(level)%", font: font(style, 40 * s, bold: true), color: tc),
                     Line(text: live.isCharging ? "charging" : "battery", font: font(style, 11 * s, bold: false), color: tc, alpha: 0.75)]
        default:
            let t = design.primaryText.isEmpty ? (design.name.isEmpty ? "WidgetKing" : design.name) : design.primaryText
            lines = [Line(text: t, font: font(style, 18 * s, bold: true), color: tc)]
        }
        drawStack(ctx, lines, W: W, H: H, pad: 12 * s)
    }

    // MARK: launcher

    func drawLauncher(_ ctx: CGContext, _ design: WKDesign, family: WKFamily, W: CGFloat, H: CGFloat) {
        let apps = Array(design.apps.prefix(12))
        let tc = WKColor.color(design.textColorHex)
        let style = design.fontStyle
        if apps.isEmpty {
            drawStack(ctx, [Line(text: "Add apps in the designer", font: font(style, 13 * scale, bold: true), color: tc)], W: W, H: H, pad: 12 * scale)
            return
        }
        let ls = design.launcherStyle
        let iconPt = CGFloat(clamp(ls.num("iconSize", 30), 16, 120))
        let showLabels = ls.bool("labels", true)
        let circle = ls.str("shape") == "circle"
        let columns = Int(clamp(ls.num("columns", 0).rounded(), 0, 6))
        let perRow = columns > 0 ? columns : (family == .small ? 2 : 4)
        let labelPt = CGFloat(min(13, max(9, Int((iconPt * 0.22).rounded()))))
        let themeName = ls.str("iconTheme")
        let theme = WKData.iconThemes[themeName]
        // Point-space layout (the same math the designer preview uses), scaled.
        let Wp = W / scale, Hp = H / scale
        let pad: CGFloat = 12, rowGap: CGFloat = 10
        let cellH = iconPt + (showLabels ? labelPt + 3 : 0)
        let rowCount = Int(ceil(Double(apps.count) / Double(perRow)))
        let contentH = CGFloat(rowCount) * cellH + CGFloat(rowCount - 1) * rowGap
        var y = max(0, (Hp - contentH) / 2)
        var i = 0
        while i < apps.count {
            let rowApps = Array(apps[i..<min(apps.count, i + perRow)])
            let n = CGFloat(rowApps.count)
            let gap = max(0, (Wp - 2 * pad - n * iconPt) / (n + 1))
            var x = pad + gap
            for (j, app) in rowApps.enumerated() {
                let tileRect = CGRect(x: x * scale, y: y * scale, width: iconPt * scale, height: iconPt * scale)
                drawAppTile(ctx, app, theme: theme, index: i + j, rect: tileRect, circle: circle)
                if showLabels {
                    let label = app.str("label", "App")
                    drawText(ctx, label.isEmpty ? "App" : label, font: font(style, labelPt * scale, bold: false), color: tc.withAlphaComponent(0.85),
                             rect: CGRect(x: (x - gap / 2) * scale, y: (y + iconPt + 3) * scale, width: (iconPt + gap) * scale, height: (labelPt + 4) * scale),
                             align: .center, lineBreak: .byTruncatingTail)
                }
                x += iconPt + gap
            }
            y += cellH + rowGap
            i += perRow
        }
    }

    /// An app's tile: a real icon when one is supplied, else the themed tile
    /// (colored rounded square + vector glyph / monogram / emoji) drawn locally.
    func drawAppTile(_ ctx: CGContext, _ app: WKElement, theme: WKIconTheme?, index: Int, rect: CGRect, circle: Bool) {
        let radius = circle ? rect.width / 2 : (rect.width * CGFloat(theme?.radius ?? 0.24)).rounded()
        ctx.saveGState()
        ctx.addPath(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath)
        ctx.clip()
        if theme == nil {
            var real: UIImage? = nil
            let b64 = app.str("iconB64")
            if !b64.isEmpty, let d = Data(base64Encoded: b64) { real = UIImage(data: d) }
            if real == nil { let url = app.str("iconUrl"); if !url.isEmpty { real = appIcons(url) } }
            if let img = real {
                img.draw(in: rect)
            } else {
                ctx.setFillColor(WKColor.color("#FFFFFF", 0.18).cgColor)
                ctx.fill(rect)
                let emoji = app.str("emoji", "🌐")
                drawText(ctx, emoji.isEmpty ? "🌐" : emoji, font: UIFont.systemFont(ofSize: rect.width * 0.62), color: .white,
                         rect: CGRect(x: rect.minX, y: rect.minY + rect.height * 0.12, width: rect.width, height: rect.height * 0.8), align: .center)
            }
            ctx.restoreGState()
            return
        }
        let t = theme!
        let S = rect.width
        let bg = t.colors[index % max(1, t.colors.count)]
        ctx.setFillColor(t.frost ? WKColor.color("#FFFFFF", 0.25).cgColor : WKColor.color(bg).cgColor)
        ctx.fill(rect)
        if t.neu {
            let space = CGColorSpaceCreateDeviceRGB()
            if let g1 = CGGradient(colorsSpace: space, colors: [WKColor.color("#FFFFFF", 0.10).cgColor, WKColor.color("#FFFFFF", 0).cgColor] as CFArray, locations: [0, 1]) {
                ctx.drawLinearGradient(g1, start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.minX, y: rect.minY + S * 0.3), options: [])
            }
            if let g2 = CGGradient(colorsSpace: space, colors: [WKColor.color("#000000", 0).cgColor, WKColor.color("#000000", 0.28).cgColor] as CFArray, locations: [0, 1]) {
                ctx.drawLinearGradient(g2, start: CGPoint(x: rect.minX, y: rect.minY + S * 0.5), end: CGPoint(x: rect.minX, y: rect.maxY), options: [])
            }
        }
        if let duo = t.duo {
            ctx.setFillColor(WKColor.color(duo[index % duo.count], 0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: rect.minX + S * 0.34, y: rect.minY + S * 0.34, width: S * 0.62, height: S * 0.62))
        }
        let glyphColor = t.glyphCycle.map { $0[index % $0.count] } ?? t.glyph
        if t.line || t.lineCycle || t.frost {
            let inset = max(2, (S * 0.035).rounded())
            let strokeColor = t.lineCycle ? glyphColor : (t.frost ? "#FFFFFF" : t.glyph)
            ctx.setStrokeColor(WKColor.color(strokeColor, t.frost ? 0.5 : 1).cgColor)
            ctx.setLineWidth(max(2, (S * 0.03).rounded()))
            ctx.addPath(UIBezierPath(roundedRect: rect.insetBy(dx: inset, dy: inset), cornerRadius: max(0, radius - inset)).cgPath)
            ctx.strokePath()
        }
        if t.dots {
            let spots: [(CGFloat, CGFloat)] = [(0.2, 0.2), (0.82, 0.24), (0.16, 0.7), (0.8, 0.78), (0.3, 0.86)]
            for (d, sp) in spots.enumerated() {
                ctx.setFillColor(WKColor.color((d + index) % 2 == 1 ? "#27C4F5" : "#FF2E92").cgColor)
                let dr = max(1.5, S * 0.02)
                ctx.fillEllipse(in: CGRect(x: rect.minX + sp.0 * S - dr, y: rect.minY + sp.1 * S - dr, width: dr * 2, height: dr * 2))
            }
        }
        let label = app.str("label", "App").trimmingCharacters(in: .whitespaces)
        if t.wordTile {
            let word = label.isEmpty ? "App" : label
            let fs = min(S * 0.3, (S * 0.8) / (CGFloat(word.count) * 0.48))
            let wc = t.wordColors.map { $0[index % $0.count] } ?? t.glyph
            drawText(ctx, word, font: font(t.wordStyle.isEmpty ? "serif" : t.wordStyle, fs.rounded(), bold: false), color: WKColor.color(wc),
                     rect: CGRect(x: rect.minX, y: rect.minY + S * 0.5 - fs * 0.72, width: S, height: fs * 1.5), align: .center, lineBreak: .byClipping)
            ctx.restoreGState()
            return
        }
        if t.glyphStyle == "line" {
            var strokes = vglyph(for: label)
            if strokes != nil && (t.thick || t.glow) { strokes = strokes!.filter { !$0.tinyCircle } }
            let gA = t.gradStroke?[0] ?? glyphColor
            let gB = t.gradStroke?[1]
            let lineW = max(2, S * (t.thick ? 0.085 : 0.045))
            let gScale = t.ring ? S * 0.5 : S * 0.92
            if t.ring {
                ctx.setStrokeColor(WKColor.color(gA).cgColor)
                ctx.setLineWidth(max(2, S * 0.035))
                ctx.strokeEllipse(in: CGRect(x: rect.minX + S * 0.14, y: rect.minY + S * 0.14, width: S * 0.72, height: S * 0.72))
            }
            if let st = strokes {
                let c = CGPoint(x: rect.midX, y: rect.midY)
                if t.glow {
                    strokeGlyph(ctx, st, center: c, size: gScale, lineW: lineW * 3.2, a: gA, b: gB, alpha: 0.16)
                    strokeGlyph(ctx, st, center: c, size: gScale, lineW: lineW * 1.9, a: gA, b: gB, alpha: 0.35)
                }
                strokeGlyph(ctx, st, center: c, size: gScale, lineW: lineW, a: gA, b: gB, alpha: 1)
            } else {
                let letter = String((label.isEmpty ? "A" : label).prefix(1)).lowercased()
                drawText(ctx, letter, font: font("serif", (S * (t.ring ? 0.32 : 0.46)).rounded(), bold: t.thick), color: WKColor.color(gA),
                         rect: CGRect(x: rect.minX, y: rect.minY + S * (t.ring ? 0.32 : 0.2), width: S, height: S * 0.64), align: .center)
            }
            ctx.restoreGState()
            return
        }
        if !(t.emojiTile || t.lettersOnly), let st = vglyph(for: label) {
            strokeGlyph(ctx, st, center: CGPoint(x: rect.midX, y: rect.midY), size: S * 0.6, lineW: max(2, S * 0.055), a: glyphColor, b: nil, alpha: 1)
            ctx.restoreGState()
            return
        }
        let emoji = app.str("emoji")
        let useEmoji = t.emojiTile && !emoji.isEmpty && emoji != "📱" && emoji != "🌐" && emoji != "📲"
        let glyph = useEmoji ? emoji : String((label.isEmpty ? "A" : label).prefix(1)).uppercased()
        let f = t.emojiTile ? UIFont.systemFont(ofSize: (S * 0.5).rounded()) : UIFont.boldSystemFont(ofSize: (S * 0.42).rounded())
        drawText(ctx, glyph, font: f, color: WKColor.color(glyphColor),
                 rect: CGRect(x: rect.minX, y: rect.minY + S * (t.emojiTile ? 0.18 : 0.22), width: S, height: S * 0.62), align: .center)
        ctx.restoreGState()
    }

    func vglyph(for label: String) -> [WKGlyphStroke]? {
        let lower = label.lowercased()
        for pair in WKData.vglyphFor where lower.contains(pair[0]) { return WKData.vglyphs[pair[1]] }
        return nil
    }

    func strokeGlyph(_ ctx: CGContext, _ strokes: [WKGlyphStroke], center: CGPoint, size: CGFloat, lineW: CGFloat, a: String, b: String?, alpha: Double) {
        ctx.setLineWidth(lineW)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        for stroke in strokes {
            let pts = stroke.points
            if pts.count < 2 { continue }
            for i in 0..<(pts.count - 1) {
                let p0 = pts[i], p1 = pts[i + 1]
                let t = (p0[0] + p0[1] + p1[0] + p1[1]) / 4
                let color = b != nil ? WKColor.lerp(a, b!, t).withAlphaComponent(CGFloat(alpha)) : WKColor.color(a, alpha)
                ctx.setStrokeColor(color.cgColor)
                ctx.move(to: CGPoint(x: center.x + CGFloat(p0[0] - 0.5) * size, y: center.y + CGFloat(p0[1] - 0.5) * size))
                ctx.addLine(to: CGPoint(x: center.x + CGFloat(p1[0] - 0.5) * size, y: center.y + CGFloat(p1[1] - 0.5) * size))
                ctx.strokePath()
            }
        }
    }

    // MARK: freestyle

    func drawFreestyle(_ ctx: CGContext, _ design: WKDesign, W: CGFloat, H: CGFloat) {
        let s = min(W, H) / 158
        let appOnly = design.elements.filter { $0.kind == "app" }
        for el in design.elements {
            let px = CGFloat(el.x) * W, py = CGFloat(el.y) * H
            let fs = CGFloat(el.size) * s
            let op = el.opacity
            switch el.kind {
            case "shape":
                drawShape(ctx, el, px: px, py: py, W: W, H: H, s: s, op: op)
            case "photo":
                drawPhoto(ctx, el, px: px, py: py, W: W, H: H, s: s)
            case "art":
                drawArt(ctx, el, design, px: px, py: py, W: W, H: H, s: s, op: op)
            case "sticker":
                if let img = stickers(el.str("stockId")) {
                    let side = CGFloat(el.w ?? 0.35) * min(W, H)
                    img.draw(in: CGRect(x: px - side / 2, y: py - side / 2, width: side, height: side))
                }
            case "progress":
                let pct = CGFloat(clamp(WKText.progressPct(el, live: live, now: now), 0, 1))
                let wPx = CGFloat(el.w ?? 0.7) * W
                let hPx = max(3 * s, fs == 0 ? 8 * s : fs)
                let x0 = px - wPx / 2, y0 = py - hPx / 2
                ctx.setFillColor(WKColor.color(el.colorHex, op * 0.25).cgColor)
                ctx.addPath(UIBezierPath(roundedRect: CGRect(x: x0, y: y0, width: wPx, height: hPx), cornerRadius: hPx / 2).cgPath); ctx.fillPath()
                if pct > 0.02 {
                    ctx.setFillColor(WKColor.color(el.colorHex, op).cgColor)
                    ctx.addPath(UIBezierPath(roundedRect: CGRect(x: x0, y: y0, width: max(hPx, wPx * pct), height: hPx), cornerRadius: hPx / 2).cgPath); ctx.fillPath()
                }
            case "ring":
                let pct = CGFloat(clamp(WKText.progressPct(el, live: live, now: now), 0, 1))
                let dia = CGFloat(el.w ?? 0.55) * min(W, H)
                let stroke = max(2 * s, fs)
                let rr = dia / 2 - stroke / 2
                ctx.setLineWidth(stroke)
                ctx.setLineCap(.round)
                ctx.setStrokeColor(WKColor.color(el.colorHex, op * 0.25).cgColor)
                ctx.addArc(center: CGPoint(x: px, y: py), radius: rr, startAngle: 0, endAngle: .pi * 2, clockwise: false); ctx.strokePath()
                if pct > 0.01 {
                    ctx.setStrokeColor(WKColor.color(el.colorHex, op).cgColor)
                    ctx.addArc(center: CGPoint(x: px, y: py), radius: rr, startAngle: -.pi / 2, endAngle: -.pi / 2 + .pi * 2 * pct, clockwise: false); ctx.strokePath()
                }
                ctx.setLineCap(.butt)
            case "month":
                drawMonth(ctx, el, design, px: px, py: py, W: W, s: s, op: op)
            case "app":
                let pt = CGFloat(clamp(el.size, 16, 120)) * s
                let theme = WKData.iconThemes[el.str("iconTheme")]
                drawAppTile(ctx, el, theme: theme, index: appOnly.firstIndex(where: { $0.raw["id"] as? String == el.raw["id"] as? String }) ?? 0,
                            rect: CGRect(x: px - pt / 2, y: py - pt / 2, width: pt, height: pt), circle: el.str("shape") == "circle")
                if el.bool("showLabel", false) {
                    drawText(ctx, el.str("label", "App"), font: font(design.fontStyle, 9 * s, bold: false), color: WKColor.color(design.textColorHex, 0.85),
                             rect: CGRect(x: px - 40 * s, y: py + pt / 2 + 1 * s, width: 80 * s, height: 12 * s), align: .center, lineBreak: .byTruncatingTail)
                }
            case "sleeperlogo":
                let pt = CGFloat(max(16, el.size)) * s
                drawText(ctx, el.str("side") == "opp" ? "🛡" : "🏈", font: UIFont.systemFont(ofSize: (pt * 0.85).rounded()), color: .white,
                         rect: CGRect(x: px - pt / 2, y: py - pt / 2, width: pt, height: pt * 1.1), align: .center)
            default:
                drawTextElement(ctx, el, design, px: px, py: py, fs: fs, W: W, H: H, s: s, op: op)
            }
        }
    }

    func drawShape(_ ctx: CGContext, _ el: WKElement, px: CGFloat, py: CGFloat, W: CGFloat, H: CGFloat, s: CGFloat, op: Double) {
        let shapeType = el.str("shape", "rect")
        var wPx: CGFloat, hPx: CGFloat
        if shapeType == "circle" { wPx = CGFloat(el.w ?? 0.5) * min(W, H); hPx = wPx }
        else { wPx = CGFloat(el.w ?? 0.5) * W; hPx = CGFloat(el.h ?? 0.25) * H }
        let rect = CGRect(x: px - wPx / 2, y: py - hPx / 2, width: wPx, height: hPx)
        let radiusRaw = el.num("radius", -1)
        let rr: CGFloat = shapeType == "pill" ? min(wPx, hPx) / 2 : (radiusRaw >= 0 ? CGFloat(radiusRaw) * s : 6 * s)
        if op > 0.02 {
            ctx.setFillColor(WKColor.color(el.colorHex, op).cgColor)
            if shapeType == "circle" { ctx.fillEllipse(in: rect) }
            else { ctx.addPath(UIBezierPath(roundedRect: rect, cornerRadius: rr).cgPath); ctx.fillPath() }
        }
        let bw = CGFloat(el.num("border", 0)) * s
        if bw > 0 {
            ctx.setStrokeColor(WKColor.color(el.hex("borderHex") ?? el.colorHex, 1).cgColor)
            ctx.setLineWidth(bw)
            let srect = rect.insetBy(dx: bw / 2, dy: bw / 2)
            if shapeType == "circle" { ctx.strokeEllipse(in: srect) }
            else { ctx.addPath(UIBezierPath(roundedRect: srect, cornerRadius: max(0, rr - bw / 2)).cgPath); ctx.strokePath() }
        }
    }

    func decodeImage(_ str: String) -> UIImage? {
        var b64 = str
        if let r = b64.range(of: "base64,") { b64 = String(b64[r.upperBound...]) }
        guard let d = Data(base64Encoded: b64, options: [.ignoreUnknownCharacters]) else { return nil }
        return UIImage(data: d)
    }

    func drawPhoto(_ ctx: CGContext, _ el: WKElement, px: CGFloat, py: CGFloat, W: CGFloat, H: CGFloat, s: CGFloat) {
        // Baked (b64/b64s from the exported script) or raw (dataUrl/photos from
        // the designer's own format); several photos rotate daily or per refresh.
        var list = el.strings("b64s")
        if list.isEmpty { let one = el.str("b64"); if !one.isEmpty { list = [one] } }
        if list.isEmpty { list = el.strings("photos") }
        if list.isEmpty { let one = el.str("dataUrl"); if !one.isEmpty { list = [one] } }
        list = list.filter { !$0.isEmpty }
        var wPx: CGFloat, hPx: CGFloat
        let circle = el.str("shape") == "circle"
        if circle { wPx = CGFloat(el.w ?? 0.55) * min(W, H); hPx = wPx }
        else { wPx = CGFloat(el.w ?? 0.55) * W; hPx = wPx * CGFloat(max(0.05, el.num("aspect", 1))) }
        let rect = CGRect(x: px - wPx / 2, y: py - hPx / 2, width: wPx, height: hPx)
        if list.isEmpty {
            ctx.setFillColor(WKColor.color("#808080", 0.25).cgColor)
            ctx.addPath(UIBezierPath(roundedRect: CGRect(x: px - 74 * s / 3, y: py - 10 * s / 3, width: 148 * s / 3, height: 20 * s / 3), cornerRadius: 10 * s / 3).cgPath); ctx.fillPath()
            drawText(ctx, "photo missing - re-add in designer", font: UIFont.systemFont(ofSize: 9 * s), color: WKColor.color("#606060", 0.95),
                     rect: CGRect(x: px - 70 * s, y: py - 6 * s, width: 140 * s, height: 14 * s), align: .center)
            return
        }
        var idx = 0
        if list.count > 1 {
            idx = el.str("rotate") == "refresh" ? Int.random(in: 0..<list.count) : WKText.dayOfYear(now) % list.count
        }
        guard let img = decodeImage(list[idx]) else { return }
        ctx.saveGState()
        let shape = el.str("shape", "rounded")
        let path: UIBezierPath
        if circle { path = UIBezierPath(ovalIn: rect) }
        else if shape == "rect" { path = UIBezierPath(rect: rect) }
        else { path = UIBezierPath(roundedRect: rect, cornerRadius: 12 * s) }
        ctx.addPath(path.cgPath); ctx.clip()
        ctx.setAlpha(CGFloat(el.opacity))
        // cover-fit: scale the image to fill the rect, centered
        let k = max(rect.width / img.size.width, rect.height / img.size.height)
        let dw = img.size.width * k, dh = img.size.height * k
        img.draw(in: CGRect(x: rect.midX - dw / 2, y: rect.midY - dh / 2, width: dw, height: dh))
        ctx.restoreGState()
        let frame = el.str("frame", "none")
        if frame != "none" {
            ctx.setStrokeColor(WKColor.color(el.hex("frameHex") ?? "#FFFFFF").cgColor)
            ctx.setLineWidth(frame == "polaroid" ? 6 * s : 2.5 * s)
            ctx.addPath(path.cgPath); ctx.strokePath()
        }
    }

    func drawArt(_ ctx: CGContext, _ el: WKElement, _ design: WKDesign, px: CGFloat, py: CGFloat, W: CGFloat, H: CGFloat, s: CGFloat, op: Double) {
        // Exported scripts carry art pre-baked; the designer's own format is
        // drawn natively: arc text, rotated text, gradient shape.
        let b64 = el.str("b64")
        if !b64.isEmpty, let img = decodeImage(b64), el.num("artW", 0) > 0 {
            let wPx = CGFloat(el.num("artW", 0)) * s, hPx = CGFloat(el.num("artH", el.num("artW", 0))) * s
            img.draw(in: CGRect(x: px - wPx / 2, y: py - hPx / 2, width: wPx, height: hPx))
            return
        }
        let type = el.str("artType", "arc")
        let color = WKColor.color(el.colorHex, op)
        let fs = CGFloat(el.size) * s
        let f = font(el.font ?? design.fontStyle, fs, bold: el.bold)
        let text = el.text.isEmpty ? "curved text" : el.text
        if type == "gradshape" {
            let wPx = CGFloat(el.w ?? 0.5) * W, hPx = CGFloat(el.h ?? 0.25) * H
            let rect = CGRect(x: px - wPx / 2, y: py - hPx / 2, width: wPx, height: hPx)
            let shape = el.str("shape", "pill")
            let path = shape == "circle" ? UIBezierPath(ovalIn: rect) : UIBezierPath(roundedRect: rect, cornerRadius: shape == "pill" ? min(wPx, hPx) / 2 : 6 * s)
            ctx.saveGState()
            ctx.addPath(path.cgPath); ctx.clip()
            let space = CGColorSpaceCreateDeviceRGB()
            if let g = CGGradient(colorsSpace: space, colors: [WKColor.color(el.colorHex, op).cgColor, WKColor.color(el.hex("color2Hex") ?? "#8F52FA", op).cgColor] as CFArray, locations: [0, 1]) {
                let ang = CGFloat(el.num("angle", 135)) * .pi / 180
                let r = max(wPx, hPx)
                let c = CGPoint(x: rect.midX, y: rect.midY)
                ctx.drawLinearGradient(g, start: CGPoint(x: c.x - cos(ang) * r / 2, y: c.y - sin(ang) * r / 2), end: CGPoint(x: c.x + cos(ang) * r / 2, y: c.y + sin(ang) * r / 2), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
            ctx.restoreGState()
            return
        }
        if type == "rotated" {
            ctx.saveGState()
            ctx.translateBy(x: px, y: py)
            ctx.rotate(by: CGFloat(el.num("angle", 0)) * .pi / 180)
            let size = textSize(text, font: f, width: 10000)
            drawText(ctx, text, font: f, color: color, rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width + 2, height: size.height + 2), align: .center, lineBreak: .byClipping)
            ctx.restoreGState()
            return
        }
        // arc: characters laid along a circle of diameter w (fraction of the short side)
        let dia = CGFloat(el.w ?? 0.7) * min(W, H)
        let radius = dia / 2
        let flip = el.bool("flip", false)
        let chars = Array(text)
        let widths = chars.map { textSize(String($0), font: f, width: 10000).width }
        let total = widths.reduce(0, +)
        let totalAngle = total / max(1, radius)
        var angle = -totalAngle / 2
        for (i, ch) in chars.enumerated() {
            let half = widths[i] / 2 / max(1, radius)
            let a = angle + half
            ctx.saveGState()
            let theta: CGFloat = flip ? (CGFloat.pi / 2 - a) : (-CGFloat.pi / 2 + a)
            ctx.translateBy(x: px + cos(theta) * radius, y: py + sin(theta) * radius)
            ctx.rotate(by: flip ? (theta - CGFloat.pi / 2) : (theta + CGFloat.pi / 2))
            let size = textSize(String(ch), font: f, width: 10000)
            drawText(ctx, String(ch), font: f, color: color, rect: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width + 2, height: size.height + 2), align: .center, lineBreak: .byClipping)
            ctx.restoreGState()
            angle += half * 2
        }
    }

    func drawMonth(_ ctx: CGContext, _ el: WKElement, _ design: WKDesign, px: CGFloat, py: CGFloat, W: CGFloat, s: CGFloat, op: Double) {
        let fsM = CGFloat(clamp(el.size, 6, 16)) * s
        let gw = CGFloat(el.w ?? 0.6) * W
        let cell = gw / 7
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let first = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: 1))!
        let startDow = cal.component(.weekday, from: first) - 1
        let daysIn = cal.range(of: .day, in: .month, for: now)!.count
        let rows = Int(ceil(Double(startDow + daysIn) / 7))
        let rowH = fsM * 1.7
        let gh = rowH * CGFloat(rows + 1)
        let x0 = px - gw / 2, y0 = py - gh / 2
        let headers = ["S", "M", "T", "W", "T", "F", "S"]
        let style = el.font ?? design.fontStyle
        for c in 0..<7 {
            drawText(ctx, headers[c], font: font(style, fsM * 0.9, bold: true), color: WKColor.color(el.colorHex, op * 0.6),
                     rect: CGRect(x: x0 + CGFloat(c) * cell, y: y0, width: cell, height: rowH), align: .center)
        }
        let prevMonth = cal.date(byAdding: .month, value: -1, to: first)!
        let prevDays = cal.range(of: .day, in: .month, for: prevMonth)!.count
        let dim = WKColor.color(el.colorHex, op * 0.3)
        for b in 0..<startDow {
            drawText(ctx, String(prevDays - startDow + 1 + b), font: font(style, fsM, bold: false), color: dim,
                     rect: CGRect(x: x0 + CGFloat(b) * cell, y: y0 + rowH + (rowH - fsM * 1.4) / 2, width: cell, height: fsM * 1.4), align: .center)
        }
        let tail = rows * 7 - (startDow + daysIn)
        for a in 0..<max(0, tail) {
            let idx = startDow + daysIn + a
            drawText(ctx, String(a + 1), font: font(style, fsM, bold: false), color: dim,
                     rect: CGRect(x: x0 + CGFloat(idx % 7) * cell, y: y0 + CGFloat(idx / 7 + 1) * rowH + (rowH - fsM * 1.4) / 2, width: cell, height: fsM * 1.4), align: .center)
        }
        let today = comps.day ?? 1
        for d in 1...daysIn {
            let idx = startDow + d - 1
            let r = idx / 7, c = idx % 7
            let cx = x0 + CGFloat(c) * cell, cy = y0 + CGFloat(r + 1) * rowH
            if d == today {
                ctx.setFillColor(WKColor.color(el.hex("accentHex") ?? "#4A90F6", op).cgColor)
                let dia = min(cell, rowH) * 0.95
                ctx.fillEllipse(in: CGRect(x: cx + (cell - dia) / 2, y: cy + (rowH - dia) / 2, width: dia, height: dia))
                drawText(ctx, String(d), font: font(style, fsM, bold: true), color: .white,
                         rect: CGRect(x: cx, y: cy + (rowH - fsM * 1.4) / 2, width: cell, height: fsM * 1.4), align: .center)
            } else {
                drawText(ctx, String(d), font: font(style, fsM, bold: false), color: WKColor.color(el.colorHex, op * 0.9),
                         rect: CGRect(x: cx, y: cy + (rowH - fsM * 1.4) / 2, width: cell, height: fsM * 1.4), align: .center)
            }
        }
    }

    func elementText(_ el: WKElement) -> (String, String?) {
        var liveColor: String? = nil
        let text: String
        switch el.kind {
        case "clock": text = WKText.timeString(now)
        case "date": text = WKText.dateString(now, "EEE MMM d")
        case "battery": text = "\(Int((live.batteryLevel * 100).rounded()))%"
        case "countdown": text = String(abs(WKText.daysUntil(el.str("dateISO"), now: now)))
        case "symbol": text = WKData.symbolEmoji[el.str("symbolName")] ?? "⭐"
        case "icon": text = el.text.isEmpty ? "★" : el.text
        case "weather": text = WKText.weather(el, live.weather)
        case "calendar": text = WKText.calendar(el, live.events)
        case "sleeper": text = WKText.sleeper(el, live.sleeper(for: el.str("leagueID")))
        case "astro": text = WKText.astro(el, live.astro, now: now)
        case "stock":
            let q = live.stocks[el.str("symbol").trimmingCharacters(in: .whitespaces).uppercased()]
            text = WKText.stock(el, q)
            if el.bool("autoColor", true), let q = q, q.pct.isFinite { liveColor = q.pct >= 0 ? "#30D158" : "#FF6961" }
        case "worldclock": text = WKText.worldClock(el, now: now)
        case "reminders": text = WKText.reminders(el, live.reminders)
        case "news": text = WKText.news(el, live.news)
        case "greeting": text = WKText.greeting(el, now: now)
        case "week": text = "Week \(WKText.weekNumber(now))"
        case "emoji": text = el.text.isEmpty ? "✨" : el.text
        default:
            var t = el.text.isEmpty ? "Text" : el.text
            if el.kind == "text", el.str("multi") == "day", t.contains("\n") {
                let lines = t.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if !lines.isEmpty { t = lines[WKText.dayOfYear(now) % lines.count] }
            }
            text = t
        }
        return (text, liveColor)
    }

    func drawTextElement(_ ctx: CGContext, _ el: WKElement, _ design: WKDesign, px: CGFloat, py: CGFloat, fs: CGFloat, W: CGFloat, H: CGFloat, s: CGFloat, op: Double) {
        // Live-art variants: stock artwork stands in for the text when available.
        if el.kind == "astro", el.str("mode") == "moonicon", !el.str("moonPack").isEmpty,
           let img = stickers(el.str("moonPack") + "-" + WKText.moonInfo(now).slug) {
            let side = max(16, fs * 1.25)
            img.draw(in: CGRect(x: px - side / 2, y: py - side / 2, width: side, height: side)); return
        }
        if el.kind == "weather", el.str("wmode") == "icon", let wx = live.weather {
            let hr = Calendar.current.component(.hour, from: now)
            if let img = stickers(WKText.weatherArtSlug(wx.code, isDay: hr >= 6 && hr < 20)) {
                let side = max(16, fs * 1.25)
                img.draw(in: CGRect(x: px - side / 2, y: py - side / 2, width: side, height: side)); return
            }
        }
        if el.kind == "battery", el.str("mode") == "icon",
           let img = stickers(WKText.batteryArtSlug(live.batteryLevel, charging: live.isCharging)) {
            let side = max(16, fs * 1.25)
            img.draw(in: CGRect(x: px - side / 2, y: py - side / 2, width: side, height: side)); return
        }
        let (text, liveColor) = elementText(el)
        let isBold = el.kind != "text" || el.bold
        let f = el.kind == "emoji" || el.kind == "symbol" ? UIFont.systemFont(ofSize: fs) : font(el.font ?? design.fontStyle, fs, bold: isBold)
        let color = WKColor.color(liveColor ?? el.colorHex, el.kind == "emoji" ? 1 : op)
        if el.kind == "text", let w = el.w {
            let align: NSTextAlignment = el.str("align") == "left" ? .left : el.str("align") == "right" ? .right : .center
            let boxW = CGFloat(w) * W
            drawText(ctx, text, font: f, color: color, rect: CGRect(x: px - boxW / 2, y: py - fs * 0.72, width: boxW, height: H), align: align)
            return
        }
        let isList = el.kind == "calendar" || el.kind == "reminders" || el.kind == "news"
        if isList {
            let boxW = max(W * 0.3, min(W, 2 * min(px, W - px)))
            let perLine = max(6, Int(boxW / (fs * 0.52)))
            var lineCount = 0
            for ln in text.split(separator: "\n", omittingEmptySubsequences: false) { lineCount += max(1, Int(ceil(Double(ln.count) / Double(perLine)))) }
            let estH = fs * 1.55 * CGFloat(lineCount)
            drawText(ctx, text, font: f, color: color, rect: CGRect(x: px - boxW / 2, y: py - estH / 2, width: boxW, height: estH + fs), align: .center)
        } else {
            drawText(ctx, text, font: f, color: color, rect: CGRect(x: px - W / 2, y: py - fs * 0.72, width: W, height: fs * 1.7), align: .center)
        }
    }

    // MARK: Lock Screen (accessory families)

    func renderLock(_ design: WKDesign, family: WKFamily) -> UIImage {
        let pts = family.points
        let W = (pts.width * scale).rounded(), H = (pts.height * scale).rounded()
        let circle = family == .accessoryCircular || design.lockStyle == "circle"
        var rows: [WKElement] = design.kind == "lock" ? Array(design.lockRows.prefix(circle ? 2 : 3)) : []
        if rows.isEmpty {
            switch design.kind {
            case "clock": rows = [WKElement(["kind": "time"]), WKElement(["kind": "date"])]
            case "countdown": rows = [WKElement(["kind": "text", "text": design.primaryText.isEmpty ? design.name : design.primaryText]),
                                      WKElement(["kind": "countdown", "dateISO": design.targetDate])]
            case "battery": rows = [WKElement(["kind": "battery"])]
            case "date": rows = [WKElement(["kind": "date"])]
            default: rows = [WKElement(["kind": "text", "text": design.primaryText.isEmpty ? design.name : design.primaryText])]
            }
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1; format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: W, height: H), format: format).image { rc in
            let ctx = rc.cgContext
            // iOS supplies the frosted background; the stand-in matches the designer preview.
            ctx.setFillColor(WKColor.color("#FFFFFF", 0.22).cgColor)
            let shape = circle ? UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: min(W, H), height: min(W, H)).offsetBy(dx: (W - min(W, H)) / 2, dy: 0))
                               : UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: W, height: H), cornerRadius: 16 * scale)
            ctx.addPath(shape.cgPath); ctx.fillPath()
            var lines: [Line] = []
            for (i, row) in rows.enumerated() {
                let big = rows.count == 1 || (i == 0 && circle)
                let size = CGFloat(big ? (circle ? 20 : 18) : (rows.count >= 3 ? 10 : 12)) * scale
                let f = font(design.fontStyle, size, bold: i == 0)
                let text: String
                switch row.kind {
                case "time": text = WKText.timeString(now)
                case "date": text = WKText.dateString(now, "EEE, MMM d")
                case "countdown":
                    let iso = row.str("dateISO").isEmpty ? design.targetDate : row.str("dateISO")
                    if iso.isEmpty { text = "Set a date" }
                    else { let d = WKText.daysUntil(iso, now: now); text = abs(d) >= 60 ? "in \(Int((Double(d) / 30).rounded())) months" : (d >= 0 ? "in \(d) days" : "\(abs(d)) days ago") }
                case "battery": text = "🔋 \(Int((live.batteryLevel * 100).rounded()))%"
                case "weather": text = WKText.weather(WKElement(["unit": row.str("unit", "f")]), live.weather)
                case "reminder":
                    if let r = live.reminders { text = r.isEmpty ? "All done ✓" : "○ " + r[0].title } else { text = "Reminders off" }
                default: text = row.text
                }
                lines.append(Line(text: text, font: f, color: .white))
            }
            drawStack(ctx, lines, W: W, H: H, pad: (circle ? 8 : 10) * scale)
        }
    }
}
