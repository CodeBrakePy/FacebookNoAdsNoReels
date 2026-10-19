import SwiftUI
import WebKit
import Combine

/// Owns the WKWebView, injects the Reels blocker, and cancels Reels navigations.
final class WebModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    static let home = URL(string: "https://m.facebook.com/")!

    let webView: WKWebView
    @Published var canGoBack = false
    @Published var canGoForward = false

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()          // keeps you logged in
        config.allowsInlineMediaPlayback = true
        config.userContentController.addUserScript(
            WKUserScript(source: ReelBlocker.script,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: false)
        )
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.publisher(for: \.canGoBack).assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward).assign(to: &$canGoForward)
        webView.load(URLRequest(url: Self.home))
    }

    func goHome() { webView.load(URLRequest(url: Self.home)) }

    // MARK: Navigation policy

    func webView(_ webView: WKWebView,
                 decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url, let host = url.host?.lowercased() else {
            decisionHandler(.allow); return
        }
        let isFacebook = host.hasSuffix("facebook.com") || host.hasSuffix("fb.com")

        if isFacebook, ReelBlocker.isReelPath(url.path) {
            decisionHandler(.cancel)
            goHome()
            return
        }
        // Open real external sites in Safari instead of inside this app.
        if action.navigationType == .linkActivated, !isFacebook,
           !host.hasSuffix("fbcdn.net"), ["http", "https"].contains(url.scheme ?? "") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // target="_blank" links load in the same view
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url { webView.load(URLRequest(url: url)) }
        return nil
    }
}

struct FacebookWebView: UIViewRepresentable {
    let model: WebModel
    func makeUIView(context: Context) -> WKWebView { model.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
