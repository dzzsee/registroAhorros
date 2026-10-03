import Foundation

enum CurrencyFormatter {
    private static let formatters: [String: NumberFormatter] = {
        let currencies = ["USD", "EUR", "GBP", "MXN", "CAD", "AUD", "JPY", "CHF", "CNY"]
        var dict: [String: NumberFormatter] = [:]
        for code in currencies {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            dict[code] = formatter
        }
        return dict
    }()

    static func format(_ value: Decimal, currencyCode: String = "USD", showSign: Bool = false) -> String {
        let formatter = formatters[currencyCode] ?? formatters["USD"]!
        let number = NSDecimalNumber(decimal: value)

        if showSign && value > 0 {
            return "+" + formatter.string(from: number)!
        }
        return formatter.string(from: number) ?? "\(currencyCode) \(value)"
    }

    static func formatAbs(_ value: Decimal, currencyCode: String = "USD") -> String {
        let formatter = formatters[currencyCode] ?? formatters["USD"]!
        let number = NSDecimalNumber(decimal: abs(value))
        return formatter.string(from: number) ?? "\(currencyCode) \(abs(value))"
    }

    static func parse(_ string: String, currencyCode: String = "USD") -> Decimal? {
        let formatter = formatters[currencyCode] ?? formatters["USD"]!
        let cleaned = string
            .replacingOccurrences(of: formatter.currencySymbol, with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let number = formatter.number(from: cleaned) else { return nil }
        return Decimal(string: number.stringValue)
    }
}