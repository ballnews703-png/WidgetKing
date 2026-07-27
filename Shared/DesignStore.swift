import Foundation
import WidgetKit

enum AppGroup {
    /// Shared container between the app and the widget extension.
    /// If you change this, update both .entitlements files to match.
    static let id = "group.com.widgetking.shared"
}

/// Loads and saves widget designs to the shared App Group container.
final class DesignStore: ObservableObject {
    static let shared = DesignStore()

    @Published private(set) var designs: [WidgetDesign]

    private static let storageKey = "widgetking.designs"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.id) ?? .standard
    }

    private init() {
        designs = Self.loadDesigns()
    }

    /// Reads all saved designs. Safe to call from the widget extension.
    static func loadDesigns() -> [WidgetDesign] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WidgetDesign].self, from: data)
        else { return [] }
        return decoded
    }

    func save(_ design: WidgetDesign) {
        if let index = designs.firstIndex(where: { $0.id == design.id }) {
            designs[index] = design
        } else {
            designs.append(design)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        designs.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(designs) {
            Self.defaults.set(data, forKey: Self.storageKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
