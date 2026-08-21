import UIKit

final class PrimaryButton: UIButton {

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: 17)
        setTitleColor(.white, for: .normal)
        backgroundColor = .systemOrange
        layer.cornerRadius = 12
        heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class QuantityControl: UIView {

    var onChange: ((Int) -> Void)?

    private let minusButton = UIButton(type: .system)
    private let plusButton = UIButton(type: .system)
    private let valueLabel = UILabel()
    private(set) var value: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemGreen
        layer.cornerRadius = 8
        clipsToBounds = true

        minusButton.setTitle("−", for: .normal)
        plusButton.setTitle("+", for: .normal)
        [minusButton, plusButton].forEach {
            $0.setTitleColor(.white, for: .normal)
            $0.titleLabel?.font = .boldSystemFont(ofSize: 18)
            $0.widthAnchor.constraint(equalToConstant: 34).isActive = true
            $0.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        }
        valueLabel.font = .boldSystemFont(ofSize: 15)
        valueLabel.textColor = .white
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [minusButton, valueLabel, plusButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 32),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 102)
        ])
        render(value: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(value: Int) {
        self.value = max(value, 0)
        valueLabel.text = "\(self.value)"
        isHidden = self.value == 0
    }

    @objc private func tapped(_ sender: UIButton) {
        if sender == minusButton {
            onChange?(value - 1)
        } else {
            onChange?(value + 1)
        }
    }
}

final class TotalsBreakdownView: UIView {

    private let subtotalValue = UILabel()
    private let discountValue = UILabel()
    private let deliveryValue = UILabel()
    private let taxValue = UILabel()
    private let grandTotalValue = UILabel()

    init() {
        super.init(frame: .zero)

        func row(_ title: String, _ value: UILabel) -> UIStackView {
            let label = UILabel()
            label.text = title
            label.font = .systemFont(ofSize: 15)
            label.textColor = .secondaryLabel
            value.font = .systemFont(ofSize: 15, weight: .medium)
            value.textAlignment = .right
            value.text = CurrencyFormatter.string(from: 0)
            let stack = UIStackView(arrangedSubviews: [label, value])
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            return stack
        }

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let grandTitle = UILabel()
        grandTitle.text = "Grand Total"
        grandTitle.font = .boldSystemFont(ofSize: 17)
        grandTotalValue.font = .boldSystemFont(ofSize: 17)
        grandTotalValue.textAlignment = .right
        let grandRow = UIStackView(arrangedSubviews: [grandTitle, grandTotalValue])
        grandRow.axis = .horizontal
        grandRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [
            row("Subtotal", subtotalValue),
            row("Discount", discountValue),
            row("Delivery Fee", deliveryValue),
            row("Tax", taxValue),
            separator,
            grandRow
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(totals: CartTotals) {
        subtotalValue.text = CurrencyFormatter.string(from: totals.cartSubtotal)
        discountValue.text = "− " + CurrencyFormatter.string(from: totals.discountAmount)
        discountValue.textColor = totals.discountAmount > 0 ? .systemGreen : .label
        deliveryValue.text = CurrencyFormatter.string(from: totals.deliveryFee)
        taxValue.text = CurrencyFormatter.string(from: totals.taxAmount)
        grandTotalValue.text = CurrencyFormatter.string(from: totals.grandTotal)
    }

    func render(orderTotals: OrderTotals) {
        render(
            totals: CartTotals(
                cartSubtotal: orderTotals.cartSubtotal,
                discountAmount: orderTotals.discountAmount,
                deliveryFee: orderTotals.deliveryFee,
                taxAmount: orderTotals.taxAmount,
                grandTotal: orderTotals.grandTotal,
                itemCount: 0,
                savingsFromOffers: 0
            )
        )
    }
}

enum ViewState: Equatable {
    case idle
    case loading
    case empty(String)
    case error(String)
}

final class StateOverlayView: UIView {

    private let spinner = UIActivityIndicatorView(style: .large)
    private let iconLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    var onRetry: (() -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = .systemBackground
        isHidden = true

        iconLabel.font = .systemFont(ofSize: 44)
        messageLabel.font = .systemFont(ofSize: 15)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = .boldSystemFont(ofSize: 15)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [spinner, iconLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(state: ViewState) {
        switch state {
        case .idle:
            isHidden = true
            spinner.stopAnimating()
        case .loading:
            isHidden = false
            spinner.startAnimating()
            iconLabel.isHidden = true
            messageLabel.text = "Loading…"
            retryButton.isHidden = true
        case .empty(let message):
            isHidden = false
            spinner.stopAnimating()
            iconLabel.isHidden = false
            iconLabel.text = "🛒"
            messageLabel.text = message
            retryButton.isHidden = true
        case .error(let message):
            isHidden = false
            spinner.stopAnimating()
            iconLabel.isHidden = false
            iconLabel.text = "⚠️"
            messageLabel.text = message
            retryButton.isHidden = false
        }
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}

final class PlaceholderImageView: UIView {

    private let emojiLabel = UILabel()
    private var gradientColors: [UIColor] = [.systemGray5, .systemGray4]

    init(emoji: String = "🛍️") {
        super.init(frame: .zero)
        emojiLabel.text = emoji
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = gradientColors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)
    }
}

extension UIViewController {

    func presentErrorAlert(_ error: Error, title: String = "Something went wrong") {
        let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
