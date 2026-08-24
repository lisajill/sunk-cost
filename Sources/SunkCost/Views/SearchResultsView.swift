import SwiftUI
import SunkCostCore

/// Shown on Overview in place of the dashboard whenever there's active
/// search text -- the search field is always visible (it's in the
/// toolbar regardless of which sidebar section you're on), but Overview
/// itself has nothing to filter, so typing there previously did nothing
/// visible even though the same search text *did* filter Items and
/// Maintenance once you switched to them. This aggregates matches from
/// both into one list, with a tap on any result jumping straight to it.
struct SearchResultsView: View {
    @Environment(AppStore.self) private var store
    let onSelectItem: (Item) -> Void
    let onSelectMaintenanceCategory: (MaintenanceCategory) -> Void

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatted(_ value: Decimal) -> String {
        let text = Self.currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
        return store.isPrivacyModeEnabled ? Theme.mask(text) : text
    }

    private var matchedItems: [Item] { store.filteredItems }
    private var matchedCategories: [MaintenanceCategory] { store.searchMatchedMaintenanceCategories }

    var body: some View {
        if matchedItems.isEmpty && matchedCategories.isEmpty {
            ContentUnavailableView.search(text: store.filter.searchText ?? "")
        } else {
            List {
                if !matchedItems.isEmpty {
                    Section("Items") {
                        ForEach(matchedItems) { item in
                            Button {
                                onSelectItem(item)
                            } label: {
                                itemRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if !matchedCategories.isEmpty {
                    Section("Maintenance") {
                        ForEach(matchedCategories) { category in
                            Button {
                                onSelectMaintenanceCategory(category)
                            } label: {
                                categoryRow(category)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func itemRow(_ item: Item) -> some View {
        HStack(spacing: 10) {
            Image(systemName: CategoryIcon.symbol(for: item.category))
                .foregroundStyle(Theme.positive)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                    .foregroundStyle(Theme.ink)
                Text(item.category)
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Spacer()
            Text(item.cost.map(formatted) ?? "—")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.vertical, 3)
    }

    private func categoryRow(_ category: MaintenanceCategory) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .foregroundStyle(Theme.gold)
                .frame(width: 20)
            Text(category.name)
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(formatted(category.monthlyAmount))/mo")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.vertical, 3)
    }
}
