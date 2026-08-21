import Foundation

struct CartItem: Identifiable, Hashable, Codable {
    let product: Product
    private(set) var quantity: Int

    init(product: Product, quantity: Int) {
        self.product = product
        self.quantity = max(quantity, 0)
    }

    var id: String { product.id }
    var lineTotal: Decimal { product.effectiveUnitPrice * Decimal(quantity) }
    var lineOriginalTotal: Decimal { product.price * Decimal(quantity) }
    var lineSavings: Decimal { lineOriginalTotal - lineTotal }

    mutating func setQuantity(_ newQuantity: Int) {
        quantity = max(newQuantity, 0)
    }

    mutating func increment(by amount: Int = 1) {
        quantity += max(amount, 0)
    }
}

enum CouponDiscountType: String, Codable, Hashable {
    case percentage
    case fixed
}

struct Coupon: Identifiable, Hashable, Codable {
    let id: String
    let code: String
    var title: String?
    let discountType: CouponDiscountType
    let value: Decimal
    var minOrderAmount: Decimal
    var maxDiscountAmount: Decimal?
    var shopId: String?
    var expiresAt: Date?
}

enum CouponValidationFailure: Equatable, Error {
    case expired
    case minimumOrderNotMet(minimum: Decimal)
    case wrongShop(expectedShopId: String)
}

enum CouponValidationResult: Equatable {
    case valid
    case failed(CouponValidationFailure)
}

struct CartTotals: Equatable {
    let cartSubtotal: Decimal
    let discountAmount: Decimal
    let deliveryFee: Decimal
    let taxAmount: Decimal
    let grandTotal: Decimal
    let itemCount: Int
    let savingsFromOffers: Decimal

    static let empty = CartTotals(
        cartSubtotal: 0,
        discountAmount: 0,
        deliveryFee: 0,
        taxAmount: 0,
        grandTotal: 0,
        itemCount: 0,
        savingsFromOffers: 0
    )
}

enum CartError: Error, Equatable {
    case invalidQuantity(requested: Int)
    case productOutOfStock
    case insufficientStock(available: Int)
    case productNotFound
    case couponInvalid(CouponValidationFailure)
}

extension CartError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidQuantity(let requested):
            return "Invalid quantity: \(requested)."
        case .productOutOfStock:
            return "This product is out of stock."
        case .insufficientStock(let available):
            return "Only \(available) left in stock."
        case .productNotFound:
            return "This product is no longer in your cart."
        case .couponInvalid(let failure):
            switch failure {
            case .expired:
                return "This coupon has expired."
            case .minimumOrderNotMet(let minimum):
                return "Add items worth \(CurrencyFormatter.string(from: minimum)) to use this coupon."
            case .wrongShop:
                return "This coupon is not valid for this shop."
            }
        }
    }
}

struct ShopConflict: Equatable {
    let shopId: String
    let shopName: String?
}

enum CartAddResult: Equatable {
    case added
    case updated(newQuantity: Int)
    case conflict(existingShop: ShopConflict)
}

enum CartChangeKind: Equatable {
    case itemAdded
    case itemUpdated
    case itemRemoved
    case cartReplaced
    case cartCleared
    case couponApplied
    case couponRemoved
    case deliveryFeeUpdated
}

struct CartChangeInfo {
    let kind: CartChangeKind
    let totals: CartTotals
}

enum CartNotificationKeys {
    static let changeInfo = "rvfood.cartChangeInfo"
}

extension Notification.Name {
    static let cartDidChange = Notification.Name("rvfood.cartDidChange")
}

extension Notification {
    var cartChangeInfo: CartChangeInfo? {
        userInfo?[CartNotificationKeys.changeInfo] as? CartChangeInfo
    }
}
