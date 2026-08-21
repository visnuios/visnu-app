import Foundation

protocol AddressRepositoryProtocol {
    func addresses() async throws -> [Address]
    func save(_ address: Address) async throws -> Address
    func delete(addressId: String) async throws
    func setDefault(addressId: String) async throws
    func address(id: String) async throws -> Address
}

final class DemoAddressRepository: AddressRepositoryProtocol {

    private let defaults: UserDefaults
    private static let storageKey = "rvfood.addresses"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if load().isEmpty {
            let seed = [
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
                )
            ]
            persist(seed)
        }
    }

    func addresses() async throws -> [Address] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return load().sorted { $0.isDefault && !$1.isDefault }
    }

    func address(id: String) async throws -> Address {
        guard let address = load().first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return address
    }

    func save(_ address: Address) async throws -> Address {
        var all = load()
        var updated = address
        if all.contains(where: { $0.id == updated.id }) {
            all.removeAll { $0.id == updated.id }
        } else {
            updated = Address(
                id: "addr_\(UUID().uuidString.prefix(8))",
                name: updated.name,
                phone: updated.phone,
                houseDetail: updated.houseDetail,
                street: updated.street,
                area: updated.area,
                city: updated.city,
                state: updated.state,
                postalCode: updated.postalCode,
                point: updated.point,
                type: updated.type,
                isDefault: updated.isDefault
            )
        }
        if updated.isDefault {
            all = all.map { item in
                var item = item
                item.isDefault = false
                return item
            }
        }
        all.append(updated)
        persist(all)
        return updated
    }

    func delete(addressId: String) async throws {
        var all = load()
        guard all.count > 1 else {
            throw APIError.businessRule("Keep at least one saved address.")
        }
        let wasDefault = all.first(where: { $0.id == addressId })?.isDefault ?? false
        all.removeAll { $0.id == addressId }
        if wasDefault, var first = all.first {
            first.isDefault = true
            all[all.startIndex] = first
        }
        persist(all)
    }

    func setDefault(addressId: String) async throws {
        var all = load()
        all = all.map { item in
            var item = item
            item.isDefault = (item.id == addressId)
            return item
        }
        persist(all)
    }

    private func load() -> [Address] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [] }
        return (try? JSONDecoder().decode([Address].self, from: data)) ?? []
    }

    private func persist(_ addresses: [Address]) {
        if let data = try? JSONEncoder().encode(addresses) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
