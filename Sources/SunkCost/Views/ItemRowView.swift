import SwiftUI
import SunkCostCore

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

    private var dateText: String? {
        item.dateAdded.map { Self.dateFormatter.string(from: $0) }
    }

    var body: some View {
        HStack {
            Button(action: onTapName) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(item.name)
                            .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                            .foregroundStyle(Theme.ink)
                        Image(systemName: item.type == .value ? "house.fill" : "shippingbox.fill")
                            .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                            .foregroundStyle(Theme.inkSecondary)
                            .help(item.type == .value ? "Value -- stays with the house" : "Moveable -- goes with you")
                        if let notes = item.notes, !notes.isEmpty {
                            Image(systemName: "note.text")
                                .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                                .foregroundStyle(Theme.inkSecondary)
                                .help(notes)
                        }
                    }
                    Text(dateText.map { "\(item.category.uppercased()) · \($0)" } ?? item.category.uppercased())
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .medium, scale: store.textScale))
                        .tracking(0.5)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(costText)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSecondary)

            Button(action: onTapStatus) {
                Text(statusLabel)
                    .font(Theme.scaledFont(Theme.FontSize.caption, weight: .semibold, scale: store.textScale))
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
        case .owned: return Theme.positive
        case .gone: return Theme.taupe
        case .planned: return Theme.terracotta
        }
    }
}
