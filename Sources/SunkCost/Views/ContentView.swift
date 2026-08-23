import SwiftUI
import SunkCostCore

private enum MainTab: String, CaseIterable {
    case items = "Items"
    case maintenance = "Maintenance"
    case sellScenario = "Sell Scenario"
}

struct ContentView: View {
    @Environment(AppStore.self) private var store
    @State private var isShowingAddForm = false
    @State private var editingItem: Item?
    @State private var selectedTab: MainTab = .items
    @State private var didCopySummary = false

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

            // Custom colors built from NSColor(name:dynamicProvider:) --
            // Theme.ink, .positive, etc. -- can go stale mid-toggle when
            // .preferredColorScheme flips live, the same class of bug as
            // the dropdown Pickers below. Forcing these three to fully
            // rebuild on appearance change fixes both. Scoped to these
            // subviews rather than all of ContentView specifically so
            // toggling appearance can't reset the sheet-presentation state
            // (isShowingAddForm/editingItem) and dismiss an open Add/Edit
            // sheet out from under whoever's mid-edit.
            SummaryHeaderView()
                .id(store.appearanceMode)

            Picker("", selection: $selectedTab) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360)
            .padding(.horizontal)
            .padding(.top, 8)

            switch selectedTab {
            case .items:
                FilterBarView()
                    .padding(.horizontal)
                    .padding(.top, 8)

                ItemListHeaderView()
                    .id(store.appearanceMode)

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
                .id(store.appearanceMode)

                ItemListFooterView()
                    .id(store.appearanceMode)
            case .maintenance:
                MaintenanceView()
                    .id(store.appearanceMode)
            case .sellScenario:
                SellScenarioView()
                    .id(store.appearanceMode)
            }
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

            if selectedTab == .items {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddForm = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }

            if selectedTab == .sellScenario {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.copyCompareSummaryToClipboard()
                        withAnimation { didCopySummary = true }
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            withAnimation { didCopySummary = false }
                        }
                    } label: {
                        Label(didCopySummary ? "Copied!" : "Copy Summary", systemImage: didCopySummary ? "checkmark" : "doc.on.doc")
                    }
                    .help("Copy all the Sell Scenario and Compare numbers as plain text — for pasting into a chat with Claude, a spreadsheet, or anywhere else.")
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
        .searchable(
            text: Binding(
                get: { store.filter.searchText ?? "" },
                set: { store.filter.searchText = $0.isEmpty ? nil : $0 }
            ),
            placement: .toolbar,
            prompt: searchPrompt
        )
    }

    private var searchPrompt: String {
        switch selectedTab {
        case .items: return "Search name, category, or notes"
        case .maintenance: return "Search categories or notes"
        case .sellScenario: return "Search"
        }
    }
}
