import SwiftUI

/// Drag-and-drop editor for Freestyle widgets: tap the palette to drop
/// elements onto the widget canvas, then drag them into place and tweak
/// size, color, and content.
struct CanvasEditorView: View {
    @Binding var draft: WidgetDesign
    let canvasSize: CGSize

    @State private var selectedID: UUID?

    private let symbolOptions = [
        "star.fill", "heart.fill", "bolt.fill", "moon.stars.fill",
        "sun.max.fill", "cloud.fill", "leaf.fill", "flame.fill",
        "sparkles", "music.note", "pawprint.fill", "crown.fill",
    ]

    var body: some View {
        VStack(spacing: 14) {
            canvas
                .frame(maxWidth: .infinity, alignment: .center)
            palette
            if let index = selectedIndex {
                inspector(for: index)
            } else {
                Text("Tap a chip to add an element, then drag it anywhere. Tap an element to edit it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
    }

    private var selectedIndex: Int? {
        guard let selectedID else { return nil }
        return draft.canvasElements.firstIndex { $0.id == selectedID }
    }

    // MARK: - Canvas

    private var canvas: some View {
        ZStack {
            draft.theme.gradient
            GeometryReader { geo in
                let scale = min(geo.size.width, geo.size.height) / 158
                ForEach(draft.canvasElements) { element in
                    CanvasElementContent(
                        element: element,
                        fontDesign: draft.fontStyle.design,
                        date: .now,
                        scale: scale
                    )
                    .padding(4)
                    .background {
                        if element.id == selectedID {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(.white.opacity(0.9), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        }
                    }
                    .position(x: element.x * geo.size.width, y: element.y * geo.size.height)
                    .onTapGesture { selectedID = element.id }
                    .gesture(dragGesture(for: element.id, in: geo.size))
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    private func dragGesture(for elementID: UUID, in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                selectedID = elementID
                guard let index = draft.canvasElements.firstIndex(where: { $0.id == elementID }) else { return }
                draft.canvasElements[index].x = min(max(value.location.x / size.width, 0), 1)
                draft.canvasElements[index].y = min(max(value.location.y / size.height, 0), 1)
            }
    }

    // MARK: - Palette

    private var palette: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CanvasElementKind.allCases) { kind in
                    Button {
                        var element = CanvasElement.makeNew(kind)
                        element.x = 0.5
                        element.y = 0.5
                        draft.canvasElements.append(element)
                        selectedID = element.id
                    } label: {
                        Label(kind.rawValue, systemImage: kind.symbolName)
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Inspector

    @ViewBuilder
    private func inspector(for index: Int) -> some View {
        let element = draft.canvasElements[index]

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(element.kind.rawValue, systemImage: element.kind.symbolName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive) {
                    draft.canvasElements.remove(at: index)
                    selectedID = nil
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.caption)
                }
            }

            if element.kind == .text || element.kind == .emoji {
                TextField(
                    element.kind == .emoji ? "Emoji" : "Text",
                    text: $draft.canvasElements[index].text
                )
                .textFieldStyle(.roundedBorder)
            }

            if element.kind == .symbol {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                    ForEach(symbolOptions, id: \.self) { symbol in
                        Button {
                            draft.canvasElements[index].symbolName = symbol
                        } label: {
                            Image(systemName: symbol)
                                .frame(width: 34, height: 34)
                                .background {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(element.symbolName == symbol
                                              ? Color.accentColor.opacity(0.25)
                                              : Color.secondary.opacity(0.1))
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Text("Size")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $draft.canvasElements[index].size, in: 8...80)
            }

            ColorPicker(
                "Color",
                selection: Binding(
                    get: { Color(hex: draft.canvasElements[index].colorHex) },
                    set: { draft.canvasElements[index].colorHex = $0.hexString }
                ),
                supportsOpacity: false
            )
            .font(.caption)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
    }
}
