import Foundation
import SwiftData

@Model
final class SavingsCard {
    var id: UUID
    var cardUID: Data
    var balance: Decimal
    var currencyCode: String
    var lastUpdated: Date
    @Relationship(deleteRule: .cascade, inverse: \Transaction.card)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        cardUID: Data,
        balance: Decimal = 0,
        currencyCode: String = "USD",
        lastUpdated: Date = Date(),
        transactions: [Transaction] = []
    ) {
        self.id = id
        self.cardUID = cardUID
        self.balance = balance
        self.currencyCode = currencyCode
        self.lastUpdated = lastUpdated
        self.transactions = transactions
    }

    var formattedBalance: String {
        CurrencyFormatter.format(balance, currencyCode: currencyCode)
    }

    var cardUIDString: String {
        cardUID.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    var shortUID: String {
        let hex = cardUID.map { String(format: "%02X", $0) }.joined()
        return String(hex.suffix(8))
    }
}

extension SavingsCard {
    static var preview: SavingsCard {
        let card = SavingsCard(
            cardUID: Data([0x04, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC]),
            balance: 1250.75,
            currencyCode: "USD"
        )
        card.transactions = [
            Transaction(amount: 500, type: .deposit, note: "Initial deposit", card: card),
            Transaction(amount: 250, type: .deposit, note: "Weekly savings", card: card),
            Transaction(amount: 50, type: .withdrawal, note: "Coffee", card: card),
        ]
        return card
    }
}