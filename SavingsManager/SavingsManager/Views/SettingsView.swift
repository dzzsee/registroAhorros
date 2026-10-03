import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [SavingsCard]
    @State private var showDeleteAllAlert = false
    @State private var showExportSheet = false
    @State private var exportData = ""
    @AppStorage("preferredCurrency") private var preferredCurrency = "USD"

    private let currencies = ["USD", "EUR", "GBP", "MXN", "CAD", "AUD", "JPY", "CHF", "CNY"]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Default Currency", selection: $preferredCurrency) {
                        ForEach(currencies, id: \.self) { code in
                            Text("\(code) - \(currencySymbol(for: code))")
                                .tag(code)
                        }
                    }
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("New cards will use this currency by default.")
                }

                Section {
                    HStack {
                        Label("Saved Cards", systemImage: "creditcard")
                        Spacer()
                        Text("\(cards.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Total Balance", systemImage: "dollarsign.circle")
                        Spacer()
                        Text(totalBalanceFormatted)
                            .fontWeight(.semibold)
                    }
                } header: {
                    Text("Statistics")
                }

                Section {
                    Button {
                        exportData = exportAllData()
                        showExportSheet = true
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        showDeleteAllAlert = true
                    } label: {
                        Label("Delete All Data", systemImage: "trash")
                    }
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Export creates a JSON backup. Delete removes all cards and transactions permanently.")
                }

                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://developer.apple.com/documentation/corenfc")!) {
                        Label("NFC Documentation", systemImage: "doc.text")
                    }

                    Link(destination: URL(string: "https://developer.apple.com/documentation/swiftdata")!) {
                        Label("SwiftData Documentation", systemImage: "doc.text")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Delete All Data", isPresented: $showDeleteAllAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all \(cards.count) cards and their transactions. This cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                NavigationStack {
                    ScrollView {
                        Text(exportData)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .textSelection(.enabled)
                    }
                    .navigationTitle("Export Data")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            ShareLink(item: exportData, subject: Text("SavingsManager Export"), message: Text("Backup of savings cards and transactions"))
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showExportSheet = false }
                        }
                    }
                }
            }
        }
    }

    private var totalBalanceFormatted: String {
        let total = cards.reduce(Decimal(0)) { $0 + $1.balance }
        return CurrencyFormatter.format(total, currencyCode: preferredCurrency)
    }

    private func currencySymbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.currencyCode = code
        formatter.numberStyle = .currency
        return formatter.currencySymbol
    }

    private func exportAllData() -> String {
        struct ExportData: Codable {
            let exportDate: Date
            let cards: [ExportCard]
        }

        struct ExportCard: Codable {
            let uid: String
            let balance: Decimal
            let currency: String
            let lastUpdated: Date
            let transactions: [ExportTransaction]
        }

        struct ExportTransaction: Codable {
            let amount: Decimal
            let type: String
            let date: Date
            let note: String?
        }

        let exportCards = cards.map { card in
            ExportCard(
                uid: card.cardUID.map { String(format: "%02X", $0) }.joined(separator: ":"),
                balance: card.balance,
                currency: card.currencyCode,
                lastUpdated: card.lastUpdated,
                transactions: card.transactions.map { tx in
                    ExportTransaction(
                        amount: tx.amount,
                        type: tx.type.rawValue,
                        date: tx.date,
                        note: tx.note
                    )
                }
            )
        }

        let data = ExportData(exportDate: Date(), cards: exportCards)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try? encoder.encode(data)
        return String(data: jsonData ?? Data(), encoding: .utf8) ?? "{}"
    }

    private func deleteAllData() {
        for card in cards {
            modelContext.delete(card)
        }
        try? modelContext.save()
    }
}