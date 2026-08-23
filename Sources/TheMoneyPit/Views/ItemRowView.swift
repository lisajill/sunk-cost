import SwiftUI
import TheMoneyPitCore

struct ItemRowView: View {
    @Environment(AppStore.self) private var store

    let item: Item
    let isStatusFilterActive: Bool
    let onTapName: () -> Void
    let onTapStatus: () -> Void

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-d-yyyy"
        return formatter
    }()

    private var costText: String {
        guard let cost = item.cost else { return "—" }
        let text = Self.currencyFormatter.string(from: cost as NSDecimalNumber) ?? "—"
        return store.isPrivacyModeEnabled ? Theme.mask(text) : text
    }

    private var dateText: String {
        Self.dateFormatter.string(from: item.dateAdded)
    }

    var body: some View {
        HStack {
            Button(action: onTapName) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.ink)
                    Text("\(item.category.uppercased()) · \(dateText)")
                        .font(.caption2.weight(.medium))
                        .tracking(0.5)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(costText)
                .font(.body.monospacedDigit())
                .foregroundStyle(Theme.inkSecondary)

            Button(action: onTapStatus) {
                Text(statusLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(isStatusFilterActive ? 0.35 : 0.18))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(statusColor, lineWidth: isStatusFilterActive ? 1.5 : 0)
                    )
            }
            .buttonStyle(.plain)
            .help("Filter the list to \(statusLabel) items")
        }
        .padding(.vertical, 4)
    }

    private var statusLabel: String {
        switch item.status {
        case .owned: return "Owned"
        case .gone: return "Gone"
        case .planned: return "Planned"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .owned: return Theme.ledgerGreen
        case .gone: return Theme.taupe
        case .planned: return Theme.terracotta
        }
    }
}
