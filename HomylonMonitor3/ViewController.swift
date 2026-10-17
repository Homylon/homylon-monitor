//
//  ViewController.swift
//  HomylonMonitor3
//
//  Created by Rob on 02/06/2023.
//  Copyright © 2023 Rob Ista. All rights reserved.
//

import UIKit
import HomylonKit

//extension Notification.Name {
//    static let dataDidUpdate = Notification.Name("dataDidUpdate")
//}

class MultiColumnTableViewCell: UITableViewCell {
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var contentTextLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    deinit {
        //print("Cell deinitialized")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        typeLabel.text = nil
        timeLabel.text = nil
        contentTextLabel.text = nil
        
        //typeLabel.textColor = UIColor.white
        //timeLabel.textColor = UIColor.yellow
        //contentTextLabel.textColor = UIColor.yellow
        
        backgroundColor = UIColor.clear
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let messageRowHeight: CGFloat = 24
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("Number of rows: \(messageTable.count)")
        return messageTable.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MultiColumnTableViewCell", for: indexPath) as! MultiColumnTableViewCell
        
        guard indexPath.row < messageTable.count else {
            return cell
        }
        
        let item = messageTable[indexPath.row]
        
        // Assuming your MultiColumnTableViewCell has typeLabel, timeLabel, textLabel
        cell.typeLabel.text = item["monitorMessageType"] as? String
        cell.timeLabel.text = numberToDate(item["monitorMessageTime"] as! NSNumber)
        cell.contentTextLabel.text = item["monitorMessageText"] as? String
        
        // Set the fonts here.
        cell.typeLabel.font = UIFont.boldSystemFont(ofSize: 18)
        cell.timeLabel.font = UIFont.systemFont(ofSize: 10)
        cell.contentTextLabel.font = UIFont.systemFont(ofSize: 18)
        
        // Colours come from Shared/MonitorMessageStyle.swift, the same on Mac and Apple TV.
        let style = MonitorMessageStyle(type: item["monitorMessageType"] as? String ?? "")
        let typeColor = Self.color(style.typeColor)
        let textColor = Self.color(style.textColor)
        if style.smallType {
            cell.typeLabel.font = UIFont.systemFont(ofSize: 14)
        }
        cell.typeLabel.textColor = typeColor
        cell.timeLabel.textColor = UIColor.white
        cell.contentTextLabel.textColor = textColor
        
        cell.backgroundColor = UIColor.clear
        
        return cell
    }

    func numberToDate(_ number: NSNumber) -> String {
        return MonitorMessageStyle.time(number.doubleValue)
    }

    private static func color(_ color: MonitorColor) -> UIColor {
        switch color {
        case .white:  return .white
        case .red:    return .red
        case .green:  return .green
        case .blue:   return .blue
        case .orange: return .orange
        case .yellow: return .yellow
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return messageRowHeight
    }
    
    @IBOutlet weak var homylonMonitor: UILabel!
    @IBOutlet weak var intIPAddress: UILabel!
    @IBOutlet weak var extIPAddress: UILabel!     // empty: the public address is no longer looked up (see _parked/public-ip-address)
    
    var logMessages: UITableView = UITableView()
    var messageTable = [Dictionary <AnyHashable, Any>]()
    
    var matrixView: MatrixView?
    let borderWidth: CGFloat = 20.0
    
    // Plain glyph rather than an image or SF Symbol: this app still targets iOS 12.4,
    // where SF Symbols do not exist, and a glyph needs no asset catalogue entry.
    let settingsButton = UIButton(type: .system)
    let settingsButtonSize: CGFloat = 44.0      // Apple's minimum comfortable tap target

    func getTableViewFrame() -> CGRect {
        let safeAreaInsets = view.safeAreaInsets
        let isLandscape = UIDevice.current.orientation.isLandscape

        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat

        if isLandscape {
            // in landscape mode, don't adjust for left and right safe area insets
            x = borderWidth
        } else {
            // in portrait mode, adjust for safe area insets
            x = safeAreaInsets.left + borderWidth
        }

        y = safeAreaInsets.top + borderWidth
        width = view.bounds.width - x - borderWidth

        height = view.bounds.height - safeAreaInsets.top - safeAreaInsets.bottom - borderWidth * 2.0

        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let frame = getTableViewFrame()
        logMessages.frame = frame
        logMessages.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        
        let insets = view.safeAreaInsets
        settingsButton.frame = CGRect(
            x: view.bounds.width - insets.right - settingsButtonSize - borderWidth / 2.0,
            y: insets.top + borderWidth / 2.0,
            width: settingsButtonSize,
            height: settingsButtonSize)
        view.bringSubviewToFront(settingsButton)
        
        matrixView?.frame = UIScreen.main.bounds
        // print("matrixView frame in viewDidLayoutSubviews: \(matrixView?.frame ?? CGRect.zero)")
        matrixView?.restart()
    }
    
    private func setupSettingsButton() {
        settingsButton.setTitle("\u{2699}", for: .normal)          // gear
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 30)
        settingsButton.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
        settingsButton.setTitleColor(UIColor.white, for: .highlighted)
        settingsButton.accessibilityLabel = "Monitor settings"
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        view.addSubview(settingsButton)
    }
    
