// The Mac settings: the same three values as the iPhone/iPad popup, in a sheet.

import AppKit

enum SettingsSheet {

    static func present(on window: NSWindow) {
        let alert = NSAlert()
        alert.messageText = "Monitor settings"
        alert.informativeText = "The engine is found automatically at home. The address below is only used when it cannot be, for instance over a VPN."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let engine = field(Preferences.engineAddressFallback ?? "", placeholder: "used when not found (optional)")
        let tcp = field(String(Preferences.tcpPort), placeholder: "TCP port")
        let udp = field(String(Preferences.udpPort), placeholder: "UDP port")

        let grid = NSGridView(views: [
            [label("Engine"), engine],
            [label("TCP"), tcp],
            [label("UDP"), udp],
        ])
        grid.column(at: 1).width = 220
        grid.rowSpacing = 8
        grid.frame = NSRect(x: 0, y: 0, width: 280, height: 84)
        alert.accessoryView = grid

        alert.beginSheetModal(for: window) { response in
            guard response == .alertFirstButtonReturn else { return }
            let engineText = engine.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            guard engineText.isEmpty || Preferences.isValidIPv4(engineText) else {
                report("The engine address must be an IPv4 address such as 192.168.1.10, or blank.", on: window)
                return
            }
            guard let tcpPort = Int(tcp.stringValue), let udpPort = Int(udp.stringValue) else {
                report("Both ports must be numbers.", on: window)
                return
            }
            guard Preferences.isValid(tcpPort), Preferences.isValid(udpPort) else {
                report("Ports must be between 1024 and 65535.", on: window)
                return
            }
            guard tcpPort != udpPort else {
                report("TCP and UDP must use different ports.", on: window)
                return
            }

            if tcpPort != Preferences.tcpPort || udpPort != Preferences.udpPort {
                Preferences.tcpPort = tcpPort
                Preferences.udpPort = udpPort
                NotificationCenter.default.post(name: Preferences.portsChanged, object: nil)
            }
            let newEngine: String? = engineText.isEmpty ? nil : engineText
            if newEngine != Preferences.engineAddressFallback {
                Preferences.engineAddressFallback = newEngine
                NotificationCenter.default.post(name: Preferences.engineChanged, object: nil)
            }
        }
    }

    private static func field(_ value: String, placeholder: String) -> NSTextField {
        let field = NSTextField(string: value)
        field.placeholderString = placeholder
        return field
    }

    private static func label(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = .secondaryLabelColor
        return label
    }

    /// Say what was wrong and offer the form straight back, rather than dropping the edit.
    private static func report(_ message: String, on window: NSWindow) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Not saved"
            alert.informativeText = message
            alert.addButton(withTitle: "Try again")
            alert.addButton(withTitle: "Cancel")
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn { present(on: window) }
            }
        }
    }
}
