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
        AppIntentConfiguration(
            kind: kind,
            intent: SelectDesignIntent.self,
            provider: DesignProvider()
        ) { entry in
            DesignWidgetView(entry: entry)
        }
        .configurationDisplayName("WidgetKing")
        .description("Show one of your custom widget designs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct DesignWidgetView: View {
    let entry: DesignEntry

    var body: some View {
        WidgetRenderView(design: entry.design, date: entry.date)
            .containerBackground(for: .widget) {
                entry.design.theme.gradient
            }
    }
}
