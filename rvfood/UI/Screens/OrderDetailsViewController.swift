import UIKit

final class OrderDetailsViewController: UIViewController {

    private var order: Order
    private let repository: OrderRepositoryProtocol
    private var observer: NSObjectProtocol?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let actionButton = PrimaryButton(title: "")

    init(order: Order, repository: OrderRepositoryProtocol = DemoOrderRepository()) {
        self.order = order
        self.repository = repository
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
        title = "Order #\(order.id)"
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -8),
            actionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)

        observer = NotificationCenter.default.addObserver(
            forName: .ordersDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadOrder()
        }
        refreshActionButton()
    }

    private func reloadOrder() {
        Task {
            if let fresh = try? await repository.order(id: order.id) {
                order = fresh
                tableView.reloadData()
                refreshActionButton()
            }
        }
    }

    private func refreshActionButton() {
        switch order.status {
        case .pending, .accepted:
            actionButton.setTitle("Cancel Order", for: .normal)
            actionButton.backgroundColor = .systemRed
            actionButton.isHidden = false
        case .delivered:
            actionButton.setTitle("Reorder", for: .normal)
            actionButton.backgroundColor = .systemOrange
            actionButton.isHidden = false
        default:
            actionButton.isHidden = true
        }
    }

    @objc private func actionTapped() {
        switch order.status {
        case .pending, .accepted:
            confirmCancel()
        case .delivered:
            reorder()
        default:
            break
        }
    }

    private func confirmCancel() {
        let alert = UIAlertController(title: "Cancel order?", message: "Are you sure you want to cancel this order?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes, Cancel", style: .destructive) { [weak self] _ in
            self?.cancelOrder()
        })
        present(alert, animated: true)
    }

    private func cancelOrder() {
        actionButton.isEnabled = false
        Task {
            do {
                let cancelled = try await repository.cancelOrder(id: order.id)
                order = cancelled
                NotificationsStore.shared.add(kind: .order, title: "Order #\(order.id) cancelled", message: "Your order was cancelled successfully.")
                tableView.reloadData()
                refreshActionButton()
            } catch {
                presentErrorAlert(error)
            }
            actionButton.isEnabled = true
        }
    }

    private func reorder() {
        actionButton.isEnabled = false
        Task {
            do {
                let result = try await repository.reorder(orderId: order.id)
                if result.addedCount > 0 {
                    var message = "\(result.addedCount) item(s) added to your cart at current prices."
                    if !result.unavailableItems.isEmpty {
                        message += "\n\nUnavailable: \(result.unavailableItems.joined(separator: ", "))"
                    }
                    let alert = UIAlertController(title: "Reorder", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "View Cart", style: .default) { [weak self] _ in
                        self?.tabBarController?.selectedIndex = 3
                        self?.navigationController?.popToRootViewController(animated: true)
                    })
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                    present(alert, animated: true)
                } else {
                    presentErrorAlert(APIError.businessRule("None of these items are available right now."), title: "Reorder")
                }
            } catch {
                presentErrorAlert(error)
            }
            actionButton.isEnabled = true
        }
    }
}

extension OrderDetailsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int { 4 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 2 ? order.items.count : 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Status"
        case 1: return "Delivery Address"
        case 2: return "Items"
        case 3: return "Bill Details"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "DetailCell")
        cell.selectionStyle = .none

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = order.status.displayTitle
            cell.textLabel?.font = .boldSystemFont(ofSize: 16)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            cell.detailTextLabel?.text = "Placed on \(formatter.string(from: order.createdAt)) · \(order.paymentMethod.displayTitle)\(order.isPaid ? " (Paid)" : "")"
        case 1:
            cell.textLabel?.text = order.addressSnapshot
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = .systemFont(ofSize: 14)
        case 2:
            let item = order.items[indexPath.row]
            cell.textLabel?.text = "\(item.productName)\(item.unit.map { " (\($0))" } ?? "") × \(item.quantity)"
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.detailTextLabel?.text = CurrencyFormatter.string(from: item.lineTotal)
        case 3:
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.textLabel?.text = [
                "Subtotal:      \(CurrencyFormatter.string(from: order.totals.cartSubtotal))",
                "Discount:      −\(CurrencyFormatter.string(from: order.totals.discountAmount))",
                "Delivery Fee:  \(CurrencyFormatter.string(from: order.totals.deliveryFee))",
                "Tax:           \(CurrencyFormatter.string(from: order.totals.taxAmount))"
            ].joined(separator: "\n") + "\nGrand Total:   \(CurrencyFormatter.string(from: order.totals.grandTotal))"
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        navigationController?.pushViewController(OrderTrackingViewController(order: order), animated: true)
    }
}
