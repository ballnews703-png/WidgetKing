import Foundation
import UIKit

// The WidgetKing design format, decoded AS the web designer writes it:
// lowercase kinds, ISO date strings, string ids, normalized 0-1 coordinates.
// Deliberately dynamic (a dictionary with typed accessors) rather than a
// rigid Codable struct: the web sanitizer is lenient about missing or odd
// fields and the native side must be too — a hand-edited backup or a field
// from a newer designer version must degrade, never fail to decode.

struct WKElement {
    var raw: [String: Any]

    init(_ raw: [String: Any]) { self.raw = raw }

    var kind: String { str("kind", "text") }
    var x: Double { clamp(num("x", 0.5), 0, 1) }
    var y: Double { clamp(num("y", 0.5), 0, 1) }
    var size: Double { let s = num("size", 18); return s > 0 ? s : 18 }
    var opacity: Double {
        let o = num("opacity", 1)
        return (o >= 0 && o <= 1) ? o : 1
    }
    var text: String { str("text") }
    var colorHex: String { hex("colorHex") ?? "#FFFFFF" }
    var w: Double? { let v = num("w", -1); return v > 0 ? v : nil }
    var h: Double? { let v = num("h", -1); return v > 0 ? v : nil }
    var bold: Bool { bool("bold", true) }
    var font: String? { let f = str("font"); return f.isEmpty ? nil : f }

    func str(_ key: String, _ fallback: String = "") -> String {
        if let s = raw[key] as? String { return s }
        if let n = raw[key] as? NSNumber { return n.stringValue }
        return fallback
    }
    func num(_ key: String, _ fallback: Double) -> Double {
        if let n = raw[key] as? NSNumber { let d = n.doubleValue; return d.isFinite ? d : fallback }
        if let s = raw[key] as? String, let d = Double(s), d.isFinite { return d }
        return fallback
    }
    func bool(_ key: String, _ fallback: Bool) -> Bool {
        if let v = raw[key] as? Bool { return v }
        if let n = raw[key] as? NSNumber { return n.intValue != 0 }
        return fallback
    }
    func hex(_ key: String) -> String? {
        let s = str(key)
        return WKColor.isHex(s) ? s : nil
    }
    func strings(_ key: String) -> [String] {
        return (raw[key] as? [Any] ?? []).compactMap { $0 as? String }
    }
}

struct WKDesign {
    var raw: [String: Any]

    init(_ raw: [String: Any]) { self.raw = raw }

    var id: String { str("id") }
    var name: String { let n = str("name"); return n.isEmpty ? "My Widget" : n }
    var kind: String { let k = str("kind"); return k.isEmpty ? "clock" : k }
    var themeID: String { let t = str("themeID"); return t.isEmpty ? "midnight" : t }
    var fontStyle: String { let f = str("fontStyle"); return f.isEmpty ? "rounded" : f }
    var textColorHex: String { WKColor.isHex(str("textColorHex")) ? str("textColorHex") : "#FFFFFF" }
    var primaryText: String { str("primaryText") }
    var secondaryText: String { str("secondaryText") }
    var targetDate: String { str("targetDate") }
    var tapUrl: String { str("tapUrl") }
    var background: String {
        let b = str("background")
        return ["gradient", "glass", "clear"].contains(b) ? b : "gradient"
    }
    var glassTint: String { str("glassTint") == "light" ? "light" : "dark" }
    var gradientDir: String {
        let g = str("gradientDir")
        return ["diagonal", "vertical", "horizontal", "mesh"].contains(g) ? g : "diagonal"
    }
    var bgPattern: String {
        let p = str("bgPattern")
        return ["grain", "dots", "grid", "stripes", "waves", "paper", "blobs"].contains(p) ? p : ""
    }
    var bgOpacity: Double {
        let o = WKElement(raw).num("bgOpacity", 1)
        return (o >= 0.1 && o <= 1) ? o : 1
    }
    var fitSize: String? { let f = str("fitSize"); return f.isEmpty ? nil : f }
    var lockStyle: String { str("lockStyle") == "circle" ? "circle" : "rect" }
    var customColors: [String]? {
        let c = WKElement(raw).strings("customColors")
        return (c.count == 2 && c.allSatisfy { WKColor.isHex($0) }) ? c : nil
    }
    var themeColors: [String] {
        if themeID == "custom", let c = customColors { return c }
        return WKData.themes[themeID] ?? WKData.themes["midnight"]!
    }
    var elements: [WKElement] {
        return (raw["canvasElements"] as? [Any] ?? []).compactMap { ($0 as? [String: Any]).map(WKElement.init) }
    }
    var apps: [WKElement] {
        return (raw["apps"] as? [Any] ?? []).compactMap { ($0 as? [String: Any]).map(WKElement.init) }
    }
    var lockRows: [WKElement] {
        let rows = (raw["lockRows"] as? [Any] ?? []).compactMap { ($0 as? [String: Any]).map(WKElement.init) }
        return rows.isEmpty ? [WKElement(["kind": "time"]), WKElement(["kind": "date"])] : Array(rows.prefix(3))
    }
    var launcherStyle: WKElement { WKElement(raw["launcherStyle"] as? [String: Any] ?? [:]) }
    var playlist: [String: String] {
        var out: [String: String] = [:]
        for (k, v) in raw["playlist"] as? [String: Any] ?? [:] { if let s = v as? String { out[k] = s } }
        return out
    }

