import SwiftUI
import TheMoneyPitCore

struct ContentView: View {
    @Environment(AppStore.self) private var store
    @State private var isShowingAddForm = false
    @State private var editingItem: Item?

    var body: some View {
        VStack(spacing: 0) {
            if let error = store.loadError {
                Text(error)
                    .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.1))
            }

            SummaryHeaderView()

            FilterBarView()
                .padding(.horizontal)
                .padding(.top, 8)

            List {
                ForEach(store.filteredItems) { item in
                    ItemRowView(
                        item: item,
                        isStatusFilterActive: store.filter.status == item.status,
                        onTapName: { editingItem = item },
                        onTapStatus: { store.toggleStatusFilter(item.status) }
                    )
                }
            }
            .listStyle(.inset)
        }
        .frame(minWidth: 560, minHeight: 480)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    store.decreaseTextSize()
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .help("Decrease Font Size (⌘-)")

                Button {
                    store.increaseTextSize()
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .help("Increase Font Size (⌘+)")

                Button {
                    store.cycleAppearanceMode()
                } label: {
                    Image(systemName: store.appearanceMode.symbolName)
                }
                .help("Appearance: \(store.appearanceMode.label) (click to change)")

                Button {
                    store.togglePrivacyMode()
                } label: {
                    Image(systemName: store.isPrivacyModeEnabled ? "eye.slash" : "eye")
                }
                .help(
                    store.isPrivacyModeEnabled
                        ? "Privacy mode is on — dollar amounts are hidden for screenshots. Click to show them again."
                        : "Hide dollar amounts for a screenshot"
                )
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddForm = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddForm) {
            ItemFormView(item: nil)
        }
        .sheet(item: $editingItem) { item in
            ItemFormView(item: item)
        }
        .tint(Theme.positive)
        .environment(\.appTextScale, store.textScale)
    }
}
