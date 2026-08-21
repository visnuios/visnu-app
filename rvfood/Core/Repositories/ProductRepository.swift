import Foundation

struct ProductVariationOption: Identifiable, Hashable {
    let id: String
    let groupName: String
    let title: String
    let priceDelta: Decimal
}

struct ProductDetails {
    let product: Product
    let variations: [ProductVariationOption]
    let isSpecial: Bool
}

protocol ProductRepositoryProtocol {
    func products(shopId: String) async throws -> [Product]
    func productDetails(productId: String) async throws -> ProductDetails
    func recommendedProducts(shopId: String?) async throws -> [Product]
    func specialProducts(shopId: String?) async throws -> [Product]
    func searchProducts(query: String) async throws -> [(product: Product, shopName: String, distanceKm: Double)]
}

final class DemoProductRepository: ProductRepositoryProtocol {

    private var catalog: [Product] { DemoCatalog.products }
    private var specialIds: Set<String> { ["ghee", "honey", "dry_fruits"] }

    func products(shopId: String) async throws -> [Product] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return catalog.filter { $0.shopId == shopId }
    }

    func productDetails(productId: String) async throws -> ProductDetails {
        try await Task.sleep(nanoseconds: 250_000_000)
        guard let product = catalog.first(where: { $0.id == productId }) else {
            throw APIError.notFound
        }
        let variations = productId == "pizza_margherita" ? DemoCatalog.pizzaVariations : []
        return ProductDetails(
            product: product,
            variations: variations,
            isSpecial: specialIds.contains(productId)
        )
    }

    func recommendedProducts(shopId: String?) async throws -> [Product] {
        try await Task.sleep(nanoseconds: 200_000_000)
        var items = catalog.filter { $0.hasDiscount }
        if let shopId {
            items = items.filter { $0.shopId == shopId }
        }
        return Array(items.prefix(8))
    }

    func specialProducts(shopId: String?) async throws -> [Product] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let items = catalog.filter { specialIds.contains($0.id) }
        if let shopId {
            let sameShopSpecials = items.filter { $0.shopId == shopId }
            if !sameShopSpecials.isEmpty {
                return sameShopSpecials
            }
        }
        return items
    }

    func searchProducts(query: String) async throws -> [(product: Product, shopName: String, distanceKm: Double)] {
        try await Task.sleep(nanoseconds: 300_000_000)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }
        let customerPoint = SelectedLocationStore.shared.current.point
        return catalog.compactMap { product in
            guard product.name.lowercased().contains(trimmed),
                  let shop = DemoCatalog.shops.first(where: { $0.id == product.shopId }),
                  shop.isServiceable(from: customerPoint) else {
                return nil
            }
            return (product, shop.name, shop.distanceKm(from: customerPoint))
        }
        .sorted { $0.distanceKm < $1.distanceKm }
    }
}
