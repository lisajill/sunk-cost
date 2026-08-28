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
    var realtorCommissionPercent: Decimal?
    var closingCostsPercent: Decimal?
    var comparisonProjectionYears: Int?
    var homeAppreciationPercent: Decimal?
    var investmentReturnPercent: Decimal?
    var monthlyRent: Decimal?
    var rentAnnualIncreasePercent: Decimal?
    var securityDeposit: Decimal?
    var petDeposit: Decimal?
    var petRentMonthly: Decimal?
    var newHomePrice: Decimal?
    var newHomeDownPayment: Decimal?
    var newMortgageRatePercent: Decimal?
    var newMortgageTermYears: Int?
    var propertyTaxAnnual: Decimal?
    var homeownersInsuranceAnnual: Decimal?
    var newPropertyTaxAnnual: Decimal?
    var newHomeownersInsuranceAnnual: Decimal?
    var hoaMonthly: Decimal?
    var newHoaMonthly: Decimal?
    var savedComparisonScenarios: [ComparisonScenario] = []
    var filter = ItemFilter()
    var sortOption: SortOption {
        didSet { UserDefaults.standard.set(sortOption.rawValue, forKey: AppStore.sortOptionKey) }
    }
    private static let sortOptionKey = "SunkCost.SortOption"

    /// Which mortgage balance the Staying long-term projection amortizes
    /// forward from. A view preference (not in the data file), like
    /// `sortOption`.
    var stayingBalanceBasis: StayingBalanceBasis {
        didSet { UserDefaults.standard.set(stayingBalanceBasis.rawValue, forKey: AppStore.stayingBalanceBasisKey) }
    }
    private static let stayingBalanceBasisKey = "SunkCost.StayingBalanceBasis"
    private(set) var storageFolderURL: URL
    var loadError: String?

    var textSizeIndex: Int {
        didSet { UserDefaults.standard.set(textSizeIndex, forKey: TextSizeControl.userDefaultsKey) }
    }
    var textScale: CGFloat { TextSizeControl.scales[textSizeIndex] }

    var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: AppearanceMode.userDefaultsKey) }
    }

    /// Whether the first-launch Welcome sheet has already been shown.
    /// Independent of the data file (like other view preferences here) so
    /// switching storage folders doesn't bring it back.
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: AppStore.onboardingKey) }
    }
    private static let onboardingKey = "SunkCost.HasCompletedOnboarding"

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
    var costToKeepAnnual: Decimal { costToKeep * 12 }
    /// Sum of monthly costs marked Required -- utilities and the like,
    /// effectively fixed.
    var requiredMonthlyCost: Decimal {
        maintenanceCategories.filter(\.isRequired).reduce(0) { $0 + $1.monthlyAmount }
    }
    /// What cutting every Optional (discretionary) Maintenance category
    /// would save per month.
    var optionalMonthlyCost: Decimal { costToKeep - requiredMonthlyCost }
    var filteredItems: [Item] { items.filtered(by: filter).sorted(using: sortOption) }
    /// Maintenance categories matching the shared search text -- same
    /// name/notes matching MaintenanceView does locally, factored out here
    /// so Overview's cross-tab search results can reuse it without
    /// duplicating the logic. Empty (not "everything") when there's no
    /// search text, since -- unlike `filteredItems` -- this isn't meant to
    /// be a general-purpose "current Maintenance list."
    var searchMatchedMaintenanceCategories: [MaintenanceCategory] {
        let trimmedSearch = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let search = trimmedSearch, !search.isEmpty else { return [] }
        return maintenanceCategories.filter { category in
            category.name.lowercased().contains(search)
                || (category.notes?.lowercased().contains(search) ?? false)
        }
    }
    var availableCategories: [String] { items.distinctCategories }
    var availableHashtags: [String] { items.distinctHashtags }
    var categoriesWithCounts: [(category: String, count: Int)] {
        availableCategories.map { category in
            (category, items.filter { $0.category == category }.count)
        }
    }
    /// Total actually-spent (Owned + Gone, matching `Totals.totalSpent`'s
    /// definition -- Planned items aren't "spent" yet) cost per category,
    /// largest first, for the Overview screen's spend-by-category chart.
    var spendByCategory: [(category: String, total: Decimal)] {
        let spentItems = items.filter { $0.status == .owned || $0.status == .gone }
        let grouped = Dictionary(grouping: spentItems, by: \.category)
        return grouped
            .map { category, items in (category, items.reduce(Decimal(0)) { $0 + ($1.cost ?? 0) }) }
            .filter { $0.total > 0 }
            .sorted { $0.total > $1.total }
    }
    var equity: Decimal? { computeEquity(homeValue: homeValue, mortgageBalance: mortgageBalance) }
    /// Everything actually invested in the house as an asset -- what was
    /// paid for it, plus Value-type item spending (things that stay with
    /// the house). Shared by `netHouseGain` and the Sell Scenario tab so
    /// both use one definition of "what you put in."
    var totalInvested: Decimal? {
        guard let purchasePrice else { return nil }
        return purchasePrice + valueSpent.totalSpent
    }
    /// Home Value minus everything actually invested in the house as an
    /// asset. The true gain/loss on the house itself, separate from
    /// Moveable spending or day-to-day Maintenance.
    var netHouseGain: Decimal? {
        guard let homeValue, let totalInvested else { return nil }
        return homeValue - totalInvested
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
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: AppStore.onboardingKey)
        self.sortOption = UserDefaults.standard.string(forKey: AppStore.sortOptionKey)
            .flatMap(SortOption.init(rawValue:)) ?? .dateNewest
        self.stayingBalanceBasis = UserDefaults.standard.string(forKey: AppStore.stayingBalanceBasisKey)
            .flatMap(StayingBalanceBasis.init(rawValue:)) ?? .recorded
        load()
        // A pre-existing install (real items or a home value already on
        // disk) never saw an onboarding flag get set -- treat that as
        // already onboarded rather than surprising a returning user with
        // the Welcome sheet on their next launch.
        if !hasCompletedOnboarding, !items.isEmpty || homeValue != nil {
            hasCompletedOnboarding = true
        }
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
            apply(try ItemStore.load(from: fileURL))
            loadError = nil
        } catch {
            loadError = "Couldn't read the data file at \(fileURL.path) — starting with an empty list so nothing gets overwritten. (\(error.localizedDescription))"
            resetToEmpty()
        }
    }

    /// Persists the current in-memory state. Returns whether the write
    /// succeeded so callers (`mutate`) can roll back a mutation the disk
    /// didn't accept.
    @discardableResult
    func save() -> Bool {
        // Snapshot the *existing* on-disk file before overwriting it, so
        // the day's backup preserves the state from before today's first
        // edit rather than the state that edit produced. `ItemStore.save`
        // writes atomically, so the file this copies is still the last
        // good one; `BackupManager.snapshot` swallows its own errors, so a
        // backup problem can't block or fail the real save.
        BackupManager.snapshot(dataFileURL: fileURL, storageFolder: storageFolderURL)
        do {
            try ItemStore.save(currentAppData(), to: fileURL)
            loadError = nil
            return true
        } catch {
            loadError = "Couldn't write your data to disk, so your last change wasn't saved. (\(error.localizedDescription))"
            return false
        }
    }

    /// Runs a domain-data mutation and persists it, restoring the previous
    /// in-memory state if the save fails so the UI never shows changes
    /// that aren't on disk. Returns whether the save succeeded.
    /// (`ItemStore.save` is atomic — a failed save leaves the old file
    /// intact, so replaying the pre-mutation snapshot fully reconciles
    /// memory with disk.)
    @discardableResult
    func mutate(_ change: () -> Void) -> Bool {
        let restorePoint = currentAppData()
        change()
        if save() { return true }
        apply(restorePoint)
        return false
    }

    /// Opens Finder to the folder of silent daily backups (Settings ->
    /// "Show Backups Folder…") -- the recovery path for an accidental
    /// delete or a bad edit.
    func revealBackupsFolder() {
        let folder = BackupManager.backupsFolder(in: storageFolderURL)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }

    /// Dates with a kept daily backup, newest first, for a Restore menu.
    func availableBackups() -> [(date: Date, url: URL)] {
        BackupManager.availableBackups(in: storageFolderURL)
    }

    /// Reads a backup file without applying it yet -- same
    /// read-then-confirm shape as `pickFileToImport`.
    func readBackup(at url: URL) -> AppData? {
        do {
            return try ItemStore.load(from: url)
        } catch {
            loadError = "Couldn't read that backup: \(error.localizedDescription)"
            return nil
        }
    }

    func addItem(_ item: Item) {
        mutate { items.append(item) }
    }

    func updateItem(_ item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        mutate { items[index] = item }
    }

    func deleteItem(_ item: Item) {
        mutate { items.removeAll { $0.id == item.id } }
    }

    func cycleStatus(for item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        mutate { items[index].status = items[index].status.next() }
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
        guard mutate({ items = items.renamingCategory(from: oldName, to: trimmedNewName) }) else { return }
        if filter.category == oldName {
            filter.category = trimmedNewName
        }
    }

    func setHomeValue(_ value: Decimal?) {
        mutate { homeValue = value }
    }

    func setPurchasePrice(_ value: Decimal?) {
        mutate { purchasePrice = value }
    }

    func setMortgage(
        originalAmount: Decimal?,
        interestRatePercent: Decimal?,
        startDate: Date?,
        balance: Decimal?,
        termYears: Int?,
        monthlyPaymentOverride: Decimal?
    ) {
        mutate {
            mortgageOriginalAmount = originalAmount
            mortgageInterestRatePercent = interestRatePercent
            mortgageStartDate = startDate
            mortgageBalance = balance
            mortgageTermYears = termYears
            self.monthlyPaymentOverride = monthlyPaymentOverride
        }
    }

    /// A storage-folder switch the user has picked but not yet confirmed --
    /// the same read-then-confirm shape as `pickFileToImport`, so switching
    /// folders can never silently overwrite a data file that's already
    /// sitting in the destination.
    struct PendingStorageChange {
        let folder: URL
        let isDefaultLocation: Bool
        /// The decoded contents of an `items.json` already in `folder`, if
        /// one is there and readable.
        let existingData: AppData?
        /// An `items.json` is in `folder` but couldn't be decoded -- the
        /// switch is refused rather than risk clobbering unknown data.
        let hasUnreadableFile: Bool
    }

    /// Phase 1 (custom folder): show the picker and report what's already
    /// in the chosen folder, changing nothing yet. Returns nil if the user
    /// cancels the picker.
    func pickNewStorageFolder() -> PendingStorageChange? {
        guard let folder = StorageLocation.pickFolder() else { return nil }
        return inspectStorageTarget(folder: folder, isDefault: false)
    }

    /// Phase 1 (default location): report what's already in the default
    /// folder so "Use Default Location" gets the same confirm-first
    /// treatment as picking a custom one.
    func prepareResetToDefaultStorageFolder() -> PendingStorageChange {
        inspectStorageTarget(folder: StorageLocation.defaultFolderURL(), isDefault: true)
    }

    private func inspectStorageTarget(folder: URL, isDefault: Bool) -> PendingStorageChange {
        let candidateFileURL = StorageLocation.itemsFileURL(in: folder)
        guard FileManager.default.fileExists(atPath: candidateFileURL.path) else {
            return PendingStorageChange(folder: folder, isDefaultLocation: isDefault, existingData: nil, hasUnreadableFile: false)
        }
        if let data = try? ItemStore.load(from: candidateFileURL) {
            return PendingStorageChange(folder: folder, isDefaultLocation: isDefault, existingData: data, hasUnreadableFile: false)
        }
        return PendingStorageChange(folder: folder, isDefaultLocation: isDefault, existingData: nil, hasUnreadableFile: true)
    }

    /// Phase 2a: switch to the folder and load whatever data is already
    /// there, discarding the current in-memory data (it stays on disk in
    /// the old location).
    func adoptStorageFolder(_ pending: PendingStorageChange) {
        guard commitStorageLocation(pending) else { return }
        load()
    }

    /// Phase 2b: switch to the folder and write the current in-memory data
    /// into it, replacing anything that was there.
    func replaceDataAtStorageFolder(_ pending: PendingStorageChange) {
        guard commitStorageLocation(pending) else { return }
        if !save() {
            // The location already moved but the write failed -- resync
            // in-memory state with whatever is actually on disk there.
            load()
        }
    }

    /// Commits the bookmark/default-location change and repoints the store
    /// at the new folder. Returns false (and sets `loadError`) without
    /// switching if the destination holds an unreadable file or a lasting
    /// bookmark can't be made.
    private func commitStorageLocation(_ pending: PendingStorageChange) -> Bool {
        if pending.hasUnreadableFile {
            loadError = "\"\(pending.folder.lastPathComponent)\" already has a Sunk Cost data file that can't be read, so it wasn't switched to. Move or fix that file first."
            return false
        }
        if pending.isDefaultLocation {
            StorageLocation.resetToDefault()
        } else if !StorageLocation.commitFolder(pending.folder) {
            loadError = "Couldn't get lasting permission to \"\(pending.folder.lastPathComponent)\", so it wasn't switched to. Try a different folder."
            return false
        }
        stopAccessingCurrentFolder?()
        let (folder, stopAccessing) = StorageLocation.resolveCurrentFolder()
        storageFolderURL = folder
        stopAccessingCurrentFolder = stopAccessing
        return true
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

    /// Populates the app with fake placeholder data (a house, some items, a
    /// mortgage) so a first-time user from the Welcome screen can see
    /// what everything looks like filled in, before typing in real
    /// numbers. Safe to call any time -- replaces whatever's currently
    /// loaded, same as any other import.
    func loadSampleData() {
        guard let data = try? ItemStore.decode(Data(SampleData.json.utf8)) else { return }
        applyImportedData(data)
    }

    func applyImportedData(_ data: AppData) {
        mutate { apply(data) }
    }

    /// The one place `AppData`'s fields are copied *into* the store —
    /// `load`, import, and the save-failure rollback all route through
    /// here so a field added to the model can't be wired into one path
    /// and silently forgotten in another. Kept field-for-field in sync
    /// with `currentAppData()` below (the reverse direction).
    private func apply(_ data: AppData) {
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
        realtorCommissionPercent = data.realtorCommissionPercent
        closingCostsPercent = data.closingCostsPercent
        comparisonProjectionYears = data.comparisonProjectionYears
        homeAppreciationPercent = data.homeAppreciationPercent
        investmentReturnPercent = data.investmentReturnPercent
        monthlyRent = data.monthlyRent
        rentAnnualIncreasePercent = data.rentAnnualIncreasePercent
        securityDeposit = data.securityDeposit
        petDeposit = data.petDeposit
        petRentMonthly = data.petRentMonthly
        newHomePrice = data.newHomePrice
        newHomeDownPayment = data.newHomeDownPayment
        newMortgageRatePercent = data.newMortgageRatePercent
        newMortgageTermYears = data.newMortgageTermYears
        propertyTaxAnnual = data.propertyTaxAnnual
        homeownersInsuranceAnnual = data.homeownersInsuranceAnnual
        newPropertyTaxAnnual = data.newPropertyTaxAnnual
        newHomeownersInsuranceAnnual = data.newHomeownersInsuranceAnnual
        hoaMonthly = data.hoaMonthly
        newHoaMonthly = data.newHoaMonthly
        savedComparisonScenarios = data.savedComparisonScenarios
    }

    /// Clears every domain field back to empty — used when a load fails,
    /// so nothing lingers from a file that was loaded before.
    private func resetToEmpty() {
        apply(AppData())
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
            maintenanceCategories: maintenanceCategories,
            realtorCommissionPercent: realtorCommissionPercent,
            closingCostsPercent: closingCostsPercent,
            comparisonProjectionYears: comparisonProjectionYears,
            homeAppreciationPercent: homeAppreciationPercent,
            investmentReturnPercent: investmentReturnPercent,
            monthlyRent: monthlyRent,
            rentAnnualIncreasePercent: rentAnnualIncreasePercent,
            securityDeposit: securityDeposit,
            petDeposit: petDeposit,
            petRentMonthly: petRentMonthly,
            newHomePrice: newHomePrice,
            newHomeDownPayment: newHomeDownPayment,
            newMortgageRatePercent: newMortgageRatePercent,
            newMortgageTermYears: newMortgageTermYears,
            propertyTaxAnnual: propertyTaxAnnual,
            homeownersInsuranceAnnual: homeownersInsuranceAnnual,
            newPropertyTaxAnnual: newPropertyTaxAnnual,
            newHomeownersInsuranceAnnual: newHomeownersInsuranceAnnual,
            hoaMonthly: hoaMonthly,
            newHoaMonthly: newHoaMonthly,
            savedComparisonScenarios: savedComparisonScenarios
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
        mutate { items = importedItems }
    }

    func addMaintenanceCategory(name: String, monthlyAmount: Decimal, notes: String? = nil, isRequired: Bool = true) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        mutate { maintenanceCategories.append(MaintenanceCategory(name: trimmedName, monthlyAmount: monthlyAmount, notes: notes, isRequired: isRequired)) }
    }

    func updateMaintenanceCategory(_ category: MaintenanceCategory) {
        guard let index = maintenanceCategories.firstIndex(where: { $0.id == category.id }) else { return }
        mutate { maintenanceCategories[index] = category }
    }

    func deleteMaintenanceCategory(_ category: MaintenanceCategory) {
        mutate { maintenanceCategories.removeAll { $0.id == category.id } }
    }
}
