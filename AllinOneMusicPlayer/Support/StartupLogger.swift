import Foundation

enum StartupLogger {
    private static let logURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("AllinOneMusicPlayer-startup.log")

    static func log(_ message: String) {
        let line = "[\(Date())] \(message)\n"
        NSLog("[AllinOne] %@", message)

        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path) {
            guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logURL)
        }
    }
}
