import CoreData
import Foundation

final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "rvfood", managedObjectModel: Self.model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data store failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        seedIfNeeded()
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    private func seedIfNeeded() {
        let request = NSFetchRequest<ManagedAddress>(entityName: "Address")
        let existingCount = (try? context.count(for: request)) ?? 0
        guard existingCount == 0 else { return }

        ManagedAddress.from(
            Address(
                id: "addr_home",
                name: "Home",
                phone: "9876543210",
                houseDetail: "12A, Lotus Apartments",
                street: "Cross Cut Road",
                area: "Gandhipuram",
                city: "Coimbatore",
                state: "Tamil Nadu",
                postalCode: "641012",
                point: GeoPoint(latitude: 11.0185, longitude: 76.9674),
                type: .home,
                isDefault: true
            ),
            in: context
        )
        ManagedAddress.from(
            Address(
                id: "addr_work",
                name: "Work",
                phone: "9876543210",
                houseDetail: "Tidel Park, 4th Floor",
                street: "Avinashi Road",
                area: "Peelamedu",
                city: "Coimbatore",
                state: "Tamil Nadu",
                postalCode: "641004",
                point: GeoPoint(latitude: 11.0297, longitude: 77.0276),
                type: .work,
                isDefault: false
            ),
            in: context
        )
        save()
    }

    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            if let defaultValue {
                attr.defaultValue = defaultValue
            }
            return attr
        }

        func entity(_ name: String, _ attributes: [NSAttributeDescription]) -> NSEntityDescription {
            let entity = NSEntityDescription()
            entity.name = name
            entity.managedObjectClassName = "Managed\(name)"
            entity.properties = attributes
            return entity
        }

        let address = entity("Address", [
            attribute("id", .stringAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("phone", .stringAttributeType, defaultValue: ""),
            attribute("houseDetail", .stringAttributeType, optional: true),
            attribute("street", .stringAttributeType, optional: true),
            attribute("area", .stringAttributeType, optional: true),
            attribute("city", .stringAttributeType, defaultValue: ""),
            attribute("state", .stringAttributeType, defaultValue: ""),
            attribute("postalCode", .stringAttributeType, optional: true),
            attribute("latitude", .doubleAttributeType, defaultValue: 0.0),
            attribute("longitude", .doubleAttributeType, defaultValue: 0.0),
            attribute("typeRaw", .stringAttributeType, defaultValue: "home"),
            attribute("isDefault", .booleanAttributeType, defaultValue: false)
        ])

        let order = entity("Order", [
            attribute("id", .stringAttributeType),
            attribute("shopId", .stringAttributeType, defaultValue: ""),
            attribute("shopName", .stringAttributeType, defaultValue: ""),
            attribute("createdAt", .dateAttributeType),
            attribute("itemsJSON", .binaryDataAttributeType, optional: true),
            attribute("addressSnapshot", .stringAttributeType, defaultValue: ""),
            attribute("paymentMethodRaw", .stringAttributeType, defaultValue: "COD"),
            attribute("isPaid", .booleanAttributeType, defaultValue: false),
            attribute("statusRaw", .stringAttributeType, defaultValue: "PENDING"),
            attribute("totalsJSON", .binaryDataAttributeType, optional: true),
            attribute("couponCode", .stringAttributeType, optional: true)
        ])

        let favorite = entity("Favorite", [
            attribute("id", .stringAttributeType),
            attribute("kind", .stringAttributeType)
        ])

        let notification = entity("Notification", [
            attribute("id", .stringAttributeType),
            attribute("kindRaw", .stringAttributeType, defaultValue: "system"),
            attribute("title", .stringAttributeType, defaultValue: ""),
            attribute("message", .stringAttributeType, defaultValue: ""),
            attribute("createdAt", .dateAttributeType),
            attribute("isRead", .booleanAttributeType, defaultValue: false)
        ])

        let review = entity("Review", [
            attribute("id", .stringAttributeType),
            attribute("orderId", .stringAttributeType),
            attribute("stars", .integer16AttributeType, defaultValue: 5),
            attribute("text", .stringAttributeType, optional: true),
            attribute("createdAt", .dateAttributeType)
        ])

        model.entities = [address, order, favorite, notification, review]
        return model
    }()
}

