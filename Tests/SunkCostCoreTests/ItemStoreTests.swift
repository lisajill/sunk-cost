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
        let item = Item(name: "Couch", category: "Furniture", cost: 1200.50, status: .owned)
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
