import Foundation

enum AddressType: String, Codable, CaseIterable, Identifiable {
    case home = "Home"
    case work = "Work"
    case other = "Other"

    var id: String { rawValue }
}

struct Address: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var phone: String
    var houseDetail: String
    var street: String
    var area: String
    var city: String
    var state: String
    var postalCode: String
    var point: GeoPoint
    var type: AddressType
    var isDefault: Bool

    var singleLine: String {
        [houseDetail, street, area, city, state, postalCode]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
    }

    var shortTitle: String {
        let first = houseDetail.isEmpty ? street : houseDetail
        return "\(type.rawValue) · \(first)"
    }
}

struct DeliveryQuote: Equatable {
    let addressId: String
    let point: GeoPoint
    let deliveryFee: Decimal
}
