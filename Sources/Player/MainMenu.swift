import AppKit

@MainActor
func makeMainMenu() -> NSMenu {
    let mainMenu = NSMenu()

    let appMenu = NSMenu()
    appMenu.addItem(withTitle: String(localized: "menu.hideApp \(Bundle.main.displayName)"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    appMenu.addItem(.separator())
    appMenu.addItem(withTitle: String(localized: "menu.quitApp \(Bundle.main.displayName)"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    let appItem = NSMenuItem()
    appItem.submenu = appMenu
    mainMenu.addItem(appItem)

    let fileMenu = NSMenu(title: String(localized: "menu.file"))
    fileMenu.addItem(withTitle: String(localized: "menu.open"), action: #selector(AppDelegate.openDocument(_:)), keyEquivalent: "o")
    fileMenu.addItem(withTitle: String(localized: "menu.close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
    let fileItem = NSMenuItem()
    fileItem.submenu = fileMenu
    mainMenu.addItem(fileItem)

    return mainMenu
}
