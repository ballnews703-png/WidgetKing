import SwiftUI

/// Renders a design's content. Used by the widget extension and for live
/// previews inside the app, so what you see while editing is exactly what
/// lands on the Home Screen.
struct WidgetRenderView: View {
    let design: WidgetDesign
    let date: Date

    var body: some View {
        content
            .foregroundStyle(design.textColor)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch design.kind {
        case .clock:
            VStack(spacing: 2) {
                Text(date, style: .time)
                    .font(styled(44, .bold))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(date, format: .dateTime.weekday(.wide).month().day())
                    .font(styled(13, .medium))
                    .opacity(0.85)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

        case .date:
            VStack(spacing: 0) {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(styled(15, .semibold))
                    .textCase(.uppercase)
                    .opacity(0.85)
                Text(date, format: .dateTime.day())
                    .font(styled(56, .heavy))
                    .minimumScaleFactor(0.4)
                Text(date, format: .dateTime.month(.wide))
                    .font(styled(15, .medium))
                    .opacity(0.85)
            }

        case .countdown:
            VStack(spacing: 4) {
                Text(title)
                    .font(styled(14, .semibold))
                    .opacity(0.85)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text("\(abs(daysUntilTarget))")
                    .font(styled(48, .heavy))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                Text(daysUntilTarget >= 0 ? "days to go" : "days ago")
                    .font(styled(12, .medium))
                    .opacity(0.75)
            }

        case .quote:
            VStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14, weight: .bold))
                    .opacity(0.6)
                Text(design.primaryText.isEmpty ? "Add a quote in WidgetKing" : design.primaryText)
                    .font(styled(17, .semibold))
                    .minimumScaleFactor(0.5)
                if !design.secondaryText.isEmpty {
                    Text("— \(design.secondaryText)")
                        .font(styled(12, .medium))
                        .opacity(0.75)
                }
            }
            .padding(.horizontal, 4)

        case .note:
            Text(design.primaryText.isEmpty ? "Add a note in WidgetKing" : design.primaryText)
                .font(styled(20, .bold))
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 4)
        }
    }

    private var title: String {
        design.primaryText.isEmpty ? design.name : design.primaryText
    }

    private var daysUntilTarget: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: design.targetDate)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private func styled(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: design.fontStyle.design)
    }
}
