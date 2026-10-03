import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var type: TransactionType
    var date: Date
    var note: String?
    var card: SavingsCard?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: TransactionType,
        date: Date = Date(),
        note: String? = nil,
        card: SavingsCard? = nil
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.card = card
    }

    var signedAmount: Decimal {
        type == .deposit ? amount : -amount
    }

    var formattedAmount: String {
        CurrencyFormatter.format(signedAmount, currencyCode: card?.currencyCode ?? "USD", showSign: true)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case deposit = "deposit"
    case withdrawal = "withdrawal"

    var displayName: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdrawal"
        }
    }

    var systemImage: String {
        switch self {
        case .deposit: return "plus.circle.fill"
        case .withdrawal: return "minus.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .deposit: return "green"
        case .withdrawal: return "red"
        }
    }
}

extension Transaction {
    static var preview: [Transaction] {
        let card = SavingsCard.preview
        return [
            Transaction(amount: 500, type: .deposit, note: "Initial deposit", card: card),
            Transaction(amount: 250, type: .deposit, note: "Weekly savings", card: card),
            Transaction(amount: 50, type: .withdrawal, note: "Coffee", card: card),
            Transaction(amount: 25.50, type: .withdrawal, note: "Lunch", card: card),
        ]
    }
}