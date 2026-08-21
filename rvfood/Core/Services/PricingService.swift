import Foundation

enum TaxDefaults {
    static let rate: Decimal = 0.05
}

protocol CartPricingEngine {
    func validate(_ coupon: Coupon, subtotal: Decimal, cartShopId: String?) -> CouponValidationResult
    func discount(for coupon: Coupon, subtotal: Decimal) -> Decimal
    func taxAmount(taxableAmount: Decimal, rate: Decimal) -> Decimal
}

struct DefaultPricingEngine: CartPricingEngine {

    func validate(
        _ coupon: Coupon,
        subtotal: Decimal,
        cartShopId: String?
    ) -> CouponValidationResult {
        if let expiresAt = coupon.expiresAt, expiresAt < Date.now {
            return .failed(.expired)
        }
        if let couponShopId = coupon.shopId, couponShopId != cartShopId {
            return .failed(.wrongShop(expectedShopId: couponShopId))
        }
        if subtotal < coupon.minOrderAmount {
            return .failed(.minimumOrderNotMet(minimum: coupon.minOrderAmount))
        }
        return .valid
    }

    func discount(for coupon: Coupon, subtotal: Decimal) -> Decimal {
        switch coupon.discountType {
        case .fixed:
            return min(coupon.value, subtotal)
        case .percentage:
            let rawDiscount = subtotal * coupon.value / 100
            return min(rawDiscount, coupon.maxDiscountAmount ?? rawDiscount)
        }
    }

    func taxAmount(taxableAmount: Decimal, rate: Decimal) -> Decimal {
        taxableAmount * rate
    }
}
