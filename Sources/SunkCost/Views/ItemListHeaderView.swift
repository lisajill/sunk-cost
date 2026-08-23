import SwiftUI
import SunkCostCore

/// Sort control above the item list -- rows are now cards rather than a
/// column-aligned table, so this is a row of chips (matching the
/// hashtag-filter and saved-scenario chip style elsewhere) instead of
/// clickable column labels that had to stay pixel-aligned with each row.
struct ItemListHeaderView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 8) {
            Text("SORT BY")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            sortChip(title: "Item", column: .item)
            sortChip(title: "Date", column: .date)
            sortChip(title: "Amount", column: .amount)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private func sortChip(title: String, column: SortColumn) -> some View {
        Button {
            store.sortOption = toggledSortOption(current: store.sortOption, tapped: column)
        } label: {
            HStack(spacing: 3) {
                Text(title)
                if let indicator = sortIndicator(for: column) {
                    Image(systemName: indicator)
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .bold, scale: store.textScale))
                }
            }
        }
        .font(Theme.scaledFont(Theme.FontSize.caption, weight: isActive(column) ? .bold : .regular, scale: store.textScale))
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(isActive(column) ? Theme.positive : nil)
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
