import Foundation
import WidgetKit

// The design library as the web designer saves it, shared between the app
// (where the WKWebView shell writes it) and the widget extension (which
// renders from it). One JSON string in the App Group — the same bytes the
// designer keeps in localStorage, so there is exactly one source of truth.
enum WKStore {
    static let groupID = "group.com.widgetking.shared"
    static let designsKey = "widgetking.designs.json"
    static let stampKey = "widgetking.designs.stamp"

    static var defaults: UserDefaults {
        return UserDefaults(suiteName: groupID) ?? .standard
    }

    static func designsJSON() -> String? {
        return defaults.string(forKey: designsKey)
    }

    static func designs() -> [WKDesign] {
        guard let json = designsJSON(), let data = json.data(using: .utf8) else { return [] }
        return WKDesign.decodeArray(data)
    }

    /// Saves the library the designer just persisted and refreshes every
    /// widget. Rejects anything that is not a JSON array of objects so a
    /// malformed message can never wipe the library.
    @discardableResult
    static func save(json: String) -> Int {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let arr = obj as? [Any] else { return -1 }
        let designs = arr.compactMap { $0 as? [String: Any] }
        defaults.set(json, forKey: designsKey)
        defaults.set(Date().timeIntervalSince1970, forKey: stampKey)
        WidgetCenter.shared.reloadAllTimelines()
        return designs.count
    }

    static func design(named name: String) -> WKDesign? {
        let wanted = name.trimmingCharacters(in: .whitespaces).lowercased()
        return designs().first { $0.name.lowercased() == wanted }
    }

    static func design(id: String) -> WKDesign? {
        return designs().first { $0.id == id }
    }
}

/// Messages the web designer posts over the WKWebView bridge
/// (`window.webkit.messageHandlers.widgetking`). Kept free of WebKit types so
/// the unit tests can feed it plain dictionaries.
enum WKBridge {
    enum Result: Equatable { case saved(Int), ignored, rejected }

    static func handle(_ body: Any) -> Result {
        guard let dict = body as? [String: Any], let type = dict["type"] as? String else { return .ignored }
        switch type {
        case "designs":
            guard let json = dict["json"] as? String else { return .rejected }
            let n = WKStore.save(json: json)
            return n >= 0 ? .saved(n) : .rejected
        default:
            return .ignored
        }
    }
}
