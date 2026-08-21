import CoreData
import Foundation

protocol OrderRepositoryProtocol {
    func placeOrder(_ request: PlaceOrderRequest) async throws -> PlaceOrderResult
    func orders() async throws -> [Order]
    func order(id: String) async throws -> Order
    func cancelOrder(id: String) async throws -> Order
    func reorder(orderId: String) async throws -> (addedCount: Int, unavailableItems: [String])
    func submitReview(orderId: String, stars: Int, text: String?) async throws
    func hasReview(orderId: String) -> Bool
}

final class LocalOrderRepository: OrderRepositoryProtocol {

    private let persistence: PersistenceController

    init(controller: PersistenceController = .shared) {
        self.persistence = controller
        OrderStatusEngine.shared.start()
    }

    private var context: NSManagedObjectContext { persistence.context }

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

        let address = try await LocalAddressRepository().address(id: request.addressId)

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

        let isPaid = request.paymentMethod.requiresOnlinePayment

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

        ManagedOrder.from(order, in: context)
        persistence.save()
        return PlaceOrderResult(order: order)
    }

    func orders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return fetchOrders()
    }

    func order(id: String) async throws -> Order {
        guard let order = fetchOrders().first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return order
    }

    func cancelOrder(id: String) async throws -> Order {
        try await Task.sleep(nanoseconds: 400_000_000)
        let all = fetchOrders()
        guard let existing = all.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        guard existing.status.canBeCancelled else {
            throw APIError.businessRule("This order can no longer be cancelled.")
        }
        let cancelled = rebuild(existing, status: .cancelled)
        update(cancelled)
        persistence.save()
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
        let review = ManagedReview(entity: PersistenceController.model.entitiesByName["Review"]!, insertInto: context)
        review.id = UUID().uuidString
        review.orderId = orderId
        review.stars = Int16(min(max(stars, 1), 5))
        review.text = text
        review.createdAt = Date.now
        persistence.save()
    }

    func hasReview(orderId: String) -> Bool {
        let request = NSFetchRequest<ManagedReview>(entityName: "Review")
        request.predicate = NSPredicate(format: "orderId == %@", orderId)
        request.fetchLimit = 1
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    private func fetchOrders() -> [Order] {
        let request = NSFetchRequest<ManagedOrder>(entityName: "Order")
        let sort = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sort]
        return ((try? context.fetch(request)) ?? []).map(\.asStruct)
    }

    private func update(_ order: Order) {
        let request = NSFetchRequest<ManagedOrder>(entityName: "Order")
        request.predicate = NSPredicate(format: "id == %@", order.id)
        request.fetchLimit = 1
        if let managed = try? context.fetch(request).first {
            ManagedOrder.apply(order, to: managed)
        }
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
}

final class OrderStatusEngine {

    static let shared = OrderStatusEngine()

    private var timer: Timer?

    private init() {}

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.advanceActiveOrders()
        }
    }

    private func advanceActiveOrders() {
        let context = PersistenceController.shared.context
        let request = NSFetchRequest<ManagedOrder>(entityName: "Order")
        let all = (try? context.fetch(request)) ?? []
        var changed = false

        for managed in all {
            guard let status = OrderStatus(rawValue: managed.statusRaw),
                  let next = nextStatus(after: status) else { continue }
            managed.statusRaw = next.rawValue
            changed = true
            NotificationsStore.shared.addOrderUpdate(orderId: managed.id, status: next)
        }

        if changed {
            PersistenceController.shared.save()
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
}
