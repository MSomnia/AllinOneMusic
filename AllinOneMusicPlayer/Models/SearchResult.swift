import Foundation

struct SearchResult: Equatable, Identifiable {
    let id: String
    let platform: PlatformID
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let playbackURL: URL

    init(
        id: String? = nil,
        platform: PlatformID,
        title: String,
        artist: String,
        album: String = "",
        artworkURL: URL? = nil,
        playbackURL: URL
    ) {
        self.id = id ?? "\(platform.rawValue)-\(playbackURL.absoluteString)-\(title)-\(artist)"
        self.platform = platform
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkURL = artworkURL
        self.playbackURL = playbackURL
    }
}

enum SearchResultOrError: Equatable {
    case result(SearchResult)
    case error(platform: PlatformID, message: String)

    var platform: PlatformID {
        switch self {
        case .result(let result):
            return result.platform
        case .error(let platform, _):
            return platform
        }
    }
}
