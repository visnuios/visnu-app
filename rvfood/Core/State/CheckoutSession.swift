import Foundation

final class CheckoutSession {

    static let shared = CheckoutSession()

    private(set) var selectedAddress: Address?
    private(set) var paymentMethod: PaymentMethod = .cashOnDelivery

    private let cart: CartManager

    init(cart: CartManager = .shared) {
        self.cart = cart
        NotificationCenter.default.addObserver(
            forName: .cartDidChange,
            object: cart,
            queue: .main
        ) { [weak self] note in
            guard let info = note.cartChangeInfo else { return }
            if info.kind == .cartCleared || info.kind == .cartReplaced {
                self?.reset()
            }
        }
    }

    func select(address: Address) {
        selectedAddress = address
        recalculateDeliveryFee()
    }

    func setPaymentMethod(_ method: PaymentMethod) {
        paymentMethod = method
    }

    func recalculateDeliveryFee() {
        guard let address = selectedAddress, let shopId = cart.shopId else { return }
        let shop = DemoCatalog.shops.first(where: { $0.id == shopId })
        let distanceKm = GeoMath.distanceKm(
            from: address.point.coordinate,
            to: (shop?.point ?? SelectedLocationStore.shared.current.point).coordinate
        )
        cart.recalculateDeliveryFee(distanceKm: Decimal(distanceKm))
    }

    func completeOrder() {
        reset()
    }

    func reset() {
        selectedAddress = nil
        paymentMethod = .cashOnDelivery
    }
}
