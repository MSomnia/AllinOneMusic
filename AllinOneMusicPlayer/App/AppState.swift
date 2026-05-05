import Foundation

@MainActor
final class AppState {
    typealias ActivePlatformHandler = (PlatformID) -> Void
    typealias NowPlayingHandler = (NowPlayingInfo?) -> Void

    var activePlatform: PlatformID {
        didSet {
            guard oldValue != activePlatform else { return }
            defaultsStore.lastActivePlatform = activePlatform
            activePlatformHandlers.forEach { $0(activePlatform) }
        }
    }

    var nowPlaying: NowPlayingInfo? {
        displayedNowPlaying
    }

    var mediaControlPlatform: PlatformID {
        displayedNowPlaying?.platform ?? activePlatform
    }

    private let defaultsStore: UserDefaultsStore
    private var nowPlayingByPlatform: [PlatformID: NowPlayingInfo] = [:]
    private var displayedNowPlaying: NowPlayingInfo?
    private var activePlatformHandlers: [ActivePlatformHandler] = []
    private var nowPlayingHandlers: [NowPlayingHandler] = []

    init(defaultsStore: UserDefaultsStore) {
        self.defaultsStore = defaultsStore
        activePlatform = defaultsStore.lastActivePlatform ?? .youtube
    }

    func observeActivePlatform(_ handler: @escaping ActivePlatformHandler) {
        activePlatformHandlers.append(handler)
        handler(activePlatform)
    }

    func observeNowPlaying(_ handler: @escaping NowPlayingHandler) {
        nowPlayingHandlers.append(handler)
        handler(nowPlaying)
    }

    func updateNowPlaying(_ nowPlaying: NowPlayingInfo) {
        let previousDisplayedNowPlaying = displayedNowPlaying
        nowPlayingByPlatform[nowPlaying.platform] = nowPlaying

        let shouldDisplay = nowPlaying.isPlaying
            || displayedNowPlaying?.platform == nowPlaying.platform
            || displayedNowPlaying == nil

        guard shouldDisplay else { return }

        displayedNowPlaying = nowPlaying
        guard previousDisplayedNowPlaying != displayedNowPlaying else { return }
        nowPlayingHandlers.forEach { $0(displayedNowPlaying) }
    }
}
