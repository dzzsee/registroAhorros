import Foundation
import SwiftData

@MainActor
final class PersistenceService {
    static let shared = PersistenceService()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {}

    func configure(with container: ModelContainer) {
        self.modelContainer = container
        self.modelContext = container.mainContext
        NFCService.shared.setModelContext(container.mainContext)
    }

    var context: ModelContext? {
        modelContext
    }

    func save() throws {
        try modelContext?.save()
    }

    func fetchAllCards() throws -> [SavingsCard] {
        let descriptor = FetchDescriptor<SavingsCard>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        return try modelContext?.fetch(descriptor) ?? []
    }

    func fetchCard(byUID uid: Data) throws -> SavingsCard? {
        let descriptor = FetchDescriptor<SavingsCard>(
            predicate: #Predicate { $0.cardUID == uid }
        )
        return try modelContext?.fetch(descriptor).first
    }

    func fetchTransactions(for card: SavingsCard) -> [Transaction] {
        card.transactions.sorted { $0.date > $1.date }
    }

    func addTransaction(_ transaction: Transaction, to card: SavingsCard) {
        modelContext?.insert(transaction)
        card.transactions.append(transaction)
        card.lastUpdated = Date()
    }

    func deleteTransaction(_ transaction: Transaction, from card: SavingsCard) {
        modelContext?.delete(transaction)
        card.transactions.removeAll { $0.id == transaction.id }
        card.lastUpdated = Date()
    }

    func deleteCard(_ card: SavingsCard) {
        modelContext?.delete(card)
    }

    func deleteAllData() throws {
        let cards = try fetchAllCards()
        for card in cards {
            deleteCard(card)
        }
        try save()
    }
}