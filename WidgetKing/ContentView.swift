import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    var body: some View {
        TabView {
            MyWidgetsView()
                .tabItem { Label("My Widgets", systemImage: "square.grid.2x2") }
            MagicView()
                .tabItem { Label("Magic", systemImage: "wand.and.stars") }
        }
    }
}

struct MyWidgetsView: View {
    @EnvironmentObject private var store: DesignStore
    @State private var editingDesign: WidgetDesign?
    @State private var showingSettings = false
    @State private var showingImporter = false
    @State private var importError: String?

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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Design", systemImage: "square.and.arrow.down")
                    }
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
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        let design = try DesignShare.importDesign(from: url)
                        store.save(design)
                    } catch {
                        importError = "That file couldn't be read as a WidgetKing design."
                    }
                case .failure:
                    break
                }
            }
            .alert("Import failed", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
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
                    .contextMenu { contextMenu(for: design) }
                }
                .onDelete { store.delete(at: $0) }
            }

            Section("Add to your Home Screen") {
                VStack(alignment: .leading, spacing: 8) {
                    instruction(1, "Touch and hold your Home Screen, then tap Edit → Add Widget.")
                    instruction(2, "Search for “WidgetKing” and pick a size.")
                    instruction(3, "Touch and hold the widget → Edit Widget → choose your design. Widgets are interchangeable — swap the design any time.")
                }
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func contextMenu(for design: WidgetDesign) -> some View {
        if let url = try? DesignShare.exportURL(for: design) {
            ShareLink(item: url) {
                Label("Share Design", systemImage: "square.and.arrow.up")
            }
        }
        Button {
            var copy = design
            copy.id = UUID()
            copy.name += " Copy"
            store.save(copy)
        } label: {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        Button(role: .destructive) {
            if let index = store.designs.firstIndex(where: { $0.id == design.id }) {
                store.delete(at: IndexSet(integer: index))
            }
        } label: {
            Label("Delete", systemImage: "trash")
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
            Text("Tap + to design a widget by hand, or head to the Magic tab and just describe the widget you want.")
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
