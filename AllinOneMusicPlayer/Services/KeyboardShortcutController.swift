import AppKit

@MainActor
final class KeyboardShortcutController {
    var onMediaAction: ((MediaAction) -> Void)?
    var onPlatformShortcut: ((PlatformID) -> Void)?

    private var keyDownMonitor: Any?
    private var mediaKeyMonitor: Any?

    init() {
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            return self.handleKeyDown(event)
        }

        mediaKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            guard let self else { return event }
            return self.handleSystemDefined(event)
        }
    }

    deinit {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
        }
        if let mediaKeyMonitor {
            NSEvent.removeMonitor(mediaKeyMonitor)
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.isEmpty, let key = event.charactersIgnoringModifiers else {
            return event
        }

        switch key {
        case "1":
            onPlatformShortcut?(.youtube)
            return nil
        case "2":
            onPlatformShortcut?(.spotify)
            return nil
        case "3":
            onPlatformShortcut?(.netease)
            return nil
        case " ":
            onMediaAction?(.playPause)
            return nil
        default:
            return event
        }
    }

    private func handleSystemDefined(_ event: NSEvent) -> NSEvent? {
        guard event.subtype.rawValue == 8 else { return event }

        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyFlags = event.data1 & 0x0000FFFF
        let keyState = (keyFlags & 0xFF00) >> 8
        guard keyState == 0x0A else { return event }

        switch keyCode {
        case 16:
            onMediaAction?(.playPause)
            return nil
        case 17:
            onMediaAction?(.next)
            return nil
        case 18:
            onMediaAction?(.previous)
            return nil
        default:
            return event
        }
    }
}
