import Foundation

struct CheckoutDraft {
    var cartSubtotal: Decimal
    var discountAmount: Decimal
    var deliveryFee: Decimal
    var taxAmount: Decimal
    var grandTotal: Decimal
    var addressId: String?

    init(cartSubtotal: Decimal = 0,
         discountAmount: Decimal = 0,
         deliveryFee: Decimal = 0,
         taxAmount: Decimal = 0,
         grandTotal: Decimal = 0,
         addressId: String? = nil) {
        self.cartSubtotal = cartSubtotal
        self.discountAmount = discountAmount
        self.deliveryFee = deliveryFee
        self.taxAmount = taxAmount
        self.grandTotal = grandTotal
        self.addressId = addressId
    }

    init(totals: CartTotals, addressId: String?) {
        self.cartSubtotal = totals.cartSubtotal
        self.discountAmount = totals.discountAmount
        self.deliveryFee = totals.deliveryFee
        self.taxAmount = totals.taxAmount
        self.grandTotal = totals.grandTotal
        self.addressId = addressId
    }

    mutating func refresh(from totals: CartTotals) {
        cartSubtotal = totals.cartSubtotal
        discountAmount = totals.discountAmount
        deliveryFee = totals.deliveryFee
        taxAmount = totals.taxAmount
        grandTotal = totals.grandTotal
    }
}
