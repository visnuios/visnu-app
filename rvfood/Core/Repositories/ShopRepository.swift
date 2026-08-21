import Foundation

protocol ShopRepositoryProtocol {
    func nearbyShops(categoryId: String?) async throws -> [Shop]
    func shop(id: String) async throws -> Shop
    func searchShops(query: String) async throws -> [Shop]
}

final class DemoShopRepository: ShopRepositoryProtocol {

    private let shops: [Shop]

    init() {
        self.shops = DemoCatalog.shops
    }

    func nearbyShops(categoryId: String?) async throws -> [Shop] {
        try await simulateLatency()
        let customerPoint = SelectedLocationStore.shared.current.point
        return shops
            .filter { !$0.isClosedPermanently }
            .filter { shop in
                guard let categoryId, !categoryId.isEmpty else { return true }
                return shop.categoryName.lowercased().contains(categoryId)
                    || DefaultShopCategories.all.first(where: { $0.id == categoryId })?.name.lowercased() == shop.categoryName.lowercased()
            }
            .filter { $0.isServiceable(from: customerPoint) }
            .sorted { $0.distanceKm(from: customerPoint) < $1.distanceKm(from: customerPoint) }
    }

    func shop(id: String) async throws -> Shop {
        try await simulateLatency()
        guard let shop = shops.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return shop
    }

    func searchShops(query: String) async throws -> [Shop] {
        try await simulateLatency()
        let customerPoint = SelectedLocationStore.shared.current.point
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        return shops
            .filter { $0.name.lowercased().contains(trimmed) || $0.categoryName.lowercased().contains(trimmed) }
            .filter { $0.isServiceable(from: customerPoint) }
            .sorted { $0.distanceKm(from: customerPoint) < $1.distanceKm(from: customerPoint) }
    }

    private func simulateLatency() async throws {
        try await Task.sleep(nanoseconds: 350_000_000)
    }
}
