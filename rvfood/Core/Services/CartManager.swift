import Foundation

struct CartPersistedState: Codable, Equatable {
    var items: [CartItem]
    var shopId: String?
    var shopName: String?
    var coupon: Coupon?
    var deliveryFee: Decimal
}

protocol CartStore: AnyObject {
    func loadState() -> CartPersistedState?
    func save(state: CartPersistedState)
    func clearState()
}

final class InMemoryCartStore: CartStore {
    private var state: CartPersistedState?

    func loadState() -> CartPersistedState? { state }
    func save(state: CartPersistedState) { self.state = state }
    func clearState() { state = nil }
}

final class UserDefaultsCartStore: CartStore {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "rvfood.cart.state") {
        self.defaults = defaults
        self.key = key
    }

    func loadState() -> CartPersistedState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CartPersistedState.self, from: data)
    }

    func save(state: CartPersistedState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }

    func clearState() {
        defaults.removeObject(forKey: key)
    }
}

final class CartManager {

    static let shared = CartManager()

    private let store: CartStore

    var pricingEngine: any CartPricingEngine
    var taxRate: Decimal
    var deliveryFeeConfiguration: DeliveryFeeConfiguration

    private(set) var items: [CartItem] = []
    private(set) var shopId: String?
    private(set) var shopName: String?
    private(set) var appliedCoupon: Coupon?
    private(set) var deliveryFee: Decimal = 0

    init(
        store: CartStore = UserDefaultsCartStore(),
        pricingEngine: any CartPricingEngine = DefaultPricingEngine(),
        taxRate: Decimal = TaxDefaults.rate,
        deliveryFeeConfiguration: DeliveryFeeConfiguration = .standard
    ) {
        self.store = store
        self.pricingEngine = pricingEngine
        self.taxRate = taxRate
        self.deliveryFeeConfiguration = deliveryFeeConfiguration
        if let saved = store.loadState() {
            items = saved.items
            shopId = saved.shopId
            shopName = saved.shopName
            appliedCoupon = saved.coupon
            deliveryFee = saved.deliveryFee
        }
    }

    var isEmpty: Bool { items.isEmpty }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var totals: CartTotals {
        calculateTotals()
    }

    func quantity(ofProductId productId: String) -> Int {
        items.first(where: { $0.product.id == productId })?.quantity ?? 0
    }

    func containsProduct(productId: String) -> Bool {
        quantity(ofProductId: productId) > 0
    }

    @discardableResult
    func addProduct(_ product: Product, quantity addedQuantity: Int = 1) throws -> CartAddResult {
        guard addedQuantity > 0 else {
            throw CartError.invalidQuantity(requested: addedQuantity)
        }
        guard !product.isOutOfStock else {
            throw CartError.productOutOfStock
        }

        if let currentShopId = shopId, currentShopId != product.shopId {
            return .conflict(existingShop: ShopConflict(shopId: currentShopId, shopName: shopName))
        }

        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            let newQuantity = items[index].quantity + addedQuantity
            guard newQuantity <= product.stock else {
                throw CartError.insufficientStock(available: product.stock)
            }
            items[index].setQuantity(newQuantity)
            commit(.itemUpdated)
            return .updated(newQuantity: newQuantity)
        }

