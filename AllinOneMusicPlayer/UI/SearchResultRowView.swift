import AppKit

@MainActor
final class SearchResultRowView: NSControl {
    var onSelect: ((SearchResult) -> Void)?

    private let result: SearchResult
    private let platformLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")

    init(result: SearchResult) {
        self.result = result
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        buildInterface()
        updateTrackingAreas()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func mouseDown(with event: NSEvent) {
    }

    override func mouseUp(with event: NSEvent) {
        guard bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        onSelect?(result)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseEntered(with event: NSEvent) {
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.12).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self
        ))
    }

    private func buildInterface() {
        let iconLabel = NSTextField(labelWithString: result.platform.shortLabel)
        iconLabel.alignment = .center
        iconLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        iconLabel.textColor = .white
        iconLabel.wantsLayer = true
        iconLabel.layer?.cornerRadius = 5
        iconLabel.layer?.backgroundColor = result.platform.tintColor.cgColor

        titleLabel.stringValue = result.title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.alignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.maximumNumberOfLines = 1
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        platformLabel.stringValue = result.platform.displayName
        platformLabel.font = .systemFont(ofSize: 11, weight: .medium)
        platformLabel.textColor = .secondaryLabelColor
        platformLabel.alignment = .right
        platformLabel.lineBreakMode = .byTruncatingTail
        platformLabel.maximumNumberOfLines = 1
        platformLabel.setContentHuggingPriority(.required, for: .horizontal)
        platformLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let secondaryText = [result.artist, result.album].filter { !$0.isEmpty }.joined(separator: " - ")
        detailLabel.stringValue = secondaryText.isEmpty ? result.playbackURL.host ?? "" : secondaryText
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .left
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.maximumNumberOfLines = 1
        detailLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let infoContainer = NSView()
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        infoContainer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        platformLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconLabel)
        addSubview(infoContainer)
        addSubview(platformLabel)
        infoContainer.addSubview(titleLabel)
        infoContainer.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 58),

            iconLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 34),
            iconLabel.heightAnchor.constraint(equalToConstant: 24),

            platformLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            platformLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            platformLabel.widthAnchor.constraint(equalToConstant: 86),

            infoContainer.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            infoContainer.trailingAnchor.constraint(lessThanOrEqualTo: platformLabel.leadingAnchor, constant: -18),
            infoContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            infoContainer.heightAnchor.constraint(equalToConstant: 38),

            titleLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: infoContainer.topAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 18),

            detailLabel.leadingAnchor.constraint(equalTo: infoContainer.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: infoContainer.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
}

private extension PlatformID {
    var displayName: String {
        PlatformCatalog.config(for: self).label
    }

    var shortLabel: String {
        switch self {
        case .youtube:
            return "YT"
        case .spotify:
            return "SP"
        case .netease:
            return "NE"
        }
    }

    var tintColor: NSColor {
        switch self {
        case .youtube:
            return NSColor.systemRed
        case .spotify:
            return NSColor.systemGreen
        case .netease:
            return NSColor.systemPink
        }
    }
}
