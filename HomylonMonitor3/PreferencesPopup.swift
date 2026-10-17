//  The settings popup for iPhone, iPad and Apple TV (UIKit).

import UIKit

// MARK: - the popup

extension Preferences {
    
    /// A plain alert with two fields. Deliberately not a whole settings screen: there
    /// are two values, and this works unchanged back to iOS 12.
    static func presentPortSettings(from presenter: UIViewController) {
        
        let alert = UIAlertController(
            title: "Monitor settings",
            //message: "These must match the port in your Homylon \"monitor ... port\" line.\n"
            //       + "Defaults are \(defaultTCPPort) (TCP) and \(defaultUDPPort) (UDP).",
            message: "The engine is found automatically at home. The address below is only used when it cannot be, for instance over a VPN.",
            preferredStyle: .alert)

        alert.addTextField { field in
            addProtocolLabel("Engine", to: field)
            field.placeholder = "used when not found (optional)"
            field.text = engineAddressFallback ?? ""
            field.keyboardType = .numbersAndPunctuation
            field.autocorrectionType = .no
            field.clearButtonMode = .whileEditing
            field.accessibilityLabel = "Engine address"
        }
        alert.addTextField { field in
            addProtocolLabel("TCP", to: field)
            field.placeholder = "TCP port"
            field.text = String(tcpPort)
            field.keyboardType = .numberPad
            field.clearButtonMode = .whileEditing
            field.accessibilityLabel = "TCP port"
        }
        alert.addTextField { field in
            addProtocolLabel("UDP", to: field)
            field.placeholder = "UDP port"
            field.text = String(udpPort)
            field.keyboardType = .numberPad
            field.clearButtonMode = .whileEditing
            field.accessibilityLabel = "UDP port"
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let fields = alert.textFields ?? []
            let engineText = (fields.count > 0 ? fields[0].text ?? "" : "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let tcpText = fields.count > 1 ? fields[1].text ?? "" : ""
            let udpText = fields.count > 2 ? fields[2].text ?? "" : ""

            guard engineText.isEmpty || isValidIPv4(engineText) else {
                report("The engine address must be an IPv4 address such as 192.168.1.10, or blank.",
                       from: presenter); return
            }
            guard let tcp = Int(tcpText), let udp = Int(udpText) else {
                report("Both ports must be numbers.", from: presenter); return
            }
            guard isValid(tcp), isValid(udp) else {
                report("Ports must be between 1024 and 65535.", from: presenter); return
            }
            guard tcp != udp else {
                report("TCP and UDP must use different ports.", from: presenter); return
            }
            
            let changed = (tcp != tcpPort) || (udp != udpPort)
            tcpPort = tcp
            udpPort = udp
            
            if changed {
                NotificationCenter.default.post(name: portsChanged, object: nil)
            }

            let newEngine: String? = engineText.isEmpty ? nil : engineText
            if newEngine != engineAddressFallback {
                engineAddressFallback = newEngine
                NotificationCenter.default.post(name: engineChanged, object: nil)
            }
        })
        
        presenter.present(alert, animated: true)
    }

    /// UIAlertController deliberately supports text fields but not arbitrary label
    /// layouts. A field's `leftView` is public UIKit API, so it gives us an unambiguous
    /// protocol label without replacing the standard alert with a custom controller.
    private static func addProtocolLabel(_ protocolName: String, to field: UITextField) {
        let label = UILabel()
        label.text = "\(protocolName)  "
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .gray
        label.sizeToFit()
        field.leftView = label
        field.leftViewMode = .always
    }
    
    /// Say what was wrong and offer the form straight back, rather than dropping the
    /// edit on the floor.
    private static func report(_ message: String, from presenter: UIViewController) {
        let alert = UIAlertController(title: "Not saved", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try again", style: .default) { _ in
            presentPortSettings(from: presenter)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        presenter.present(alert, animated: true)
    }
}
