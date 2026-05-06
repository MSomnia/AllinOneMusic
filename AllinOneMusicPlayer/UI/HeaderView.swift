import AppKit

@MainActor
final class HeaderView: NSVisualEffectView {
    var onPlatformSelected: ((PlatformID) -> Void)? {
        get { tabBarView.onPlatformSelected }
        set { tabBarView.onPlatformSelected = newValue }
    }
    var onSearchQueryChanged: ((String) -> Void)? {
        get { searchFieldView.onQueryChanged }
        set { searchFieldView.onQueryChanged = newValue }
    }
    var onSearchCancelled: (() -> Void)? {
        get { searchFieldView.onEscape }
        set { searchFieldView.onEscape = newValue }
    }

    private let tabBarView: PlatformTabBarView
    private let searchFieldView = SearchFieldView()

    init(platforms: [PlatformConfig]) {
        tabBarView = PlatformTabBarView(platforms: platforms)
        super.init(frame: .zero)

        material = .headerView
        blendingMode = .withinWindow
        state = .active
        buildInterface()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func select(_ platform: PlatformID) {
        tabBarView.select(platform)
    }

    func focusSearch() {
        window?.makeFirstResponder(searchFieldView)
    }

    func setSearchQuery(_ query: String) {
        guard searchFieldView.stringValue != query else { return }
        searchFieldView.stringValue = query
    }

    private func buildInterface() {
        let titleLabel = NSTextField(labelWithString: "AllinOne Music Player")
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        searchFieldView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(tabBarView)
        addSubview(searchFieldView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),

            tabBarView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 18),
            tabBarView.trailingAnchor.constraint(lessThanOrEqualTo: searchFieldView.leadingAnchor, constant: -18),
            tabBarView.centerXAnchor.constraint(equalTo: centerXAnchor).withPriority(.defaultHigh),
            tabBarView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            tabBarView.widthAnchor.constraint(greaterThanOrEqualToConstant: 360),

            searchFieldView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            searchFieldView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            searchFieldView.widthAnchor.constraint(equalToConstant: 260),
        ])
    }
}

private extension NSLayoutConstraint {
    func withPriority(_ priority: Priority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
