import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: transaction.type.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(transactionColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(transaction.note ?? transaction.type.displayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    if let note = transaction.note, note != transaction.type.displayName {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(transaction.type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.formattedAmount)
                .font(.headline.monospacedDigit())
                .foregroundStyle(transactionColor)
        }
        .padding(.vertical, 4)
    }

    private var transactionColor: Color {
        switch transaction.type {
        case .deposit: return .green
        case .withdrawal: return .red
        }
    }
}