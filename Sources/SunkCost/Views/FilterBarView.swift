import SwiftUI
import SunkCostCore

struct FilterBarView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("Category", selection: Binding(
                    get: { store.filter.category ?? "" },
                    set: { store.filter.category = $0.isEmpty ? nil : $0 }
                )) {
                    Text("All Categories").tag("")
                    ForEach(store.availableCategories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .frame(maxWidth: 220)
                .help("Show only items in one category")

                Picker("Status", selection: Binding(
                    get: { store.filter.status },
                    set: { store.filter.status = $0 }
                )) {
                    Text("All Statuses").tag(Status?.none)
                    ForEach(Status.allCases, id: \.self) { status in
                        Text(status.rawValue.capitalized).tag(Status?.some(status))
                    }
                }
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .frame(maxWidth: 200)
                .help("Show only items with one status — tapping a status pill on a row does this too")

                Picker("Type", selection: Binding(
                    get: { store.filter.type },
                    set: { store.filter.type = $0 }
                )) {
                    Text("All Types").tag(ItemType?.none)
                    ForEach(ItemType.allCases, id: \.self) { type in
                        Text(type.label).tag(ItemType?.some(type))
                    }
                }
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .frame(maxWidth: 180)
                .help("Show only Value or only Moveable items")

                Spacer()
            }
            // NSPopUpButton-backed Pickers can be slow to pick up the new
            // effective appearance right when .preferredColorScheme flips,
            // leaving stale (near-invisible) text/background color until
            // something else forces a redraw. Rebuilding them fresh on
            // every appearance change sidesteps that instead of patching
            // it in place.
            .id(store.appearanceMode)

            if !store.availableHashtags.isEmpty {
                hashtagRow
            }
        }
    }

    private var hashtagRow: some View {
        FlowLayout(spacing: 6) {
            ForEach(store.availableHashtags, id: \.self) { hashtag in
                let isActive = store.filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == hashtag
                Button(hashtag) {
                    store.toggleHashtagFilter(hashtag)
                }
                .font(Theme.scaledFont(Theme.FontSize.caption, weight: isActive ? .semibold : .regular, scale: store.textScale))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(isActive ? Theme.terracotta : nil)
                .help("Filter to items tagged \(hashtag)")
            }
        }
    }
}
