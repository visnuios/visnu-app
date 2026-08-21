import UIKit

final class PaymentGatewayViewController: UIViewController {

    private let amount: Decimal
    private let onSuccess: () -> Void

    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let amountLabel = UILabel()

    init(amount: Decimal, onSuccess: @escaping () -> Void) {
        self.amount = amount
        self.onSuccess = onSuccess
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "Secure Payment"
        titleLabel.font = .boldSystemFont(ofSize: 20)

        amountLabel.text = CurrencyFormatter.string(from: amount)
        amountLabel.font = .boldSystemFont(ofSize: 32)

        statusLabel.text = "Contacting payment gateway…"
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [titleLabel, amountLabel, spinner, statusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        spinner.startAnimating()

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard let self else { return }
            self.spinner.stopAnimating()
            self.statusLabel.text = "Payment successful ✓"
            try? await Task.sleep(nanoseconds: 600_000_000)
            self.dismiss(animated: true) {
                self.onSuccess()
            }
        }
    }
}
