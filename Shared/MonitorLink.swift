// The monitor's link with the Homylon engine, the same on iPhone/iPad, Mac and Apple TV:
// find the engine, listen for its messages, and register with a heartbeat.
//
// Each app only says when it is active (activate/deactivate); everything else happens here.

import Foundation
import HomylonKit

final class MonitorLink {

    /// The name the engine shows for this monitor, e.g. "HomylonMonitor Rob's iPad".
    let identifier: String

    /// Re-register every few seconds while active. The engine skips a heartbeat monitor that
    /// has gone quiet (locked iPad, app in the background) instead of sending into the void.
    private let heartbeatInterval: TimeInterval = 3
    private var heartbeat: Timer?

    private let finder: EngineFinder
    private var isActive = false

    private var tcpServer: TCPServer?
    private var udpServer: UDPServer?
    /// Listener creation and cancellation must be serial. In particular, a listener
    /// must be allowed to release its port before the replacement binds it.
    private let serverQueue = DispatchQueue(label: "com.homylonmonitor.servers")
    private var serverGeneration = 0

    init(identifier: String) {
        self.identifier = identifier
        MonitorLink.keepLastEngineFromBefore()
        finder = EngineFinder(storageKey: "HomylonMonitor",
                              settingsAddress: { Preferences.engineAddressFallback })
        finder.onEngine = { [weak self] engine in
            print("Engine at \(engine.description)")
            self?.register()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(portsChanged),
                                               name: Preferences.portsChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(engineChanged),
                                               name: Preferences.engineChanged, object: nil)
    }

    // MARK: - active or not

    /// The app is in front: listen, look for the engine, and keep registering.
    func activate() {
        guard !isActive else { return }
        isActive = true
        restartServers()
        finder.start()
        let heartbeat = Timer(timeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.register(quietly: true)
        }
        RunLoop.main.add(heartbeat, forMode: .common)
        self.heartbeat = heartbeat
    }

    /// The app goes to the background: stop everything, so the engine stops sending here.
    func deactivate() {
        guard isActive else { return }
        isActive = false
        heartbeat?.invalidate()
        heartbeat = nil
        finder.stop()
        stopServers()
    }

    // MARK: - registering

    private func register(quietly: Bool = false) {
        guard isActive, let engine = finder.engine else { return }
        guard let ownAddress = localAddress(toward: engine.address) else {
            print("Cannot register monitor: no local IPv4 route to the engine at \(engine.address)")
            return
        }
        let monitor: [String: Any] = [
            "name": identifier,
            "address": ownAddress,
            "port": String(Preferences.tcpPort),
            "protocol": "tcp",
            "types": "all",
            "heartbeat": heartbeatInterval,
        ]
        // Registration and heartbeat are small, so UDP to the engine's UDP port. Log lines come
        // back over TCP because "protocol" above asks for that explicitly: long lines are not dropped.
        Homylon.send(["action": "RegisterMonitor", "monitor": monitor],
                     to: engine.address, port: engine.udpPort, over: .udp)
        if !quietly {
            print("Registered monitor \(identifier) at \(ownAddress):\(Preferences.tcpPort) "
                + "with engine \(engine.address):\(engine.tcpPort)")
        }
    }

    // MARK: - listening

    /// Replace both listeners after an app return or a port edit. iOS can suspend an app in
    /// the background, leaving a previously valid listener unusable when the app wakes.
    /// Recreating listeners is deterministic; waiting briefly avoids an "address already in
    /// use" race while their old ports are released.
    private func restartServers() {
        serverQueue.async { [weak self] in
            guard let self = self else { return }
            self.serverGeneration += 1
            let generation = self.serverGeneration
            self.tcpServer?.stop()
            self.udpServer?.stop()
            self.tcpServer = nil
            self.udpServer = nil

            self.serverQueue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.serverGeneration == generation else { return }
                let tcp = TCPServer()
                tcp.delegate = self
                tcp.start(onPort: UInt16(Preferences.tcpPort), queue: self.serverQueue)
                self.tcpServer = tcp

                let udp = UDPServer()
                udp.delegate = self
                udp.start(onPort: UInt16(Preferences.udpPort), queue: self.serverQueue)
                self.udpServer = udp

                print("Listening on TCP \(Preferences.tcpPort) / UDP \(Preferences.udpPort)")
                DispatchQueue.main.async { [weak self] in self?.register() }
            }
        }
    }

    private func stopServers() {
        serverQueue.async { [weak self] in
            guard let self = self else { return }
            self.serverGeneration += 1
            self.tcpServer?.stop()
            self.udpServer?.stop()
            self.tcpServer = nil
            self.udpServer = nil
        }
    }

    @objc private func portsChanged() {
        guard isActive else { return }
        restartServers()
    }

    @objc private func engineChanged() {
        finder.settingsChanged()
        register()
    }

    // MARK: - receiving

    private func handleReceivedData(_ data: Data?) {
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data),
              let json = object as? [String: Any] else {
            print("Received data could not be read as JSON")
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.finder.engineAnswered()
            Processor.shared.processReceivedJSON(json) { result in
                if case .failure(let error) = result {
                    print("Error with received JSON: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Keeps the engine Monitor3 remembered before it used HomylonKit, so an update does not
    /// forget where the engine was.
    private static func keepLastEngineFromBefore() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "HomylonMonitor.lastEngineAddress") == nil,
              let address = defaults.string(forKey: "LastEngineAddress"), !address.isEmpty else { return }
        defaults.set(address, forKey: "HomylonMonitor.lastEngineAddress")
        defaults.set(defaults.integer(forKey: "LastEnginePort"), forKey: "HomylonMonitor.lastEnginePort")
    }
}

extension MonitorLink: TCPServerDelegate, UDPServerDelegate {
    func tcpDidReceiveData(_ data: Data?, from: String) { handleReceivedData(data) }
    func udpDidReceiveData(_ data: Data?, from: String) { handleReceivedData(data) }

    func tcpDidFailToStartWithError(_ error: Error) { print("Monitor TCP listener failed to start: \(error)") }
    func udpDidFailToStartWithError(_ error: Error) { print("Monitor UDP listener failed to start: \(error)") }
    func tcpDidStartSuccessfully(onPort: Int) { print("Listening on TCP port \(onPort)") }
    func udpDidStartSuccessfully(onPort: Int) { print("Listening on UDP port \(onPort)") }
    func tcpDidReportMessage(_ message: String) { print("Monitor TCP: \(message)") }
}
