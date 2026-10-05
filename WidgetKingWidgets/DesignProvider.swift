import WidgetKit
import SwiftUI

struct DesignEntry: TimelineEntry {
    let date: Date
    let design: WKDesign
    let live: WKLiveData
}

struct DesignProvider: AppIntentTimelineProvider {
    static let placeholderDesign = WKDesign(["name": "WidgetKing", "kind": "clock", "themeID": "royal", "fontStyle": "rounded", "textColorHex": "#FFFFFF"])
    static let emptyDesign = WKDesign(["name": "WidgetKing", "kind": "note", "themeID": "midnight", "fontStyle": "rounded", "textColorHex": "#FFFFFF",
                                       "primaryText": "Open WidgetKing and save a design — it shows up here."])

    func placeholder(in context: Context) -> DesignEntry {
        DesignEntry(date: .now, design: Self.placeholderDesign, live: .sample)
    }

    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> DesignEntry {
        let design = resolveDesign(for: configuration)
        return DesignEntry(date: .now, design: design, live: context.isPreview ? .sample : .offline)
    }

    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<DesignEntry> {
        let design = resolveDesign(for: configuration)
        let live = await WKLiveFetch.liveData(for: design)
        let now = Date()
        let cal = Calendar.current
        if Self.showsClock(design) {
            // One entry per minute for the next hour: the baked time text stays
            // right between refreshes (native live clock overlays are next).
            let start = cal.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? now
            var entries = [DesignEntry(date: now, design: design, live: live)]
            for minute in 0..<60 {
                entries.append(DesignEntry(date: start.addingTimeInterval(TimeInterval(minute * 60)), design: design, live: live))
            }
            return Timeline(entries: entries, policy: .atEnd)
        }
        let refresh = Self.usesLiveData(design) ? now.addingTimeInterval(15 * 60)
            : (cal.startOfDay(for: now).addingTimeInterval(24 * 60 * 60))
        return Timeline(entries: [DesignEntry(date: now, design: design, live: live)], policy: .after(refresh))
    }

    static func showsClock(_ design: WKDesign) -> Bool {
        if design.kind == "clock" { return true }
        if design.kind == "lock" { return design.lockRows.contains { $0.kind == "time" } }
        return design.elements.contains { $0.kind == "clock" || $0.kind == "worldclock" }
    }

    static func usesLiveData(_ design: WKDesign) -> Bool {
        let liveKinds: Set<String> = ["weather", "calendar", "reminders", "reminder", "news", "stock", "astro", "sleeper", "sleeperlogo", "battery", "greeting"]
        if design.kind == "battery" { return true }
        if design.kind == "lock" { return design.lockRows.contains { liveKinds.contains($0.kind) } }
        return design.elements.contains { liveKinds.contains($0.kind) }
    }

    private func resolveDesign(for configuration: SelectDesignIntent) -> WKDesign {
        let designs = WKStore.designs()
        if let id = configuration.design?.id, let match = designs.first(where: { $0.id == id }) { return match }
        return designs.first ?? Self.emptyDesign
    }
}
