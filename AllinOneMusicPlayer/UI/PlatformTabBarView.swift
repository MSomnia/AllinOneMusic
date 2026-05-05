import AppKit

@MainActor
final class PlatformTabBarView: NSView {
    var onPlatformSelected: ((PlatformID) -> Void)?

    private let platforms: [PlatformConfig]
    private let segmentedControl: NSSegmentedControl

    init(platforms: [PlatformConfig]) {
        self.platforms = platforms
        segmentedControl = NSSegmentedControl(labels: platforms.map(\.label), trackingMode: .selectOne, target: nil, action: nil)
        super.init(frame: .zero)

        segmentedControl.target = self
        segmentedControl.action = #selector(platformChanged(_:))
        segmentedControl.segmentStyle = .texturedRounded
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmentedControl)

        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func select(_ platform: PlatformID) {
        guard let index = platforms.firstIndex(where: { $0.id == platform }) else { return }
        segmentedControl.selectedSegment = index
    }

    @objc private func platformChanged(_ sender: NSSegmentedControl) {
        let index = sender.selectedSegment
        guard platforms.indices.contains(index) else { return }
        onPlatformSelected?(platforms[index].id)
    }
}
