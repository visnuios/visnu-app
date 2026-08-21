import CoreLocation
import Foundation

extension Notification.Name {
    static let selectedLocationDidChange = Notification.Name("rvfood.selectedLocationDidChange")
}

final class SelectedLocationStore {

    static let shared = SelectedLocationStore()

    struct Snapshot: Codable, Equatable {
        var point: GeoPoint
        var title: String
    }

    private(set) var current: Snapshot

    private let defaults: UserDefaults
    private static let storageKey = "rvfood.selectedLocation"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) {
            current = snapshot
        } else {
            current = Snapshot(
                point: GeoPoint(latitude: 11.0168, longitude: 76.9558),
                title: "RS Puram, Coimbatore"
            )
        }
    }

    func update(point: GeoPoint, title: String) {
        current = Snapshot(point: point, title: title)
        if let data = try? JSONEncoder().encode(current) {
            defaults.set(data, forKey: Self.storageKey)
        }
        NotificationCenter.default.post(name: .selectedLocationDidChange, object: nil)
    }

    func update(title: String) {
        update(point: current.point, title: title)
    }
}
