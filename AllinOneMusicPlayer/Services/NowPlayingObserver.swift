import Foundation
import WebKit

@MainActor
final class NowPlayingObserver {
    private let webViewManager: WebViewManager
    private var playbackWebViews: [PlatformID: WKWebView] = [:]
    private var platformByWebViewID: [ObjectIdentifier: PlatformID] = [:]
    private var reinjectionTimer: Timer?

    private lazy var listenerSource: String = {
        guard
            let url = Bundle.main.url(forResource: "nowPlayingListener", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            StartupLogger.log("NowPlayingObserver could not load nowPlayingListener.js")
            return ""
        }
        return source
    }()

    init(webViewManager: WebViewManager) {
        self.webViewManager = webViewManager
    }

    deinit {
        reinjectionTimer?.invalidate()
    }

    func start() {
        webViewManager.onPlaybackWebViewCreated = { [weak self] platform, webView in
            self?.observe(platform: platform, webView: webView)
        }

        for (platform, webView) in webViewManager.allPlaybackWebViews() {
            observe(platform: platform, webView: webView)
        }

        WebNavigationPolicy.shared.onDidCommit = { [weak self] webView in
            self?.injectIfObserved(webView)
        }
        WebNavigationPolicy.shared.onDidFinish = { [weak self] webView in
            self?.injectIfObserved(webView)
        }

        reinjectionTimer = Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.injectIntoAllPlaybackWebViews()
            }
        }
    }

    private func observe(platform: PlatformID, webView: WKWebView) {
        playbackWebViews[platform] = webView
        platformByWebViewID[ObjectIdentifier(webView)] = platform
        inject(platform: platform, into: webView)
    }

    private func injectIfObserved(_ webView: WKWebView) {
        guard let platform = platformByWebViewID[ObjectIdentifier(webView)] else { return }
        inject(platform: platform, into: webView)
    }

    private func injectIntoAllPlaybackWebViews() {
        for (platform, webView) in playbackWebViews {
            inject(platform: platform, into: webView)
        }
    }

    private func inject(platform: PlatformID, into webView: WKWebView) {
        guard !listenerSource.isEmpty, let configJSON = listenerConfig(for: platform).jsonEncoded else { return }

        let script = """
        (() => {
        \(listenerSource)
          window.__allinoneNowPlayingStart(\(configJSON));
        })();
        """

        webView.evaluateJavaScript(script) { _, error in
            if let error {
                StartupLogger.log("NowPlayingObserver \(platform.rawValue) injection error: \(error.localizedDescription)")
            }
        }
    }

    private func listenerConfig(for platform: PlatformID) -> ListenerConfig {
        ListenerConfig(
            platform: platform.rawValue,
            selectors: NowPlayingSelectors.catalog[platform] ?? .empty,
            prefersDOMMetadata: platform == .youtube
        )
    }
}

private struct ListenerConfig: Encodable {
    let platform: String
    let selectors: NowPlayingSelectors
    let prefersDOMMetadata: Bool
}

private struct NowPlayingSelectors: Encodable {
    let title: [String]
    let artist: [String]
    let album: [String]
    let artwork: [String]
    let isPlaying: [String]

    static let empty = NowPlayingSelectors(title: [], artist: [], album: [], artwork: [], isPlaying: [])

    static let catalog: [PlatformID: NowPlayingSelectors] = [
        .youtube: NowPlayingSelectors(
            title: [
                "ytmusic-player-bar .content-info-wrapper yt-formatted-string.title",
                "ytmusic-player-bar yt-formatted-string.title",
                "ytmusic-player-bar .title",
                ".ytmusic-player-bar .title.style-scope",
                "#layout ytmusic-player-bar .title",
            ],
            artist: [
                "ytmusic-player-bar .content-info-wrapper .byline",
                "ytmusic-player-bar .subtitle yt-formatted-string",
                "ytmusic-player-bar .byline-wrapper",
                "ytmusic-player-bar .byline",
                ".ytmusic-player-bar .byline.style-scope",
                "#layout ytmusic-player-bar .byline",
            ],
            album: [],
            artwork: [
                "ytmusic-player-bar img.image",
                "ytmusic-player-bar .thumbnail img",
            ],
            isPlaying: [
                "ytmusic-player-bar[player-ui-state_=\"PLAYER_BAR_PLAYING\"]",
                "ytmusic-player-bar[player-ui-state_=\"PLAYING\"]",
                "ytmusic-player-bar[play-button-state=\"pause\"]",
                "#play-pause-button[aria-label=\"Pause\"]",
                "#play-pause-button[title=\"Pause\"]",
            ]
        ),
        .spotify: NowPlayingSelectors(
            title: [
                "[data-testid=\"now-playing-widget\"] [data-testid=\"trackInfo-name\"]",
                "[data-testid=\"context-item-info-title\"]",
                "[data-testid=\"nowplaying-track-link\"]",
            ],
            artist: [
                "[data-testid=\"now-playing-widget\"] [data-testid=\"trackInfo-artists\"]",
                "[data-testid=\"context-item-info-artist\"]",
                "[data-testid=\"nowplaying-artist\"]",
            ],
            album: [],
            artwork: [
                "[data-testid=\"now-playing-widget\"] img",
                "[data-testid=\"cover-art-image\"]",
            ],
            isPlaying: [
                "[data-testid=\"control-button-playpause\"][aria-label=\"Pause\"]",
                "[data-testid=\"control-button-playpause\"][aria-label=\"暂停\"]",
            ]
        ),
        .netease: NowPlayingSelectors(
            title: [
                "#song-name-value",
                "#g_player .words .name",
                "#g_player .words .name a",
                ".m-player .words .name",
                ".m-player .words .name a",
            ],
            artist: [
                "#artist-name-value",
                "#g_player .words .by",
                "#g_player .words .by a",
                ".m-player .words .by",
                ".m-player .words .by a",
            ],
            album: [],
            artwork: [
                "#g_player .head img",
                ".m-player .head img",
            ],
            isPlaying: [
                ".btnplay.playing",
                "#g_player .btns a.pas",
                ".m-player .btns a.pas",
                "a.pas",
            ]
        ),
    ]
}

private extension Encodable {
    var jsonEncoded: String? {
        let data = try? JSONEncoder().encode(self)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }
}