    @objc private func openSettings() {
        Preferences.presentPortSettings(from: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = getTableViewFrame()
        
        logMessages = UITableView(frame: frame, style: .plain)
        logMessages.register(UINib(nibName: "MultiColumnTableViewCell", bundle: nil), forCellReuseIdentifier: "MultiColumnTableViewCell")
        
        // Assuming the labels are direct subviews of the main view, we are putting the tableview just iunderneath it
        if let firstLabel = view.subviews.first(where: { $0 is UILabel }) {
            view.insertSubview(logMessages, belowSubview: firstLabel)
        } else {
            // If no labels are found, add the table view as normal
            view.addSubview(logMessages)
        }

        // Set the table view's data source and delegate
        logMessages.dataSource = self
        logMessages.delegate = self
        
        logMessages.separatorStyle = .none
        logMessages.backgroundColor = UIColor.clear
        logMessages.rowHeight = messageRowHeight
        logMessages.estimatedRowHeight = messageRowHeight
        logMessages.estimatedSectionHeaderHeight = 0
        logMessages.estimatedSectionFooterHeight = 0
        
        logMessages.tableHeaderView = nil
        logMessages.contentInsetAdjustmentBehavior = .never
        logMessages.allowsSelection = false
        // Leave one row of scrollable room below the final message. This lets
        // `scrollToRow(..., at: .bottom)` bring that row fully into view.
        logMessages.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: messageRowHeight, right: 0)
        if #available(iOS 15.0, *) {
            logMessages.sectionHeaderTopPadding = 0
        }
        
        setupSettingsButton()
        
        // set the delegate of Processor so it can call the delegated functions here
        Processor.shared.delegate = self
        
        self.homylonMonitor.alpha = 0
        self.intIPAddress.alpha = 0
        self.extIPAddress.alpha = 0
        
        self.displayTitleAndAddresses()
        
        startTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedLocalIPAddresses(_:)), name: NSNotification.Name(rawValue: "LocalIPAddressesFetched"), object: nil)
        
        // observe notfications of application coming into active state (again)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive(_:)), name:   Notification.Name("AppBecameActive"), object: nil)
        // add an observer for when the app enters the background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        // observe notifications of data updates
        // NotificationCenter.default.addObserver(self, selector: #selector(dataDidUpdate), name: .dataDidUpdate, object: nil)
        
        matrixView = MatrixView(frame: self.view.frame)
        self.view.insertSubview(matrixView!, at: 0)
        
        let now = Date()
        let timeStamp : Double = now.timeIntervalSince1970 * 1000
        let timeStampNumber = NSNumber(value: timeStamp)
        
        var dictionary = Dictionary <String, Any>()
        dictionary["monitorMessageType"] = "Monitor"
        dictionary["monitorMessageTime"] = timeStampNumber
        dictionary["monitorMessageText"] = "Started"
        
        DispatchQueue.main.async {
            self.messageTable.append(dictionary)
            self.logMessages.reloadData()
        }
        
        // Create a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(displayTitleAndAddresses))
        // Optional: If you want the tap to not interfere with other touch events
        tapGesture.cancelsTouchesInView = false
        // Add the tap gesture recognizer to the view
        self.view.addGestureRecognizer(tapGesture)
    }
    
    var timer: Timer?
    func startTimer() {
        // Invalidate existing timer if there is one
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(fadeOutTableView), userInfo: nil, repeats: false)
    }
    
    @objc func fadeOutTableView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1) {
                self.logMessages.alpha = 0
            }
        }
    }
    
    func fadeInTableView() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 1) {
                self.logMessages.alpha = 1
            }
        }
        startTimer()
    }
    
    @objc func displayTitleAndAddresses() {
        DispatchQueue.main.async {
            // heading
            self.homylonMonitor.showAndFadeOut()
            self.fadeInTableView()
 
        }
        // these functions wil try to get the requested address and send a notification when found
        IPAddressFetcher.getLocalIPAddresses()
    }
    
    @objc func receivedLocalIPAddresses(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let ipAddresses = userInfo["LocalIPAddresses"] as? [String] else {
            return
        }
        DispatchQueue.main.async {
            // Update your UI here with the received local IP addresses
            // For example:
            self.intIPAddress.text = ipAddresses.joined(separator: ", ")
            self.intIPAddress.showAndFadeOut()
        }
    }
    
    @objc private func appBecameActive(_ rnotification: Notification) {
        self.displayTitleAndAddresses()
        matrixView?.restart()
        fadeInTableView()
    }
    
    // this method will be called when the app enters the background
    @objc func appDidEnterBackground(_ notification: Notification) {
        self.matrixView?.clearMatrix()
    }
       
    let messageTableQueue = DispatchQueue(label: "com.homylonmonitor.messageTableQueue")
    
    func updateMonitorMessagesUI(_ dictionary: [String: Any]) {
        guard let dicTime = dictionary["monitorMessageTime"] as? Double else {
            print("Time value is not valid.")
            return
        }

        messageTableQueue.async { [weak self] in
            guard let self = self else {
                print("Could not get self.")
                return
            }

            var scrollIndexPath: IndexPath

            // Find the index where the new message should be inserted.
            if let insertIndex = self.messageTable.firstIndex(where: { (dict) -> Bool in
                (dict["monitorMessageTime"] as? Double ?? .infinity) > dicTime
            }) {
                self.messageTable.insert(dictionary, at: insertIndex)
                scrollIndexPath = IndexPath(row: insertIndex, section: 0)
            } else {
                self.messageTable.append(dictionary)
                scrollIndexPath = IndexPath(row: self.messageTable.count - 1, section: 0)
            }

            DispatchQueue.main.async {
                self.logMessages.reloadData()
                self.logMessages.scrollToRow(at: scrollIndexPath, at: .bottom, animated: true)

            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.displayTitleAndAddresses()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


extension ViewController: ProcessorDelegate {
    func updateMonitorMessages(_ jsonObject: [String: Any]) {
        // print(jsonObject)
        // Messages arrive on a TCP connection's background queue. The fade timer must be
        // created and invalidated on the main thread: two lines arriving at once on two
        // connections used to replace the timer concurrently and crash in CFRelease.
        DispatchQueue.main.async { self.fadeInTableView() }
        updateMonitorMessagesUI(jsonObject)
    }
}

/*
 
 // now unused beacuse we dont really need the display in milliseconds
 func numberToDateAndMilliseconds(_ number: NSNumber) -> String {
     let date = Date(timeIntervalSince1970: TimeInterval(truncating: number))
     
     let calendar = Calendar.current
     let hour = String(format: "%02d", calendar.component(.hour, from: date))
     let minutes = String(format: "%02d",calendar.component(.minute, from: date))
     let seconds = String(format: "%02d",calendar.component(.second, from: date))
     
     let numberString =  String(describing: number)
     let numberArray = numberString.components(separatedBy: ".")
     var thousands = "0000"   // defaultupdate      if numberArray.count > 1 {
         let lowerBound = numberArray[1].index(numberArray[1].startIndex, offsetBy: 0)
         var upperOffset : Int
         if numberArray[1].count < 4 {
             upperOffset = numberArray[1].count
         } else {
             upperOffset = 4
         }
         let upperBound = numberArray[1].index(numberArray[1].startIndex, offsetBy: upperOffset)
         thousands = String(numberArray[1][lowerBound..<upperBound])
     }
     
     return "\(hour):\(minutes):\(seconds) +\(thousands)"
 }
 
 */
