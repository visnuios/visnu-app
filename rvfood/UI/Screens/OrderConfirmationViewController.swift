import UIKit

final class OrderConfirmationViewController: UIViewController {

    private let order: Order

    init(order: Order) {
        self.order = order
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        buildUI()
    }

    private func buildUI() {
        let checkLabel = UILabel()
        checkLabel.text = "✓"
        checkLabel.font = .systemFont(ofSize: 56, weight: .bold)
        checkLabel.textColor = .white
        checkLabel.textAlignment = .center
        checkLabel.backgroundColor = .systemGreen
        checkLabel.layer.cornerRadius = 44
        checkLabel.clipsToBounds = true
        checkLabel.widthAnchor.constraint(equalToConstant: 88).isActive = true
        checkLabel.heightAnchor.constraint(equalToConstant: 88).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "Order Placed Successfully!"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your order #\(order.id) has been placed with \(order.shopName)."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 14

        func row(_ title: String, _ value: String) -> UIStackView {
            let t = UILabel()
            t.text = title
            t.font = .systemFont(ofSize: 14)
            t.textColor = .secondaryLabel
            let v = UILabel()
            v.text = value
            v.font = .systemFont(ofSize: 14, weight: .semibold)
            v.textAlignment = .right
            v.numberOfLines = 0
            let s = UIStackView(arrangedSubviews: [t, v])
            s.axis = .horizontal
            return s
        }

        let itemsSummary = order.items.map { "\($0.productName) × \($0.quantity)" }.joined(separator: "\n")
        let detailsStack = UIStackView(arrangedSubviews: [
            row("Order ID", "#\(order.id)"),
            row("Shop", order.shopName),
            row("Items", itemsSummary),
            row("Deliver to", order.addressSnapshot),
            row("Payment", order.paymentMethod.displayTitle + (order.isPaid ? " (Paid)" : "")),
            row("Grand Total", CurrencyFormatter.string(from: order.totals.grandTotal)),
            row("Estimated Delivery", "≈ \(30 + Int.random(in: 0...15)) mins")
        ])
        detailsStack.axis = .vertical
        detailsStack.spacing = 12
        detailsStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailsStack)

        let trackButton = PrimaryButton(title: "Track Order")
        trackButton.addTarget(self, action: #selector(trackTapped), for: .touchUpInside)

        let shopMoreButton = UIButton(type: .system)
        shopMoreButton.setTitle("Continue Shopping", for: .normal)
        shopMoreButton.setTitleColor(.systemOrange, for: .normal)
        shopMoreButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        shopMoreButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        shopMoreButton.addTarget(self, action: #selector(continueShoppingTapped), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [
            checkLabel, titleLabel, subtitleLabel, card, trackButton, shopMoreButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            detailsStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            detailsStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            detailsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            detailsStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    @objc private func trackTapped() {
        navigationController?.pushViewController(OrderTrackingViewController(order: order), animated: true)
    }

    @objc private func continueShoppingTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}
