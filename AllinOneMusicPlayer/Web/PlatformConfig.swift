import Foundation

struct PlatformConfig {
    let id: PlatformID
    let label: String
    let playbackURL: URL
    let searchURL: (String) -> URL
    let customUserAgent: String?
}

enum PlatformCatalog {
    private static let desktopSafariUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    private static let desktopChromeUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

    static let all: [PlatformConfig] = [
        PlatformConfig(
            id: .youtube,
            label: "YouTube Music",
            playbackURL: URL(string: "https://music.youtube.com")!,
            searchURL: { query in
                URL(string: "https://music.youtube.com/search?q=\(query.urlEncoded)")!
            },
            customUserAgent: desktopSafariUserAgent
        ),
        PlatformConfig(
            id: .spotify,
            label: "Spotify",
            playbackURL: URL(string: "https://open.spotify.com/search")!,
            searchURL: { query in
                URL(string: "https://open.spotify.com/search/\(query.urlEncoded)/tracks")!
            },
            customUserAgent: desktopChromeUserAgent
        ),
        PlatformConfig(
            id: .netease,
            label: "网易云音乐",
            playbackURL: URL(string: "https://music.163.com")!,
            searchURL: { query in
                URL(string: "https://music.163.com/#/search/m/?s=\(query.urlEncoded)&type=1")!
            },
            customUserAgent: desktopSafariUserAgent
        ),
    ]

    static func config(for id: PlatformID) -> PlatformConfig {
        all.first { $0.id == id }!
    }
}

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
