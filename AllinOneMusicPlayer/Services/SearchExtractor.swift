import Foundation
import WebKit

enum SearchExtractorError: LocalizedError {
    case missingWebView(PlatformID)
    case missingScript(PlatformID)
    case invalidResult(PlatformID)

    var errorDescription: String? {
        switch self {
        case .missingWebView(let platform):
            return "Missing search WebView for \(platform.rawValue)."
        case .missingScript(let platform):
            return "Missing search extractor script for \(platform.rawValue)."
        case .invalidResult(let platform):
            return "Search results from \(platform.rawValue) could not be decoded."
        }
    }
}

@MainActor
final class SearchExtractor {
    private let webViewManager: WebViewManager
    private var scripts: [PlatformID: String] = [:]

    init(webViewManager: WebViewManager) {
        self.webViewManager = webViewManager
    }

    func extract(platform: PlatformID, query: String) async throws -> [SearchResultOrError] {
        guard let webView = webViewManager.searchWebView(for: platform) else {
            throw SearchExtractorError.missingWebView(platform)
        }

        let config = PlatformCatalog.config(for: platform)
        webView.load(URLRequest(url: config.searchURL(query)))
        try await waitForSearchPage(in: webView)
        try await prepareSearchPageIfNeeded(platform: platform, webView: webView)

        guard let source = script(for: platform) else {
            throw SearchExtractorError.missingScript(platform)
        }

        let data = try await extractResultData(platform: platform, webView: webView, source: source)

        let rawResults = try JSONDecoder().decode([RawSearchResult].self, from: data)
        let results = rawResults.prefix(3).compactMap { rawResult -> SearchResultOrError? in
            guard
                !rawResult.title.trimmedForSearch.isEmpty,
                let playbackURL = rawResult.resolvedPlaybackURL(defaultBaseURL: config.playbackURL)
            else {
                return nil
            }

            return .result(SearchResult(
                platform: platform,
                title: rawResult.title.trimmedForSearch,
                artist: rawResult.artist.trimmedForSearch,
                album: rawResult.album?.trimmedForSearch ?? "",
                artworkURL: rawResult.resolvedArtworkURL(defaultBaseURL: config.playbackURL),
                playbackURL: playbackURL
            ))
        }

        return Array(results)
    }

    private func extractResultData(platform: PlatformID, webView: WKWebView, source: String) async throws -> Data {
        let deadline = Date().addingTimeInterval(8)
        let wrappedScript = """
        (() => {
        \(source)
          const results = window.__allinoneExtractSearchResults();
          return JSON.stringify(Array.isArray(results) ? results : []);
        })();
        """

        var lastData: Data?

        while Date() < deadline {
            if Task.isCancelled {
                throw CancellationError()
            }

            let value = try await webView.evaluateJavaScriptAsync(wrappedScript)
            guard let jsonString = value as? String, let data = jsonString.data(using: .utf8) else {
                throw SearchExtractorError.invalidResult(platform)
            }

            lastData = data
            if let rawResults = try? JSONDecoder().decode([RawSearchResult].self, from: data), !rawResults.isEmpty {
                return data
            }

            try await Task.sleep(for: .milliseconds(250))
        }

        if let lastData {
            return lastData
        }

        throw SearchExtractorError.invalidResult(platform)
    }

    private func prepareSearchPageIfNeeded(platform: PlatformID, webView: WKWebView) async throws {
        guard platform == .youtube else { return }

        let script = """
        (() => {
          const text = (element) => element && element.textContent ? element.textContent.trim().toLowerCase() : "";
          const chips = Array.from(document.querySelectorAll("ytmusic-chip-cloud-chip-renderer, tp-yt-paper-tab, a"));
          const songsChip = chips.find((chip) => /^(songs?|歌曲|单曲)$/.test(text(chip)));
          if (songsChip && !songsChip.hasAttribute("selected") && songsChip.getAttribute("aria-selected") !== "true") {
            songsChip.click();
            return true;
          }
          return false;
        })();
        """

        let didClick = (try? await webView.evaluateJavaScriptAsync(script)) as? Bool ?? false
        if didClick {
            try await Task.sleep(for: .milliseconds(900))
        }
    }

    private func waitForSearchPage(in webView: WKWebView) async throws {
        let deadline = Date().addingTimeInterval(8)

        while Date() < deadline {
            if Task.isCancelled {
                throw CancellationError()
            }

            let readyState = try? await webView.evaluateJavaScriptAsync("document.readyState")
            if (readyState as? String) == "complete" {
                try await Task.sleep(for: .milliseconds(700))
                return
            }

            try await Task.sleep(for: .milliseconds(200))
        }
    }

    private func script(for platform: PlatformID) -> String? {
        if let script = scripts[platform] {
            return script
        }

        guard
            let url = Bundle.main.url(forResource: "\(platform.rawValue)Search", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            return nil
        }

        scripts[platform] = source
        return source
    }
}

private struct RawSearchResult: Decodable {
    let title: String
    let artist: String
    let album: String?
    let artworkURL: String?
    let playbackURL: String?

    func resolvedPlaybackURL(defaultBaseURL: URL) -> URL? {
        resolvedURL(from: playbackURL, defaultBaseURL: defaultBaseURL)
    }

    func resolvedArtworkURL(defaultBaseURL: URL) -> URL? {
        resolvedURL(from: artworkURL, defaultBaseURL: defaultBaseURL)
    }

    private func resolvedURL(from value: String?, defaultBaseURL: URL) -> URL? {
        guard let value, !value.isEmpty else { return nil }

        if value.hasPrefix("//") {
            return URL(string: "https:\(value)")
        }

        if let absoluteURL = URL(string: value), absoluteURL.scheme != nil {
            return absoluteURL
        }

        return URL(string: value, relativeTo: defaultBaseURL)?.absoluteURL
    }
}

private extension WKWebView {
    func evaluateJavaScriptAsync(_ javaScriptString: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(javaScriptString) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }
}

private extension String {
    var trimmedForSearch: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
