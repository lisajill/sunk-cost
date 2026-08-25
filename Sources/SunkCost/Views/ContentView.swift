import SwiftUI
import SunkCostCore

private enum MainSection: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case items = "Items"
    case maintenance = "Maintenance"
    case sellScenario = "Sell Scenario"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "house.fill"
        case .items: return "shippingbox.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .sellScenario: return "dollarsign.circle.fill"
        }
    }
}

struct ContentView: View {
    @Environment(AppStore.self) private var store
    // The actual, currently-rendered appearance -- reflects System mode's
    // resolved light/dark, not just store.appearanceMode's raw setting.
    // The toolbar toggle needs this to know what "the opposite" even means
    // when the mode is System rather than an explicit Light/Dark.
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingAddForm = false
    @State private var editingItem: Item?
    @State private var selectedSection: MainSection = .overview
    @State private var didCopySummary = false

    var body: some View {
        NavigationSplitView {
            // A plain VStack of buttons that directly set `selectedSection`,
            // not List(selection:) -- that relies on List's native
            // selection-binding machinery, which silently failed to
            // register clicks here (every section stayed on Overview no
            // matter what was clicked). A Button's action closure setting
            // @State directly has no equivalent failure mode.
            VStack(alignment: .leading, spacing: 2) {
                ForEach(MainSection.allCases) { section in
                    sidebarRow(section)
                }
                Spacer()
            }
            .padding(8)
            .frame(minWidth: 170, idealWidth: 190, maxWidth: 240, maxHeight: .infinity, alignment: .top)
        } detail: {
            VStack(spacing: 0) {
                if let error = store.loadError {
                    Text(error)
                        .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                        .foregroundStyle(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                }

                switch selectedSection {
                case .overview:
                    searchAwareContent { OverviewView() }
                case .items:
                    itemsSection
                case .maintenance:
                    MaintenanceView()
                        .id(store.appearanceMode)
                case .sellScenario:
                    searchAwareContent { SellScenarioView() }
                        .id(store.appearanceMode)
                }
            }
            .frame(minWidth: 480, minHeight: 480)
            .toolbar {
                // .primaryAction, not .automatic -- NavigationSplitView adds
                // its own sidebar-toggle button to the toolbar, and with a
                // sidebar present .automatic-grouped items are more likely
                // to get swept into the overflow "..." menu when the window
                // narrows. .primaryAction keeps these pinned as visible
                // trailing buttons instead.
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        store.decreaseTextSize()
                    } label: {
                        Image(systemName: "textformat.size.smaller")
                    }
                    .help("Decrease Font Size (⌘-)")
                    .accessibilityLabel("Decrease Font Size")

                    Button {
                        store.increaseTextSize()
                    } label: {
                        Image(systemName: "textformat.size.larger")
                    }
                    .help("Increase Font Size (⌘+)")
                    .accessibilityLabel("Increase Font Size")

                    // Binary toggle, not a 3-way cycle through System too --
                    // System is a different kind of choice ("follow the
                    // Mac" vs. an explicit pick), so it lives in Settings
                    // instead. Clicking here always sets an explicit
                    // opposite of whatever's currently showing -- including
                    // escaping System mode with an explicit choice, if
                    // that's what's active.
                    Button {
                        store.appearanceMode = colorScheme == .dark ? .light : .dark
                    } label: {
                        Image(systemName: colorScheme == .dark ? "moon.fill" : "sun.max.fill")
                    }
                    .help("Switch to \(colorScheme == .dark ? "Light" : "Dark") Mode (choose System in Settings to follow your Mac instead)")
                    .accessibilityLabel("Switch to \(colorScheme == .dark ? "Light" : "Dark") Mode")

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
                    .accessibilityLabel(
                        store.isPrivacyModeEnabled
                            ? "Privacy mode is on. Click to show dollar amounts again."
                            : "Hide dollar amounts for a screenshot"
                    )
                }

                if selectedSection == .items {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isShowingAddForm = true
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }

                if selectedSection == .sellScenario {
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
            .searchable(
                text: Binding(
                    get: { store.filter.searchText ?? "" },
                    set: { store.filter.searchText = $0.isEmpty ? nil : $0 }
                ),
                placement: .toolbar,
                prompt: searchPrompt
            )
        }
        .sheet(isPresented: Binding(
            get: { !store.hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented { store.hasCompletedOnboarding = true }
            }
        )) {
            WelcomeView()
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

    private var itemsSection: some View {
        VStack(spacing: 0) {
            FilterBarView()
                .padding(.horizontal)
                .padding(.top, 8)

            ItemListHeaderView()
                .id(store.appearanceMode)

            if store.filteredItems.isEmpty {
                ContentUnavailableView(
                    store.items.isEmpty ? "No Items Yet" : "No Matching Items",
                    systemImage: store.items.isEmpty ? "tray" : "magnifyingglass",
                    description: Text(
                        store.items.isEmpty
                            ? "Add your first item to start tracking what the house costs."
                            : "Try a different search or filter."
                    )
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(store.appearanceMode)
            } else {
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
            }

            ItemListFooterView()
                .id(store.appearanceMode)
        }
    }

    private func sidebarRow(_ section: MainSection) -> some View {
        let isSelected = selectedSection == section
        return Button {
            selectedSection = section
        } label: {
            Label(section.rawValue, systemImage: section.icon)
                .font(Theme.scaledFont(Theme.FontSize.body, weight: isSelected ? .semibold : .regular, scale: store.textScale))
                .foregroundStyle(isSelected ? Theme.positive : Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(isSelected ? Theme.positive.opacity(0.14) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var searchPrompt: String {
        switch selectedSection {
        case .overview: return "Search items and maintenance"
        case .items: return "Search name, category, or notes"
        case .maintenance: return "Search categories or notes"
        case .sellScenario: return "Search items and maintenance"
        }
    }

    /// Overview and Sell Scenario have nothing of their own to search --
    /// while there's active search text, show matches from Items and
    /// Maintenance instead of the section's normal content, since the
    /// search field is visible (and typing into it felt "dead") no matter
    /// which section you're on. Originally only wired up for Overview;
    /// Sell Scenario had the same dead-search-field problem until this was
    /// extracted so both sections share it.
    @ViewBuilder
    private func searchAwareContent<Default: View>(@ViewBuilder default defaultView: () -> Default) -> some View {
        if let searchText = store.filter.searchText, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            SearchResultsView(
                onSelectItem: { item in
                    selectedSection = .items
                    editingItem = item
                },
                onSelectMaintenanceCategory: { _ in
                    selectedSection = .maintenance
                }
            )
        } else {
            defaultView()
        }
    }
}
