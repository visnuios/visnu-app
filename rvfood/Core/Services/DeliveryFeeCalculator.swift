import Foundation

struct DeliverySlab: Hashable, Codable {
    let maxDistanceKm: Decimal
    let fee: Decimal
}

struct DeliveryFeeConfiguration: Hashable, Codable {
    var slabs: [DeliverySlab]
    var beyondLastSlabFee: Decimal
    var freeDeliveryThresholdSubtotal: Decimal?

    static let standard = DeliveryFeeConfiguration(
        slabs: [
            DeliverySlab(maxDistanceKm: 3, fee: 20),
            DeliverySlab(maxDistanceKm: 5, fee: 30),
            DeliverySlab(maxDistanceKm: 8, fee: 50)
        ],
        beyondLastSlabFee: 50,
        freeDeliveryThresholdSubtotal: 499
    )
}

enum DeliveryFeeCalculator {

    static func fee(
        distanceKm: Decimal,
        subtotal: Decimal,
        configuration: DeliveryFeeConfiguration = .standard
    ) -> Decimal {
        if let threshold = configuration.freeDeliveryThresholdSubtotal,
           subtotal >= threshold {
            return 0
        }
        for slab in configuration.slabs where distanceKm <= slab.maxDistanceKm {
            return slab.fee
        }
        return configuration.beyondLastSlabFee
    }
}
