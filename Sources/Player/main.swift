import AppKit

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.mainMenu = makeMainMenu()
    withExtendedLifetime(delegate) {
        application.run()
    }
}
