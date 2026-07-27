import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: DesignStore
    @State private var editingDesign: WidgetDesign?

    var body: some View {
        NavigationStack {
            Group {
                if store.designs.isEmpty {
                    emptyState
                } else {
                    designList
                }
            }
            .navigationTitle("WidgetKing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingDesign = WidgetDesign()
                    } label: {
                        Label("New Widget", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editingDesign) { design in
                NavigationStack {
                    DesignEditorView(design: design)
                }
            }
        }
    }

    private var designList: some View {
        List {
            Section {
                ForEach(store.designs) { design in
                    Button {
                        editingDesign = design
                    } label: {
                        DesignRow(design: design)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { store.delete(at: $0) }
            }

            Section("Add to your Home Screen") {
                VStack(alignment: .leading, spacing: 8) {
                    instruction(1, "Touch and hold your Home Screen, then tap Edit → Add Widget.")
                    instruction(2, "Search for “WidgetKing” and pick a size.")
                    instruction(3, "Touch and hold the widget → Edit Widget → choose your design.")
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func instruction(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor.opacity(0.2)))
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Widgets Yet", systemImage: "square.grid.2x2")
        } description: {
            Text("Tap + to design your first widget. Pick a style, theme, and font — then add it to your Home Screen.")
        } actions: {
            Button("Create a Widget") {
                editingDesign = WidgetDesign()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct DesignRow: View {
    let design: WidgetDesign

    var body: some View {
        HStack(spacing: 14) {
            WidgetRenderView(design: design, date: .now)
                .padding(14)
                .frame(width: 158, height: 158)
                .background(design.theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .scaleEffect(60 / 158)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text(design.name)
                    .font(.headline)
                Label(design.kind.rawValue, systemImage: design.kind.symbolName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .environmentObject(DesignStore.shared)
}
