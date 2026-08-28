import Foundation
@testable import SunkCost
@testable import SunkCostCore

/// A throwaway directory for a single test, cleaned up on `deinit`.
final class TempFolder {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SunkCostTests-\(UUID().uuidString)", isDirectory: true)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
        try? FileManager.default.removeItem(at: url)
    }

    var itemsFileURL: URL { StorageLocation.itemsFileURL(in: url) }

    func writeItemsFile(_ data: AppData) {
        try! ItemStore.save(data, to: itemsFileURL)
    }

    func writeRawItemsFile(_ text: String) {
        try! text.write(to: itemsFileURL, atomically: true, encoding: .utf8)
    }

    func setWritable(_ writable: Bool) {
        try! FileManager.default.setAttributes(
            [.posixPermissions: writable ? 0o755 : 0o555],
            ofItemAtPath: url.path
        )
    }
}

/// Compares two folder URLs by canonical path -- `/var` vs `/private/var`
/// and trailing slashes otherwise make identical directories look unequal.
func sameFolder(_ a: URL, _ b: URL) -> Bool {
    a.resolvingSymlinksInPath().standardizedFileURL.path
        == b.resolvingSymlinksInPath().standardizedFileURL.path
}

func sampleItem(_ name: String, cost: Decimal? = 10) -> Item {
    Item(name: name, category: "Test", cost: cost, status: .owned, dateAdded: nil)
}

/// A fully-populated `AppData` for round-trip assertions.
func richAppData() -> AppData {
    AppData(
        items: [sampleItem("Sofa", cost: 1200), sampleItem("Fence", cost: 3000)],
        homeValue: 525_000,
        purchasePrice: 410_000,
        mortgageOriginalAmount: 328_000,
        mortgageInterestRatePercent: 3.25,
        mortgageStartDate: Date(timeIntervalSince1970: 1_600_000_000),
        mortgageBalance: 290_500,
        mortgageTermYears: 30,
        monthlyPaymentOverride: 1_612,
        maintenanceCategories: [
            MaintenanceCategory(name: "Utilities", monthlyAmount: 240, notes: "gas + electric", isRequired: true)
        ],
        realtorCommissionPercent: 5.5,
        closingCostsPercent: 1.75,
        comparisonProjectionYears: 12,
        homeAppreciationPercent: 3.5,
        investmentReturnPercent: 6.5,
        monthlyRent: 2_300,
        rentAnnualIncreasePercent: 4,
        securityDeposit: 2_300,
        petDeposit: 500,
        petRentMonthly: 35,
        newHomePrice: 600_000,
        newHomeDownPayment: 150_000,
        newMortgageRatePercent: 6.125,
        newMortgageTermYears: 20,
        propertyTaxAnnual: 6_400,
        homeownersInsuranceAnnual: 1_450,
        newPropertyTaxAnnual: 7_800,
        newHomeownersInsuranceAnnual: 1_900,
        hoaMonthly: 0,
        newHoaMonthly: 120,
        savedComparisonScenarios: [
            ComparisonScenario(name: "Conservative", homeAppreciationPercent: 2, notes: "low growth")
        ]
    )
}
