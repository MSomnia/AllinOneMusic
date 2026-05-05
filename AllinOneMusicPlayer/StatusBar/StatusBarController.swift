import AppKit

@MainActor
final class StatusBarController: NSObject {
    private static let statusItemWidth: CGFloat = 147

    var onOpenApp: (() -> Void)?
    var onQuit: (() -> Void)?
    var onMediaAction: ((MediaAction) -> Void)?

    private let item = NSStatusBar.system.statusItem(withLength: statusItemWidth)
    private let marqueeView = StatusBarMarqueeView(width: statusItemWidth)
    private var activePlatform: PlatformID
    private var nowPlaying: NowPlayingInfo?

    init(activePlatform: PlatformID) {
        self.activePlatform = activePlatform
        super.init()
        item.length = Self.statusItemWidth
        if let button = item.button {
            button.title = ""
            marqueeView.frame = button.bounds
            marqueeView.autoresizingMask = [.width, .height]
            button.addSubview(marqueeView)
        }
        update(activePlatform: activePlatform, nowPlaying: nil)
    }

    func update(activePlatform: PlatformID, nowPlaying: NowPlayingInfo?) {
        self.activePlatform = activePlatform
        self.nowPlaying = nowPlaying

        marqueeView.setTitle(title(activePlatform: activePlatform, nowPlaying: nowPlaying))
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if let nowPlaying {
            let titleItem = NSMenuItem(title: nowPlaying.title, action: nil, keyEquivalent: "")
            titleItem.isEnabled = false
            menu.addItem(titleItem)

            let artistItem = NSMenuItem(title: nowPlaying.artist, action: nil, keyEquivalent: "")
            artistItem.isEnabled = false
            menu.addItem(artistItem)
        } else {
            let platformItem = NSMenuItem(title: "Active: \(PlatformCatalog.config(for: activePlatform).label)", action: nil, keyEquivalent: "")
            platformItem.isEnabled = false
            menu.addItem(platformItem)
        }

        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Previous", action: #selector(previous)))
        menu.addItem(menuItem(title: "Play/Pause", action: #selector(playPause)))
        menu.addItem(menuItem(title: "Next", action: #selector(next)))
        menu.addItem(.separator())
        menu.addItem(menuItem(title: "Open AllinOne", action: #selector(openApp)))
        menu.addItem(menuItem(title: "Quit", action: #selector(quit)))

        item.menu = menu
    }

    private func menuItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func title(activePlatform: PlatformID, nowPlaying: NowPlayingInfo?) -> String {
        if let nowPlaying, !nowPlaying.title.isEmpty {
            let artist = nowPlaying.artist.isEmpty ? PlatformCatalog.config(for: nowPlaying.platform).label : nowPlaying.artist
            return "♫ \(nowPlaying.title) - \(artist)"
        }

        return "♫ \(PlatformCatalog.config(for: activePlatform).label)"
    }

    @objc private func previous() {
        onMediaAction?(.previous)
    }

    @objc private func playPause() {
        onMediaAction?(.playPause)
    }

    @objc private func next() {
        onMediaAction?(.next)
    }

    @objc private func openApp() {
        onOpenApp?()
    }

    @objc private func quit() {
        onQuit?()
    }
}

@MainActor
private final class StatusBarMarqueeView: NSView {
    private let label = NSTextField(labelWithString: "")
    private let trailingLabel = NSTextField(labelWithString: "")
    private let horizontalInset: CGFloat = 8
    private let marqueeGap: CGFloat = 36
    private let scrollStep: CGFloat = 0.55
    private var timer: Timer?
    private var offset: CGFloat = 0
    private var titleWidth: CGFloat = 0

    init(width: CGFloat) {
        let height = NSStatusBar.system.thickness
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        wantsLayer = true
        layer?.masksToBounds = true
        buildInterface()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    deinit {
        timer?.invalidate()
    }

    func setTitle(_ title: String) {
        guard label.stringValue != title else { return }

        label.stringValue = title
        trailingLabel.stringValue = title
        offset = 0
        titleWidth = ceil(label.intrinsicContentSize.width)
        configureTimer()
        needsLayout = true
    }

    override func layout() {
        super.layout()

        let availableWidth = bounds.width - horizontalInset * 2
        let labelHeight = bounds.height
        let y = (bounds.height - labelHeight) / 2

        if titleWidth <= availableWidth {
            label.frame = NSRect(x: horizontalInset, y: y, width: availableWidth, height: labelHeight)
            trailingLabel.isHidden = true
        } else {
            label.frame = NSRect(x: horizontalInset - offset, y: y, width: titleWidth, height: labelHeight)
            trailingLabel.frame = NSRect(x: label.frame.maxX + marqueeGap, y: y, width: titleWidth, height: labelHeight)
            trailingLabel.isHidden = false
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func buildInterface() {
        [label, trailingLabel].forEach { textField in
            textField.font = .menuBarFont(ofSize: 0)
            textField.textColor = .labelColor
            textField.lineBreakMode = .byClipping
            textField.alignment = .left
            textField.isBezeled = false
            textField.drawsBackground = false
            textField.isEditable = false
            textField.isSelectable = false
            addSubview(textField)
        }
    }

    private func configureTimer() {
        timer?.invalidate()
        timer = nil

        let availableWidth = bounds.width - horizontalInset * 2
        guard titleWidth > availableWidth else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advance()
            }
        }
    }

    private func advance() {
        offset += scrollStep

        let resetPoint = titleWidth + marqueeGap
        if offset >= resetPoint {
            offset = 0
        }

        needsLayout = true
    }
}
