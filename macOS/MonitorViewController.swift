// The Mac monitor window: a header (title, this Mac's internal and external address) and the
// engine's messages, newest at the bottom, in the same colours as on iPhone/iPad.

import AppKit
import HomylonKit

final class MonitorViewController: NSViewController {

    private var messages: [[String: Any]] = []
    /// A Mac monitor may run for days; keep the newest messages only.
    private let maximumMessages = 5000

    private let tableView = NSTableView()
    private let addressLabel = NSTextField(labelWithString: "")
    private var localAddresses = ""

    override func loadView() {
        let root = NSView()
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.black.cgColor
        root.appearance = NSAppearance(named: .darkAqua)

        let title = NSTextField(labelWithString: "Homylon Monitor")
        title.font = .boldSystemFont(ofSize: 15)
        title.textColor = .white
        addressLabel.font = .systemFont(ofSize: 11)
        addressLabel.textColor = .secondaryLabelColor
        addressLabel.alignment = .right

        let header = NSStackView(views: [title, addressLabel])
        header.orientation = .horizontal
        header.distribution = .fill
        title.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addressLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        for (identifier, width) in [("type", 110.0), ("time", 95.0), ("text", 640.0)] {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(identifier))
            column.width = CGFloat(width)
            column.title = identifier.capitalized
            tableView.addTableColumn(column)
        }
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.headerView = nil
        tableView.backgroundColor = .black
        tableView.rowHeight = 22
        tableView.intercellSpacing = NSSize(width: 8, height: 2)
        tableView.dataSource = self
        tableView.delegate = self

        let scroll = NSScrollView()
        scroll.documentView = tableView
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false

        for view in [header, scroll] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 14),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -14),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor),
        ])
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Processor.shared.delegate = self

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(receivedLocalIPAddresses(_:)),
                           name: Notification.Name(LocalIPAddressesFetchedNotification), object: nil)
        IPAddressFetcher.getLocalIPAddresses()
    }

    @objc private func receivedLocalIPAddresses(_ notification: Notification) {
        guard let addresses = notification.userInfo?["LocalIPAddresses"] as? [String] else { return }
        localAddresses = addresses.joined(separator: ", ")
        showAddresses()
    }

    private func showAddresses() {
        addressLabel.stringValue = localAddresses
    }

    private static func color(_ color: MonitorColor) -> NSColor {
        switch color {
        case .white:  return .white
        case .red:    return .systemRed
        case .green:  return .systemGreen
        case .blue:   return .systemBlue
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        }
    }
}

extension MonitorViewController: ProcessorDelegate {
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
            self.tableView.scrollRowToVisible(min(index, self.messages.count - 1))
        }
    }
}

extension MonitorViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        messages.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn?.identifier.rawValue, row < messages.count else { return nil }
        let message = messages[row]
        let type = message["monitorMessageType"] as? String ?? ""
        let style = MonitorMessageStyle(type: type)

        let cell = (tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(column), owner: self) as? NSTextField)
            ?? {
                let field = NSTextField(labelWithString: "")
                field.identifier = NSUserInterfaceItemIdentifier(column)
                field.lineBreakMode = .byTruncatingTail
                field.isSelectable = true
                return field
            }()

        switch column {
        case "type":
            cell.stringValue = type
            cell.font = style.smallType ? .systemFont(ofSize: 11) : .boldSystemFont(ofSize: 13)
            cell.textColor = Self.color(style.typeColor)
        case "time":
            let time = (message["monitorMessageTime"] as? NSNumber)?.doubleValue ?? 0
            cell.stringValue = MonitorMessageStyle.time(time)
            cell.font = .monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            cell.textColor = .white
        default:
            cell.stringValue = message["monitorMessageText"] as? String ?? ""
            cell.font = .systemFont(ofSize: 13)
            cell.textColor = Self.color(style.textColor)
            cell.toolTip = cell.stringValue   // long JSON lines in full
        }
        return cell
    }
}
