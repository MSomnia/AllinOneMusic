import AppKit

@MainActor
final class MainWindowController: NSWindowController, NSWindowDelegate {
    var onMediaAction: ((MediaAction) -> Void)? {
        didSet {
            nowPlayingBarView.onMediaAction = onMediaAction
            (window as? PlayerWindow)?.onMediaAction = onMediaAction
        }
    }
    var onPlatformShortcut: ((PlatformID) -> Void)? {
        didSet {
            (window as? PlayerWindow)?.onPlatformShortcut = onPlatformShortcut
        }
    }

    private let appState: AppState
    private let webViewManager: WebViewManager
    private let defaultsStore: UserDefaultsStore
    private let headerView: HeaderView
    private let contentViewHost = NSView()
    private let nowPlayingBarView = NowPlayingBarView()
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
        window.onPlatformShortcut = onPlatformShortcut
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
        nowPlayingBarView.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(headerView)
        rootView.addSubview(contentViewHost)
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

        appState.observeActivePlatform { [weak self] platform in
            self?.headerView.select(platform)
            self?.webViewManager.switchToPlatform(platform)
            self?.nowPlayingBarView.update(activePlatform: platform, nowPlaying: self?.appState.nowPlaying)
        }

        appState.observeNowPlaying { [weak self] nowPlaying in
            guard let self else { return }
            self.nowPlayingBarView.update(activePlatform: self.appState.activePlatform, nowPlaying: nowPlaying)
        }
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
