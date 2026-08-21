import CoreLocation
import Foundation

enum GeoMath {

    static func distanceKm(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let earthRadiusKm = 6371.0
        let dLat = degreesToRadians(destination.latitude - source.latitude)
        let dLon = degreesToRadians(destination.longitude - source.longitude)
        let lat1 = degreesToRadians(source.latitude)
        let lat2 = degreesToRadians(destination.latitude)

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }

    static func isServiceable(
        customerLocation: CLLocationCoordinate2D,
        shopLocation: CLLocationCoordinate2D,
        deliveryRadiusKm: Double
    ) -> Bool {
        distanceKm(from: customerLocation, to: shopLocation) <= deliveryRadiusKm
    }

    static func formattedDistance(_ km: Double) -> String {
        if km < 1 {
            return "\(Int((km * 1000).rounded())) m"
        }
        return String(format: "%.1f km", km)
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}

struct GeoPoint: Equatable, Hashable, Codable {
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}
