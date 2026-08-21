import Foundation

struct Shop: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let categoryName: String
    let descriptionText: String?
    let rating: Double
    let ratingCount: Int
    let point: GeoPoint
    let deliveryRadiusKm: Double
    let minOrderAmount: Decimal
    let deliveryTimeMinutes: Int
    let opensAtHour: Int
    let closesAtHour: Int
    var isOpenNow: Bool { !isClosedPermanently && currentHour >= opensAtHour && currentHour < closesAtHour }
    var isClosedPermanently: Bool
    let offerText: String?
    let imageURL: URL?

    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date.now)
    }

    func distanceKm(from customerPoint: GeoPoint) -> Double {
        GeoMath.distanceKm(from: customerPoint.coordinate, to: point.coordinate)
    }

    func isServiceable(from customerPoint: GeoPoint) -> Bool {
        GeoMath.isServiceable(
            customerLocation: customerPoint.coordinate,
            shopLocation: point.coordinate,
            deliveryRadiusKm: deliveryRadiusKm
        )
    }
}

struct ShopCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let symbolName: String
}

enum DefaultShopCategories {
    static let all: [ShopCategory] = [
        ShopCategory(id: "grocery", name: "Grocery", symbolName: "basket.fill"),
        ShopCategory(id: "vegetables", name: "Vegetables", symbolName: "carrot.fill"),
        ShopCategory(id: "fruits", name: "Fruits", symbolName: "apple.logo"),
        ShopCategory(id: "bakery", name: "Bakery", symbolName: "birthday.cake.fill"),
        ShopCategory(id: "meat", name: "Meat", symbolName: "drumstick.fill"),
        ShopCategory(id: "dairy", name: "Dairy", symbolName: "drop.fill"),
        ShopCategory(id: "restaurant", name: "Restaurant", symbolName: "fork.knife"),
        ShopCategory(id: "snacks", name: "Snacks", symbolName: "cookie.fill")
    ]
}
