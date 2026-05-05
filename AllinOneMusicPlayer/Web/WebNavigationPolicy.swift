import WebKit

@MainActor
final class WebNavigationPolicy: NSObject, WKNavigationDelegate, WKUIDelegate {
    static let shared = WebNavigationPolicy()

    var onDidCommit: ((WKWebView) -> Void)?
    var onDidFinish: ((WKWebView) -> Void)?

    private override init() {}

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        onDidCommit?(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onDidFinish?(webView)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
