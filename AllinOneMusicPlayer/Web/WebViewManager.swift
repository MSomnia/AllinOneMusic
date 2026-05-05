import AppKit
import WebKit

@MainActor
final class WebViewManager {
    var onPlaybackWebViewCreated: ((PlatformID, WKWebView) -> Void)?

    private let factory: WebViewFactory
    private var playbackWebViews: [PlatformID: WKWebView] = [:]
    private var activePlatform: PlatformID = .youtube

    init(factory: WebViewFactory) {
        self.factory = factory
    }

    func installPlaybackViews(in containerView: NSView) {
        for platform in PlatformCatalog.all {
            let webView = playbackWebView(for: platform.id) ?? makePlaybackWebView(for: platform)
            guard webView.superview == nil else { continue }

            webView.translatesAutoresizingMaskIntoConstraints = false
            webView.isHidden = platform.id != activePlatform
            containerView.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                webView.topAnchor.constraint(equalTo: containerView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])
        }
    }

    func switchToPlatform(_ platform: PlatformID) {
        activePlatform = platform
        for (id, webView) in playbackWebViews {
            webView.isHidden = id != platform
        }
    }

    func playbackWebView(for platform: PlatformID) -> WKWebView? {
        playbackWebViews[platform]
    }

    func allPlaybackWebViews() -> [(PlatformID, WKWebView)] {
        playbackWebViews.map { ($0.key, $0.value) }
    }

    private func makePlaybackWebView(for platform: PlatformConfig) -> WKWebView {
        let webView = factory.makeWebView(platform: platform, role: .playback)
        webView.load(URLRequest(url: platform.playbackURL))
        playbackWebViews[platform.id] = webView
        onPlaybackWebViewCreated?(platform.id, webView)
        return webView
    }
}
