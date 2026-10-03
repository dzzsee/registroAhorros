import SwiftUI
import SwiftData

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var card: SavingsCard
    @State private var showAddTransaction = false
    @State private var showSaveConfirmation = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            Section {
                BalanceCard(card: card, compact: false)

                HStack(spacing: 16) {
                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Add Funds", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)

                    Button {
                        showAddTransaction = true
                    } label: {
                        Label("Withdraw", systemImage: "minus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.large)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                HStack {
                    Label("Card ID", systemImage: "number")
                    Spacer()
                    Text(card.shortUID)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Currency", systemImage: "dollarsign.circle")
                    Spacer()
                    Text(card.currencyCode)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Label("Last Updated", systemImage: "clock")
                    Spacer()
                    Text(card.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Card Details")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete Card", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Card Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(card: card)
        }
        .alert("Save to Card", isPresented: $showSaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                Task { await saveToCard() }
            }
        } message: {
            Text("Write the updated balance to the physical NFC card?")
        }
        .alert("Error", isPresented: .constant(saveError != nil)) {
            Button("OK") { saveError = nil }
        } message: {
            if let error = saveError {
                Text(error)
            }
        }
        .alert("Delete Card", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("This will permanently delete this card and all its transactions. This cannot be undone.")
        }
        .overlay {
            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("Saving to card...")
                    .padding(24)
                    .background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
        }
    }

    private func saveToCard() async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await NFCService.shared.writeBalance(to: card)
        } catch let error as NFCError {
            saveError = error.localizedDescription
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func deleteCard() {
        modelContext.delete(card)
        try? modelContext.save()
        dismiss()
    }
}