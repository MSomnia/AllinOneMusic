import MediaPlayer

@MainActor
final class RemoteCommandController {
    var onMediaAction: ((MediaAction) -> Void)?

    private let commandCenter = MPRemoteCommandCenter.shared()

    init() {
        configure()
    }

    private func configure() {
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.dispatch(.playPause)
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.dispatch(.playPause)
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.dispatch(.playPause)
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.dispatch(.next)
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.dispatch(.previous)
            return .success
        }
    }

    private nonisolated func dispatch(_ action: MediaAction) {
        Task { @MainActor [weak self] in
            self?.onMediaAction?(action)
        }
    }
}
