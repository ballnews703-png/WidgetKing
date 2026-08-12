import Foundation

enum ClaudeServiceError: LocalizedError {
    case missingAPIKey
    case badResponse(String)
    case refused

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "No Claude API key configured."
        case .badResponse(let message): return message
        case .refused: return "Claude declined to build this widget."
        }
    }
}

/// Calls the Anthropic Messages API to turn a plain-English idea into a
/// widget design. Uses structured outputs so the reply is guaranteed to be
/// valid JSON matching our widget spec.
enum ClaudeService {
    static let model = "claude-opus-5"
    static let apiKeyDefaultsKey = "claude_api_key"
    private static let apiKeyAccount = "anthropic-api-key"

    /// The key lives in the Keychain. Early builds kept it in UserDefaults
    /// (unencrypted, included in backups); the first read migrates any legacy
    /// copy into the Keychain and deletes the plain-text original.
    static var apiKey: String {
        get {
            if let legacy = UserDefaults.standard.string(forKey: apiKeyDefaultsKey),
               !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                KeychainStore.write(legacy.trimmingCharacters(in: .whitespacesAndNewlines),
                                    account: apiKeyAccount)
                UserDefaults.standard.removeObject(forKey: apiKeyDefaultsKey)
            }
            return KeychainStore.read(apiKeyAccount)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        set {
            KeychainStore.write(newValue.trimmingCharacters(in: .whitespacesAndNewlines),
                                account: apiKeyAccount)
        }
    }

    static var isConfigured: Bool { !apiKey.isEmpty }

    static func generateDesign(from idea: String) async throws -> WidgetDesign {
        guard isConfigured else { throw ClaudeServiceError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 16000,
            "system": systemPrompt,
            "output_config": ["format": ["type": "json_schema", "schema": specSchema]],
            "messages": [["role": "user", "content": idea]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ClaudeServiceError.badResponse("No response from the Claude API.")
        }
        guard http.statusCode == 200 else {
            let apiError = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data)
            throw ClaudeServiceError.badResponse(
                apiError?.error.message ?? "Claude API returned status \(http.statusCode)."
            )
        }

        let message = try JSONDecoder().decode(MessageResponse.self, from: data)
        guard message.stopReason != "refusal" else { throw ClaudeServiceError.refused }
        guard let text = message.content.first(where: { $0.type == "text" })?.text,
              let specData = text.data(using: .utf8)
        else {
            throw ClaudeServiceError.badResponse("Claude returned an empty response.")
        }

        let spec = try JSONDecoder().decode(WidgetSpec.self, from: specData)
        return spec.asDesign()
    }

    // MARK: - Prompt & schema

    private static var systemPrompt: String {
        let themes = WidgetTheme.presets.map { "\($0.id) (\($0.name))" }.joined(separator: ", ")
        let today = ISO8601DateFormatter.dateOnly.string(from: .now)
        return """
        You design iPhone Home Screen widgets for the WidgetKing app. The user \
        describes a widget in plain language; you return a widget spec.

        Widget kinds: clock (time + date), date (big day of month), countdown \
        (days until an event), quote (a quote with optional author), note \
        (short free text).

        Available themes: \(themes). Pick the theme that best matches the mood \
        or colors the user mentions. The "paper" theme is light, so use a dark \
        textColorHex like #333333 with it; all other themes are dark, so use a \
        light color like #FFFFFF unless the user asks for something specific.

        Today's date is \(today). For countdowns, resolve relative dates \
        ("in 30 days", "next Christmas") to an absolute future date. Keep the \
        name short (max 24 characters). Fill unused fields with empty strings.
        """
    }

    private static var specSchema: [String: Any] {
        [
            "type": "object",
            "properties": [
                "name": ["type": "string", "description": "Short widget name, max 24 characters"],
                "kind": ["type": "string", "enum": ["clock", "date", "countdown", "quote", "note"]],
                "themeID": ["type": "string", "enum": WidgetTheme.presets.map(\.id)],
                "fontStyle": ["type": "string", "enum": ["classic", "rounded", "serif", "mono"]],
                "textColorHex": ["type": "string", "description": "#RRGGBB text color readable on the chosen theme"],
                "primaryText": ["type": "string", "description": "Quote text, note text, or countdown event title; empty if unused"],
                "secondaryText": ["type": "string", "description": "Quote author; empty if unused"],
                "targetDate": ["type": "string", "description": "yyyy-MM-dd for countdowns; empty string otherwise"],
            ],
            "required": [
                "name", "kind", "themeID", "fontStyle", "textColorHex",
                "primaryText", "secondaryText", "targetDate",
            ],
            "additionalProperties": false,
        ]
    }

    // MARK: - Wire types

    private struct APIErrorEnvelope: Decodable {
        struct APIError: Decodable { let message: String }
        let error: APIError
    }

    private struct MessageResponse: Decodable {
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }

        let content: [ContentBlock]
        let stopReason: String?

        enum CodingKeys: String, CodingKey {
            case content
            case stopReason = "stop_reason"
        }
    }

    private struct WidgetSpec: Decodable {
        let name: String
        let kind: String
        let themeID: String
        let fontStyle: String
        let textColorHex: String
        let primaryText: String
        let secondaryText: String
        let targetDate: String

        func asDesign() -> WidgetDesign {
            var design = WidgetDesign()
            design.name = name.isEmpty ? "My Widget" : name
            design.kind = WidgetKind.allCases.first {
                $0.rawValue.lowercased() == kind.lowercased()
            } ?? .note
            if WidgetTheme.presets.contains(where: { $0.id == themeID }) {
                design.themeID = themeID
            }
            design.fontStyle = FontStyle.allCases.first {
                $0.rawValue.lowercased() == fontStyle.lowercased()
            } ?? .rounded
            if !textColorHex.isEmpty {
                design.textColorHex = textColorHex
            }
            design.primaryText = primaryText
            design.secondaryText = secondaryText
            if !targetDate.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                if let date = formatter.date(from: targetDate) {
                    design.targetDate = date
                }
            }
            return design
        }
    }
}

private extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
