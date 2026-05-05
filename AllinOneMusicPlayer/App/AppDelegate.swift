import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appController: AppController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        StartupLogger.log("applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.regular)

        let controller = AppController()
        appController = controller
        controller.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        StartupLogger.log("applicationDidBecomeActive")
        appController?.showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        StartupLogger.log("applicationShouldHandleReopen hasVisibleWindows=\(flag)")
        appController?.showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
