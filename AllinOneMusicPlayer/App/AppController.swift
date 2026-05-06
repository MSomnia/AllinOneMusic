import AppKit

@MainActor
final class AppController {
    private let defaultsStore = UserDefaultsStore()
    private lazy var appState = AppState(defaultsStore: defaultsStore)
    private lazy var webViewManager = WebViewManager(factory: WebViewFactory())
    private lazy var playbackController = PlaybackController(webViewManager: webViewManager)
    private lazy var nowPlayingObserver = NowPlayingObserver(webViewManager: webViewManager)
    private lazy var statusBarController = StatusBarController(activePlatform: appState.activePlatform)
    private lazy var remoteCommandController = RemoteCommandController()
    private lazy var keyboardShortcutController = KeyboardShortcutController()
    private var mainWindowController: MainWindowController?
    private var playingPlatform: PlatformID?

    func start() {
        StartupLogger.log("AppController.start")
        let windowController = MainWindowController(
            appState: appState,
            webViewManager: webViewManager,
            defaultsStore: defaultsStore
        )
        mainWindowController = windowController
        configureControllers()
        showMainWindow()

        DispatchQueue.main.async { [weak self] in
            self?.mainWindowController?.installPlaybackViewsIfNeeded()
            self?.showMainWindow()
        }
    }

    func showMainWindow() {
        guard let windowController = mainWindowController, let window = windowController.window else {
            StartupLogger.log("showMainWindow skipped because window is nil")
            return
        }

        windowController.showWindow(nil)
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        StartupLogger.log("showMainWindow visible=\(window.isVisible) frame=\(NSStringFromRect(window.frame))")
    }

    private func configureControllers() {
        mainWindowController?.onMediaAction = { [weak self] action in
            self?.sendMediaAction(action)
        }
        mainWindowController?.onPlatformShortcut = { [weak self] platform in
            self?.appState.activePlatform = platform
        }

        statusBarController.onOpenApp = { [weak self] in
            self?.showMainWindow()
        }
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
        statusBarController.onMediaAction = { [weak self] action in
            self?.sendMediaAction(action)
        }

        remoteCommandController.onMediaAction = { [weak self] action in
            self?.sendMediaAction(action)
        }
        keyboardShortcutController.onMediaAction = { [weak self] action in
            self?.sendMediaAction(action)
        }
        keyboardShortcutController.onPlatformShortcut = { [weak self] platform in
            self?.appState.activePlatform = platform
        }

        WebScriptBridge.shared.onNowPlaying = { [weak self] nowPlaying in
            self?.handleNowPlaying(nowPlaying)
        }
        nowPlayingObserver.start()

        appState.observeActivePlatform { [weak self] platform in
            guard let self else { return }
            self.statusBarController.update(activePlatform: platform, nowPlaying: self.appState.nowPlaying)
        }
        appState.observeNowPlaying { [weak self] nowPlaying in
            guard let self else { return }
            self.statusBarController.update(activePlatform: self.appState.activePlatform, nowPlaying: nowPlaying)
        }
    }

    private func sendMediaAction(_ action: MediaAction) {
        playbackController.send(action, to: appState.mediaControlPlatform)
    }

    private func handleNowPlaying(_ nowPlaying: NowPlayingInfo) {
        let previousPlayingPlatform = playingPlatform

        if nowPlaying.isPlaying {
            playingPlatform = nowPlaying.platform
        } else if playingPlatform == nowPlaying.platform {
            playingPlatform = nil
        }

        appState.updateNowPlaying(nowPlaying)

        guard
            nowPlaying.isPlaying,
            let platformToPause = previousPlayingPlatform,
            platformToPause != nowPlaying.platform
        else {
            return
        }

        playbackController.pause(platformToPause)
    }
}
