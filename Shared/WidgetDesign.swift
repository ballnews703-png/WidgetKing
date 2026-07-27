import SwiftUI

/// The kinds of widgets a user can build.
enum WidgetKind: String, Codable, CaseIterable, Identifiable {
    case clock = "Clock"
    case date = "Date"
    case countdown = "Countdown"
    case quote = "Quote"
    case note = "Note"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .clock: return "clock.fill"
        case .date: return "calendar"
        case .countdown: return "hourglass"
        case .quote: return "quote.opening"
        case .note: return "note.text"
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
