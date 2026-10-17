//
//  Preferences.swift
//  HomylonMonitor3
//
//  The monitor's settings, shared by the iPhone/iPad, Mac and Apple TV apps. Each app has
//  its own screen to change them (PreferencesPopup.swift for UIKit).
//
//  The ports used to be `let` constants in AppDelegate, so changing one meant a
//  recompile - and getting it wrong failed silently: the engine happily sent to a
//  port nobody was listening on and the monitor just stayed empty. Worse, the two
//  monitor apps were built for different ports (HomylonMonitor 55210/55211,
//  HomylonMonitor3 55212/55213), so pointing a script at the wrong one looked
//  exactly like a broken engine.
//

import Foundation

enum Preferences {
    
    static let defaultTCPPort = 55212
    static let defaultUDPPort = 55213
    
    /// Posted after the user changes a port, so the servers can be restarted.
    static let portsChanged = Notification.Name("HomylonMonitorPortsChanged")
    
    private static let tcpKey = "TCPPort"
    private static let udpKey = "UDPPort"
    
    static var tcpPort: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: tcpKey)
            return isValid(stored) ? stored : defaultTCPPort
        }
        set { UserDefaults.standard.set(newValue, forKey: tcpKey) }
    }
    
    static var udpPort: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: udpKey)
            return isValid(stored) ? stored : defaultUDPPort
        }
        set { UserDefaults.standard.set(newValue, forKey: udpKey) }
    }
    
    /// Below 1024 needs privileges an iOS app does not have, so refuse it here
    /// rather than let the listener fail somewhere the user cannot see.
    static func isValid(_ port: Int) -> Bool {
        return port >= 1024 && port <= 65535
    }

    // MARK: - engine address

    /// The engine's TCP port when its address is typed in rather than found by Bonjour.
    static let defaultEngineTCPPort = 55050

    /// Posted after the user changes the engine address.
    static let engineChanged = Notification.Name("HomylonMonitorEngineChanged")

    // The stored key keeps its old name, so an address saved earlier stays saved.
    private static let engineAddressKey = "EngineAddressOverride"

    /// Used only when Bonjour cannot find the engine (over a VPN, from another network),
    /// never instead of it. Nil means "no fallback address". The last engine that answered
    /// is remembered by HomylonKit's EngineFinder.
    static var engineAddressFallback: String? {
        get {
            let address = UserDefaults.standard.string(forKey: engineAddressKey) ?? ""
            return address.isEmpty ? nil : address
        }
        set { UserDefaults.standard.set(newValue ?? "", forKey: engineAddressKey) }
    }

    /// The registration needs the local address on the route to the engine, which is only
    /// determined for a numeric IPv4 address - so a host name is refused here.
    static func isValidIPv4(_ address: String) -> Bool {
        var parsed = in_addr()
        return address.withCString { inet_pton(AF_INET, $0, &parsed) } == 1
    }
}
