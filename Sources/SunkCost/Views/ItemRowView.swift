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
        HStack(spacing: 14) {
            Image(systemName: CategoryIcon.symbol(for: item.category))
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(statusColor)
                .frame(width: 36 * store.textScale, height: 36 * store.textScale)
                .background(statusColor.opacity(0.15))
                .clipShape(Circle())

            Button(action: onTapName) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(item.name)
                            .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
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
                    Text(item.category.uppercased())
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .medium, scale: store.textScale))
                        .tracking(0.5)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(costText)
                    .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Text(dateText ?? "—")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

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
            .help(statusTooltip)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Theme.ledgerPaper.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.vertical, 4)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    private var statusTooltip: String {
        guard item.status == .gone, let disposition = item.disposition else {
            return "Filter the list to \(statusLabel) items"
        }
        var text = disposition.label
        if disposition == .sold, let amountRecovered = item.amountRecovered {
            let formatted = Self.currencyFormatter.string(from: amountRecovered as NSDecimalNumber) ?? "$0"
            text += " for \(formatted)"
        }
        return "\(text) — click to filter the list to Gone items"
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
