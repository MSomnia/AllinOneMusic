import Foundation

enum MediaAction: CaseIterable {
    case playPause
    case next
    case previous

    var title: String {
        switch self {
        case .playPause:
            return "Play/Pause"
        case .next:
            return "Next"
        case .previous:
            return "Previous"
        }
    }
}
