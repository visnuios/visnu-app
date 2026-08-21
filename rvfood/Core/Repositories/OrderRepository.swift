import Foundation

protocol OrderRepositoryProtocol {
    func placeOrder(_ request: PlaceOrderRequest) async throws -> PlaceOrderResult
    func orders() async throws -> [Order]
    func order(id: String) async throws -> Order
    func cancelOrder(id: String) async throws -> Order
    func reorder(orderId: String) async throws -> (addedCount: Int, unavailableItems: [String])
    func submitReview(orderId: String, stars: Int, text: String?) async throws
}

final class DemoOrderRepository: OrderRepositoryProtocol {

    private let defaults: UserDefaults
    private static let storageKey = "rvfood.orders"
    private var statusTimer: Timer?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        startStatusProgression()
    }

    func placeOrder(_ request: PlaceOrderRequest) async throws -> PlaceOrderResult {
        try await Task.sleep(nanoseconds: 900_000_000)

        guard let shop = DemoCatalog.shops.first(where: { $0.id == request.shopId }) else {
            throw APIError.notFound
        }

        var orderItems: [OrderItem] = []
        for line in request.lines {
            guard let product = DemoCatalog.products.first(where: { $0.id == line.productId }) else {
                throw APIError.businessRule("\(line.productId) is no longer available.")
            }
            guard !product.isOutOfStock else {
                throw APIError.businessRule("\(product.name) is out of stock.")
            }
            guard line.quantity <= product.stock else {
                throw APIError.businessRule("Only \(product.stock) units of \(product.name) left.")
            }
            orderItems.append(OrderItem(
                productId: product.id,
                productName: product.name,
                unit: product.unit,
                unitPrice: product.effectiveUnitPrice,
                quantity: line.quantity,
                lineTotal: product.effectiveUnitPrice * Decimal(line.quantity)
            ))
        }

        guard !orderItems.isEmpty else {
            throw APIError.businessRule("Your cart is empty.")
        }

        let address = try await DemoAddressRepository().address(id: request.addressId)

        let cartSubtotal = orderItems.reduce(Decimal(0)) { $0 + $1.lineTotal }.roundedTo()

        guard cartSubtotal >= shop.minOrderAmount else {
            throw APIError.businessRule("Minimum order for \(shop.name) is \(CurrencyFormatter.string(from: shop.minOrderAmount)).")
        }

        var discountAmount: Decimal = 0
        if let code = request.couponCode, let coupon = DemoCatalog.coupon(forCode: code) {
            let engine = DefaultPricingEngine()
            switch engine.validate(coupon, subtotal: cartSubtotal, cartShopId: shop.id) {
            case .valid:
                discountAmount = engine.discount(for: coupon, subtotal: cartSubtotal).roundedTo()
            case .failed(let failure):
                throw CartError.couponInvalid(failure)
            }
        }

        let distanceKm = GeoMath.distanceKm(
            from: address.point.coordinate,
            to: shop.point.coordinate
        )
        let deliveryFee = DeliveryFeeCalculator.fee(
            distanceKm: Decimal(distanceKm),
            subtotal: cartSubtotal,
            configuration: .standard
        )
        let taxableAmount = max(cartSubtotal - discountAmount, 0)
        let taxAmount = (taxableAmount * TaxDefaults.rate).roundedTo()
        let grandTotal = max(taxableAmount + deliveryFee + taxAmount, 0)

        let isPaid = !request.paymentMethod.requiresOnlinePayment ? false : true

        let order = Order(
            id: "ORD\(Int.random(in: 10000...99999))",
            shopId: shop.id,
            shopName: shop.name,
            createdAt: Date.now,
            items: orderItems,
            addressSnapshot: address.singleLine,
            paymentMethod: request.paymentMethod,
            isPaid: isPaid,
            status: .pending,
            totals: OrderTotals(
                cartSubtotal: cartSubtotal,
                discountAmount: discountAmount,
                deliveryFee: deliveryFee,
                taxAmount: taxAmount,
                grandTotal: grandTotal
            ),
            couponCode: request.couponCode
        )

        var all = load()
        all.insert(order, at: 0)
        persist(all)
        return PlaceOrderResult(order: order)
    }

    func orders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return load()
    }

    func order(id: String) async throws -> Order {
        guard let order = load().first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return order
    }

    func cancelOrder(id: String) async throws -> Order {
        try await Task.sleep(nanoseconds: 400_000_000)
        var all = load()
        guard let index = all.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        guard all[index].status.canBeCancelled else {
            throw APIError.businessRule("This order can no longer be cancelled.")
        }
        let cancelled = rebuild(all[index], status: .cancelled)
        all[index] = cancelled
        persist(all)
        return cancelled
    }

    func reorder(orderId: String) async throws -> (addedCount: Int, unavailableItems: [String]) {
        let previous = try await order(id: orderId)
        var addedCount = 0
        var unavailable: [String] = []
        for item in previous.items {
            guard let fresh = DemoCatalog.products.first(where: { $0.id == item.productId }) else {
                unavailable.append(item.productName)
                continue
            }
            guard !fresh.isOutOfStock else {
                unavailable.append(fresh.name)
                continue
            }
            let requestedQuantity = min(item.quantity, fresh.stock)
            do {
                switch try CartManager.shared.addProduct(fresh, quantity: requestedQuantity) {
                case .conflict:
                    unavailable.append("\(fresh.name) (different shop in cart)")
                default:
                    addedCount += requestedQuantity
                }
            } catch {
                unavailable.append(fresh.name)
            }
        }
        return (addedCount, unavailable)
    }

    func submitReview(orderId: String, stars: Int, text: String?) async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        _ = Review(
            id: UUID().uuidString,
            orderId: orderId,
            subject: .shop,
            stars: min(max(stars, 1), 5),
            text: text,
            createdAt: Date.now
        )
    }

    private func rebuild(_ order: Order, status: OrderStatus) -> Order {
        Order(
            id: order.id,
            shopId: order.shopId,
            shopName: order.shopName,
            createdAt: order.createdAt,
            items: order.items,
            addressSnapshot: order.addressSnapshot,
            paymentMethod: order.paymentMethod,
            isPaid: order.isPaid,
            status: status,
            totals: order.totals,
            couponCode: order.couponCode
        )
    }

    private func startStatusProgression() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceActiveOrders()
            }
        }
    }

    private func advanceActiveOrders() {
        var all = load()
        var changed = false
        for index in all.indices {
            guard let next = nextStatus(after: all[index].status) else { continue }
            all[index] = rebuild(all[index], status: next)
            changed = true
            NotificationsStore.shared.addOrderUpdate(orderId: all[index].id, status: next)
        }
        if changed {
            persist(all)
            NotificationCenter.default.post(name: .ordersDidChange, object: nil)
        }
    }

    private func nextStatus(after status: OrderStatus) -> OrderStatus? {
        switch status {
        case .pending: return .accepted
        case .accepted: return .preparing
        case .preparing: return .readyForPickup
        case .readyForPickup: return .outForDelivery
        case .outForDelivery: return .delivered
        default: return nil
        }
    }

    private func load() -> [Order] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([StoredOrder].self, from: data)).map { stored in
            stored.map(\.order)
        } ?? []
    }

    private func persist(_ orders: [Order]) {
        let stored = orders.map(StoredOrder.init)
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}

