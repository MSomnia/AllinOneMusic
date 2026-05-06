import AppKit

@MainActor
final class PlayerWindow: NSWindow {
    var onMediaAction: ((MediaAction) -> Void)?
    var onFocusSearch: (() -> Void)?
    var onCloseSearch: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        if modifiers == .command, event.charactersIgnoringModifiers?.lowercased() == "f" {
            onFocusSearch?()
            return
        }

        if modifiers.isEmpty, let key = event.charactersIgnoringModifiers {
            switch key {
            case "\u{1b}":
                onCloseSearch?()
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }
}
