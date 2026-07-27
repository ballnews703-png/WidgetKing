import SwiftUI

@main
struct WidgetKingApp: App {
    @StateObject private var store = DesignStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