private struct StoredOrder: Codable {
    let order: Order

    init(order: Order) {
        self.order = order
    }

    enum CodingKeys: String, CodingKey {
        case id, shopId, shopName, createdAt, items, addressSnapshot
        case paymentMethod, isPaid, status, totals, couponCode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        order = Order(
            id: (try? container.decode(String.self, forKey: .id)) ?? "",
            shopId: (try? container.decode(String.self, forKey: .shopId)) ?? "",
            shopName: (try? container.decode(String.self, forKey: .shopName)) ?? "",
            createdAt: (try? container.decode(Date.self, forKey: .createdAt)) ?? Date(timeIntervalSince1970: 0),
            items: (try? container.decode([OrderItem].self, forKey: .items)) ?? [],
            addressSnapshot: (try? container.decode(String.self, forKey: .addressSnapshot)) ?? "",
            paymentMethod: (try? container.decode(PaymentMethod.self, forKey: .paymentMethod)) ?? .cashOnDelivery,
            isPaid: (try? container.decode(Bool.self, forKey: .isPaid)) ?? false,
            status: (try? container.decode(OrderStatus.self, forKey: .status)) ?? .pending,
            totals: (try? container.decode(OrderTotals.self, forKey: .totals)) ?? .empty,
            couponCode: try? container.decodeIfPresent(String.self, forKey: .couponCode)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order.id, forKey: .id)
        try container.encode(order.shopId, forKey: .shopId)
        try container.encode(order.shopName, forKey: .shopName)
        try container.encode(order.createdAt, forKey: .createdAt)
        try container.encode(order.items, forKey: .items)
        try container.encode(order.addressSnapshot, forKey: .addressSnapshot)
        try container.encode(order.paymentMethod, forKey: .paymentMethod)
        try container.encode(order.isPaid, forKey: .isPaid)
        try container.encode(order.status, forKey: .status)
        try container.encode(order.totals, forKey: .totals)
        try container.encodeIfPresent(order.couponCode, forKey: .couponCode)
    }
}
