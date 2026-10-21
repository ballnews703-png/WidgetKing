import UIKit

// Wallpaper slices for Glass / Clear / see-through backgrounds — the native
// twin of the Scriptable template's widgetRect/cropImage/blurImage/tintImage.
// The app stores one wallpaper image (ideally a screenshot of an empty Home
// Screen page, because iOS shades wallpapers) in the App Group; the widget
// extension cuts the slice for its family and the design's chosen spot.
enum WKWallpaper {
    /// Measured widget frames per iPhone, keyed by screen pixel height:
    /// [small, medium, large, left, right, top, middle, bottom]. "labels" is
    /// the normal Home Screen, "nolabels" the Large-icons look (labels hidden).
    static let frames: [String: (labels: [Double], nolabels: [Double]?)] = [
        "2868": ([510, 1092, 1146, 114, 696, 276, 912, 1548], [530, 1138, 1136, 91, 699, 276, 882, 1488]),
        "2796": ([510, 1092, 1146, 98, 681, 252, 888, 1524], [530, 1139, 1136, 75, 684, 252, 858, 1464]),
        "2622": ([486, 1032, 1098, 87, 633, 261, 872, 1485], [495, 1037, 1035, 84, 626, 270, 810, 1350]),
        "2556": ([474, 1017, 1062, 81, 624, 240, 828, 1416], [495, 1047, 1047, 66, 618, 243, 795, 1347]),
        "2778": ([510, 1092, 1146, 96, 678, 246, 882, 1518], nil),
        "2688": ([507, 1080, 1137, 81, 654, 228, 858, 1488], nil),
        "2532": ([474, 1014, 1062, 78, 618, 231, 819, 1407], nil),
        "2436": ([465, 987, 1035, 69, 591, 213, 783, 1353], nil),
        "2079": ([423, 875, 933, 42, 494, 186, 696, 1206], nil),
        "1792": ([338, 720, 758, 55, 437, 159, 579, 999], nil),
        "1624": ([310, 658, 690, 46, 394, 142, 522, 902], nil),
        "1334": ([296, 642, 648, 54, 400, 60, 412, 764], [309, 667, 667, 41, 399, 67, 425, 783]),
        "2208": ([471, 1044, 1071, 99, 672, 114, 696, 1278], nil),
        "2001": ([444, 963, 972, 81, 600, 90, 618, 1146], nil),
        "1136": ([282, 584, 622, 30, 332, 59, 399, 399], nil)
    ]

    static let fileName = "widgetking-wallpaper.img"
    static let iconLabelsKey = "widgetking.iconLabels"
    static let offsetXKey = "widgetking.wallpaper.offsetX"
    static let offsetYKey = "widgetking.wallpaper.offsetY"

