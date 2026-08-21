import UIKit

final class OrderDetailsViewController: UIViewController {

    private var order: Order
    private let repository: OrderRepositoryProtocol
    private var observer: NSObjectProtocol?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let actionButton = PrimaryButton(title: "")

    init(order: Order, repository: OrderRepositoryProtocol = LocalOrderRepository()) {
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
        tableView.rowHeight = UITableView.automaticDimension
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
            if repository.hasReview(orderId: order.id) {
                actionButton.setTitle("Reorder", for: .normal)
            } else {
                actionButton.setTitle("Rate & Review", for: .normal)
            }
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
            if repository.hasReview(orderId: order.id) {
                reorder()
            } else {
                promptReview()
            }
        default:
            break
        }
    }

    private func promptReview() {
        let reviewVC = ReviewViewController(shopName: order.shopName) { [weak self] stars, text in
            guard let self else { return }
            Task {
                try? await self.repository.submitReview(orderId: self.order.id, stars: stars, text: text)
                NotificationsStore.shared.add(kind: .system, title: "Thanks for your review!", message: "You rated order #\(self.order.id) \(stars) star(s).")
                self.refreshActionButton()
            }
        }
        reviewVC.modalPresentationStyle = .overFullScreen
        present(reviewVC, animated: false)
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
            if order.status.isActive || order.status == .delivered {
                cell.accessoryType = .disclosureIndicator
                cell.detailTextLabel?.text? += "\nTap to track this order →"
            }
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

final class ReviewViewController: UIViewController {

    private let shopName: String
    private let onSubmit: (Int, String?) -> Void
    private var selectedStars = 5

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let starsStack = UIStackView()
    private let commentField = UITextField()
    private let submitButton = PrimaryButton(title: "Submit Review")
    private var starButtons: [UIButton] = []

    init(shopName: String, onSubmit: @escaping (Int, String?) -> Void) {
        self.shopName = shopName
        self.onSubmit = onSubmit
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.45)

        cardView.backgroundColor = .secondarySystemGroupedBackground
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardView)

        titleLabel.text = "Rate \(shopName)"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center

        starsStack.axis = .horizontal
        starsStack.alignment = .center
        starsStack.distribution = .equalSpacing

        for star in 1...5 {
            let button = UIButton(type: .system)
            button.setTitle("★", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 36)
            button.tag = star
            button.addAction(UIAction { [weak self] _ in
                self?.select(stars: button.tag)
            }, for: .touchUpInside)
            starButtons.append(button)
            starsStack.addArrangedSubview(button)
        }

        commentField.placeholder = "Tell us more (optional)"
        commentField.borderStyle = .roundedRect
        commentField.heightAnchor.constraint(equalToConstant: 44).isActive = true

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, starsStack, commentField, submitButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)

        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),

            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])

        select(stars: 5)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissTapped))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func select(stars: Int) {
        selectedStars = max(stars, 1)
        for button in starButtons {
            button.tintColor = button.tag <= selectedStars ? .systemOrange : .systemGray4
        }
    }

    @objc private func submitTapped() {
        dismiss(animated: false) { [weak self] in
            guard let self else { return }
            let text = commentField.text?.trimmingCharacters(in: .whitespaces)
            onSubmit(selectedStars, (text?.isEmpty == true) ? nil : text)
        }
    }

    @objc private func dismissTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        if !cardView.frame.contains(point) {
            dismiss(animated: false)
        }
    }
}

