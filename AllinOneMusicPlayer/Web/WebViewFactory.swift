import WebKit

enum WebViewRole {
    case playback
    case search
}

@MainActor
final class WebViewFactory {
    private var processPools: [PlatformID: WKProcessPool] = [:]

    func makeWebView(platform: PlatformConfig, role: WebViewRole) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.processPool = processPool(for: platform.id)
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let contentController = WKUserContentController()
        contentController.add(WebScriptBridge.shared, name: "allinone")
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = platform.customUserAgent
        webView.allowsBackForwardNavigationGestures = role == .playback
        webView.navigationDelegate = WebNavigationPolicy.shared
        webView.uiDelegate = WebNavigationPolicy.shared
        return webView
    }

    private func processPool(for platform: PlatformID) -> WKProcessPool {
        if let processPool = processPools[platform] {
            return processPool
        }

        let processPool = WKProcessPool()
        processPools[platform] = processPool
        return processPool
    }
}
