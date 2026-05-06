import Foundation

@MainActor
final class AppState {
    typealias ActivePlatformHandler = (PlatformID) -> Void
    typealias NowPlayingHandler = (NowPlayingInfo?) -> Void
    typealias SearchHandler = () -> Void

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

    var searchQuery: String = "" {
        didSet {
            guard oldValue != searchQuery else { return }
            notifySearchChanged()
        }
    }

    var searchResults: [SearchResultOrError] = [] {
        didSet {
            notifySearchChanged()
        }
    }

    var isSearching: Bool = false {
        didSet {
            guard oldValue != isSearching else { return }
            notifySearchChanged()
        }
    }

    var isSearchOpen: Bool = false {
        didSet {
            guard oldValue != isSearchOpen else { return }
            notifySearchChanged()
        }
    }

    private let defaultsStore: UserDefaultsStore
    private var nowPlayingByPlatform: [PlatformID: NowPlayingInfo] = [:]
    private var displayedNowPlaying: NowPlayingInfo?
    private var activePlatformHandlers: [ActivePlatformHandler] = []
    private var nowPlayingHandlers: [NowPlayingHandler] = []
    private var searchHandlers: [SearchHandler] = []

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

    func observeSearch(_ handler: @escaping SearchHandler) {
        searchHandlers.append(handler)
        handler()
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

    func openSearch() {
        isSearchOpen = true
    }

    func closeSearch() {
        isSearchOpen = false
        isSearching = false
        searchResults = []
    }

    private func notifySearchChanged() {
        searchHandlers.forEach { $0() }
    }
}
