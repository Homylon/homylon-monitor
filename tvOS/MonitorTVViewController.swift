// The Apple TV monitor: a header (title, this Apple TV's addresses, a Settings button for the
// Siri Remote) and the engine's messages in TV-sized type, newest at the bottom, in the same
// colours as on iPhone/iPad and Mac. Built in code: iOS storyboards do not run on tvOS.

import UIKit
import HomylonKit

final class MonitorTVViewController: UIViewController {

    private var messages: [[String: Any]] = []
    /// The Apple TV may run for days; keep the newest messages only.
    private let maximumMessages = 2000
    private let rowHeight: CGFloat = 46

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let titleLabel = UILabel()
    private let addressLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    private var localAddresses = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        titleLabel.text = "Homylon Monitor"
        titleLabel.font = .boldSystemFont(ofSize: 38)
        titleLabel.textColor = .white
        addressLabel.font = .systemFont(ofSize: 24)
        addressLabel.textColor = .lightGray
        addressLabel.textAlignment = .right
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .primaryActionTriggered)

        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.identifier)
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.rowHeight = rowHeight
        tableView.remembersLastFocusedIndexPath = false

        for subview in [titleLabel, addressLabel, settingsButton, tableView] as [UIView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            addressLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -40),
            addressLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 40),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ])

        Processor.shared.delegate = self
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(receivedLocalIPAddresses(_:)),
                           name: Notification.Name(LocalIPAddressesFetchedNotification), object: nil)
        IPAddressFetcher.getLocalIPAddresses()
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [settingsButton]
    }

    @objc private func openSettings() {
        Preferences.presentPortSettings(from: self)
    }

    @objc private func receivedLocalIPAddresses(_ notification: Notification) {
        guard let addresses = notification.userInfo?["LocalIPAddresses"] as? [String] else { return }
        localAddresses = addresses.joined(separator: ", ")
        showAddresses()
    }

    private func showAddresses() {
        addressLabel.text = localAddresses
    }

    fileprivate static func color(_ color: MonitorColor) -> UIColor {
        switch color {
        case .white:  return .white
        case .red:    return .red
        case .green:  return .green
        case .blue:   return UIColor(red: 0.35, green: 0.55, blue: 1, alpha: 1)   // readable on a TV
        case .orange: return .orange
        case .yellow: return .yellow
        }
    }
}

extension MonitorTVViewController: ProcessorDelegate {
    /// Messages are kept in time order: a late one is inserted where it belongs.
    func updateMonitorMessages(_ message: [String: Any]) {
        guard let time = (message["monitorMessageTime"] as? NSNumber)?.doubleValue else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let index = self.messages.firstIndex {
                (($0["monitorMessageTime"] as? NSNumber)?.doubleValue ?? .infinity) > time
            } ?? self.messages.count
            self.messages.insert(message, at: index)
            if self.messages.count > self.maximumMessages {
                self.messages.removeFirst(self.messages.count - self.maximumMessages)
            }
            self.tableView.reloadData()
            let row = min(index, self.messages.count - 1)
            self.tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .bottom, animated: true)
        }
    }
}

extension MonitorTVViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.identifier, for: indexPath) as! MessageCell
        guard indexPath.row < messages.count else { return cell }
        cell.show(messages[indexPath.row])
        return cell
    }
}

/// One message: type, time and text side by side.
private final class MessageCell: UITableViewCell {
    static let identifier = "MessageCell"

    private let typeLabel = UILabel()
    private let timeLabel = UILabel()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .regular)
        timeLabel.textColor = .white
        messageLabel.lineBreakMode = .byTruncatingTail
        for label in [typeLabel, timeLabel, messageLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }
        NSLayoutConstraint.activate([
            typeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            typeLabel.widthAnchor.constraint(equalToConstant: 170),
            timeLabel.leadingAnchor.constraint(equalTo: typeLabel.trailingAnchor, constant: 16),
            timeLabel.widthAnchor.constraint(equalToConstant: 150),
            messageLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            typeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("built in code") }

    func show(_ message: [String: Any]) {
        let type = message["monitorMessageType"] as? String ?? ""
        let style = MonitorMessageStyle(type: type)
        typeLabel.text = type
        typeLabel.font = style.smallType ? .systemFont(ofSize: 22) : .boldSystemFont(ofSize: 28)
        typeLabel.textColor = MonitorTVViewController.color(style.typeColor)
        timeLabel.text = MonitorMessageStyle.time((message["monitorMessageTime"] as? NSNumber)?.doubleValue ?? 0)
        messageLabel.text = message["monitorMessageText"] as? String
        messageLabel.font = .systemFont(ofSize: 28)
        messageLabel.textColor = MonitorTVViewController.color(style.textColor)
    }
}
