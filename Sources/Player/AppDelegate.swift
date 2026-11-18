import AppKit
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var playerWindow = PlayerWindowController()

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        showPlayer(url)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        playerWindow.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, UTType("com.apple.m4v-video")].compactMap { $0 }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        showPlayer(url)
    }

    private func showPlayer(_ url: URL) {
        playerWindow.showWindow(nil)
        playerWindow.open(url)
    }
}
