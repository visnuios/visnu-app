import CoreData
import Foundation

protocol AddressRepositoryProtocol {
    func addresses() async throws -> [Address]
    func save(_ address: Address) async throws -> Address
    func delete(addressId: String) async throws
    func setDefault(addressId: String) async throws
    func address(id: String) async throws -> Address
}

final class LocalAddressRepository: AddressRepositoryProtocol {

    private let persistence: PersistenceController

    init(controller: PersistenceController = .shared) {
        self.persistence = controller
    }

    private var context: NSManagedObjectContext { persistence.context }

    func addresses() async throws -> [Address] {
        let request = NSFetchRequest<ManagedAddress>(entityName: "Address")
        let results = try context.fetch(request)
        return results
            .map(\.asStruct)
            .sorted { lhs, rhs in
                if lhs.isDefault != rhs.isDefault { return lhs.isDefault }
                return lhs.name < rhs.name
            }
    }

    func address(id: String) async throws -> Address {
        guard let managed = fetch(id: id) else {
            throw APIError.notFound
        }
        return managed.asStruct
    }

    func save(_ address: Address) async throws -> Address {
        var updated = address
        if let existing = fetch(id: address.id) {
            ManagedAddress.apply(address, to: existing)
        } else {
            updated = Address(
                id: "addr_\(UUID().uuidString.prefix(8))",
                name: address.name,
                phone: address.phone,
                houseDetail: address.houseDetail,
                street: address.street,
                area: address.area,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                point: address.point,
                type: address.type,
                isDefault: address.isDefault
            )
            ManagedAddress.from(updated, in: context)
        }
        if updated.isDefault {
            clearDefaults(except: updated.id)
        }
        persistence.save()
        return updated
    }

    func delete(addressId: String) async throws {
        let all = try await addresses()
        guard all.count > 1 else {
            throw APIError.businessRule("Keep at least one saved address.")
        }
        let wasDefault = all.first(where: { $0.id == addressId })?.isDefault ?? false
        if let managed = fetch(id: addressId) {
            context.delete(managed)
        }
        if wasDefault, let first = try? await addresses().first(where: { $0.id != addressId }) {
            setDefaultSync(first.id)
        }
        persistence.save()
    }

    func setDefault(addressId: String) async throws {
        setDefaultSync(addressId)
        persistence.save()
    }

    private func setDefaultSync(_ addressId: String) {
        let request = NSFetchRequest<ManagedAddress>(entityName: "Address")
        let all = (try? context.fetch(request)) ?? []
        for managed in all {
            managed.isDefault = (managed.id == addressId)
        }
    }

    private func clearDefaults(except keepId: String) {
        let request = NSFetchRequest<ManagedAddress>(entityName: "Address")
        let all = (try? context.fetch(request)) ?? []
        for managed in all where managed.id != keepId {
            managed.isDefault = false
        }
    }

    private func fetch(id: String) -> ManagedAddress? {
        let request = NSFetchRequest<ManagedAddress>(entityName: "Address")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}
