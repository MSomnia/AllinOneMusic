import AppKit

final class UserDefaultsStore {
    private enum Key {
        static let lastActivePlatform = "lastActivePlatform"
        static let mainWindowFrame = "mainWindowFrame"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastActivePlatform: PlatformID? {
        get {
            defaults.string(forKey: Key.lastActivePlatform).flatMap(PlatformID.init(rawValue:))
        }
        set {
            defaults.set(newValue?.rawValue, forKey: Key.lastActivePlatform)
        }
    }

    var mainWindowFrame: NSRect? {
        get {
            guard let string = defaults.string(forKey: Key.mainWindowFrame) else { return nil }
            let rect = NSRectFromString(string)
            return rect.isEmpty ? nil : rect
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: Key.mainWindowFrame)
                return
            }
            defaults.set(NSStringFromRect(newValue), forKey: Key.mainWindowFrame)
        }
    }
}
