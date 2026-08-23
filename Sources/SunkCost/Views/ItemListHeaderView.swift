import SwiftUI
import SunkCostCore

/// Clickable column headers (Item, Date, Amount) above the item list --
/// replaces a separate Sort dropdown. Clicking a column sorts by it;
/// clicking the active column again flips its direction.
struct ItemListHeaderView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack {
            columnButton(title: "Item", column: .item)
            Spacer(minLength: 8)
            columnButton(title: "Date", column: .date)
                .frame(width: ItemListColumn.date * store.textScale, alignment: .trailing)
            columnButton(title: "Amount", column: .amount)
                .frame(width: ItemListColumn.amount * store.textScale, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }

    // A tightly-sized label (no internal Spacer) so the outer .frame's
    // alignment is what positions it -- an earlier version used an internal
    // Spacer(minLength: 0) to fake trailing alignment, which let long labels
    // (e.g. "AMOUNT") render past their column's bounds with nothing to
    // clip them, and made the button's actual hit-test area drift from
    // what was visibly drawn.
    private func columnButton(title: String, column: SortColumn) -> some View {
        Button {
            store.sortOption = toggledSortOption(current: store.sortOption, tapped: column)
        } label: {
            HStack(spacing: 3) {
                Text(title.uppercased())
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                if let indicator = sortIndicator(for: column) {
                    Image(systemName: indicator)
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .bold, scale: store.textScale))
                }
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
