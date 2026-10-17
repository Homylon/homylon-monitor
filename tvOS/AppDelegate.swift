// The Apple TV app's lifecycle. Everything that talks to the engine is in
// Shared/MonitorLink.swift, the same as on iPhone/iPad and Mac.

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// The Apple TV's name makes two monitors on the same network distinct in the engine log.
    private lazy var link: MonitorLink = {
        let name = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return MonitorLink(identifier: name.isEmpty ? "HomylonMonitor" : "HomylonMonitor \(name)")
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = MonitorTVViewController()
        window.makeKeyAndVisible()
        self.window = window
        _ = link
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // A dashboard: keep the screen on while the monitor is in front.
        application.isIdleTimerDisabled = true
        link.activate()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.isIdleTimerDisabled = false
        link.deactivate()
    }
}