    static var fileURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WKStore.groupID)?.appendingPathComponent(fileName)
    }

    /// Accepts a data: URL or raw base64 (PNG/JPEG) from the designer.
    @discardableResult
    static func save(dataURL: String) -> Bool {
        var b64 = dataURL
        if let r = b64.range(of: "base64,") { b64 = String(b64[r.upperBound...]) }
        guard let data = Data(base64Encoded: b64, options: [.ignoreUnknownCharacters]), UIImage(data: data) != nil,
              let url = fileURL else { return false }
        do { try data.write(to: url, options: .atomic) } catch { return false }
        cache = nil
        WKStore.defaults.set(Date().timeIntervalSince1970, forKey: "widgetking.wallpaper.at")
        return true
    }

    static func clear() {
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        cache = nil
        WKStore.defaults.removeObject(forKey: "widgetking.wallpaper.at")
    }

    static var cache: UIImage? = nil
    static func load() -> UIImage? {
        if let c = cache { return c }
        guard let url = fileURL, let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return nil }
        cache = img
        return img
    }

    /// The screen's pixel height decides which measured frame table applies.
    static func frameKey(screenHeightPx: Double) -> String? {
        let k = String(Int(screenHeightPx.rounded()))
        return frames[k] != nil ? k : nil
    }

    /// The pixel rectangle a widget occupies on a wallpaper image of imgW×imgH.
    static func widgetRect(imgW: Double, imgH: Double, family: WKFamily, position: String?, frameKey: String?,
                           iconLabels: Bool = true, offsetX: Double = 0, offsetY: Double = 0) -> CGRect {
        let pos = (position ?? "").isEmpty ? (family == .small ? "top-left" : "top") : position!
        let parts = pos.split(separator: "-").map(String.init)
        let row = parts.first ?? "top"
        let side = parts.count > 1 ? parts[1] : "left"
        var key = frameKey
        if key == nil, frames[String(Int(imgH.rounded()))] != nil { key = String(Int(imgH.rounded())) }
        var x: Double, y: Double, w: Double, h: Double
        var rows: [String: Double]
        if let k = key, let entry = frames[k] {
            let raw = (!iconLabels && entry.nolabels != nil) ? entry.nolabels! : entry.labels
            let sc = imgH / (Double(k) ?? imgH)
            let f = raw.map { $0 * sc }
            rows = ["top": f[5], "middle": f[6], "bottom": f[7]]
            x = f[3]; w = f[0]; h = f[0]
            switch family {
            case .small: x = side == "right" ? f[4] : f[3]
            case .medium: w = f[1]
            case .large: w = f[1]; h = f[2]
            case .extraLargePortrait: w = f[1]; h = f[2] + (f[2] - f[0]) + f[0]
            default: break
            }
        } else {
            let sw = (imgW * 0.402).rounded()
            let gap = ((imgW - 2 * sw) / 3).rounded()
            let rowStep = sw + gap
            let top = (imgH * 0.0965).rounded()
            rows = ["top": top, "middle": top + rowStep, "bottom": top + 2 * rowStep]
            x = gap; w = sw; h = sw
            switch family {
            case .small: x = side == "right" ? gap * 2 + sw : gap
            case .medium: w = imgW - 2 * gap
            case .large: w = imgW - 2 * gap; h = sw * 2 + gap
            case .extraLargePortrait: w = imgW - 2 * gap; h = sw * 3 + gap * 2
            default: break
            }
        }
        y = rows[row] ?? rows["top"]!
        if (family == .large || family == .extraLargePortrait) && row == "bottom" { y = rows["middle"]! }
        y += offsetY; x += offsetX
        x = min(max(0, x), max(0, imgW - w))
        if y + h > imgH { y = max(0, imgH - h) }
        if y < 0 { y = 0 }
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Poor-man's gaussian, as the template does it: downscale then upscale.
    static func blur(_ img: UIImage) -> UIImage {
        let w = max(2, img.size.width), h = max(2, img.size.height)
        let dw = max(2, (w / 16).rounded()), dh = max(2, (h / 16).rounded())
        let f = UIGraphicsImageRendererFormat(); f.scale = 1; f.opaque = true
        let small = UIGraphicsImageRenderer(size: CGSize(width: dw, height: dh), format: f).image { _ in
            img.draw(in: CGRect(x: 0, y: 0, width: dw, height: dh))
        }
        return UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: f).image { rc in
            rc.cgContext.interpolationQuality = .high
            small.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    /// The slice for a design at a family: cropped to the widget frame for
    /// Clear (and any design with a chosen spot), a centered crop otherwise,
    /// blurred for Glass. Tint and gradient veils are painted by the renderer.
    static func slice(for design: WKDesign, family: WKFamily, screenHeightPx: Double) -> UIImage? {
        guard !family.isAccessory, let wall = load(), let cg = wall.cgImage else { return nil }
        let imgW = Double(cg.width), imgH = Double(cg.height)
        let base = UIImage(cgImage: cg) // pixel space, scale 1
        let position = design.str("position")
        let rect: CGRect
        if !position.isEmpty || design.background == "clear" {
            let labels = WKStore.defaults.object(forKey: iconLabelsKey) as? Bool ?? true
            rect = widgetRect(imgW: imgW, imgH: imgH, family: family, position: position, frameKey: frameKey(screenHeightPx: screenHeightPx),
                              iconLabels: labels, offsetX: WKStore.defaults.double(forKey: offsetXKey), offsetY: WKStore.defaults.double(forKey: offsetYKey))
        } else {
            let pts = family.points
            let aspect = Double(pts.width / pts.height)
            var w = imgW * 0.86, h = w / aspect
            if h > imgH * 0.8 { h = imgH * 0.8; w = h * aspect }
            rect = CGRect(x: (imgW - w) / 2, y: (imgH - h) / 2, width: w, height: h)
        }
        guard let cut = base.cgImage?.cropping(to: rect.integral) else { return nil }
        let img = UIImage(cgImage: cut)
        return design.background == "glass" ? blur(img) : img
    }
}
