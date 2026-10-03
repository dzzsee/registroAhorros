import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var card: SavingsCard

    @State private var amount: String = ""
    @State private var type: TransactionType = .deposit
    @State private var note: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isAmountFocused: Bool

    var isValidAmount: Bool {
        guard let value = CurrencyFormatter.parse(amount, currencyCode: card.currencyCode) else { return false }
        if type == .withdrawal && value > card.balance {
            return false
        }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases) { t in
                            Label(t.displayName, systemImage: t.systemImage)
                                .tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Transaction Type")
                }

                Section {
                    HStack {
                        Text(card.currencyCode)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amount)
                            .font(.title2.monospacedDigit())
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Amount")
                } footer: {
                    if type == .withdrawal {
                        Text("Available balance: \(card.formattedBalance)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("Note (optional)", text: $note)
                } header: {
                    Text("Note")
                }

                Section {
                    HStack {
                        Text("New Balance")
                        Spacer()
                        Text(projectedBalance)
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(projectedBalanceDecimal >= 0 ? .primary : .red)
                    }
                }
            }
            .navigationTitle(type == .deposit ? "Add Funds" : "Withdraw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(!isValidAmount)
                }
            }
            .onAppear {
                isAmountFocused = true
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var projectedBalanceDecimal: Decimal {
        let value = CurrencyFormatter.parse(amount, currencyCode: card.currencyCode) ?? 0
        return type == .deposit ? card.balance + value : card.balance - value
    }

    private var projectedBalance: String {
        CurrencyFormatter.format(projectedBalanceDecimal, currencyCode: card.currencyCode)
    }

    private func saveTransaction() {
        guard let value = CurrencyFormatter.parse(amount, currencyCode: card.currencyCode),
              value > 0 else {
            errorMessage = "Please enter a valid amount"
            showError = true
            return
        }

        if type == .withdrawal && value > card.balance {
            errorMessage = "Insufficient balance"
            showError = true
            return
        }

        let transaction = Transaction(
            amount: value,
            type: type,
            note: note.isEmpty ? nil : note,
            card: card
        )

        card.balance = projectedBalanceDecimal
        card.lastUpdated = Date()
        card.transactions.append(transaction)
        modelContext.insert(transaction)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showError = true
        }
    }
}