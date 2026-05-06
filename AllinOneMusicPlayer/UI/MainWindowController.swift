import AppKit

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    var onMediaAction: ((MediaAction) -> Void)? {
        didSet {
            nowPlayingBarView.onMediaAction = onMediaAction
            (window as? PlayerWindow)?.onMediaAction = onMediaAction
        }
    }

    private let appState: AppState
    private let webViewManager: WebViewManager
    private let defaultsStore: UserDefaultsStore
    private let headerView: HeaderView
    private let contentViewHost = NSView()
    private let searchOverlayView = SearchOverlayView()
    private let searchResultsView = SearchResultsView()
    private let nowPlayingBarView = NowPlayingBarView()
    private lazy var searchOrchestrator = SearchOrchestrator(
        extractor: SearchExtractor(webViewManager: webViewManager)
    )
    private let searchDebouncer = Debouncer(milliseconds: 300)
    private var searchTask: Task<Void, Never>?
    private var didInstallPlaybackViews = false

    init(
        appState: AppState,
        webViewManager: WebViewManager,
        defaultsStore: UserDefaultsStore
    ) {
        self.appState = appState
        self.webViewManager = webViewManager
        self.defaultsStore = defaultsStore
        headerView = HeaderView(platforms: PlatformCatalog.all)

        let persistedFrame = defaultsStore.validMainWindowFrame
        let frame = persistedFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let window = PlayerWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 900, height: 600)
        window.title = "AllinOne Music Player"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.centerIfNeeded(usingPersistedFrame: persistedFrame)

        super.init(window: window)

        window.delegate = self
        window.onMediaAction = onMediaAction
        window.onFocusSearch = { [weak self] in
            self?.openAndFocusSearch()
        }
        window.onCloseSearch = { [weak self] in
            self?.closeSearch()
        }
        buildInterface()
        bindState()
        StartupLogger.log("MainWindowController initialized frame=\(NSStringFromRect(window.frame))")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func windowDidMove(_ notification: Notification) {
        persistWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        persistWindowFrame()
    }

    func installPlaybackViewsIfNeeded() {
        guard !didInstallPlaybackViews else { return }
        didInstallPlaybackViews = true
        StartupLogger.log("installPlaybackViewsIfNeeded")
        webViewManager.installPlaybackViews(in: contentViewHost)
        webViewManager.switchToPlatform(appState.activePlatform)
    }

    private func buildInterface() {
        guard let window else { return }

        let rootView = NSView()
        rootView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = rootView

        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentViewHost.translatesAutoresizingMaskIntoConstraints = false
        searchOverlayView.translatesAutoresizingMaskIntoConstraints = false
        searchResultsView.translatesAutoresizingMaskIntoConstraints = false
        nowPlayingBarView.translatesAutoresizingMaskIntoConstraints = false
        searchOverlayView.isHidden = true
        rootView.addSubview(headerView)
        rootView.addSubview(contentViewHost)
        rootView.addSubview(searchOverlayView, positioned: .above, relativeTo: contentViewHost)
        searchOverlayView.addSubview(searchResultsView)
        rootView.addSubview(nowPlayingBarView)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 72),

            contentViewHost.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            contentViewHost.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            contentViewHost.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentViewHost.bottomAnchor.constraint(equalTo: nowPlayingBarView.topAnchor),

            searchOverlayView.leadingAnchor.constraint(equalTo: contentViewHost.leadingAnchor),
            searchOverlayView.trailingAnchor.constraint(equalTo: contentViewHost.trailingAnchor),
            searchOverlayView.topAnchor.constraint(equalTo: contentViewHost.topAnchor),
            searchOverlayView.bottomAnchor.constraint(equalTo: contentViewHost.bottomAnchor),

            searchResultsView.topAnchor.constraint(equalTo: searchOverlayView.topAnchor, constant: 12),
            searchResultsView.trailingAnchor.constraint(equalTo: searchOverlayView.trailingAnchor, constant: -24),
            searchResultsView.widthAnchor.constraint(equalToConstant: 430),
            searchResultsView.heightAnchor.constraint(equalToConstant: 560),

            nowPlayingBarView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            nowPlayingBarView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            nowPlayingBarView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            nowPlayingBarView.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private func bindState() {
        headerView.onPlatformSelected = { [weak self] platform in
            self?.appState.activePlatform = platform
        }
        headerView.onSearchQueryChanged = { [weak self] query in
            self?.updateSearchQuery(query)
        }
        headerView.onSearchCancelled = { [weak self] in
            self?.closeSearch()
        }
        searchResultsView.onResultSelected = { [weak self] result in
            self?.selectSearchResult(result)
        }
        searchResultsView.onClose = { [weak self] in
            self?.closeSearch()
        }

        appState.observeActivePlatform { [weak self] platform in
            self?.headerView.select(platform)
            self?.webViewManager.switchToPlatform(platform)
            self?.nowPlayingBarView.update(activePlatform: platform, nowPlaying: self?.appState.nowPlaying)
        }

        appState.observeNowPlaying { [weak self] nowPlaying in
            guard let self else { return }
            self.nowPlayingBarView.update(activePlatform: self.appState.activePlatform, nowPlaying: nowPlaying)
        }

        appState.observeSearch { [weak self] in
            guard let self else { return }
            self.headerView.setSearchQuery(self.appState.searchQuery)
            self.searchOverlayView.isHidden = !self.appState.isSearchOpen
            self.searchResultsView.update(
                query: self.appState.searchQuery,
                results: self.appState.searchResults,
                isSearching: self.appState.isSearching,
                isOpen: self.appState.isSearchOpen
            )
        }
    }

    private func updateSearchQuery(_ query: String) {
        appState.searchQuery = query
        appState.isSearchOpen = true

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            searchDebouncer.cancel()
            searchTask?.cancel()
            appState.closeSearch()
            return
        }

        appState.isSearching = true
        searchDebouncer.schedule { [weak self] in
            self?.performSearch(trimmedQuery)
        }
    }

    private func performSearch(_ query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            let results = await self.searchOrchestrator.search(query)
            guard !Task.isCancelled, self.appState.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines) == query else {
                return
            }
            self.appState.searchResults = results
            self.appState.isSearching = false
        }
    }

    private func selectSearchResult(_ result: SearchResult) {
        appState.activePlatform = result.platform
        webViewManager.navigatePlaybackWebView(to: result.playbackURL, platform: result.platform)
        closeSearch()
    }

    private func openAndFocusSearch() {
        appState.openSearch()
        headerView.focusSearch()
    }

    private func closeSearch() {
        searchDebouncer.cancel()
        searchTask?.cancel()
        appState.searchQuery = ""
        appState.closeSearch()
    }

    private func persistWindowFrame() {
        guard let frame = window?.frame, frame.isUsableWindowFrame else { return }
        defaultsStore.mainWindowFrame = frame
    }
}

private extension NSWindow {
    func centerIfNeeded(usingPersistedFrame persistedFrame: NSRect?) {
        guard persistedFrame == nil else { return }
        center()
    }
}

private extension UserDefaultsStore {
    var validMainWindowFrame: NSRect? {
        guard let frame = mainWindowFrame, frame.isUsableWindowFrame else {
            return nil
        }

        let intersectsVisibleScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }

        return intersectsVisibleScreen ? frame : nil
    }
}

private extension NSRect {
    var isUsableWindowFrame: Bool {
        width >= 300 && height >= 240 && !isNull && !isInfinite
    }
}

@MainActor
private final class SearchOverlayView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard !isHidden, bounds.contains(point) else { return nil }

        for subview in subviews.reversed() {
            let convertedPoint = subview.convert(point, from: self)
            if let hitView = subview.hitTest(convertedPoint) {
                return hitView
            }
        }

        return self
    }

    override func mouseDown(with event: NSEvent) {}

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
