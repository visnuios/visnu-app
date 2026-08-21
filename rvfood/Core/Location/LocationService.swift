import CoreLocation
import Foundation

final class LocationService: NSObject, CLLocationManagerDelegate {

    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func currentLocation() async throws -> CLLocation {
        if let cached = manager.location, Date.now.timeIntervalSince(cached.timestamp) < 120 {
            return cached
        }
        manager.requestLocation()
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await geocoder.reverseGeocodeLocation(location)
        guard let place = placemarks?.first else { return nil }
        var parts: [String] = []
        if let sublocality = place.subLocality, !sublocality.isEmpty { parts.append(sublocality) }
        if let locality = place.locality, !locality.isEmpty { parts.append(locality) }
        return parts.isEmpty ? place.name : parts.joined(separator: ", ")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if let continuation = permissionContinuation {
            self.permissionContinuation = nil
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                continuation.resume(returning: true)
            default:
                continuation.resume(returning: false)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    private var permissionContinuation: CheckedContinuation<Bool, Never>?
}
