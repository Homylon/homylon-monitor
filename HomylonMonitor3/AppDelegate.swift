//
//  AppDelegate.swift
//  HomylonMonitor3
//
//  Created by Rob on 02/06/2023.
//  Copyright © 2023 Rob Ista. All rights reserved.
//
//  The iPhone/iPad app's lifecycle. Everything that talks to the engine is in
//  Shared/MonitorLink.swift, the same for the Mac and Apple TV apps.

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Device names are visible in the engine log and make two monitors on the same network
    /// distinct. The app prefix keeps the role obvious there.
    private lazy var link: MonitorLink = {
        let deviceName = UIDevice.current.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return MonitorLink(identifier: deviceName.isEmpty ? "HomylonMonitor" : "HomylonMonitor \(deviceName)")
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = link
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // This monitor is a dashboard, so it should stay illuminated while it is the
        // foreground app. The user can still lock the device or leave the app normally.
        application.isIdleTimerDisabled = true
        link.activate()
        NotificationCenter.default.post(name: Notification.Name("AppBecameActive"), object: nil)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        application.isIdleTimerDisabled = false
        link.deactivate()
    }
}
