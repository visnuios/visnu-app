import UIKit

final class OrderTrackingViewController: UIViewController {

    private var order: Order
    private var observer: NSObjectProtocol?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let flow: [OrderStatus] = [
        .pending, .accepted, .preparing, .readyForPickup, .outForDelivery, .delivered
    ]

    init(order: Order) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Track Order"
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        observer = NotificationCenter.default.addObserver(
            forName: .ordersDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task {
                if let fresh = try? await DemoOrderRepository().order(id: self.order.id) {
                    self.order = fresh
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func isCompleted(_ status: OrderStatus) -> Bool {
        guard let currentIndex = order.status.progressIndex,
              let stepIndex = flow.firstIndex(of: status) else { return false }
        return stepIndex <= currentIndex
    }
}

extension OrderTrackingViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        order.status == .cancelled || order.status == .rejected ? 1 : flow.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Order #\(order.id) · \(order.shopName)"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TrackCell")
        cell.selectionStyle = .none

        if order.status == .cancelled || order.status == .rejected {
            cell.textLabel?.text = "❌ \(order.status.displayTitle)"
            cell.textLabel?.textColor = .systemRed
            cell.detailTextLabel?.text = "This order was cancelled."
            return cell
        }

        let step = flow[indexPath.row]
        let done = isCompleted(step)
        let isCurrent = step == order.status

        let symbol = done ? "✓" : "○"
        cell.textLabel?.text = "\(symbol) \(step.displayTitle)"
        cell.textLabel?.font = isCurrent
            ? .boldSystemFont(ofSize: 16)
            : .systemFont(ofSize: 15)
        cell.textLabel?.textColor = done ? .label : .tertiaryLabel

        switch step {
        case .pending:
            cell.detailTextLabel?.text = done ? "We received your order" : nil
        case .accepted:
            cell.detailTextLabel?.text = done ? "\(order.shopName) accepted your order" : nil
        case .preparing:
            cell.detailTextLabel?.text = done ? "Your items are being packed" : nil
        case .readyForPickup:
            cell.detailTextLabel?.text = done ? "Ready for the delivery partner" : nil
        case .outForDelivery:
            cell.detailTextLabel?.text = done ? "On the way to you" : nil
        case .delivered:
            cell.detailTextLabel?.text = done ? "Enjoy your order!" : nil
        default:
            break
        }
        return cell
    }
}
