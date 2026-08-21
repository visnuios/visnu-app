import Foundation

struct Product: Identifiable, Hashable, Encodable {
    let id: String
    let name: String
    let shopId: String
    var shopName: String?
    var categoryId: String?
    var unit: String?
    var productDescription: String?
    var price: Decimal
    var discountPrice: Decimal?
    var stock: Int
    var imageURL: URL?

    var hasDiscount: Bool {
        guard let discountPrice else { return false }
        return discountPrice < price
    }

    var effectiveUnitPrice: Decimal {
        hasDiscount ? discountPrice! : price
    }

    var isOutOfStock: Bool {
        stock <= 0
    }

    var discountPercent: Int? {
        guard hasDiscount, price > 0 else { return nil }
        let fraction = (price - discountPrice!) * 100 / price
        return Int(truncating: NSDecimalNumber(decimal: fraction.roundedTo(scale: 0)))
    }
}

extension Product: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id, name, unit, stock, price
        case shopId = "shop_id"
        case shopName = "shop_name"
        case categoryId = "category_id"
        case productDescription = "description_text"
        case discountPrice = "discount_price"
        case imageURL = "image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = Self.string(in: container, forKey: .id) ?? UUID().uuidString
        name = Self.string(in: container, forKey: .name) ?? ""
        shopId = Self.string(in: container, forKey: .shopId) ?? ""
        shopName = Self.string(in: container, forKey: .shopName)
        categoryId = Self.string(in: container, forKey: .categoryId)
        unit = Self.string(in: container, forKey: .unit)
        productDescription = Self.string(in: container, forKey: .productDescription)
        price = Self.decimal(in: container, forKey: .price) ?? 0
        discountPrice = Self.decimal(in: container, forKey: .discountPrice)
        stock = Self.int(in: container, forKey: .stock) ?? 0
        imageURL = Self.string(in: container, forKey: .imageURL).flatMap(URL.init(string:))
    }

    private static func string(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        try? container.decode(String.self, forKey: key)
    }

    private static func decimal(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Decimal? {
        if let value = try? container.decode(Decimal.self, forKey: key) {
            return value
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            return Decimal(string: raw)
        }
        return nil
    }

    private static func int(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Int? {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            return Int(raw)
        }
        return nil
    }
}
