import Testing
import CoreData
@testable import rvfood

@MainActor
@Suite(.serialized)
struct PersistenceTests {

    private func makeRepository() -> LocalAddressRepository {
        LocalAddressRepository(controller: PersistenceController(inMemory: true))
    }

    @Test func addressRoundTripsThroughCoreData() async throws {
        let repository = makeRepository()

        let newAddress = Address(
            id: "",
            name: "Test User",
            phone: "9000000000",
            houseDetail: "Flat 3",
            street: "MG Road",
            area: "RS Puram",
            city: "Coimbatore",
            state: "Tamil Nadu",
            postalCode: "641002",
            point: GeoPoint(latitude: 11.01, longitude: 76.95),
            type: .home,
            isDefault: false
        )

        let saved = try await repository.save(newAddress)
        #expect(saved.id.hasPrefix("addr_"))

        let all = try await repository.addresses()
        #expect(all.contains { $0.id == saved.id })

        try await repository.setDefault(addressId: saved.id)
        let reloaded = try await repository.addresses()
        #expect(reloaded.first(where: { $0.id == saved.id })?.isDefault == true)
        #expect(reloaded.filter(\.isDefault).count == 1)

        try await repository.delete(addressId: saved.id)
        let afterDelete = try await repository.addresses()
        #expect(!afterDelete.contains { $0.id == saved.id })
    }

    @Test func orderPersistsAndRoundTripsThroughCoreData() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.context

        let item = OrderItem(productId: "milk", productName: "Aavin Milk", unit: "500 ml", unitPrice: 26, quantity: 2, lineTotal: 52)
        let order = Order(
            id: "ORD_TEST_1",
            shopId: "shop_dairy",
            shopName: "Sri Dairy & Farms",
            createdAt: Date.now,
            items: [item],
            addressSnapshot: "12A Test Street, Coimbatore",
            paymentMethod: .cashOnDelivery,
            isPaid: false,
            status: .pending,
            totals: OrderTotals(cartSubtotal: 52, discountAmount: 0, deliveryFee: 20, taxAmount: 2, grandTotal: 74),
            couponCode: nil
        )
        ManagedOrder.from(order, in: context)
        controller.save()

        let request = NSFetchRequest<ManagedOrder>(entityName: "Order")
        request.predicate = NSPredicate(format: "id == %@", "ORD_TEST_1")
        let managed = try context.fetch(request).first
        #expect(managed != nil)

        let decoded = managed?.asStruct
        #expect(decoded?.items.count == 1)
        #expect(decoded?.items.first?.productName == "Aavin Milk")
        #expect(decoded?.totals.grandTotal == 74)
        #expect(decoded?.status == .pending)

        managed?.statusRaw = OrderStatus.delivered.rawValue
        controller.save()
        #expect(managed?.asStruct.status == .delivered)
    }

    @Test func favoritesToggleInIsolatedStore() {
        let store = FavoritesStore(controller: PersistenceController(inMemory: true))
        let testShopId = "test_shop_\(UUID().uuidString.prefix(6))"
        let testProductId = "test_product_\(UUID().uuidString.prefix(6))"

        #expect(!store.isFavoriteShop(testShopId))
        store.toggleShop(testShopId)
        #expect(store.isFavoriteShop(testShopId))

        store.toggleProduct(testProductId)
        #expect(store.isFavoriteProduct(testProductId))
        #expect(store.favoriteProductIds.count == 1)

        store.toggleShop(testShopId)
        #expect(!store.isFavoriteShop(testShopId))
    }

    @Test func notificationsAddMarkReadAndClear() {
        let store = NotificationsStore(controller: PersistenceController(inMemory: true))
        let marker = "Test notification"

        store.add(kind: .system, title: marker, message: "Body")
        #expect(store.notifications.contains { $0.title == marker })
        #expect(store.unreadCount >= 1)

        store.markAllRead()
        #expect(store.unreadCount == 0)

        store.clearAll()
        #expect(store.notifications.isEmpty)
    }

    @Test func reviewPersistenceWorks() async throws {
        let controller = PersistenceController(inMemory: true)
        let repository = LocalOrderRepository(controller: controller)

        #expect(!repository.hasReview(orderId: "ORD_REVIEW_TEST"))

        try await repository.submitReview(orderId: "ORD_REVIEW_TEST", stars: 4, text: "Great service")
        #expect(repository.hasReview(orderId: "ORD_REVIEW_TEST"))
    }
}
