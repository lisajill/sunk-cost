import SwiftUI
import SunkCostCore

/// Clickable column headers (Item, Date, Amount) above the item list --
/// replaces a separate Sort dropdown. Clicking a column sorts by it;
/// clicking the active column again flips its direction.
struct ItemListHeaderView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack {
            columnButton(title: "Item", column: .item, alignment: .leading)
            Spacer(minLength: 8)
            columnButton(title: "Date", column: .date, alignment: .trailing)
                .frame(width: ItemListColumn.date * store.textScale, alignment: .trailing)
            columnButton(title: "Amount", column: .amount, alignment: .trailing)
                .frame(width: ItemListColumn.amount * store.textScale, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    private func columnButton(title: String, column: SortColumn, alignment: Alignment) -> some View {
        Button {
            store.sortOption = toggledSortOption(current: store.sortOption, tapped: column)
        } label: {
            HStack(spacing: 3) {
                if alignment == .trailing { Spacer(minLength: 0) }
                Text(title.uppercased())
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                if let indicator = sortIndicator(for: column) {
                    Image(systemName: indicator)
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .bold, scale: store.textScale))
                }
                if alignment == .leading { Spacer(minLength: 0) }
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isActive(column) ? Theme.ink : Theme.inkSecondary)
        .help("Sort by \(title)")
    }

    private func isActive(_ column: SortColumn) -> Bool {
        switch column {
        case .date: return store.sortOption == .dateNewest || store.sortOption == .dateOldest
        case .item: return store.sortOption == .nameAZ || store.sortOption == .nameZA
        case .amount: return store.sortOption == .costHighLow || store.sortOption == .costLowHigh
        }
    }

    private func sortIndicator(for column: SortColumn) -> String? {
        guard isActive(column) else { return nil }
        switch store.sortOption {
        case .dateNewest, .nameZA, .costHighLow: return "chevron.down"
        case .dateOldest, .nameAZ, .costLowHigh: return "chevron.up"
        }
    }
}
