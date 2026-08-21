import Foundation

extension Decimal {

    func roundedTo(scale: Int = 2) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .bankers)
        return result
    }
}

enum CurrencyFormatter {

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        return formatter
    }()

    static func string(from value: Decimal) -> String {
        formatter.string(from: NSDecimalNumber(decimal: value)) ?? "₹\(value)"
    }
}
