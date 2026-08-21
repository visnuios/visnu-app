import Foundation

extension Notification.Name {
    static let ordersDidChange = Notification.Name("rvfood.ordersDidChange")
    static let unreadNotificationsDidChange = Notification.Name("rvfood.unreadNotificationsDidChange")
}

final class NotificationsStore {

    static let shared = NotificationsStore()

    private(set) var notifications: [AppNotification] = []

    private let defaults: UserDefaults
    private static let storageKey = "rvfood.notifications"

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notifications = saved
        } else {
            notifications = [
                AppNotification(
                    id: "seed_offer",
                    kind: .offer,
                    title: "Welcome offer!",
                    message: "Use coupon SAVE10 for 10% off (up to ₹40) on orders above ₹300.",
                    createdAt: Date.now.addingTimeInterval(-3600),
                    isRead: false
                )
            ]
            persist()
        }
    }

    func add(kind: AppNotification.Kind, title: String, message: String) {
        notifications.insert(
            AppNotification(id: UUID().uuidString, kind: kind, title: title, message: message, createdAt: Date.now, isRead: false),
            at: 0
        )
        persist()
        NotificationCenter.default.post(name: .unreadNotificationsDidChange, object: nil)
    }

    func addOrderUpdate(orderId: String, status: OrderStatus) {
        add(
            kind: .order,
            title: "Order #\(orderId)",
            message: "Your order is now: \(status.displayTitle)"
        )
    }

    func markAllRead() {
        guard unreadCount > 0 else { return }
        notifications = notifications.map { item in
            var item = item
            item.isRead = true
            return item
        }
        persist()
        NotificationCenter.default.post(name: .unreadNotificationsDidChange, object: nil)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notifications) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}

final class FavoritesStore {

    static let shared = FavoritesStore()

    private(set) var favoriteShopIds: Set<String> = []
    private(set) var favoriteProductIds: Set<String> = []

    private let defaults: UserDefaults
    private static let shopsKey = "rvfood.favoriteShops"
    private static let productsKey = "rvfood.favoriteProducts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoriteShopIds = Set(defaults.stringArray(forKey: Self.shopsKey) ?? [])
        favoriteProductIds = Set(defaults.stringArray(forKey: Self.productsKey) ?? [])
    }

    func toggleShop(_ shopId: String) {
        if favoriteShopIds.contains(shopId) {
            favoriteShopIds.remove(shopId)
        } else {
            favoriteShopIds.insert(shopId)
        }
        defaults.set(Array(favoriteShopIds), forKey: Self.shopsKey)
    }

    func toggleProduct(_ productId: String) {
        if favoriteProductIds.contains(productId) {
            favoriteProductIds.remove(productId)
        } else {
            favoriteProductIds.insert(productId)
        }
        defaults.set(Array(favoriteProductIds), forKey: Self.productsKey)
    }

    func isFavoriteShop(_ shopId: String) -> Bool {
        favoriteShopIds.contains(shopId)
    }

    func isFavoriteProduct(_ productId: String) -> Bool {
        favoriteProductIds.contains(productId)
    }
}
