import AppKit

@MainActor
final class KeyboardShortcutController {
    var onMediaAction: ((MediaAction) -> Void)?

    private var mediaKeyMonitor: Any?

    init() {
        mediaKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            guard let self else { return event }
            return self.handleSystemDefined(event)
        }
    }

    deinit {
        if let mediaKeyMonitor {
            NSEvent.removeMonitor(mediaKeyMonitor)
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
