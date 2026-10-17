import Foundation

protocol ProcessorDelegate : AnyObject {
    func updateMonitorMessages(_ jsonObject: [String: Any])
}

class Processor {
    static let shared = Processor()

    weak var delegate: ProcessorDelegate?
    
    func processReceivedJSON(_ jsonObject: [String: Any], completionHandler: @escaping (Result<String, Error>) -> Void) {
        // Instead of posting a notification...
        // NotificationCenter.default.post(name: .dataDidUpdate, object: nil, userInfo: jsonObject)
        // Call the delegate method
        self.delegate?.updateMonitorMessages(jsonObject)
        
        // Call the completion handler as needed, e.g., completionHandler(.success("Message processed"))
    }
}

