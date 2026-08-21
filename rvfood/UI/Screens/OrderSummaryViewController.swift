import UIKit

final class OrderSummaryViewController: UIViewController {

    private var draft: CheckoutDraft
    private let cart: CartManager
    private let orderRepository: OrderRepositoryProtocol
    private let productRepository: ProductRepositoryProtocol

    private var specialProducts: [Product] = []
    private var selectedAddress: Address?
    private var observer: NSObjectProtocol?
    private var isPlacingOrder = false

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let placeOrderButton = PrimaryButton(title: "Place Order")

    init(
        draft: CheckoutDraft,
        cart: CartManager = .shared,
        orderRepository: OrderRepositoryProtocol = DemoOrderRepository(),
        productRepository: ProductRepositoryProtocol = DemoProductRepository()
    ) {
        self.draft = draft
        self.cart = cart
        self.orderRepository = orderRepository
        self.productRepository = productRepository
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
        title = "Order Summary"
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProductRowCell.self, forCellReuseIdentifier: ProductRowCell.reuseID)
        tableView.register(SubtitleCell.self, forCellReuseIdentifier: SubtitleCell.reuseID)
        tableView.register(ProductCarouselCell.self, forCellReuseIdentifier: ProductCarouselCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        placeOrderButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(placeOrderButton)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: placeOrderButton.topAnchor, constant: -8),
            placeOrderButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            placeOrderButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            placeOrderButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        placeOrderButton.addTarget(self, action: #selector(placeOrderTapped), for: .touchUpInside)

        selectedAddress = CheckoutSession.shared.selectedAddress

        observer = NotificationCenter.default.addObserver(
            forName: .cartDidChange,
            object: cart,
            queue: .main
        ) { [weak self] _ in
            self?.syncWithCart()
        }

        loadSpecialProducts()
        syncWithCart()
    }

    private func syncWithCart() {
        draft.refresh(from: cart.totals)
        if cart.isEmpty {
            navigationController?.popViewController(animated: true)
            return
        }
        tableView.reloadData()
    }

    private func loadSpecialProducts() {
        Task {
            specialProducts = (try? await productRepository.specialProducts(shopId: cart.shopId)) ?? []
            tableView.reloadData()
        }
    }

    private enum Section: Int, CaseIterable {
        case shopInfo
        case deliveryAddress
        case items
        case totals
        case payment
        case specialProducts
    }

    private var sections: [Section] {
        specialProducts.isEmpty ? [.shopInfo, .deliveryAddress, .items, .totals, .payment] : Section.allCases
    }

    @objc private func placeOrderTapped() {
        guard !isPlacingOrder else { return }
        guard let addressId = draft.addressId ?? CheckoutSession.shared.selectedAddress?.id else {
            presentErrorAlert(APIError.businessRule("Please select a delivery address."), title: "Address required")
            return
        }
        guard let shopId = cart.shopId else { return }

        let method = CheckoutSession.shared.paymentMethod
        if method.requiresOnlinePayment {
            startOnlinePayment { [weak self] in
                self?.submitOrder(shopId: shopId, addressId: addressId, paymentMethod: method)
            }
        } else {
            submitOrder(shopId: shopId, addressId: addressId, paymentMethod: method)
        }
    }

    private func startOnlinePayment(onSuccess: @escaping () -> Void) {
        let gateway = PaymentGatewayViewController(amount: draft.grandTotal) { [weak self] in
            onSuccess()
        }
        present(gateway, animated: true)
    }

    private func submitOrder(shopId: String, addressId: String, paymentMethod: PaymentMethod) {
        isPlacingOrder = true
        placeOrderButton.isEnabled = false
        placeOrderButton.setTitle("Placing Order…", for: .normal)

        let request = PlaceOrderRequest(
            shopId: shopId,
            lines: cart.items.map { PlaceOrderRequest.Line(productId: $0.product.id, quantity: $0.quantity) },
            addressId: addressId,
            couponCode: cart.appliedCoupon?.code,
            paymentMethod: paymentMethod
        )

        Task {
            do {
                let result = try await orderRepository.placeOrder(request)
                NotificationsStore.shared.add(
                    kind: .order,
                    title: "Order #\(result.order.id) placed",
                    message: "\(result.order.shopName) received your order."
                )
                cart.clearCart()
                CheckoutSession.shared.completeOrder()

                let confirmation = OrderConfirmationViewController(order: result.order)
                navigationController?.setViewControllers([confirmation], animated: true)
            } catch {
                isPlacingOrder = false
                placeOrderButton.isEnabled = true
                placeOrderButton.setTitle("Place Order", for: .normal)
                presentErrorAlert(error, title: "Order Failed")
            }
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .shopInfo, .deliveryAddress, .totals, .specialProducts:
            return 1
        case .items:
            return cart.items.count
        case .payment:
            return PaymentMethod.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .shopInfo: return "Shop"
        case .deliveryAddress: return "Delivery Address"
        case .items: return "Items (\(cart.itemCount))"
        case .totals: return "Bill Details"
        case .payment: return "Payment Method"
        case .specialProducts: return "Special Products"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .shopInfo:
            let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
            cell.textLabel?.text = cart.shopName ?? "Shop"
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
            cell.detailTextLabel?.text = "Delivering from your nearby shop"
            cell.selectionStyle = .none
            return cell

        case .deliveryAddress:
            let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
            if let address = selectedAddress {
                cell.textLabel?.text = "\(address.type.rawValue) · \(address.name)"
                cell.textLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
                cell.detailTextLabel?.numberOfLines = 0
                cell.detailTextLabel?.text = address.singleLine
            } else {
                cell.textLabel?.text = "No address selected"
                cell.detailTextLabel?.text = nil
            }
            cell.selectionStyle = .none
            return cell

        case .items:
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

        case .totals:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            let totalsView = TotalsBreakdownView()
            totalsView.render(totals: CartTotals(
                cartSubtotal: draft.cartSubtotal,
                discountAmount: draft.discountAmount,
                deliveryFee: draft.deliveryFee,
                taxAmount: draft.taxAmount,
                grandTotal: draft.grandTotal,
                itemCount: cart.itemCount,
                savingsFromOffers: 0
            ))
            totalsView.backgroundColor = .secondarySystemGroupedBackground
            totalsView.layer.cornerRadius = 12
            totalsView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(totalsView)
            NSLayoutConstraint.activate([
                totalsView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 4),
                totalsView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -4),
                totalsView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                totalsView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16)
            ])
            return cell

        case .payment:
            let method = PaymentMethod.allCases[indexPath.row]
            let isSelected = CheckoutSession.shared.paymentMethod == method
            let cell = tableView.dequeueReusableCell(withIdentifier: SubtitleCell.reuseID, for: indexPath)
            var config = UIListContentConfiguration.cell()
            config.text = "\(method.displayTitle)\(method.requiresOnlinePayment ? "  · Pay online" : "")"
            config.textProperties.font = .systemFont(ofSize: 15, weight: isSelected ? .bold : .regular)
            cell.contentConfiguration = config
            cell.accessoryType = isSelected ? .checkmark : .none
            return cell

        case .specialProducts:
            let cell = tableView.dequeueReusableCell(withIdentifier: ProductCarouselCell.reuseID, for: indexPath) as! ProductCarouselCell
            cell.configure(products: specialProducts) { [weak self] product in
                guard let self else { return }
                CartFlowHelper.add(product: product, from: self)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard sections[indexPath.section] == .payment else { return }
        CheckoutSession.shared.setPaymentMethod(PaymentMethod.allCases[indexPath.row])
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    }
}
