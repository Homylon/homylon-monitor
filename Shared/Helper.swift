import Foundation

class Helper {
    
    static func log(_ message: String, _ tag: String?) {
        let timestamp = timeStamp(tag ?? "log")
        //print("\(timestamp) \(message)")
    }

    static func timeStamp(_ tag: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        return "\(tag): \(timestamp)"
    }
    
    static func stamp(_ tag: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        //print("\(tag): \(timestamp)")
    }
}
