import SwiftUI

struct BalanceCard: View {
    let card: SavingsCard
    let compact: Bool

    var body: some View {
        VStack(spacing: compact ? 8 : 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BALANCE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(card.formattedBalance)
                        .font(compact ? .title2.weight(.bold) : .system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }

                Spacer()

                Image(systemName: "creditcard.fill")
                    .font(.system(size: compact ? 24 : 36))
                    .foregroundStyle(.blue.gradient)
            }

            if !compact {
                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARD ID")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(card.cardUIDString)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("UPDATED")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        Text(card.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(compact ? 16 : 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 0.5)
        )
    }
}