import Testing
import Foundation
@testable import SunkCost
@testable import SunkCostCore

@MainActor
@Suite("AppStore persistence")
struct AppStorePersistenceTests {

    @Test("apply / currentAppData round-trips every domain field through disk")
    func roundTripsEveryField() {
        let folder = TempFolder()
        let data = richAppData() // one instance: the nested types carry random ids
        folder.writeItemsFile(data)

        let store = AppStore(storageOverrideForTesting: folder.url)

        #expect(store.currentAppData() == data)
        #expect(store.loadError == nil)
    }

    @Test("a failed save rolls the in-memory mutation back")
    func failedSaveRollsBack() {
        let folder = TempFolder()
        let store = AppStore(storageOverrideForTesting: folder.url)

        store.addItem(sampleItem("first"))
        #expect(store.items.map(\.name) == ["first"])

        folder.setWritable(false)
        defer { folder.setWritable(true) }

        store.addItem(sampleItem("second"))

        // Rolled back: the in-memory list matches the (untouched) file.
        #expect(store.items.map(\.name) == ["first"])
        #expect(store.loadError != nil)

        folder.setWritable(true)
        let onDisk = try! ItemStore.load(from: folder.itemsFileURL)
        #expect(onDisk.items.map(\.name) == ["first"])
    }

    @Test("a failed save on a multi-field mutation restores all of them")
    func failedSaveRestoresEveryField() {
        let folder = TempFolder()
        let store = AppStore(storageOverrideForTesting: folder.url)
        store.setPurchasePrice(400_000)

        folder.setWritable(false)
        defer { folder.setWritable(true) }

        store.setMortgage(
            originalAmount: 300_000,
            interestRatePercent: 4,
            startDate: nil,
            balance: 275_000,
            termYears: 30,
            monthlyPaymentOverride: nil
        )

        #expect(store.mortgageOriginalAmount == nil)
        #expect(store.mortgageBalance == nil)
        #expect(store.purchasePrice == 400_000) // untouched field survives too
    }

    @Test("a corrupt data file loads as empty (not a partial reset) and flags the error")
    func corruptFileResetsToEmpty() {
        let folder = TempFolder()
        folder.writeItemsFile(richAppData())          // a valid file first...
        folder.writeRawItemsFile("{ this is not json") // ...then corrupt it

        let store = AppStore(storageOverrideForTesting: folder.url)

        #expect(store.items.isEmpty)
        #expect(store.homeValue == nil)
        #expect(store.mortgageBalance == nil)
        #expect(store.maintenanceCategories.isEmpty)
        #expect(store.savedComparisonScenarios.isEmpty)
        #expect(store.loadError != nil)
    }
}
