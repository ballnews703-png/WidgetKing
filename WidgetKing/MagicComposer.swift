import Foundation

struct MagicResult {
    let design: WidgetDesign
    let usedAI: Bool
    let note: String?
}

/// Turns a plain-English idea into a widget design. Uses Claude when an API
/// key is configured; otherwise (or if the request fails) falls back to a
/// fast on-device keyword parser so the feature always works.
enum MagicComposer {
    static func compose(idea: String) async -> MagicResult {
        if ClaudeService.isConfigured {
            do {
                let design = try await ClaudeService.generateDesign(from: idea)
                return MagicResult(design: design, usedAI: true, note: nil)
            } catch {
                return MagicResult(
                    design: localParse(idea),
                    usedAI: false,
                    note: "Claude was unavailable (\(error.localizedDescription)) — built locally instead."
                )
            }
        }
        return MagicResult(design: localParse(idea), usedAI: false, note: nil)
    }

    // MARK: - On-device parser

    static func localParse(_ idea: String) -> WidgetDesign {
        let lowered = idea.lowercased()
        var design = WidgetDesign()

        // Theme from color/mood keywords.
        let themeKeywords: [(String, [String])] = [
            ("sunset", ["sunset", "orange", "warm"]),
            ("ocean", ["ocean", "sea", "blue", "water"]),
            ("forest", ["forest", "green", "nature"]),
            ("midnight", ["dark", "black", "midnight", "night"]),
            ("royal", ["purple", "royal"]),
            ("candy", ["pink", "candy", "cute"]),
            ("lava", ["red", "lava", "fire"]),
            ("gold", ["gold", "yellow"]),
            ("berry", ["berry", "violet"]),
            ("mist", ["gray", "grey", "mist", "slate"]),
            ("mint", ["mint", "teal", "aqua"]),
            ("paper", ["white", "light", "paper", "cream", "minimal"]),
        ]
        for (themeID, keywords) in themeKeywords where keywords.contains(where: lowered.contains) {
            design.themeID = themeID
            break
        }
        if design.themeID == "paper" {
            design.textColorHex = "#333333"
        }

        // Font hints.
        if lowered.contains("serif") || lowered.contains("elegant") || lowered.contains("fancy") {
            design.fontStyle = .serif
        } else if lowered.contains("mono") || lowered.contains("code") || lowered.contains("terminal") {
            design.fontStyle = .mono
        } else if lowered.contains("classic") {
            design.fontStyle = .classic
        }

        // Pull out quoted text ("..." or “...”).
        let quoted = firstQuotedText(in: idea)
        let detectedDate = firstFutureDate(in: idea)

        // Widget kind.
        if lowered.contains("countdown") || lowered.contains("days until") || lowered.contains("until")
            || (detectedDate != nil && !lowered.contains("clock")) {
            design.kind = .countdown
        } else if lowered.contains("quote") || (quoted != nil && authorName(in: idea) != nil) {
            design.kind = .quote
        } else if lowered.contains("clock") || lowered.contains("time") {
            design.kind = .clock
        } else if lowered.contains("date") || lowered.contains("calendar") || lowered.contains("today") {
            design.kind = .date
        } else {
            design.kind = .note
        }

        // Kind-specific content.
        switch design.kind {
        case .countdown:
            if let detectedDate {
                design.targetDate = detectedDate
            }
            design.primaryText = eventTitle(from: idea)
            design.name = design.primaryText.isEmpty ? "Countdown" : design.primaryText
        case .quote:
            design.primaryText = quoted ?? idea.trimmedSentence(limit: 80)
            design.secondaryText = authorName(in: idea) ?? ""
            design.name = "Quote"
        case .note:
            design.primaryText = quoted ?? idea.trimmedSentence(limit: 60)
            design.name = "Note"
        case .clock:
            design.name = "Clock"
        case .date:
            design.name = "Date"
        case .freestyle:
            break
        }

        return design
    }

    private static func firstQuotedText(in text: String) -> String? {
        for (open, close) in [("\u{201C}", "\u{201D}"), ("\"", "\""), ("'", "'")] {
            if let start = text.range(of: open),
               let end = text.range(of: close, range: start.upperBound..<text.endIndex) {
                let inner = String(text[start.upperBound..<end.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !inner.isEmpty { return inner }
            }
        }
        return nil
    }

    private static func firstFutureDate(in text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let dates = matches.compactMap(\.date)
        return dates.first { $0 > .now } ?? dates.first
    }

    /// "countdown to my birthday on June 5" → "My birthday"
    private static func eventTitle(from idea: String) -> String {
        var text = idea
        for phrase in ["countdown to", "countdown for", "days until", "until", "countdown"] {
            if let range = text.range(of: phrase, options: .caseInsensitive) {
                text = String(text[range.upperBound...])
                break
            }
        }
        // Drop the date-ish tail ("on June 5", "in 30 days").
        for marker in [" on ", " in ", " by ", " at "] {
            if let range = text.range(of: marker, options: .caseInsensitive) {
                text = String(text[..<range.lowerBound])
            }
        }
        let title = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return title.isEmpty ? "" : title.prefix(1).capitalized + title.dropFirst()
    }

    /// "— Maya Angelou" or "by Maya Angelou" → "Maya Angelou"
    private static func authorName(in text: String) -> String? {
        for marker in ["—", "–", " - ", " by "] {
            if let range = text.range(of: marker, options: .caseInsensitive) {
                let author = String(text[range.upperBound...])
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
                if !author.isEmpty, author.count <= 40 { return author }
            }
        }
        return nil
    }
}

private extension String {
    func trimmedSentence(limit: Int) -> String {
        let cleaned = trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.count > limit else { return cleaned }
        return String(cleaned.prefix(limit)).trimmingCharacters(in: .whitespaces) + "…"
    }
}
