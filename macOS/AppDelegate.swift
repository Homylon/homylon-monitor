// The Mac app's lifecycle and menu. Everything that talks to the engine is in
// Shared/MonitorLink.swift, the same as on iPhone/iPad and Apple TV.

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow?
    private var viewController: MonitorViewController?

    /// The Mac's name makes two monitors on the same network distinct in the engine log.
    private lazy var link: MonitorLink = {
        let name = Host.current().localizedName ?? ""
        return MonitorLink(identifier: name.isEmpty ? "HomylonMonitor" : "HomylonMonitor \(name)")
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        let viewController = MonitorViewController()
        let window = NSWindow(contentViewController: viewController)
        window.title = "Homylon Monitor"
        window.setContentSize(NSSize(width: 900, height: 560))
        window.minSize = NSSize(width: 480, height: 300)
        window.setFrameAutosaveName("HomylonMonitorWindow")
        window.makeKeyAndOrderFront(nil)
        self.window = window
        self.viewController = viewController

        NSApp.activate(ignoringOtherApps: true)
        // A Mac monitor keeps watching while it is in the background, unlike a phone.
        link.activate()
    }

    func applicationWillTerminate(_ notification: Notification) {
        link.deactivate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc private func openSettings(_ sender: Any?) {
        guard let window else { return }
        SettingsSheet.present(on: window)
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Homylon Monitor",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let settings = appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings(_:)), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Homylon Monitor", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Homylon Monitor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowItem.submenu = windowMenu
        mainMenu.addItem(windowItem)
        NSApp.windowsMenu = windowMenu

        NSApp.mainMenu = mainMenu
    }
}
