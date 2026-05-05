import AppKit

private let app = NSApplication.shared
private let appDelegate = AppDelegate()

StartupLogger.log("main.swift entered")
app.setActivationPolicy(.regular)
app.delegate = appDelegate
app.run()
