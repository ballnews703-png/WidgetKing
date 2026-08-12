import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    // The key lives in the Keychain (via ClaudeService.apiKey), which
    // @AppStorage can't back — load on appear, save on every edit.
    @State private var apiKey = ""
    @State private var selectedIcon: String? = UIApplication.shared.alternateIconName

    // Alternate icons bundled with the app. nil = the primary (royal) icon.
    private let iconChoices: [(name: String?, label: String, colors: [Color])] = [
        (nil, "Royal", [Color(red: 0.56, green: 0.36, blue: 0.94), Color(red: 0.48, green: 0.25, blue: 0.91)]),
        ("AppIcon-noir", "Noir", [Color(red: 0.11, green: 0.11, blue: 0.13), Color(red: 0.06, green: 0.06, blue: 0.08)]),
        ("AppIcon-glass", "Glass", [Color(red: 0.73, green: 0.78, blue: 0.85), Color(red: 0.56, green: 0.64, blue: 0.75)]),
        ("AppIcon-cream", "Cream", [Color(red: 0.96, green: 0.94, blue: 0.89), Color(red: 0.93, green: 0.89, blue: 0.81)]),
        ("AppIcon-ocean", "Ocean", [Color(red: 0.12, green: 0.49, blue: 0.78), Color(red: 0.08, green: 0.72, blue: 0.68)]),
        ("AppIcon-sunset", "Sunset", [Color(red: 0.95, green: 0.45, blue: 0.37), Color(red: 0.91, green: 0.34, blue: 0.55)]),
        ("AppIcon-neon", "Neon", [Color(red: 0.04, green: 0.04, blue: 0.08), Color(red: 0.49, green: 0.98, blue: 0.89)]),
        ("AppIcon-pastel", "Pastel", [Color(red: 0.98, green: 0.85, blue: 0.90), Color(red: 0.91, green: 0.84, blue: 0.97)]),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Anthropic API key (sk-ant-…)", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !apiKey.isEmpty {
                        Button("Clear key from this device", role: .destructive) {
                            apiKey = ""
                        }
                    }
                } header: {
                    Text("Claude AI")
                } footer: {
                    Text("""
                    With a key, the Magic tab sends your widget idea to Claude \
                    (\(ClaudeService.model)) to design the widget. Requests go \
                    directly from your phone to the Anthropic API, and the key \
                    is stored only in this device's Keychain. Without a key, \
                    widgets are built by a simpler on-device parser. Get a key \
                    at platform.claude.com.
                    """)
                }

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(iconChoices, id: \.label) { choice in
                            Button {
                                setIcon(choice.name)
                            } label: {
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(LinearGradient(colors: choice.colors,
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                        .frame(width: 48, height: 48)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(selectedIcon == choice.name ? Color.accentColor : .clear,
                                                              lineWidth: 3)
                                        }
                                        .overlay {
                                            if selectedIcon == choice.name {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                                    .shadow(radius: 2)
                                            }
                                        }
                                    Text(choice.label)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("App icon")
                } footer: {
                    Text("Same crown, your color — the icon switches instantly.")
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

                Section {
                    Link("Privacy Policy",
                         destination: URL(string: "https://ballnews703-png.github.io/WidgetKing/privacy.html")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { apiKey = ClaudeService.apiKey }
            .onChange(of: apiKey) { _, newValue in
                ClaudeService.apiKey = newValue
            }
        }
    }

    private func setIcon(_ name: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil {
                selectedIcon = name
            }
        }
    }
}

#Preview {
    SettingsView()
}
