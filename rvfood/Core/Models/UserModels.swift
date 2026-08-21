import Foundation

struct UserProfile: Codable, Equatable {
    var id: String
    var name: String
    var email: String
    var phone: String
}

struct AppNotification: Identifiable, Hashable, Codable {
    enum Kind: String, Codable {
        case order, offer, system
    }

    let id: String
    let kind: Kind
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool
}

struct Review: Identifiable, Hashable {
    enum Subject: String {
        case shop, product, delivery
    }

    let id: String
    let orderId: String
    let subject: Subject
    let stars: Int
    let text: String?
    let createdAt: Date
}
