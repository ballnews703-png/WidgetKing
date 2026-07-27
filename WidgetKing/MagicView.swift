import SwiftUI

/// "Type an idea, get a widget" — describe a widget in plain English and it
/// gets auto-built, with Claude when configured or the on-device parser
/// otherwise.
struct MagicView: View {
    @EnvironmentObject private var store: DesignStore

    @State private var idea = ""
    @State private var isGenerating = false
    @State private var result: MagicResult?
    @State private var editingDesign: WidgetDesign?
    @State private var showingSettings = false
    @State private var savedBanner = false

    private let examples = [
        "Countdown to my birthday on October 12",
        "A sunset quote widget: “Dream big” — Mom",
        "Minimal dark clock with a serif font",
        "Note that says Drink water! in mint green",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    exampleChips
                    if isGenerating {
                        generatingCard
                    } else if let result {
                        resultCard(result)
                    }
                }
                .padding()
            }
            .navigationTitle("Magic")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { inputBar }
            .alert("Saved! Find it in My Widgets.", isPresented: $savedBanner) {
                Button("OK") {}
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(item: $editingDesign) { design in
                NavigationStack {
                    DesignEditorView(design: design)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Describe your widget")
                .font(.title2.bold())
            Text(ClaudeService.isConfigured
                 ? "Powered by Claude — say anything and I'll build it."
                 : "Type an idea and I'll build it. Add a Claude API key in Settings for smarter results.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var exampleChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(examples, id: \.self) { example in
                Button {
                    idea = example
                } label: {
                    Text(example)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generatingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
            Text(ClaudeService.isConfigured ? "Asking Claude to design your widget…" : "Building your widget…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func resultCard(_ result: MagicResult) -> some View {
        VStack(spacing: 14) {
            WidgetRenderView(design: result.design, date: .now)
                .padding(16)
                .frame(width: 158, height: 158)
                .background(result.design.theme.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)

            VStack(spacing: 4) {
                Text(result.design.name)
                    .font(.headline)
                Label(
                    result.usedAI ? "Designed by Claude" : "Built on-device",
                    systemImage: result.usedAI ? "sparkles" : "cpu"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                if let note = result.note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }

            HStack(spacing: 12) {
                Button {
                    store.save(result.design)
                    self.result = nil
                    idea = ""
                    savedBanner = true
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    editingDesign = result.design
                    self.result = nil
                } label: {
                    Label("Customize", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button(role: .destructive) {
                    self.result = nil
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.secondary.opacity(0.08)))
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("A widget that…", text: $idea, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)
                .disabled(isGenerating)

            Button {
                generate()
            } label: {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .frame(width: 44, height: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isGenerating || idea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func generate() {
        let text = idea.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        isGenerating = true
        result = nil
        Task {
            let composed = await MagicComposer.compose(idea: text)
            await MainActor.run {
                result = composed
                isGenerating = false
            }
        }
    }
}

#Preview {
    MagicView()
        .environmentObject(DesignStore.shared)
}
