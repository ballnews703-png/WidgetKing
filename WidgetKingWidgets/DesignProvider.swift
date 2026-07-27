import WidgetKit
import SwiftUI

struct DesignEntry: TimelineEntry {
    let date: Date
    let design: WidgetDesign
}

struct DesignProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DesignEntry {
        DesignEntry(date: .now, design: .sample)
    }

    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> DesignEntry {
        DesignEntry(date: .now, design: resolveDesign(for: configuration))
    }

    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<DesignEntry> {
        let design = resolveDesign(for: configuration)
        let now = Date()
        let calendar = Calendar.current

        let showsLiveClock = design.kind == .clock
            || (design.kind == .freestyle && design.canvasElements.contains { $0.kind == .clock })

        if showsLiveClock {
            // One entry per minute for the next hour so the time stays fresh.
            let start = calendar.nextDate(
                after: now,
                matching: DateComponents(second: 0),
                matchingPolicy: .nextTime
            ) ?? now
            var entries = [DesignEntry(date: now, design: design)]
            for minute in 0..<60 {
                let entryDate = start.addingTimeInterval(TimeInterval(minute * 60))
                entries.append(DesignEntry(date: entryDate, design: design))
            }
            return Timeline(entries: entries, policy: .atEnd)
        }

        switch design.kind {
        case .date, .countdown, .freestyle:
            // Refresh just after midnight so the day rolls over correctly.
            let midnight = calendar.startOfDay(for: now).addingTimeInterval(60 * 60 * 24)
            return Timeline(entries: [DesignEntry(date: now, design: design)], policy: .after(midnight))

        case .quote, .note, .clock:
            let nextHour = now.addingTimeInterval(60 * 60)
            return Timeline(entries: [DesignEntry(date: now, design: design)], policy: .after(nextHour))
        }
    }

    private func resolveDesign(for configuration: SelectDesignIntent) -> WidgetDesign {
        let designs = DesignStore.loadDesigns()
        if let id = configuration.design?.id,
           let match = designs.first(where: { $0.id == id }) {
            return match
        }
        return designs.first ?? .sample
    }
}
