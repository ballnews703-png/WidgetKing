import SwiftUI

/// Full editor for a single widget design, with a live preview that uses the
/// exact same rendering code as the Home Screen widget.
struct DesignEditorView: View {
    @EnvironmentObject private var store: DesignStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft: WidgetDesign
    @State private var previewSize: PreviewSize = .small
    private let isNew: Bool

    init(design: WidgetDesign) {
        _draft = State(initialValue: design)
        isNew = !DesignStore.shared.designs.contains { $0.id == design.id }
    }

    var body: some View {
        Form {
            Section {
                preview
                Picker("Preview size", selection: $previewSize) {
                    ForEach(PreviewSize.allCases) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Widget") {
                TextField("Name", text: $draft.name)
                Picker("Type", selection: $draft.kind) {
                    ForEach(WidgetKind.allCases) { kind in
                        Label(kind.rawValue, systemImage: kind.symbolName).tag(kind)
                    }
                }
            }

            kindFields

            Section("Theme") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(WidgetTheme.presets) { theme in
                        Button {
                            draft.themeID = theme.id
                        } label: {
                            Circle()
                                .fill(theme.gradient)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if draft.themeID == theme.id {
                                        Circle().strokeBorder(.primary, lineWidth: 3)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.name)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Style") {
                Picker("Font", selection: $draft.fontStyle) {
                    ForEach(FontStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                ColorPicker("Text color", selection: textColorBinding, supportsOpacity: false)
            }
        }
        .navigationTitle(isNew ? "New Widget" : "Edit Widget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.save(draft)
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private var preview: some View {
        HStack {
            Spacer()
            TimelineView(.everyMinute) { context in
                WidgetRenderView(design: draft, date: context.date)
                    .padding(16)
                    .frame(width: previewSize.dimensions.width, height: previewSize.dimensions.height)
                    .background(draft.theme.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .animation(.snappy, value: draft)
    }

    @ViewBuilder
    private var kindFields: some View {
        switch draft.kind {
        case .clock, .date:
            EmptyView()
        case .countdown:
            Section("Countdown") {
                TextField("Event title", text: $draft.primaryText)
                DatePicker("Date", selection: $draft.targetDate, displayedComponents: .date)
            }
        case .quote:
            Section("Quote") {
                TextField("Quote", text: $draft.primaryText, axis: .vertical)
                    .lineLimit(2...5)
                TextField("Author (optional)", text: $draft.secondaryText)
            }
        case .note:
            Section("Note") {
                TextField("Your text", text: $draft.primaryText, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }

    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: draft.textColorHex) },
            set: { draft.textColorHex = $0.hexString }
        )
    }
}

private enum PreviewSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"

    var id: String { rawValue }

    var dimensions: CGSize {
        switch self {
        case .small: return CGSize(width: 158, height: 158)
        case .medium: return CGSize(width: 338, height: 158)
        case .large: return CGSize(width: 338, height: 354)
        }
    }
}

#Preview {
    NavigationStack {
        DesignEditorView(design: WidgetDesign())
    }
    .environmentObject(DesignStore.shared)
}
