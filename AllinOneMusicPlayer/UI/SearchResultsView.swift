import AppKit

@MainActor
final class SearchResultsView: NSVisualEffectView {
    var onResultSelected: ((SearchResult) -> Void)?
    var onClose: (() -> Void)?

    private let contentView = NSView()
    private let stackView = NSStackView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let closeButton = NSButton(title: "x", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .popover
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 8
        buildInterface()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

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

    func update(query: String, results: [SearchResultOrError], isSearching: Bool, isOpen: Bool) {
        isHidden = !isOpen

        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.isEmpty {
            statusLabel.stringValue = "Type to search across platforms"
            stackView.addArrangedSubview(statusLabel)
            return
        }

        if isSearching {
            statusLabel.stringValue = "Searching..."
            stackView.addArrangedSubview(statusLabel)
        }

        let resultItems = results.compactMap { item -> SearchResult? in
            if case .result(let result) = item {
                return result
            }
            return nil
        }

        for result in resultItems {
            let rowView = SearchResultRowView(result: result)
            rowView.onSelect = onResultSelected
            stackView.addArrangedSubview(rowView)
            rowView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }

        for error in results {
            guard case .error(let platform, let message) = error else { continue }
            let label = errorLabel("\(PlatformCatalog.config(for: platform).label): \(message)")
            stackView.addArrangedSubview(label)
        }

        if !isSearching && results.isEmpty {
            statusLabel.stringValue = "No results"
            stackView.addArrangedSubview(statusLabel)
        }
    }

    private func buildInterface() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.font = .systemFont(ofSize: 17, weight: .medium)
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.target = self
        closeButton.action = #selector(closeButtonClicked)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(closeButton)

        stackView.orientation = .vertical
        stackView.spacing = 4
        stackView.alignment = .width
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)

        statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 34),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])
    }

    @objc private func closeButtonClicked() {
        onClose?()
    }

    private func errorLabel(_ message: String) -> NSTextField {
        let label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byTruncatingTail
        return label
    }
}
