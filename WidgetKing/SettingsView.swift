import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(ClaudeService.apiKeyDefaultsKey) private var apiKey = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Anthropic API key (sk-ant-…)", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Claude AI")
                } footer: {
                    Text("""
                    With a key, the Magic tab sends your widget idea to Claude \
                    (\(ClaudeService.model)) to design the widget. Requests go \
                    directly from your phone to the Anthropic API, and the key \
                    is stored only on this device. Without a key, widgets are \
                    built by a simpler on-device parser. Get a key at \
                    platform.claude.com.
                    """)
                }

                Section("Sharing") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Widgets are interchangeable")
                            .font(.subheadline.weight(.semibold))
                        Text("""
                        Long-press any design in My Widgets to share it as a \
                        .widgetking file — friends can import it from the same \
                        menu. On your Home Screen, long-press a WidgetKing \
                        widget → Edit Widget to swap which design it shows.
                        """)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
