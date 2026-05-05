import AppKit

@MainActor
final class HeaderView: NSVisualEffectView {
    var onPlatformSelected: ((PlatformID) -> Void)? {
        get { tabBarView.onPlatformSelected }
        set { tabBarView.onPlatformSelected = newValue }
    }

    private let tabBarView: PlatformTabBarView

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

    private func buildInterface() {
        let titleLabel = NSTextField(labelWithString: "AllinOne Music Player")
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)
        addSubview(tabBarView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),

            tabBarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            tabBarView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            tabBarView.widthAnchor.constraint(greaterThanOrEqualToConstant: 420),
        ])
    }
}
