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
        r.bakeClocks = false
        r.stickers = { WKAssets.stockArt($0) }
        r.appIcons = { WKIconCache.cached($0) }
        r.wallpaper = { design, fam in WKWallpaper.slice(for: design, family: fam, screenHeightPx: Double(UIScreen.main.nativeBounds.height)) }
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

    /// Freestyle clock elements, laid out for this family, drawn as live
    /// SwiftUI time text over the baked image — they tick on their own.
    func liveClocks(_ size: CGSize) -> [(WKElement, CGFloat)] {
        guard entry.design.kind == "freestyle", !wkFamily.isAccessory else { return [] }
        let laid = entry.design.applyingSizeLayout(wkFamily.rawValue)
        let s = min(size.width, size.height) / 158
        return laid.elements.filter { $0.kind == "clock" }.map { ($0, s) }
    }

    var body: some View {
        GeometryReader { geo in
            let image = renderer.render(entry.design, family: wkFamily, pointSize: geo.size)
            ZStack(alignment: .topLeading) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: geo.size.width, height: geo.size.height)
                ForEach(Array(liveClocks(geo.size).enumerated()), id: \.offset) { item in
                    let el = item.element.0
                    let fs = CGFloat(el.size) * item.element.1
                    Text(entry.date, style: .time)
                        .font(Font(renderer.font(el.font ?? entry.design.fontStyle, fs, bold: el.bold)))
                        .foregroundColor(Color(WKColor.color(el.colorHex, el.opacity)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .frame(width: geo.size.width, alignment: .center)
                        .position(x: CGFloat(el.x) * geo.size.width, y: CGFloat(el.y) * geo.size.height)
                }
            }
        }
        .widgetURL(URL(string: entry.design.tapUrl))
        .containerBackground(for: .widget) { Color.clear }
    }
}
