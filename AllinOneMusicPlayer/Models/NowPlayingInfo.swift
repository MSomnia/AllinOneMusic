import Foundation

struct NowPlayingInfo: Equatable, Sendable {
    let platform: PlatformID
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let isPlaying: Bool
}
