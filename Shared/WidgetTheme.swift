import SwiftUI

/// A background gradient preset.
struct WidgetTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let colorHexes: [String]

    var colors: [Color] { colorHexes.map { Color(hex: $0) } }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let presets: [WidgetTheme] = [
        WidgetTheme(id: "midnight", name: "Midnight", colorHexes: ["#232526", "#414345"]),
        WidgetTheme(id: "royal", name: "Royal", colorHexes: ["#5B2C98", "#8E44AD"]),
        WidgetTheme(id: "sunset", name: "Sunset", colorHexes: ["#FF512F", "#F09819"]),
        WidgetTheme(id: "ocean", name: "Ocean", colorHexes: ["#1A2980", "#26D0CE"]),
        WidgetTheme(id: "forest", name: "Forest", colorHexes: ["#134E5E", "#71B280"]),
        WidgetTheme(id: "candy", name: "Candy", colorHexes: ["#FC5C7D", "#6A82FB"]),
        WidgetTheme(id: "lava", name: "Lava", colorHexes: ["#870000", "#190A05"]),
        WidgetTheme(id: "gold", name: "Gold", colorHexes: ["#B8860B", "#FFD700"]),
        WidgetTheme(id: "berry", name: "Berry", colorHexes: ["#8E2DE2", "#4A00E0"]),
        WidgetTheme(id: "mist", name: "Mist", colorHexes: ["#606C88", "#3F4C6B"]),
        WidgetTheme(id: "mint", name: "Mint", colorHexes: ["#02AABD", "#00CDAC"]),
        WidgetTheme(id: "paper", name: "Paper", colorHexes: ["#F5F5F0", "#E4E0D8"]),
    ]
}

extension Color {
    /// Creates a color from a "#RRGGBB" or "RRGGBB" hex string.
    init(hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    /// Converts the color back to a "#RRGGBB" hex string.
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(round(r * 255)), Int(round(g * 255)), Int(round(b * 255))
        )
    }
}
