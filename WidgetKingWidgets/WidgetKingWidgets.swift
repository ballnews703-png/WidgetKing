import WidgetKit
import SwiftUI

@main
struct WidgetKingWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WidgetKingWidget()
    }
}

struct WidgetKingWidget: Widget {
    let kind = "WidgetKingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectDesignIntent.self, provider: DesignProvider()) { entry in
            DesignWidgetView(entry: entry)
        }
        .configurationDisplayName("WidgetKing")
        .description("Show one of your WidgetKing designs.")
        // iOS 27's systemExtraLargePortrait joins this list the day the CI
        // runner's Xcode ships an SDK that names it; the renderer already
        // draws at any size (see GeometryReader below).
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
        .contentMarginsDisabled()
    }
}

/// Paints the design with the native renderer at the widget's real size, so
/// every family (including ones newer than this build) gets a pixel-exact
/// image, then lets WidgetKit place it.
struct DesignWidgetView: View {
    let entry: DesignEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.displayScale) private var displayScale

    var wkFamily: WKFamily {
        switch family {
        case .systemSmall: return .small
        case .systemMedium: return .medium
        case .systemLarge: return .large
        case .systemExtraLarge: return .extraLarge
        case .accessoryRectangular: return .accessoryRectangular
        case .accessoryCircular: return .accessoryCircular
        case .accessoryInline: return .accessoryInline
        @unknown default: return .extraLargePortrait
        }
    }

    var renderer: WKRenderer {
        var r = WKRenderer(live: entry.live)
        r.now = entry.date
        r.scale = displayScale
        r.lockBackdrop = false
        r.stickers = { WKAssets.stockArt($0) }
        r.resolvePlaylist = { design, now in
            let hr = Calendar.current.component(.hour, from: now)
            let slot = hr >= 5 && hr < 11 ? "morning" : hr >= 11 && hr < 16 ? "midday" : hr >= 16 && hr < 21 ? "evening" : "night"
            let map = design.playlist
            let order = [slot, "morning", "midday", "evening", "night"]
            for key in order { if let id = map[key], !id.isEmpty, let d = WKStore.design(id: id) { return d } }
            return nil
        }
        return r
    }

    var body: some View {
        GeometryReader { geo in
            let image = renderer.render(entry.design, family: wkFamily, pointSize: geo.size)
            Image(uiImage: image)
                .resizable()
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .widgetURL(URL(string: entry.design.tapUrl))
        .containerBackground(for: .widget) { Color.clear }
    }
}
