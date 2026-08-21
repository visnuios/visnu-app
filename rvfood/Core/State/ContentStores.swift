import CoreData
import Foundation

extension Notification.Name {
    static let ordersDidChange = Notification.Name("rvfood.ordersDidChange")
    static let unreadNotificationsDidChange = Notification.Name("rvfood.unreadNotificationsDidChange")
    static let favoritesDidChange = Notification.Name("rvfood.favoritesDidChange")
}

final class NotificationsStore {

    static let shared = NotificationsStore()

    private let persistence: PersistenceController

    init(controller: PersistenceController = .shared) {
        self.persistence = controller
        seedWelcomeIfNeeded()
    }

    private var context: NSManagedObjectContext { persistence.context }

    var notifications: [AppNotification] {
        let request = NSFetchRequest<ManagedNotification>(entityName: "Notification")
        let sort = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sort]
        return ((try? context.fetch(request)) ?? []).map(\.asStruct)
    }

    var unreadCount: Int {
        let request = NSFetchRequest<ManagedNotification>(entityName: "Notification")
        request.predicate = NSPredicate(format: "isRead == NO")
        return (try? context.count(for: request)) ?? 0
    }

    func add(kind: AppNotification.Kind, title: String, message: String) {
        let managed = ManagedNotification(entity: PersistenceController.model.entitiesByName["Notification"]!, insertInto: context)
        managed.id = UUID().uuidString
        managed.kindRaw = kind.rawValue
        managed.title = title
        managed.message = message
        managed.createdAt = Date.now
        managed.isRead = false
        persistence.save()
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
        let request = NSFetchRequest<ManagedNotification>(entityName: "Notification")
        for managed in (try? context.fetch(request)) ?? [] {
            managed.isRead = true
        }
        persistence.save()
        NotificationCenter.default.post(name: .unreadNotificationsDidChange, object: nil)
    }

    func clearAll() {
        let request = NSFetchRequest<ManagedNotification>(entityName: "Notification")
        for managed in (try? context.fetch(request)) ?? [] {
            context.delete(managed)
        }
        persistence.save()
        NotificationCenter.default.post(name: .unreadNotificationsDidChange, object: nil)
    }

    private func seedWelcomeIfNeeded() {
        guard notifications.isEmpty else { return }
        let managed = ManagedNotification(entity: PersistenceController.model.entitiesByName["Notification"]!, insertInto: context)
        managed.id = "seed_offer"
        managed.kindRaw = AppNotification.Kind.offer.rawValue
        managed.title = "Welcome offer!"
        managed.message = "Use coupon WELCOME20 for ₹20 off your first order above ₹99. Also try SAVE10 and FLAT50."
        managed.createdAt = Date.now.addingTimeInterval(-3600)
        managed.isRead = false
        persistence.save()
    }
}

final class FavoritesStore {

    enum Kind: String {
        case shop, product
    }

    static let shared = FavoritesStore()

    private let persistence: PersistenceController

    init(controller: PersistenceController = .shared) {
        self.persistence = controller
    }

    private var context: NSManagedObjectContext { persistence.context }

    var favoriteShopIds: Set<String> { ids(for: .shop) }
    var favoriteProductIds: Set<String> { ids(for: .product) }

    func toggleShop(_ shopId: String) {
        toggle(shopId, kind: .shop)
    }

    func toggleProduct(_ productId: String) {
        toggle(productId, kind: .product)
    }

    func isFavoriteShop(_ shopId: String) -> Bool {
        favoriteShopIds.contains(shopId)
    }

    func isFavoriteProduct(_ productId: String) -> Bool {
        favoriteProductIds.contains(productId)
    }

    private func ids(for kind: Kind) -> Set<String> {
        let request = NSFetchRequest<ManagedFavorite>(entityName: "Favorite")
        request.predicate = NSPredicate(format: "kind == %@", kind.rawValue)
        return Set(((try? context.fetch(request)) ?? []).map(\.id))
    }

    private func toggle(_ id: String, kind: Kind) {
        let request = NSFetchRequest<ManagedFavorite>(entityName: "Favorite")
        request.predicate = NSPredicate(format: "id == %@ AND kind == %@", id, kind.rawValue)
        if let existing = try? context.fetch(request).first {
            context.delete(existing)
        } else {
            let managed = ManagedFavorite(entity: PersistenceController.model.entitiesByName["Favorite"]!, insertInto: context)
            managed.id = id
            managed.kind = kind.rawValue
        }
        persistence.save()
        NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
    }
}
