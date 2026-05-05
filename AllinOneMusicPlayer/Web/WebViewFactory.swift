import WebKit

enum WebViewRole {
    case playback
}

@MainActor
final class WebViewFactory {
    func makeWebView(platform: PlatformConfig, role: WebViewRole) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let contentController = WKUserContentController()
        contentController.add(WebScriptBridge.shared, name: "allinone")
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = platform.customUserAgent
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = WebNavigationPolicy.shared
        webView.uiDelegate = WebNavigationPolicy.shared
        return webView
    }
}
