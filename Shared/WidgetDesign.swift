import SwiftUI

/// The kinds of widgets a user can build.
enum WidgetKind: String, Codable, CaseIterable, Identifiable {
    case clock = "Clock"
    case date = "Date"
    case countdown = "Countdown"
    case quote = "Quote"
    case note = "Note"
    case freestyle = "Freestyle"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .clock: return "clock.fill"
        case .date: return "calendar"
        case .countdown: return "hourglass"
        case .quote: return "quote.opening"
        case .note: return "note.text"
        case .freestyle: return "hand.draw"
        }
    }
}

/// Font families the user can choose from.
enum FontStyle: String, Codable, CaseIterable, Identifiable {
    case classic = "Classic"
    case rounded = "Rounded"
    case serif = "Serif"
    case mono = "Mono"

    var id: String { rawValue }

    var design: Font.Design {
        switch self {
        case .classic: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .mono: return .monospaced
        }
    }
}

/// The building blocks available on the Freestyle drag-and-drop canvas.
enum CanvasElementKind: String, Codable, CaseIterable, Identifiable {
    case text = "Text"
    case clock = "Clock"
    case date = "Date"
    case emoji = "Emoji"
    case symbol = "Symbol"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .text: return "textformat"
        case .clock: return "clock"
        case .date: return "calendar"
        case .emoji: return "face.smiling"
        case .symbol: return "star"
        }
    }
}

/// One draggable element on a Freestyle widget. Position is normalized
/// (0...1) so the same layout scales to any widget size; `size` is the point
/// size on a reference 158pt (small widget) canvas.
struct CanvasElement: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: CanvasElementKind = .text
    var text = "Your text"
    var symbolName = "star.fill"
    var x: Double = 0.5
    var y: Double = 0.5
    var size: Double = 20
    var colorHex = "#FFFFFF"

    static func makeNew(_ kind: CanvasElementKind) -> CanvasElement {
        var element = CanvasElement()
        element.kind = kind
        switch kind {
        case .text:
            element.text = "Your text"
            element.size = 18
        case .clock:
            element.size = 34
        case .date:
            element.size = 14
        case .emoji:
            element.text = "✨"
            element.size = 30
        case .symbol:
            element.symbolName = "star.fill"
            element.size = 26
        }
        return element
    }

    static var starterElements: [CanvasElement] {
        var clock = CanvasElement.makeNew(.clock)
        clock.x = 0.5
        clock.y = 0.42
        var caption = CanvasElement.makeNew(.text)
        caption.text = "My Widget"
        caption.size = 13
        caption.x = 0.5
        caption.y = 0.66
        return [clock, caption]
    }
}

/// A single user-created widget design. Stored as JSON in the shared App Group
/// so both the app and the widget extension can read it.
struct WidgetDesign: Identifiable, Codable, Hashable {
    var id = UUID()
    var name = "My Widget"
    var kind: WidgetKind = .clock
    var themeID: String = WidgetTheme.presets[0].id
    var fontStyle: FontStyle = .rounded
    var textColorHex = "#FFFFFF"
    var primaryText = ""
    var secondaryText = ""
    var targetDate = Date().addingTimeInterval(60 * 60 * 24 * 30)
    var canvasElements: [CanvasElement] = []

    var theme: WidgetTheme {
        WidgetTheme.presets.first { $0.id == themeID } ?? WidgetTheme.presets[0]
    }

    var textColor: Color { Color(hex: textColorHex) }

    static var sample: WidgetDesign {
        var design = WidgetDesign()
        design.name = "WidgetKing"
        design.kind = .clock
        return design
    }
}

extension WidgetDesign {
    private enum CodingKeys: String, CodingKey {
        case id, name, kind, themeID, fontStyle, textColorHex
        case primaryText, secondaryText, targetDate, canvasElements
    }

    // Lenient decoding so designs saved by older app versions (without newer
    // fields like canvasElements) still load.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = WidgetDesign()
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? defaults.name
        kind = try container.decodeIfPresent(WidgetKind.self, forKey: .kind) ?? defaults.kind
        themeID = try container.decodeIfPresent(String.self, forKey: .themeID) ?? defaults.themeID
        fontStyle = try container.decodeIfPresent(FontStyle.self, forKey: .fontStyle) ?? defaults.fontStyle
        textColorHex = try container.decodeIfPresent(String.self, forKey: .textColorHex) ?? defaults.textColorHex
        primaryText = try container.decodeIfPresent(String.self, forKey: .primaryText) ?? ""
        secondaryText = try container.decodeIfPresent(String.self, forKey: .secondaryText) ?? ""
        targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate) ?? defaults.targetDate
        canvasElements = try container.decodeIfPresent([CanvasElement].self, forKey: .canvasElements) ?? []
    }
}
