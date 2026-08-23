import Testing
import Foundation
@testable import SunkCostCore

@Suite("ItemStore persistence")
struct ItemStoreTests {
    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("items.json")
    }

    @Test("loading a URL with no file yet returns empty data")
    func loadingMissingFileReturnsEmptyData() throws {
        let url = makeTempFileURL()

        let data = try ItemStore.load(from: url)

        #expect(data.items.isEmpty)
        #expect(data.homeValue == nil)
    }

    @Test("saving then loading round-trips items and home value")
    func saveThenLoadRoundTrips() throws {
        let url = makeTempFileURL()
        let item = Item(
            name: "Couch",
            category: "Furniture",
            cost: 1200.50,
            status: .owned,
            notes: "Bought on sale, #livingroom, **great** find"
        )
        let original = AppData(items: [item], homeValue: 450_000)

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded == original)
    }

    @Test("saving creates any missing parent directories")
    func savingCreatesParentDirectories() throws {
        let url = makeTempFileURL()
        #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))

        try ItemStore.save(AppData(), to: url)

        #expect(FileManager.default.fileExists(atPath: url.path))
    }

    @Test("mortgage fields round-trip")
    func mortgageFieldsRoundTrip() throws {
        let url = makeTempFileURL()
        let original = AppData(
            mortgageOriginalAmount: 250_000,
            mortgageInterestRatePercent: 5.5,
            mortgageStartDate: Date(timeIntervalSince1970: 1_609_459_200), // Jan 2021
            mortgageBalance: 210_000,
            mortgageTermYears: 15,
            monthlyPaymentOverride: 2042.13
        )

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded == original)
    }

    @Test("blank cost round-trips as nil")
    func blankCostRoundTripsAsNil() throws {
        let url = makeTempFileURL()
        let item = Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned)
        let original = AppData(items: [item], homeValue: nil)

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded.items.first?.cost == nil)
    }

    @Test("blank date round-trips as nil")
    func blankDateRoundTripsAsNil() throws {
        let url = makeTempFileURL()
        let item = Item(name: "TV", category: "Furniture", cost: 999, status: .owned, dateAdded: nil)
        let original = AppData(items: [item], homeValue: nil)

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded.items.first?.dateAdded == nil)
    }

    @Test("purchase price round-trips")
    func purchasePriceRoundTrips() throws {
        let url = makeTempFileURL()
        let original = AppData(homeValue: 450_000, purchasePrice: 380_000)

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded == original)
    }

    @Test("loading JSON saved before purchase price existed gives nil purchase price")
    func loadingPrePurchasePriceJSONGivesNil() throws {
        let url = makeTempFileURL()
        let json = """
        {
            "items": [],
            "homeValue": 450000
        }
        """
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)

        let loaded = try ItemStore.load(from: url)

        #expect(loaded.purchasePrice == nil)
    }

    @Test("maintenance categories round-trip")
    func maintenanceRoundTrips() throws {
        let url = makeTempFileURL()
        let category = MaintenanceCategory(name: "Oil", monthlyAmount: 200)
        let original = AppData(maintenanceCategories: [category])

        try ItemStore.save(original, to: url)
        let loaded = try ItemStore.load(from: url)

        #expect(loaded == original)
    }

    @Test("loading JSON saved before Maintenance existed gives empty maintenance categories")
    func loadingPreMaintenanceJSONGivesEmptyArrays() throws {
        let url = makeTempFileURL()
        let json = """
        {
            "items": [],
            "homeValue": 450000
        }
        """
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)

        let loaded = try ItemStore.load(from: url)

        #expect(loaded.maintenanceCategories.isEmpty)
        #expect(loaded.homeValue == 450_000)
    }

    @Test("loading corrupt JSON throws instead of silently losing data")
    func loadingCorruptJSONThrows() throws {
        let url = makeTempFileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not valid json".utf8).write(to: url)

        #expect(throws: (any Error).self) {
            try ItemStore.load(from: url)
        }
    }
}
