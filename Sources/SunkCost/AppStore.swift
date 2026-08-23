import Foundation
import Observation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import SunkCostCore

/// PITI-style monthly cost breakdown for one Compare scenario -- Renting
/// only ever populates `maintenanceOrRent`, since it has no mortgage, tax,
/// or insurance of its own.
struct MonthlyCostBreakdown {
    var principalAndInterest: Decimal = 0
    var propertyTax: Decimal = 0
    var insurance: Decimal = 0
    var maintenanceOrRent: Decimal = 0
    var total: Decimal { principalAndInterest + propertyTax + insurance + maintenanceOrRent }
}

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
    var newHomePrice: Decimal?
    var newHomeDownPayment: Decimal?
    var newMortgageRatePercent: Decimal?
    var newMortgageTermYears: Int?
    var propertyTaxPercent: Decimal?
    var homeownersInsuranceAnnual: Decimal?
    var newPropertyTaxPercent: Decimal?
    var newHomeownersInsuranceAnnual: Decimal?
    var savedComparisonScenarios: [ComparisonScenario] = []
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
    var availableCategories: [String] { items.distinctCategories }
    var availableHashtags: [String] { items.distinctHashtags }
    var categoriesWithCounts: [(category: String, count: Int)] {
        availableCategories.map { category in
            (category, items.filter { $0.category == category }.count)
        }
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
    /// What selling today would net, after assumed selling costs pay off
    /// the mortgage -- falls back to 6%/2% commission/closing when the
    /// user hasn't set their own assumptions yet, so the Sell Scenario tab
    /// always shows a usable estimate.
    var sellScenario: SellScenario? {
        computeSellScenario(
            homeValue: homeValue,
            mortgageBalance: mortgageBalance,
            realtorCommissionPercent: realtorCommissionPercent ?? 6,
            closingCostsPercent: closingCostsPercent ?? 2,
            totalInvested: totalInvested
        )
    }

    /// Compare: Stay vs. Rent vs. Buy Elsewhere -- the horizon (years) for
    /// all three projections below.
    var projectionYears: Int { comparisonProjectionYears ?? 10 }

    private var monthsSinceMortgageStart: Int? {
        guard let mortgageStartDate else { return nil }
        let months = Calendar.current.dateComponents([.month], from: mortgageStartDate, to: Date()).month ?? 0
        return max(months, 0)
    }

    /// Ending home equity if she stays -- nil until the *actual* mortgage
    /// details (not just the balance) are on record, since there's no
    /// sensible default for someone's real loan terms the way there is for
    /// a general assumption like appreciation rate.
    var stayingNetWorthProjection: Decimal? {
        guard let homeValue, let mortgageOriginalAmount, let mortgageInterestRatePercent,
              let mortgageTermYears, let monthsSinceMortgageStart else { return nil }
        return projectStayingNetWorth(
            homeValue: homeValue,
            appreciationPercent: homeAppreciationPercent ?? 3,
            mortgageOriginalAmount: mortgageOriginalAmount,
            mortgageAnnualRatePercent: mortgageInterestRatePercent,
            mortgageTermYears: mortgageTermYears,
            monthsAlreadyPaid: monthsSinceMortgageStart,
            projectionYears: projectionYears
        )
    }

    /// Ending investment balance if she sells and rents -- nil until a
    /// rent figure is entered, since no generic default is meaningful
    /// (unlike the investment-return assumption, which does get one).
    var rentingNetWorthProjection: Decimal? {
        guard monthlyRent != nil, let netProceeds = sellScenario?.netProceeds else { return nil }
        return projectRentingNetWorth(
            netProceedsToday: netProceeds,
            investmentReturnPercent: investmentReturnPercent ?? 6,
            projectionYears: projectionYears
        )
    }

    /// Ending home equity in a new home if she sells and buys elsewhere --
    /// nil until a new home price is entered; down payment/rate/term all
    /// fall back to reasonable suggestions (today's sale proceeds, her
    /// current mortgage's rate, a 30-year term).
    var buyingElsewhereNetWorthProjection: Decimal? {
        guard let newHomePrice else { return nil }
        let netProceeds = sellScenario?.netProceeds ?? 0
        return projectBuyingElsewhereNetWorth(
            newHomePrice: newHomePrice,
            downPayment: newHomeDownPayment ?? netProceeds,
            netProceedsAvailable: netProceeds,
            appreciationPercent: homeAppreciationPercent ?? 3,
            newMortgageAnnualRatePercent: newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6,
            newMortgageTermYears: newMortgageTermYears ?? 30,
            projectionYears: projectionYears,
            leftoverCashInvestmentReturnPercent: investmentReturnPercent ?? 6
        )
    }

    /// Today's PITI breakdown for each Compare scenario -- nil under the
    /// same gating as the net-worth projections above (this is about
    /// *today's* monthly cost, so it doesn't need the projection horizon).
    var stayingMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let homeValue, let principalAndInterest = monthlyPayment else { return nil }
        return MonthlyCostBreakdown(
            principalAndInterest: principalAndInterest,
            propertyTax: monthlyPropertyTax(homeValue: homeValue, annualTaxPercent: propertyTaxPercent ?? 1.2),
            insurance: (homeownersInsuranceAnnual ?? 1500) / 12,
            maintenanceOrRent: costToKeep
        )
    }

    var rentingMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let monthlyRent else { return nil }
        return MonthlyCostBreakdown(maintenanceOrRent: monthlyRent)
    }

    /// Maintenance reuses today's `costToKeep` as a stand-in for the new
    /// home's upkeep -- a second full Maintenance estimate for a home she
    /// hasn't picked wasn't part of what was scoped.
    var buyingElsewhereMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let newHomePrice else { return nil }
        let downPayment = newHomeDownPayment ?? sellScenario?.netProceeds ?? 0
        let principalAndInterest = MortgageMath.monthlyPayment(
            principal: newHomePrice - downPayment,
            annualRatePercent: newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6,
            termYears: newMortgageTermYears ?? 30
        ) ?? 0
        return MonthlyCostBreakdown(
            principalAndInterest: principalAndInterest,
            propertyTax: monthlyPropertyTax(homeValue: newHomePrice, annualTaxPercent: newPropertyTaxPercent ?? 1.2),
            insurance: (newHomeownersInsuranceAnnual ?? 1500) / 12,
            maintenanceOrRent: costToKeep
        )
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
            realtorCommissionPercent = data.realtorCommissionPercent
            closingCostsPercent = data.closingCostsPercent
            comparisonProjectionYears = data.comparisonProjectionYears
            homeAppreciationPercent = data.homeAppreciationPercent
            investmentReturnPercent = data.investmentReturnPercent
            monthlyRent = data.monthlyRent
            rentAnnualIncreasePercent = data.rentAnnualIncreasePercent
            newHomePrice = data.newHomePrice
            newHomeDownPayment = data.newHomeDownPayment
            newMortgageRatePercent = data.newMortgageRatePercent
            newMortgageTermYears = data.newMortgageTermYears
            propertyTaxPercent = data.propertyTaxPercent
            homeownersInsuranceAnnual = data.homeownersInsuranceAnnual
            newPropertyTaxPercent = data.newPropertyTaxPercent
            newHomeownersInsuranceAnnual = data.newHomeownersInsuranceAnnual
            savedComparisonScenarios = data.savedComparisonScenarios
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
            BackupManager.snapshot(dataFileURL: fileURL, storageFolder: storageFolderURL)
            loadError = nil
        } catch {
            loadError = "Couldn't save your changes: \(error.localizedDescription)"
        }
    }

    /// Opens Finder to the folder of silent daily backups (Settings ->
    /// "Show Backups Folder…") -- the recovery path for an accidental
    /// delete or a bad edit.
    func revealBackupsFolder() {
        let folder = BackupManager.backupsFolder(in: storageFolderURL)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        NSWorkspace.shared.activateFileViewerSelecting([folder])
    }

    /// Plain-text dump of the Sell Scenario and Compare numbers -- inputs
    /// and results both -- meant for pasting into a chat (with Claude or
    /// anyone else) to play with the numbers outside the app, without
    /// wiring any actual network access into the app itself.
    func compareSummaryText() -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        currencyFormatter.maximumFractionDigits = 0

        func fmt(_ value: Decimal?) -> String {
            guard let value else { return "—" }
            return currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
        }
        func pct(_ value: Decimal?) -> String {
            guard let value else { return "—" }
            return "\(NSDecimalNumber(decimal: value).stringValue)%"
        }

        var lines: [String] = ["Sunk Cost — Cost to Leave Summary", ""]

        if let scenario = sellScenario {
            lines += [
                "SELL SCENARIO (today)",
                "Home Value: \(fmt(homeValue))",
                "Mortgage Payoff: \(fmt(mortgageBalance))",
                "Selling Costs: \(fmt(scenario.sellingCosts)) (\(pct(realtorCommissionPercent ?? 6)) commission + \(pct(closingCostsPercent ?? 2)) closing)",
                "Net Proceeds if Sold Today: \(fmt(scenario.netProceeds))",
            ]
            if let totalInvested {
                lines.append("Total Invested (Purchase Price + Value spending): \(fmt(totalInvested))")
            }
            if let netProfitOrLoss = scenario.netProfitOrLoss {
                lines.append("Profit/Loss vs. Total Invested: \(fmt(netProfitOrLoss))")
            }
            lines.append("")
        }

        lines += ["COMPARE: STAY VS. RENT VS. BUY ELSEWHERE (\(projectionYears) years)", ""]

        lines.append("STAYING")
        lines.append("Home Appreciation: \(pct(homeAppreciationPercent ?? 3))/yr")
        lines.append("Property Tax: \(pct(propertyTaxPercent ?? 1.2))/yr, Insurance: \(fmt(homeownersInsuranceAnnual ?? 1500))/yr")
        if let breakdown = stayingMonthlyBreakdown {
            lines.append("Monthly: P&I \(fmt(breakdown.principalAndInterest)), Tax \(fmt(breakdown.propertyTax)), Insurance \(fmt(breakdown.insurance)), Maintenance \(fmt(breakdown.maintenanceOrRent)) → Total \(fmt(breakdown.total))/mo")
        }
        lines.append("Ending Net Worth: \(stayingNetWorthProjection.map(fmt) ?? "needs full mortgage details (original amount, rate, term, start date) in Settings")")
        lines.append("")

        lines.append("RENTING")
        lines.append("Investment Return: \(pct(investmentReturnPercent ?? 6))/yr")
        lines.append("Monthly Rent: \(fmt(monthlyRent)), Rent Increase: \(pct(rentAnnualIncreasePercent ?? 3))/yr")
        if let breakdown = rentingMonthlyBreakdown {
            lines.append("Monthly Total: \(fmt(breakdown.total))/mo")
        }
        lines.append("Ending Net Worth: \(rentingNetWorthProjection.map(fmt) ?? "needs a monthly rent figure")")
        lines.append("")

        lines.append("BUYING ELSEWHERE")
        lines.append("New Home Price: \(fmt(newHomePrice)), Down Payment: \(fmt(newHomeDownPayment ?? sellScenario?.netProceeds))")
        if let newHomePrice {
            let downPayment = newHomeDownPayment ?? sellScenario?.netProceeds ?? 0
            lines.append("Loan Amount: \(fmt(max(newHomePrice - min(downPayment, newHomePrice), 0)))")
        }
        lines.append("Mortgage Rate: \(pct(newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6)), Term: \(newMortgageTermYears ?? 30) years")
        lines.append("Property Tax: \(pct(newPropertyTaxPercent ?? 1.2))/yr, Insurance: \(fmt(newHomeownersInsuranceAnnual ?? 1500))/yr")
        if let breakdown = buyingElsewhereMonthlyBreakdown {
            lines.append("Monthly: P&I \(fmt(breakdown.principalAndInterest)), Tax \(fmt(breakdown.propertyTax)), Insurance \(fmt(breakdown.insurance)), Maintenance \(fmt(breakdown.maintenanceOrRent)) → Total \(fmt(breakdown.total))/mo")
        }
        lines.append("Ending Net Worth: \(buyingElsewhereNetWorthProjection.map(fmt) ?? "needs a new home price")")

        return lines.joined(separator: "\n")
    }

    func copyCompareSummaryToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(compareSummaryText(), forType: .string)
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

    func setSellingCostAssumptions(commissionPercent: Decimal?, closingPercent: Decimal?) {
        realtorCommissionPercent = commissionPercent
        closingCostsPercent = closingPercent
        save()
    }

    func setComparisonAssumptions(
        projectionYears: Int?,
        homeAppreciationPercent: Decimal?,
        investmentReturnPercent: Decimal?,
        monthlyRent: Decimal?,
        rentAnnualIncreasePercent: Decimal?,
        newHomePrice: Decimal?,
        newHomeDownPayment: Decimal?,
        newMortgageRatePercent: Decimal?,
        newMortgageTermYears: Int?,
        propertyTaxPercent: Decimal?,
        homeownersInsuranceAnnual: Decimal?,
        newPropertyTaxPercent: Decimal?,
        newHomeownersInsuranceAnnual: Decimal?
    ) {
        self.comparisonProjectionYears = projectionYears
        self.homeAppreciationPercent = homeAppreciationPercent
        self.investmentReturnPercent = investmentReturnPercent
        self.monthlyRent = monthlyRent
        self.rentAnnualIncreasePercent = rentAnnualIncreasePercent
        self.newHomePrice = newHomePrice
        self.newHomeDownPayment = newHomeDownPayment
        self.newMortgageRatePercent = newMortgageRatePercent
        self.newMortgageTermYears = newMortgageTermYears
        self.propertyTaxPercent = propertyTaxPercent
        self.homeownersInsuranceAnnual = homeownersInsuranceAnnual
        self.newPropertyTaxPercent = newPropertyTaxPercent
        self.newHomeownersInsuranceAnnual = newHomeownersInsuranceAnnual
        save()
    }

    /// Saves the 13 live Compare assumption fields as a named, reloadable
    /// snapshot -- lets the user flip between several what-ifs without
    /// retyping. Doesn't capture Home Value, mortgage balance, Purchase
    /// Price, or Sell Scenario's selling-cost percentages, which are facts
    /// about the house/sale rather than "what-if" assumptions.
    func saveCurrentScenarioAsPreset(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let scenario = ComparisonScenario(
            name: trimmedName,
            projectionYears: comparisonProjectionYears,
            homeAppreciationPercent: homeAppreciationPercent,
            investmentReturnPercent: investmentReturnPercent,
            monthlyRent: monthlyRent,
            rentAnnualIncreasePercent: rentAnnualIncreasePercent,
            newHomePrice: newHomePrice,
            newHomeDownPayment: newHomeDownPayment,
            newMortgageRatePercent: newMortgageRatePercent,
            newMortgageTermYears: newMortgageTermYears,
            propertyTaxPercent: propertyTaxPercent,
            homeownersInsuranceAnnual: homeownersInsuranceAnnual,
            newPropertyTaxPercent: newPropertyTaxPercent,
            newHomeownersInsuranceAnnual: newHomeownersInsuranceAnnual
        )
        savedComparisonScenarios.append(scenario)
        save()
    }

    /// Overwrites the 13 live Compare assumption fields from a saved
    /// scenario, so the table/results update immediately.
    func loadScenario(_ scenario: ComparisonScenario) {
        comparisonProjectionYears = scenario.projectionYears
        homeAppreciationPercent = scenario.homeAppreciationPercent
        investmentReturnPercent = scenario.investmentReturnPercent
        monthlyRent = scenario.monthlyRent
        rentAnnualIncreasePercent = scenario.rentAnnualIncreasePercent
        newHomePrice = scenario.newHomePrice
        newHomeDownPayment = scenario.newHomeDownPayment
        newMortgageRatePercent = scenario.newMortgageRatePercent
        newMortgageTermYears = scenario.newMortgageTermYears
        propertyTaxPercent = scenario.propertyTaxPercent
        homeownersInsuranceAnnual = scenario.homeownersInsuranceAnnual
        newPropertyTaxPercent = scenario.newPropertyTaxPercent
        newHomeownersInsuranceAnnual = scenario.newHomeownersInsuranceAnnual
        save()
    }

    func deleteScenario(_ scenario: ComparisonScenario) {
        savedComparisonScenarios.removeAll { $0.id == scenario.id }
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
        realtorCommissionPercent = data.realtorCommissionPercent
        closingCostsPercent = data.closingCostsPercent
        comparisonProjectionYears = data.comparisonProjectionYears
        homeAppreciationPercent = data.homeAppreciationPercent
        investmentReturnPercent = data.investmentReturnPercent
        monthlyRent = data.monthlyRent
        rentAnnualIncreasePercent = data.rentAnnualIncreasePercent
        newHomePrice = data.newHomePrice
        newHomeDownPayment = data.newHomeDownPayment
        newMortgageRatePercent = data.newMortgageRatePercent
        newMortgageTermYears = data.newMortgageTermYears
        propertyTaxPercent = data.propertyTaxPercent
        homeownersInsuranceAnnual = data.homeownersInsuranceAnnual
        newPropertyTaxPercent = data.newPropertyTaxPercent
        newHomeownersInsuranceAnnual = data.newHomeownersInsuranceAnnual
        savedComparisonScenarios = data.savedComparisonScenarios
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
            maintenanceCategories: maintenanceCategories,
            realtorCommissionPercent: realtorCommissionPercent,
            closingCostsPercent: closingCostsPercent,
            comparisonProjectionYears: comparisonProjectionYears,
            homeAppreciationPercent: homeAppreciationPercent,
            investmentReturnPercent: investmentReturnPercent,
            monthlyRent: monthlyRent,
            rentAnnualIncreasePercent: rentAnnualIncreasePercent,
            newHomePrice: newHomePrice,
            newHomeDownPayment: newHomeDownPayment,
            newMortgageRatePercent: newMortgageRatePercent,
            newMortgageTermYears: newMortgageTermYears,
            propertyTaxPercent: propertyTaxPercent,
            homeownersInsuranceAnnual: homeownersInsuranceAnnual,
            newPropertyTaxPercent: newPropertyTaxPercent,
            newHomeownersInsuranceAnnual: newHomeownersInsuranceAnnual,
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
        items = importedItems
        save()
    }

    func addMaintenanceCategory(name: String, monthlyAmount: Decimal, notes: String? = nil, isRequired: Bool = true) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        maintenanceCategories.append(MaintenanceCategory(name: trimmedName, monthlyAmount: monthlyAmount, notes: notes, isRequired: isRequired))
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
