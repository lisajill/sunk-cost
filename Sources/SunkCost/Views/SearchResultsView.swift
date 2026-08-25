import SwiftUI
import SunkCostCore

/// Shown on Overview and Sell Scenario in place of their normal content
/// whenever there's active search text -- the search field is always
/// visible (it's in the toolbar regardless of which sidebar section
/// you're on), but neither section has anything of its own to filter, so
/// typing there previously did nothing visible even though the same
/// search text *did* filter Items and Maintenance once you switched to
/// them. This aggregates matches from both into one list, reusing the
/// exact same row views as the real Items/Maintenance pages (not a
/// simplified summary row) so a match looks and behaves identically to
/// finding it by browsing there directly -- a tap does the same thing
/// either way, it just also jumps you to that section first.
struct SearchResultsView: View {
    @Environment(AppStore.self) private var store
    let onSelectItem: (Item) -> Void
    let onSelectMaintenanceCategory: (MaintenanceCategory) -> Void

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
                            ItemRowView(
                                item: item,
                                isStatusFilterActive: store.filter.status == item.status,
                                onTapName: { onSelectItem(item) },
                                onTapStatus: { store.toggleStatusFilter(item.status) }
                            )
                        }
                    }
                }
                if !matchedCategories.isEmpty {
                    Section("Maintenance") {
                        ForEach(matchedCategories) { category in
                            MaintenanceCategoryRowView(category: category) {
                                onSelectMaintenanceCategory(category)
                            }
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }
}
