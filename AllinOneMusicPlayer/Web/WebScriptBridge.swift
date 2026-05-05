import Foundation
import WebKit

final class WebScriptBridge: NSObject, WKScriptMessageHandler {
    static let shared = WebScriptBridge()

    var onNowPlaying: (@MainActor (NowPlayingInfo) -> Void)?

    private override init() {}

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "allinone" else { return }
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }

        switch type {
        case "__allinone_now_playing":
            guard let info = Self.parseNowPlaying(from: body) else { return }
            Task { @MainActor in
                WebScriptBridge.shared.onNowPlaying?(info)
            }

        case "__allinone_log":
            let value = body["message"].map { String(describing: $0) } ?? ""
            StartupLogger.log("WebScriptBridge: \(value)")

        default:
            break
        }
    }

    private static func parseNowPlaying(from body: [String: Any]) -> NowPlayingInfo? {
        guard
            let rawPlatform = body["platform"] as? String,
            let platform = PlatformID(rawValue: rawPlatform)
        else {
            return nil
        }

        let title = trimmedString(body["title"])
        let artist = trimmedString(body["artist"])
        let album = trimmedString(body["album"])
        let artworkURL = trimmedString(body["artworkUrl"]).flatMap(URL.init(string:))
        let isPlaying = (body["isPlaying"] as? Bool) ?? false

        guard title != nil || artist != nil else { return nil }

        return NowPlayingInfo(
            platform: platform,
            title: title ?? "",
            artist: artist ?? "",
            album: album ?? "",
            artworkURL: artworkURL,
            isPlaying: isPlaying
        )
    }

    private static func trimmedString(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
