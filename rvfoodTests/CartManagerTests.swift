import Foundation
import Testing
@testable import rvfood

struct CartManagerTests {

    private func makeManager(taxRate: Decimal = 0) -> CartManager {
        CartManager(
            store: InMemoryCartStore(),
            pricingEngine: DefaultPricingEngine(),
            taxRate: taxRate,
            deliveryFeeConfiguration: .standard
        )
    }

    private func makeProduct(
        id: String,
        price: Decimal,
        discountPrice: Decimal? = nil,
        stock: Int = 10,
        shopId: String = "shop_1",
        shopName: String? = "ABC Grocery"
    ) -> Product {
        Product(
            id: id,
            name: "Product \(id)",
            shopId: shopId,
            shopName: shopName,
            categoryId: "cat_1",
            unit: "1 kg",
            productDescription: nil,
            price: price,
            discountPrice: discountPrice,
            stock: stock,
            imageURL: nil
        )
    }

    @Test
    func addProductUpdatesSubtotalItemCountAndGrandTotal() throws {
        let cart = makeManager()
        let tomato = makeProduct(id: "tomato", price: 60, discountPrice: 45)

        _ = try cart.addProduct(tomato, quantity: 2)

        let totals = cart.totals
        #expect(totals.cartSubtotal == 90)
        #expect(totals.itemCount == 2)
        #expect(totals.grandTotal == 90)
        #expect(totals.savingsFromOffers == 30)
    }

