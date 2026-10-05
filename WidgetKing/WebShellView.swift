import SwiftUI
import WebKit

// The app IS the web designer: web/index.html ships inside the bundle and
// runs in a WKWebView, offline, as the exact file the site serves. Two
// bridges make it native:
//  - the designer posts its library on every save → App Group → widgets
//  - native tells the page it is running inside the app (`wk-native` class
//    and `window.wkNative`) so the page can hide Scriptable-only setup.
struct WebShellView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "widgetking")
        let boot = """
        (function () {
          document.documentElement.classList.add('wk-native');
          window.wkNative = { platform: 'ios', version: 1 };
        })();
        """
        controller.addUserScript(WKUserScript(source: boot, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = controller
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.isOpaque = false
        web.backgroundColor = UIColor.systemBackground
        web.allowsBackForwardNavigationGestures = false
        if #available(iOS 16.4, *) { web.isInspectable = true }
        Self.load(into: web)
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    static func indexURL() -> URL? {
        return Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "web")
    }

    static func load(into web: WKWebView) {
        guard let index = indexURL() else {
            web.loadHTMLString("<h2 style='font-family:-apple-system;padding:40px'>WidgetKing's designer is missing from this build.</h2>", baseURL: nil)
            return
        }
        web.loadFileURL(index, allowingReadAccessTo: index.deletingLastPathComponent())
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "widgetking" else { return }
            _ = WKBridge.handle(message.body)
        }

        // Links that leave the bundled page open in the system (App Store,
        // scriptable://, shortcuts://, the privacy policy's external links).
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
            if url.isFileURL || url.scheme == "about" || url.scheme == "blob" || url.scheme == "data" {
                decisionHandler(.allow)
                return
            }
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        }

        // window.open → same rule.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                if url.isFileURL { webView.load(navigationAction.request) } else { UIApplication.shared.open(url) }
            }
            return nil
        }

        // The designer uses alert/confirm for a few confirmations.
        // WebKit blocks the page until each completion handler runs, so every
        // path — including "no view controller to present on" — must call it.
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            if let top = topController() { top.present(alert, animated: true) } else { completionHandler() }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            if let top = topController() { top.present(alert, animated: true) } else { completionHandler(false) }
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
            if let top = topController() { top.present(alert, animated: true) } else { completionHandler(nil) }
        }

        private func topController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            guard let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) else { return nil }
            var top = window.rootViewController
            while let presented = top?.presentedViewController { top = presented }
            return top
        }
    }
}
