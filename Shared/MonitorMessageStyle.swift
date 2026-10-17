// How a monitor message looks, the same on iPhone/iPad, Mac and Apple TV: the colour of its
// type and text, and how its time is written. Each app turns these into its own colours.

import Foundation

enum MonitorColor {
    case white, red, green, blue, orange, yellow
}

struct MonitorMessageStyle {
    let typeColor: MonitorColor
    let textColor: MonitorColor
    /// JSON lines are long; their type is shown smaller.
    let smallType: Bool

    init(type: String) {
        switch type {
        case "Warning":                     self.init(.red, .white)
        case "Error", "Alert":              self.init(.red, .red)
        case "Safe":                        self.init(.green, .green)
        case "Engine", "Time", "Monitor":   self.init(.blue, .blue)
        case "<--":                         self.init(.green, .white)
        case "Notify":                      self.init(.orange, .white)
        case "-->":                         self.init(.yellow, .white)
        case "JSONin":                      self.init(.yellow, .yellow, smallType: true)
        case "JSONout":                     self.init(.green, .green, smallType: true)
        default:                            self.init(.white, .white)   // "Log" and anything new
        }
    }

    private init(_ typeColor: MonitorColor, _ textColor: MonitorColor, smallType: Bool = false) {
        self.typeColor = typeColor
        self.textColor = textColor
        self.smallType = smallType
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SS"
        return formatter
    }()

    /// The engine sends milliseconds since 1970; shown as 14:03:27+45.
    static func time(_ milliseconds: Double) -> String {
        var text = timeFormatter.string(from: Date(timeIntervalSince1970: milliseconds / 1000))
        if let range = text.range(of: ":", options: .backwards) {
            text = text.replacingCharacters(in: range, with: "+")
        }
        return text
    }
}
