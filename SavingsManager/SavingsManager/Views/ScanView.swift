import SwiftUI
import SwiftData

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var nfcService = NFCService.shared
    @State private var showCardDetail = false
    @State private var scannedCard: SavingsCard?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(.blue.gradient)
                        .symbolEffect(.pulse, options: .repeating, value: nfcService.isScanning)

                    VStack(spacing: 12) {
                        Text("Tap your savings card")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("Hold your NFC card near the top of your iPhone to read or write the balance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    NFCScanButton(isScanning: nfcService.isScanning) {
                        Task {
                            await scanCard()
                        }
                    }
                    .disabled(nfcService.isScanning)

                    Spacer()

                    if let card = nfcService.lastScannedCard {
                        VStack(spacing: 8) {
                            Text("Last scanned card")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            BalanceCard(card: card, compact: true)
                                .onTapGesture {
                                    scannedCard = card
                                    showCardDetail = true
                                }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Scan Card")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCardDetail) {
                if let card = scannedCard {
                    NavigationStack {
                        CardDetailView(card: card)
                    }
                    .presentationDetents([.large])
                }
            }
        }
    }

    private func scanCard() async {
        do {
            let card = try await nfcService.scanForCard()
            scannedCard = card
            showCardDetail = true
        } catch let error as NFCError {
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}