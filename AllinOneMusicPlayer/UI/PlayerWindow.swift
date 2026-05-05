import AppKit

@MainActor
final class PlayerWindow: NSWindow {
    var onMediaAction: ((MediaAction) -> Void)?
    var onPlatformShortcut: ((PlatformID) -> Void)?

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers.isEmpty, let key = event.charactersIgnoringModifiers {
            switch key {
            case " ":
                onMediaAction?(.playPause)
                return
            case "1":
                onPlatformShortcut?(.youtube)
                return
            case "2":
                onPlatformShortcut?(.spotify)
                return
            case "3":
                onPlatformShortcut?(.netease)
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }
}
