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
    @State private var isShowingAddForm = false
    @State private var editingItem: Item?
    @State private var selectedSection: MainSection? = .overview
    @State private var didCopySummary = false

    var body: some View {
        NavigationSplitView {
            List(MainSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 240)
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

                switch selectedSection ?? .overview {
                case .overview:
                    OverviewView()
                case .items:
                    itemsSection
                case .maintenance:
                    MaintenanceView()
                        .id(store.appearanceMode)
                case .sellScenario:
                    SellScenarioView()
                        .id(store.appearanceMode)
                }
            }
            .frame(minWidth: 480, minHeight: 480)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
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

                    Button {
                        store.cycleAppearanceMode()
                    } label: {
                        Image(systemName: store.appearanceMode.symbolName)
                    }
                    .help("Appearance: \(store.appearanceMode.label) (click to change)")
                    .accessibilityLabel("Appearance: \(store.appearanceMode.label). Click to change.")

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

    private var searchPrompt: String {
        switch selectedSection ?? .overview {
        case .overview: return "Search"
        case .items: return "Search name, category, or notes"
        case .maintenance: return "Search categories or notes"
        case .sellScenario: return "Search"
        }
    }
}
