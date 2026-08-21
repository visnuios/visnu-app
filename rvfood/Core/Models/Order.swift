import Foundation

enum OrderStatus: String, Codable, CaseIterable {
    case pending = "PENDING"
    case accepted = "ACCEPTED"
    case preparing = "PREPARING"
    case readyForPickup = "READY_FOR_PICKUP"
    case outForDelivery = "OUT_FOR_DELIVERY"
    case delivered = "DELIVERED"
    case cancelled = "CANCELLED"
    case rejected = "REJECTED"

    var displayTitle: String {
        switch self {
        case .pending: return "Order Placed"
        case .accepted: return "Shop Accepted"
        case .preparing: return "Preparing"
        case .readyForPickup: return "Ready for Pickup"
        case .outForDelivery: return "Out for Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .rejected: return "Rejected"
        }
    }

    var progressIndex: Int? {
        let flow: [OrderStatus] = [.pending, .accepted, .preparing, .readyForPickup, .outForDelivery, .delivered]
        return flow.firstIndex(of: self)
    }

    var isActive: Bool {
        switch self {
        case .pending, .accepted, .preparing, .readyForPickup, .outForDelivery:
            return true
        default:
            return false
        }
    }

    var canBeCancelled: Bool {
        self == .pending || self == .accepted
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case cashOnDelivery = "COD"
    case upi = "UPI"
    case card = "CARD"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .cashOnDelivery: return "Cash on Delivery"
        case .upi: return "UPI"
        case .card: return "Card"
        }
    }

    var symbolName: String {
        switch self {
        case .cashOnDelivery: return "banknote.fill"
        case .upi: return "qrcode"
        case .card: return "creditcard.fill"
        }
    }

    var requiresOnlinePayment: Bool {
        self != .cashOnDelivery
    }
}

struct OrderItem: Identifiable, Hashable, Codable {
    var id: String { productId }
    let productId: String
    let productName: String
    let unit: String?
    let unitPrice: Decimal
    let quantity: Int
    let lineTotal: Decimal
}

struct OrderTotals: Equatable, Codable {
    let cartSubtotal: Decimal
    let discountAmount: Decimal
    let deliveryFee: Decimal
    let taxAmount: Decimal
    let grandTotal: Decimal

    static let empty = OrderTotals(cartSubtotal: 0, discountAmount: 0, deliveryFee: 0, taxAmount: 0, grandTotal: 0)
}

struct Order: Identifiable, Equatable {
    let id: String
    let shopId: String
    let shopName: String
    let createdAt: Date
    let items: [OrderItem]
    let addressSnapshot: String
    let paymentMethod: PaymentMethod
    let isPaid: Bool
    let status: OrderStatus
    let totals: OrderTotals
    let couponCode: String?

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
}

struct PlaceOrderRequest {
    struct Line {
        let productId: String
        let quantity: Int
    }

    let shopId: String
    let lines: [Line]
    let addressId: String
    let couponCode: String?
    let paymentMethod: PaymentMethod
}

struct PlaceOrderResult {
    let order: Order
}
