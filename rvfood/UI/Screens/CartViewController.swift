import UIKit

final class CartViewController: UIViewController {

    private let cart: CartManager
    private var draft = CheckoutDraft()
    private var observer: NSObjectProtocol?

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let totalsView = TotalsBreakdownView()
    private let couponButton = UIButton(type: .system)
    private let continueButton = PrimaryButton(title: "Continue")
    private let emptyLabel = UILabel()

    init(cart: CartManager = .shared) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cart"
        view.backgroundColor = .systemGroupedBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )

        tableView.dataSource = self
        tableView.register(ProductRowCell.self, forCellReuseIdentifier: ProductRowCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension

        totalsView.backgroundColor = .secondarySystemGroupedBackground
        totalsView.layer.cornerRadius = 12

        couponButton.setTitle("Apply Coupon", for: .normal)
        couponButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        couponButton.setTitleColor(.systemOrange, for: .normal)
        couponButton.contentHorizontalAlignment = .left
        couponButton.addTarget(self, action: #selector(couponTapped), for: .touchUpInside)

        emptyLabel.text = "Your cart is empty.\nAdd items from nearby shops!"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 16)

        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        layout()
        observer = NotificationCenter.default.addObserver(
            forName: .cartDidChange,
            object: cart,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
        refresh()
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func layout() {
        let bottomStack = UIStackView(arrangedSubviews: [couponButton, totalsView, continueButton])
        bottomStack.axis = .vertical
        bottomStack.spacing = 12
        bottomStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(bottomStack)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomStack.topAnchor, constant: -8),

            bottomStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func refresh() {
        let totals = cart.totals
        draft.refresh(from: totals)
        totalsView.render(totals: totals)
        tableView.reloadData()
        emptyLabel.isHidden = !cart.isEmpty
        tableView.isHidden = cart.isEmpty
        continueButton.isEnabled = !cart.isEmpty
        refreshCouponTitle()
    }

    private func refreshCouponTitle() {
        if let coupon = cart.appliedCoupon {
            couponButton.setTitle("✓ \(coupon.code) applied · Tap to remove", for: .normal)
            couponButton.setTitleColor(.systemGreen, for: .normal)
        } else {
            couponButton.setTitle("Apply Coupon", for: .normal)
            couponButton.setTitleColor(.systemOrange, for: .normal)
        }
    }

    @objc private func clearTapped() {
        guard !cart.isEmpty else { return }
        let alert = UIAlertController(title: "Clear cart?", message: "All items will be removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            self.cart.clearCart()
        })
        present(alert, animated: true)
    }

    @objc private func couponTapped() {
        if cart.appliedCoupon != nil {
            cart.removeCoupon()
            return
        }
        let alert = UIAlertController(title: "Apply Coupon", message: "Try SAVE10 or FLAT50", preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter coupon code"
            field.autocapitalizationType = .allCharacters
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Apply", style: .default) { [weak self] _ in
            guard let code = alert.textFields?.first?.text else { return }
            self?.applyCoupon(code: code)
        })
        present(alert, animated: true)
    }

    private func applyCoupon(code: String) {
        guard let coupon = DemoCatalog.coupon(forCode: code) else {
            presentErrorAlert(APIError.businessRule("Invalid coupon code."), title: "Invalid Coupon")
            return
        }
        do {
            try cart.applyCoupon(coupon)
        } catch {
            presentErrorAlert(error, title: "Coupon Not Applied")
        }
    }

    @objc private func continueTapped() {
        let addressDraft = CheckoutDraft(totals: cart.totals, addressId: CheckoutSession.shared.selectedAddress?.id)
        navigationController?.pushViewController(AddressSelectionViewController(draft: addressDraft), animated: true)
    }
}

extension CartViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cart.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductRowCell.reuseID, for: indexPath) as! ProductRowCell
        let item = cart.items[indexPath.row]
        cell.configure(product: item.product, quantityInCart: item.quantity)
        cell.onAddTapped = nil
        cell.onQuantityChanged = { [weak self] newValue in
            guard let self else { return }
            if newValue < item.quantity {
                self.cart.decreaseQuantity(productId: item.product.id)
            } else {
                try? self.cart.updateQuantity(newValue, forProductId: item.product.id)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            cart.removeProduct(productId: cart.items[indexPath.row].product.id)
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Remove"
    }
}
