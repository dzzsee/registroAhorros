import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsCard.lastUpdated, order: .reverse) private var cards: [SavingsCard]
    @State private var selectedCard: SavingsCard?
    @State private var showCardPicker = false

    var allTransactions: [Transaction] {
        cards.flatMap { $0.transactions }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allTransactions.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Transactions",
                        message: "Scan a card and add your first deposit or withdrawal."
                    )
                } else {
                    List {
                        if cards.count > 1 {
                            Picker("Card", selection: $selectedCard) {
                                Text("All Cards").tag(nil as SavingsCard?)
                                ForEach(cards) { card in
                                    Text(card.shortUID).tag(card as SavingsCard?)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedCard) { _, newValue in
                            }
                        }

                        let transactions = selectedCard?.transactions.sorted { $0.date > $1.date } ?? allTransactions

                        ForEach(transactions) { transaction in
                            TransactionRowView(transaction: transaction)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteTransaction(transaction)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if cards.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("All Cards") { selectedCard = nil }
                            Divider()
                            ForEach(cards) { card in
                                Button(card.shortUID) { selectedCard = card }
                            }
                        } label: {
                            Image(systemName: "creditcard")
                        }
                    }
                }
            }
        }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        withAnimation {
            if let card = transaction.card {
                card.transactions.removeAll { $0.id == transaction.id }
                card.lastUpdated = Date()
            }
            modelContext.delete(transaction)
            try? modelContext.save()
        }
    }
}