@objc(ManagedAddress)
final class ManagedAddress: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var phone: String
    @NSManaged var houseDetail: String?
    @NSManaged var street: String?
    @NSManaged var area: String?
    @NSManaged var city: String
    @NSManaged var state: String
    @NSManaged var postalCode: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var typeRaw: String
    @NSManaged var isDefault: Bool

    static func from(_ address: Address, in context: NSManagedObjectContext) -> ManagedAddress {
        let managed = ManagedAddress(entity: PersistenceController.model.entitiesByName["Address"]!, insertInto: context)
        apply(address, to: managed)
        return managed
    }

    static func apply(_ address: Address, to managed: ManagedAddress) {
        managed.id = address.id
        managed.name = address.name
        managed.phone = address.phone
        managed.houseDetail = address.houseDetail
        managed.street = address.street
        managed.area = address.area
        managed.city = address.city
        managed.state = address.state
        managed.postalCode = address.postalCode
        managed.latitude = address.point.latitude
        managed.longitude = address.point.longitude
        managed.typeRaw = address.type.rawValue
        managed.isDefault = address.isDefault
    }

    var asStruct: Address {
        Address(
            id: id,
            name: name,
            phone: phone,
            houseDetail: houseDetail ?? "",
            street: street ?? "",
            area: area ?? "",
            city: city,
            state: state,
            postalCode: postalCode ?? "",
            point: GeoPoint(latitude: latitude, longitude: longitude),
            type: AddressType(rawValue: typeRaw) ?? .other,
            isDefault: isDefault
        )
    }
}

@objc(ManagedOrder)
final class ManagedOrder: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var shopId: String
    @NSManaged var shopName: String
    @NSManaged var createdAt: Date
    @NSManaged var itemsJSON: Data?
    @NSManaged var addressSnapshot: String
    @NSManaged var paymentMethodRaw: String
    @NSManaged var isPaid: Bool
    @NSManaged var statusRaw: String
    @NSManaged var totalsJSON: Data?
    @NSManaged var couponCode: String?

    static func from(_ order: Order, in context: NSManagedObjectContext) -> ManagedOrder {
        let managed = ManagedOrder(entity: PersistenceController.model.entitiesByName["Order"]!, insertInto: context)
        apply(order, to: managed)
        return managed
    }

    static func apply(_ order: Order, to managed: ManagedOrder) {
        managed.id = order.id
        managed.shopId = order.shopId
        managed.shopName = order.shopName
        managed.createdAt = order.createdAt
        managed.itemsJSON = try? JSONEncoder().encode(order.items)
        managed.addressSnapshot = order.addressSnapshot
        managed.paymentMethodRaw = order.paymentMethod.rawValue
        managed.isPaid = order.isPaid
        managed.statusRaw = order.status.rawValue
        managed.totalsJSON = try? JSONEncoder().encode(order.totals)
        managed.couponCode = order.couponCode
    }

    var asStruct: Order {
        let items = itemsJSON.flatMap { try? JSONDecoder().decode([OrderItem].self, from: $0) } ?? []
        let totals = totalsJSON.flatMap { try? JSONDecoder().decode(OrderTotals.self, from: $0) } ?? .empty
        return Order(
            id: id,
            shopId: shopId,
            shopName: shopName,
            createdAt: createdAt,
            items: items,
            addressSnapshot: addressSnapshot,
            paymentMethod: PaymentMethod(rawValue: paymentMethodRaw) ?? .cashOnDelivery,
            isPaid: isPaid,
            status: OrderStatus(rawValue: statusRaw) ?? .pending,
            totals: totals,
            couponCode: couponCode
        )
    }
}

@objc(ManagedFavorite)
final class ManagedFavorite: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var kind: String
}

@objc(ManagedNotification)
final class ManagedNotification: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var kindRaw: String
    @NSManaged var title: String
    @NSManaged var message: String
    @NSManaged var createdAt: Date
    @NSManaged var isRead: Bool

    var asStruct: AppNotification {
        AppNotification(
            id: id,
            kind: AppNotification.Kind(rawValue: kindRaw) ?? .system,
            title: title,
            message: message,
            createdAt: createdAt,
            isRead: isRead
        )
    }
}

@objc(ManagedReview)
final class ManagedReview: NSManagedObject {
    @NSManaged var id: String
    @NSManaged var orderId: String
    @NSManaged var stars: Int16
    @NSManaged var text: String?
    @NSManaged var createdAt: Date
}
