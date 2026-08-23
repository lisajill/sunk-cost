import SwiftUI
import SunkCostCore

/// Sticky totals bar under the item list -- reflects whatever's currently
/// filtered/searched, not the grand total already shown in the header.
struct ItemListFooterView: View {
    @Environment(AppStore.self) private var store

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private var visibleItems: [Item] { store.filteredItems }

    private var visibleTotal: Decimal {
        visibleItems.compactMap(\.cost).reduce(0, +)
    }

    private var formattedTotal: String {
        let text = Self.currencyFormatter.string(from: visibleTotal as NSDecimalNumber) ?? "$0"
        return store.isPrivacyModeEnabled ? Theme.mask(text) : text
    }

    var body: some View {
        HStack {
            HStack(spacing: 3) {
                Text("\(visibleItems.count) ITEM\(visibleItems.count == 1 ? "" : "S")")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSecondary)
                Image(systemName: "info.circle")
                    .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Text(formattedTotal)
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Theme.ledgerPaper)
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.ledgerBorder).frame(height: 1)
        }
        .help("Total cost of the \(visibleItems.count) item\(visibleItems.count == 1 ? "" : "s") currently shown — reflects any active category/status/type filters or search, not the full list.")
    }
}
