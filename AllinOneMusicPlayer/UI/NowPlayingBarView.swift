import AppKit

@MainActor
final class NowPlayingBarView: NSVisualEffectView {
    var onMediaAction: ((MediaAction) -> Void)?

    private let titleLabel = NSTextField(labelWithString: "Ready")
    private let detailLabel = NSTextField(labelWithString: "")
    private let previousButton = NSButton()
    private let playPauseButton = NSButton()
    private let nextButton = NSButton()
    private var isDispatchingAction = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .underWindowBackground
        blendingMode = .withinWindow
        state = .active
        buildInterface()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(activePlatform: PlatformID, nowPlaying: NowPlayingInfo?) {
        if let nowPlaying {
            titleLabel.stringValue = nowPlaying.title.isEmpty ? "Playing" : nowPlaying.title
            detailLabel.stringValue = nowPlaying.artist.isEmpty ? PlatformCatalog.config(for: nowPlaying.platform).label : nowPlaying.artist
        } else {
            titleLabel.stringValue = PlatformCatalog.config(for: activePlatform).label
            detailLabel.stringValue = "Playback controls"
        }
    }

    private func buildInterface() {
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.lineBreakMode = .byTruncatingTail
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail

        configure(button: previousButton, imageName: "backward.fill", fallbackTitle: "Prev", action: #selector(previous))
        configure(button: playPauseButton, imageName: "playpause.fill", fallbackTitle: "Play", action: #selector(playPause))
        configure(button: nextButton, imageName: "forward.fill", fallbackTitle: "Next", action: #selector(next))

        let textStack = NSStackView(views: [titleLabel, detailLabel])
        textStack.orientation = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = NSStackView(views: [previousButton, playPauseButton, nextButton])
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 8
        buttonStack.alignment = .centerY
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(textStack)
        addSubview(buttonStack)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            textStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: buttonStack.leadingAnchor, constant: -16),

            buttonStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            buttonStack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func configure(button: NSButton, imageName: String, fallbackTitle: String, action: Selector) {
        button.target = self
        button.action = action
        button.bezelStyle = .texturedRounded
        button.setButtonType(.momentaryPushIn)
        button.image = NSImage(systemSymbolName: imageName, accessibilityDescription: fallbackTitle)
        button.title = button.image == nil ? fallbackTitle : ""
        button.imagePosition = .imageOnly
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    @objc private func previous() {
        dispatch(.previous)
    }

    @objc private func playPause() {
        dispatch(.playPause)
    }

    @objc private func next() {
        dispatch(.next)
    }

    private func dispatch(_ action: MediaAction) {
        guard !isDispatchingAction else { return }
        isDispatchingAction = true

        let buttons = [previousButton, playPauseButton, nextButton]
        buttons.forEach { $0.isEnabled = false }

        DispatchQueue.main.async { [weak self] in
            self?.onMediaAction?(action)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                guard let self else { return }
                self.isDispatchingAction = false
                buttons.forEach { $0.isEnabled = true }
            }
        }
    }
}
