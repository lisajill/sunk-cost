import Foundation
import Observation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SunkCostCore

@Observable
@MainActor
final class AppStore {
    var items: [Item] = []
    var homeValue: Decimal?
    var purchasePrice: Decimal?
    var mortgageOriginalAmount: Decimal?
    var mortgageInterestRatePercent: Decimal?
    var mortgageStartDate: Date?
    var mortgageBalance: Decimal?
    var mortgageTermYears: Int?
    var monthlyPaymentOverride: Decimal?
    var maintenanceCategories: [MaintenanceCategory] = []
    var filter = ItemFilter()
    var sortOption: SortOption {
        didSet { UserDefaults.standard.set(sortOption.rawValue, forKey: AppStore.sortOptionKey) }
    }
    private static let sortOptionKey = "SunkCost.SortOption"
    private(set) var storageFolderURL: URL
    var loadError: String?

    var textSizeIndex: Int {
        didSet { UserDefaults.standard.set(textSizeIndex, forKey: TextSizeControl.userDefaultsKey) }
    }
    var textScale: CGFloat { TextSizeControl.scales[textSizeIndex] }

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: AppearanceMode.userDefaultsKey) }
    }

    /// Masks dollar figures for sharing a screenshot. Deliberately not
    /// persisted -- always starts back off on launch, so it can't leave
    /// values hidden and forgotten.
    var isPrivacyModeEnabled = false
    func togglePrivacyMode() { isPrivacyModeEnabled.toggle() }

    private var stopAccessingCurrentFolder: (() -> Void)?

    var totals: Totals { Totals(items: items) }
    /// Value-type spending only -- what should actually be compared against
    /// Home Value, since Moveable items don't raise it.
    var valueSpent: Totals { Totals(items: items.filter { $0.type == .value }) }
    /// Total recurring monthly cost across every Maintenance category --
    /// the "cost to keep the house running," a peer total to Total Spent,
    /// not folded into it. A monthly figure, not all-time.
    var costToKeep: Decimal { maintenanceCategories.reduce(0) { $0 + $1.monthlyAmount } }
    var filteredItems: [Item] { items.filtered(by: filter).sorted(using: sortOption) }
    var availableCategories: [String] { items.distinctCategories }
    var availableHashtags: [String] { items.distinctHashtags }
    var categoriesWithCounts: [(category: String, count: Int)] {
        availableCategories.map { category in
            (category, items.filter { $0.category == category }.count)
        }
    }
    var equity: Decimal? { computeEquity(homeValue: homeValue, mortgageBalance: mortgageBalance) }
    /// Home Value minus everything actually invested in the house as an
    /// asset -- what was paid for it, plus Value-type item spending (things
    /// that stay with the house). The true gain/loss on the house itself,
    /// separate from Moveable spending or day-to-day Maintenance.
    var netHouseGain: Decimal? {
        guard let homeValue, let purchasePrice else { return nil }
        return homeValue - (purchasePrice + valueSpent.totalSpent)
    }

    /// The manually-entered payment if there is one; otherwise a calculated
    /// estimate from amount/rate/term, if all three are present.
    var monthlyPayment: Decimal? {
        if let monthlyPaymentOverride { return monthlyPaymentOverride }
        guard let mortgageOriginalAmount, let mortgageInterestRatePercent, let mortgageTermYears else {
            return nil
        }
        return MortgageMath.monthlyPayment(
            principal: mortgageOriginalAmount,
            annualRatePercent: mortgageInterestRatePercent,
            termYears: mortgageTermYears
        )
    }
    var isMonthlyPaymentCalculated: Bool { monthlyPaymentOverride == nil && monthlyPayment != nil }

    init() {
        let (folder, stopAccessing) = StorageLocation.resolveCurrentFolder()
        self.storageFolderURL = folder
        self.stopAccessingCurrentFolder = stopAccessing
        self.textSizeIndex = UserDefaults.standard.object(forKey: TextSizeControl.userDefaultsKey) as? Int
            ?? TextSizeControl.defaultIndex
        self.appearanceMode = UserDefaults.standard.string(forKey: AppearanceMode.userDefaultsKey)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .system
        self.sortOption = UserDefaults.standard.string(forKey: AppStore.sortOptionKey)
            .flatMap(SortOption.init(rawValue:)) ?? .dateNewest
        load()
    }

    func cycleAppearanceMode() {
        appearanceMode = appearanceMode.next()
    }

    func increaseTextSize() {
        textSizeIndex = min(textSizeIndex + 1, TextSizeControl.scales.count - 1)
    }

    func decreaseTextSize() {
        textSizeIndex = max(textSizeIndex - 1, 0)
    }

    func resetTextSize() {
        textSizeIndex = TextSizeControl.defaultIndex
    }

    private var fileURL: URL {
        StorageLocation.itemsFileURL(in: storageFolderURL)
    }

    func load() {
        do {
            let data = try ItemStore.load(from: fileURL)
            items = data.items
            homeValue = data.homeValue
            purchasePrice = data.purchasePrice
            mortgageOriginalAmount = data.mortgageOriginalAmount
            mortgageInterestRatePercent = data.mortgageInterestRatePercent
            mortgageStartDate = data.mortgageStartDate
            mortgageBalance = data.mortgageBalance
            mortgageTermYears = data.mortgageTermYears
            monthlyPaymentOverride = data.monthlyPaymentOverride
            maintenanceCategories = data.maintenanceCategories
            loadError = nil
        } catch {
            loadError = "Couldn't read the data file at \(fileURL.path) — starting with an empty list so nothing gets overwritten. (\(error.localizedDescription))"
            items = []
            homeValue = nil
        }
    }

    private func save() {
        do {
            try ItemStore.save(currentAppData(), to: fileURL)
            loadError = nil
        } catch {
            loadError = "Couldn't save your changes: \(error.localizedDescription)"
        }
    }

    func addItem(_ item: Item) {
        items.append(item)
        save()
    }

    func updateItem(_ item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
    }

    func deleteItem(_ item: Item) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func cycleStatus(for item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].status = items[index].status.next()
        save()
    }

    func toggleStatusFilter(_ status: Status) {
        filter.status = toggledStatusFilter(current: filter.status, tapped: status)
    }

    /// Tapping a hashtag filters the list to items whose notes mention it;
    /// tapping the same one again clears the search.
    func toggleHashtagFilter(_ hashtag: String) {
        let trimmedCurrent = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filter.searchText = (trimmedCurrent == hashtag) ? nil : hashtag
    }

    /// Renames a category across every item that uses it. Renaming into an
    /// already-existing category merges the two -- this is also how you
    /// "remove" a category: rename it into one you want to keep.
    func renameCategory(from oldName: String, to newName: String) {
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty, trimmedNewName != oldName else { return }
        items = items.renamingCategory(from: oldName, to: trimmedNewName)
        if filter.category == oldName {
            filter.category = trimmedNewName
        }
        save()
    }

    func setHomeValue(_ value: Decimal?) {
        homeValue = value
        save()
    }

    func setPurchasePrice(_ value: Decimal?) {
        purchasePrice = value
        save()
    }

    func setMortgage(
        originalAmount: Decimal?,
        interestRatePercent: Decimal?,
        startDate: Date?,
        balance: Decimal?,
        termYears: Int?,
        monthlyPaymentOverride: Decimal?
    ) {
        mortgageOriginalAmount = originalAmount
        mortgageInterestRatePercent = interestRatePercent
        mortgageStartDate = startDate
        mortgageBalance = balance
        mortgageTermYears = termYears
        self.monthlyPaymentOverride = monthlyPaymentOverride
        save()
    }

    func chooseNewStorageFolder() {
        guard StorageLocation.chooseNewFolder() != nil else { return }
        stopAccessingCurrentFolder?()
        let (folder, stopAccessing) = StorageLocation.resolveCurrentFolder()
        storageFolderURL = folder
        stopAccessingCurrentFolder = stopAccessing
        save()
    }

    func resetToDefaultStorageFolder() {
        stopAccessingCurrentFolder?()
        StorageLocation.resetToDefault()
        let (folder, stopAccessing) = StorageLocation.resolveCurrentFolder()
        storageFolderURL = folder
        stopAccessingCurrentFolder = stopAccessing
        save()
    }

    /// Saves a standalone copy of the current data to a file the user picks
    /// -- for backups, or to hand data to another Mac.
    func exportData() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Sunk Cost Export.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try ItemStore.save(currentAppData(), to: url)
        } catch {
            loadError = "Couldn't export: \(error.localizedDescription)"
        }
    }

    /// Opens a file picker and reads the chosen file without applying it yet
    /// -- the caller should confirm with the user (importing replaces
    /// everything currently loaded) before calling `applyImportedData`.
    func pickFileToImport() -> (url: URL, data: AppData)? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            return (url, try ItemStore.load(from: url))
        } catch {
            loadError = "Couldn't read that file: \(error.localizedDescription)"
            return nil
        }
    }

    func applyImportedData(_ data: AppData) {
        items = data.items
        homeValue = data.homeValue
        purchasePrice = data.purchasePrice
        mortgageOriginalAmount = data.mortgageOriginalAmount
        mortgageInterestRatePercent = data.mortgageInterestRatePercent
        mortgageStartDate = data.mortgageStartDate
        mortgageBalance = data.mortgageBalance
        mortgageTermYears = data.mortgageTermYears
        monthlyPaymentOverride = data.monthlyPaymentOverride
        maintenanceCategories = data.maintenanceCategories
        save()
    }

    private func currentAppData() -> AppData {
        AppData(
            items: items,
            homeValue: homeValue,
            purchasePrice: purchasePrice,
            mortgageOriginalAmount: mortgageOriginalAmount,
            mortgageInterestRatePercent: mortgageInterestRatePercent,
            mortgageStartDate: mortgageStartDate,
            mortgageBalance: mortgageBalance,
            mortgageTermYears: mortgageTermYears,
            monthlyPaymentOverride: monthlyPaymentOverride,
            maintenanceCategories: maintenanceCategories
        )
    }

    /// Saves items as CSV -- the practical way to interoperate with Excel,
    /// Numbers, and Google Sheets, all of which open/save CSV natively.
    func exportCSV() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Sunk Cost Export.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try CSVCodec.encode(items).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            loadError = "Couldn't export CSV: \(error.localizedDescription)"
        }
    }

    /// Opens a file picker and parses the chosen CSV without applying it yet
    /// -- the caller should confirm with the user (importing replaces every
    /// item currently loaded; home value/mortgage info are untouched, since
    /// CSV only carries items) before calling `applyImportedCSVItems`.
    func pickCSVFileToImport() -> (url: URL, items: [Item])? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            let csvText = try String(contentsOf: url, encoding: .utf8)
            return (url, try CSVCodec.decode(csvText))
        } catch {
            loadError = "Couldn't read that CSV: \(error.localizedDescription)"
            return nil
        }
    }

    func applyImportedCSVItems(_ importedItems: [Item]) {
        items = importedItems
        save()
    }

    func addMaintenanceCategory(name: String, monthlyAmount: Decimal, notes: String? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        maintenanceCategories.append(MaintenanceCategory(name: trimmedName, monthlyAmount: monthlyAmount, notes: notes))
        save()
    }

    func updateMaintenanceCategory(_ category: MaintenanceCategory) {
        guard let index = maintenanceCategories.firstIndex(where: { $0.id == category.id }) else { return }
        maintenanceCategories[index] = category
        save()
    }

    func deleteMaintenanceCategory(_ category: MaintenanceCategory) {
        maintenanceCategories.removeAll { $0.id == category.id }
        save()
    }
}