    @Test
    func increaseAndDecreaseQuantityUpdateTotalsImmediately() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 300), quantity: 1)

        try cart.increaseQuantity(productId: "rice")
        #expect(cart.totals.cartSubtotal == 600)
        #expect(cart.totals.itemCount == 2)

        cart.decreaseQuantity(productId: "rice")
        #expect(cart.totals.cartSubtotal == 300)
        #expect(cart.totals.itemCount == 1)
    }

    @Test
    func decreaseToZeroRemovesLineItem() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "milk", price: 60), quantity: 1)

        cart.decreaseQuantity(productId: "milk")

        #expect(cart.isEmpty)
        #expect(cart.shopId == nil)
        #expect(cart.totals == .empty)
    }

    @Test
    func removeProductRecalculatesTotals() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 300), quantity: 1)
        _ = try cart.addProduct(makeProduct(id: "milk", price: 60), quantity: 2)

        cart.removeProduct(productId: "rice")

        #expect(cart.totals.cartSubtotal == 120)
        #expect(cart.itemCount == 2)
    }

    @Test
    func addingFromDifferentShopReturnsConflictWithoutMutatingCart() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 300, shopId: "shop_1"), quantity: 1)

        let result = try cart.addProduct(makeProduct(id: "pizza", price: 250, shopId: "shop_2", shopName: "Pizza Hub"))

        guard case .conflict(let existingShop) = result else {
            Issue.record("Expected conflict, got \(result)")
            return
        }
        #expect(existingShop.shopId == "shop_1")
        #expect(existingShop.shopName == "ABC Grocery")
        #expect(cart.shopId == "shop_1")
        #expect(cart.totals.cartSubtotal == 300)
        #expect(!cart.containsProduct(productId: "pizza"))
    }

    @Test
    func replaceCartSwapsShopAndItemsAndDropsCoupon() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500, shopId: "shop_1"), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c1", code: "SAVE50", title: nil, discountType: .fixed,
            value: 50, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        try cart.replaceCart(with: makeProduct(id: "pizza", price: 250, shopId: "shop_2", shopName: "Pizza Hub"), quantity: 2)

        #expect(cart.shopId == "shop_2")
        #expect(cart.shopName == "Pizza Hub")
        #expect(cart.appliedCoupon == nil)
        #expect(cart.totals.cartSubtotal == 500)
        #expect(cart.totals.discountAmount == 0)
    }

    @Test
    func outOfStockProductIsRejected() {
        let cart = makeManager()
        #expect(throws: CartError.productOutOfStock) {
            try cart.addProduct(makeProduct(id: "bread", price: 40, stock: 0))
        }
    }

    @Test
    func exceedingStockThrowsInsufficientStock() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "eggs", price: 90, stock: 3), quantity: 3)

        #expect(throws: CartError.insufficientStock(available: 3)) {
            try cart.increaseQuantity(productId: "eggs")
        }
        #expect(throws: CartError.insufficientStock(available: 3)) {
            try cart.updateQuantity(5, forProductId: "eggs")
        }
        #expect(cart.totals.itemCount == 3)
    }

    @Test
    func percentageCouponAppliesMaximumDiscountCap() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c1", code: "SAVE10", title: nil, discountType: .percentage,
            value: 10, minOrderAmount: 0, maxDiscountAmount: 40, shopId: nil, expiresAt: nil
        ))

        let totals = cart.totals
        #expect(totals.discountAmount == 40)
        #expect(totals.cartSubtotal == 500)
        #expect(totals.grandTotal == 460)
    }

    @Test
    func fixedCouponCappedAtSubtotal() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "bread", price: 80), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c2", code: "FLAT100", title: nil, discountType: .fixed,
            value: 100, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        let totals = cart.totals
        #expect(totals.discountAmount == 80)
        #expect(totals.grandTotal == 0)
    }

    @Test
    func couponMinimumOrderAmountEnforced() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "snack", price: 200), quantity: 1)

        #expect(throws: CartError.couponInvalid(.minimumOrderNotMet(minimum: 300))) {
            try cart.applyCoupon(Coupon(
                id: "c3", code: "MIN300", title: nil, discountType: .percentage,
                value: 5, minOrderAmount: 300, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
            ))
        }
        #expect(cart.appliedCoupon == nil)
    }

    @Test
    func shopSpecificCouponRejectedForOtherShop() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500, shopId: "shop_1"), quantity: 1)

        #expect(throws: CartError.couponInvalid(.wrongShop(expectedShopId: "shop_9"))) {
            try cart.applyCoupon(Coupon(
                id: "c4", code: "SHOP9", title: nil, discountType: .percentage,
                value: 10, minOrderAmount: 0, maxDiscountAmount: nil, shopId: "shop_9", expiresAt: nil
            ))
        }
    }

    @Test
    func expiredCouponRejected() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)

        #expect(throws: CartError.couponInvalid(.expired)) {
            try cart.applyCoupon(Coupon(
                id: "c5", code: "OLD", title: nil, discountType: .percentage,
                value: 10, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil,
                expiresAt: Date(timeIntervalSinceNow: -86400)
            ))
        }
    }

    @Test
    func couponBecomesIneffectiveWhenSubtotalDropsBelowMinimum() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 400), quantity: 1)
        _ = try cart.addProduct(makeProduct(id: "milk", price: 60), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c6", code: "MIN350", title: nil, discountType: .fixed,
            value: 40, minOrderAmount: 350, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))
        #expect(cart.totals.discountAmount == 40)

        cart.removeProduct(productId: "rice")

        #expect(cart.totals.cartSubtotal == 60)
        #expect(cart.totals.discountAmount == 0)
        #expect(cart.validateAppliedCoupon() == .failed(.minimumOrderNotMet(minimum: 350)))
    }

    @Test
    func removeCouponRestoresTotals() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c7", code: "SAVE50", title: nil, discountType: .fixed,
            value: 50, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        cart.removeCoupon()

        #expect(cart.appliedCoupon == nil)
        #expect(cart.totals.discountAmount == 0)
        #expect(cart.totals.grandTotal == 500)
    }

    @Test
    func deliveryFeeStaysSeparateFromSubtotal() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)

        cart.updateDeliveryFee(30)

        var totals = cart.totals
        #expect(totals.cartSubtotal == 500)
        #expect(totals.deliveryFee == 30)
        #expect(totals.grandTotal == 530)

        cart.updateDeliveryFee(50)
        totals = cart.totals
        #expect(totals.cartSubtotal == 500)
        #expect(totals.deliveryFee == 50)
        #expect(totals.grandTotal == 550)
    }

    @Test
    func specialProductScenarioRequirement31() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 300), quantity: 1)
        _ = try cart.addProduct(makeProduct(id: "milk", price: 200), quantity: 1)
        cart.updateDeliveryFee(30)

        var totals = cart.totals
        #expect(totals.cartSubtotal == 500)
        #expect(totals.deliveryFee == 30)
        #expect(totals.grandTotal == 530)

        _ = try cart.addProduct(makeProduct(id: "special_ghee", price: 100), quantity: 1)

        totals = cart.totals
        #expect(totals.cartSubtotal == 600)
        #expect(totals.deliveryFee == 30)
        #expect(totals.grandTotal == 630)
        #expect(totals.itemCount == 3)
    }

    @Test
    func taxAppliedOnDiscountedSubtotalOnly() throws {
        let cart = makeManager(taxRate: 0.05)
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)
        try cart.applyCoupon(Coupon(
            id: "c8", code: "SAVE50", title: nil, discountType: .fixed,
            value: 50, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))
        cart.updateDeliveryFee(30)

        let totals = cart.totals
        #expect(totals.cartSubtotal == 500)
        #expect(totals.discountAmount == 50)
        #expect(totals.taxAmount == Decimal(string: "22.50"))
        #expect(totals.deliveryFee == 30)
        #expect(totals.grandTotal == Decimal(string: "502.50"))
    }

    @Test
    func clearCartResetsAllState() throws {
        let cart = makeManager()
        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)
        cart.updateDeliveryFee(30)
        try cart.applyCoupon(Coupon(
            id: "c9", code: "SAVE10", title: nil, discountType: .percentage,
            value: 10, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        cart.clearCart()

        #expect(cart.isEmpty)
        #expect(cart.shopId == nil)
        #expect(cart.appliedCoupon == nil)
        #expect(cart.deliveryFee == 0)
        #expect(cart.totals == .empty)
    }

    @Test
    func everyMutationPostsChangeNotificationWithFreshTotals() throws {
        let cart = makeManager()
        var received: [CartChangeKind] = []
        var lastTotals: [CartTotals] = []
        let observer = NotificationCenter.default.addObserver(
            forName: .cartDidChange,
            object: cart,
            queue: nil
        ) { note in
            guard let info = note.cartChangeInfo else { return }
            received.append(info.kind)
            lastTotals.append(info.totals)
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = try cart.addProduct(makeProduct(id: "rice", price: 500), quantity: 1)
        cart.updateDeliveryFee(30)
        try cart.applyCoupon(Coupon(
            id: "c10", code: "SAVE50", title: nil, discountType: .fixed,
            value: 50, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        #expect(received == [.itemAdded, .deliveryFeeUpdated, .couponApplied])
        #expect(lastTotals.last?.grandTotal == 480)
        #expect(lastTotals.last?.cartSubtotal == 500)
    }

    @Test
    func persistedStateLoadsIntoNewManagerInstance() throws {
        let store = InMemoryCartStore()
        let first = CartManager(store: store, pricingEngine: DefaultPricingEngine(), taxRate: 0)
        _ = try first.addProduct(makeProduct(id: "rice", price: 120), quantity: 2)
        first.updateDeliveryFee(25)
        try first.applyCoupon(Coupon(
            id: "c11", code: "SAVE20", title: nil, discountType: .fixed,
            value: 20, minOrderAmount: 0, maxDiscountAmount: nil, shopId: nil, expiresAt: nil
        ))

        let second = CartManager(store: store, pricingEngine: DefaultPricingEngine(), taxRate: 0)

        #expect(second.itemCount == 2)
        #expect(second.shopId == "shop_1")
        #expect(second.totals.cartSubtotal == 240)
        #expect(second.totals.deliveryFee == 25)
        #expect(second.totals.discountAmount == 20)
        #expect(second.totals.grandTotal == 245)
    }

    @Test
    func productDecodingSurvivesMissingNullAndStringFields() throws {
        let json = """
        {
            "id": "p9",
            "name": null,
            "price": "60",
            "discount_price": 45,
            "stock": 5
        }
        """
        let product = try JSONDecoder().decode(Product.self, from: Data(json.utf8))

        #expect(product.id == "p9")
        #expect(product.name == "")
        #expect(product.price == 60)
        #expect(product.discountPrice == 45)
        #expect(product.effectiveUnitPrice == 45)
        #expect(product.stock == 5)
        #expect(product.productDescription == nil)
        #expect(product.imageURL == nil)
        #expect(product.discountPercent == 25)
    }
}
