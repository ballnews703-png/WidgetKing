import SwiftUI

// The native app is a shell around the web designer (M2 of NATIVE_PLAN.md):
// web/index.html runs inside a WKWebView from the bundle, and hands its
// library to the App Group on every save for the widget extension.
@main
struct WidgetKingApp: App {
    var body: some Scene {
        WindowGroup {
            WebShellView()
                .ignoresSafeArea()
        }
    }
}