        guard addedQuantity <= product.stock else {
            throw CartError.insufficientStock(available: product.stock)
        }
        items.append(CartItem(product: product, quantity: addedQuantity))
        if shopId == nil {
            shopId = product.shopId
            shopName = product.shopName
        }
        commit(.itemAdded)
        return .added
    }

    func replaceCart(with product: Product, quantity: Int = 1) throws {
        guard quantity > 0 else {
            throw CartError.invalidQuantity(requested: quantity)
        }
        guard !product.isOutOfStock else {
            throw CartError.productOutOfStock
        }
        guard quantity <= product.stock else {
            throw CartError.insufficientStock(available: product.stock)
        }
        items.removeAll()
        appliedCoupon = nil
        shopId = product.shopId
        shopName = product.shopName
        items.append(CartItem(product: product, quantity: quantity))
        commit(.cartReplaced)
    }

    func removeProduct(productId: String) {
        guard let index = items.firstIndex(where: { $0.product.id == productId }) else { return }
        items.remove(at: index)
        if items.isEmpty {
            resetShopAndCoupon()
        }
        commit(.itemRemoved)
    }

    func increaseQuantity(productId: String) throws {
        guard let index = items.firstIndex(where: { $0.product.id == productId }) else {
            throw CartError.productNotFound
        }
        let newQuantity = items[index].quantity + 1
        guard newQuantity <= items[index].product.stock else {
            throw CartError.insufficientStock(available: items[index].product.stock)
        }
        items[index].setQuantity(newQuantity)
        commit(.itemUpdated)
    }

    func decreaseQuantity(productId: String) {
        guard let index = items.firstIndex(where: { $0.product.id == productId }) else { return }
        if items[index].quantity <= 1 {
            removeProduct(productId: productId)
        } else {
            items[index].setQuantity(items[index].quantity - 1)
            commit(.itemUpdated)
        }
    }

    func updateQuantity(_ quantity: Int, forProductId productId: String) throws {
        guard quantity > 0 else {
            removeProduct(productId: productId)
            return
        }
        guard let index = items.firstIndex(where: { $0.product.id == productId }) else {
            throw CartError.productNotFound
        }
        guard quantity <= items[index].product.stock else {
            throw CartError.insufficientStock(available: items[index].product.stock)
        }
        items[index].setQuantity(quantity)
        commit(.itemUpdated)
    }

    func clearCart() {
        guard !items.isEmpty || appliedCoupon != nil || deliveryFee != 0 else { return }
        items.removeAll()
        resetShopAndCoupon()
        deliveryFee = 0
        commit(.cartCleared)
    }

    func applyCoupon(_ coupon: Coupon) throws {
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.lineTotal }
        switch pricingEngine.validate(coupon, subtotal: subtotal, cartShopId: shopId) {
        case .valid:
            appliedCoupon = coupon
            commit(.couponApplied)
        case .failed(let failure):
            throw CartError.couponInvalid(failure)
        }
    }

    func removeCoupon() {
        guard appliedCoupon != nil else { return }
        appliedCoupon = nil
        commit(.couponRemoved)
    }

    func validateAppliedCoupon() -> CouponValidationResult {
        guard let coupon = appliedCoupon else { return .valid }
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.lineTotal }
        return pricingEngine.validate(coupon, subtotal: subtotal, cartShopId: shopId)
    }

    func updateDeliveryFee(_ fee: Decimal) {
        let sanitized = max(fee, 0)
        guard sanitized != deliveryFee else { return }
        deliveryFee = sanitized
        commit(.deliveryFeeUpdated)
    }

    func recalculateDeliveryFee(distanceKm: Decimal) {
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.lineTotal }
        updateDeliveryFee(
            DeliveryFeeCalculator.fee(
                distanceKm: distanceKm,
                subtotal: subtotal,
                configuration: deliveryFeeConfiguration
            )
        )
    }

    func calculateTotals() -> CartTotals {
        let cartSubtotal = items.reduce(Decimal(0)) { $0 + $1.lineTotal }.roundedTo()
        let discountAmount = appliedDiscountAmount().roundedTo()
        let taxableAmount = max(cartSubtotal - discountAmount, 0)
        let taxAmount = pricingEngine.taxAmount(taxableAmount: taxableAmount, rate: taxRate).roundedTo()
        let grandTotal = max(taxableAmount + deliveryFee + taxAmount, 0)
        let savingsFromOffers = items.reduce(Decimal(0)) { $0 + $1.lineSavings }.roundedTo()
        return CartTotals(
            cartSubtotal: cartSubtotal,
            discountAmount: discountAmount,
            deliveryFee: deliveryFee,
            taxAmount: taxAmount,
            grandTotal: grandTotal,
            itemCount: itemCount,
            savingsFromOffers: savingsFromOffers
        )
    }

    private func appliedDiscountAmount() -> Decimal {
        guard let coupon = appliedCoupon else { return 0 }
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.lineTotal }
        guard case .valid = pricingEngine.validate(coupon, subtotal: subtotal, cartShopId: shopId) else {
            return 0
        }
        return pricingEngine.discount(for: coupon, subtotal: subtotal)
    }

    private func resetShopAndCoupon() {
        shopId = nil
        shopName = nil
        appliedCoupon = nil
    }

    private func commit(_ kind: CartChangeKind) {
        persist()
        let info = CartChangeInfo(kind: kind, totals: calculateTotals())
        NotificationCenter.default.post(
            name: .cartDidChange,
            object: self,
            userInfo: [CartNotificationKeys.changeInfo: info]
        )
    }

    private func persist() {
        store.save(
            state: CartPersistedState(
                items: items,
                shopId: shopId,
                shopName: shopName,
                coupon: appliedCoupon,
                deliveryFee: deliveryFee
            )
        )
    }
}