    func str(_ key: String) -> String { WKElement(raw).str(key) }

    /// v113 per-size layouts: a design can carry the layout the user authored
    /// for a given family. Applied once so every element shares the same
    /// coordinates for that size. Returns a copy; the stored design is untouched.
    func applyingSizeLayout(_ family: String) -> WKDesign {
        guard let sizes = raw["sizes"] as? [String: Any],
              let snaps = sizes[family] as? [Any],
              fitSize != family else { return self }
        var byId: [String: [String: Any]] = [:]
        for s in snaps { if let d = s as? [String: Any], let id = d["id"] as? String { byId[id] = d } }
        var copy = raw
        var els = (raw["canvasElements"] as? [Any] ?? []).compactMap { $0 as? [String: Any] }
        for i in 0..<els.count {
            guard let id = els[i]["id"] as? String, let sv = byId[id] else { continue }
            if let x = sv["x"] as? NSNumber { els[i]["x"] = x }
            if let y = sv["y"] as? NSNumber { els[i]["y"] = y }
            if let v = sv["size"] as? NSNumber { els[i]["size"] = v }
            if let v = sv["w"] as? NSNumber { els[i]["w"] = v }
            if let v = sv["h"] as? NSNumber { els[i]["h"] = v }
        }
        copy["canvasElements"] = els
        copy.removeValue(forKey: "sizes")
        return WKDesign(copy)
    }

    // MARK: decoding

    static func decodeArray(_ data: Data) -> [WKDesign] {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return [] }
        if let arr = obj as? [Any] { return arr.compactMap { ($0 as? [String: Any]).map(WKDesign.init) } }
        if let one = obj as? [String: Any] { return [WKDesign(one)] }
        return []
    }
    static func decode(_ data: Data) -> WKDesign? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return WKDesign(obj)
    }
    func encoded() -> Data? {
        return try? JSONSerialization.data(withJSONObject: raw)
    }
}

enum WKColor {
    static func isHex(_ s: String) -> Bool {
        guard s.count == 7, s.hasPrefix("#") else { return false }
        return s.dropFirst().allSatisfy { $0.isHexDigit }
    }
    static func rgb(_ hex: String) -> (Double, Double, Double) {
        guard isHex(hex), let v = UInt32(hex.dropFirst(), radix: 16) else { return (1, 1, 1) }
        return (Double((v >> 16) & 255) / 255, Double((v >> 8) & 255) / 255, Double(v & 255) / 255)
    }
    static func color(_ hex: String, _ alpha: Double = 1) -> UIColor {
        let c = rgb(hex)
        return UIColor(red: c.0, green: c.1, blue: c.2, alpha: CGFloat(max(0, min(1, alpha))))
    }
    static func lerp(_ a: String, _ b: String, _ t: Double) -> UIColor {
        let pa = rgb(a), pb = rgb(b)
        let k = max(0, min(1, t))
        return UIColor(red: pa.0 + (pb.0 - pa.0) * k, green: pa.1 + (pb.1 - pa.1) * k, blue: pa.2 + (pb.2 - pa.2) * k, alpha: 1)
    }
}

@inline(__always) func clamp(_ v: Double, _ lo: Double, _ hi: Double) -> Double { return min(max(v, lo), hi) }
