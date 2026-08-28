import Testing
import Foundation
@testable import SunkCostCore

@Suite("CSV import/export")
struct CSVCodecTests {
    /// A fixed calendar day in whatever timezone the tests run in, so the
    /// "yyyy-MM-dd" CSV encoding is deterministic regardless of runner TZ.
    private static func localDay(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test("encodes a header row and one item row")
    func encodesHeaderAndRow() {
        let item = Item(name: "Couch", category: "Furniture", cost: 1200.5, status: .owned, dateAdded: Self.localDay(2025, 1, 1))

        let csv = CSVCodec.encode([item])

        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[0] == "Name,Category,Cost,Status,Date,Notes,Type,Disposition,Amount Recovered")
        #expect(lines[1] == "Couch,Furniture,1200.5,Owned,2025-01-01,,Moveable,,")
    }

    @Test("blank cost encodes as an empty field")
    func blankCostEncodesEmpty() {
        let item = Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned)

        let csv = CSVCodec.encode([item])

        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[1].hasPrefix("Ceiling Fan,Property Upgrades,,Planned,"))
    }

    @Test("blank date round-trips as nil")
    func blankDateRoundTripsAsNil() throws {
        let item = Item(name: "TV", category: "Furniture", cost: 999, status: .owned, dateAdded: nil)

        let csv = CSVCodec.encode([item])
        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[1] == "TV,Furniture,999,Owned,,,Moveable,,")

        let decoded = try CSVCodec.decode(csv)
        #expect(decoded[0].dateAdded == nil)
    }

    @Test("a name containing a comma is quoted")
    func nameContainingCommaIsQuoted() {
        let item = Item(name: "Sofa, Reclining", category: "Furniture", cost: 500, status: .owned)

        let csv = CSVCodec.encode([item])

        #expect(csv.contains("\"Sofa, Reclining\""))
    }

    @Test("round-trips items through encode then decode")
    func roundTripsThroughEncodeAndDecode() throws {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1200.5, status: .owned),
            Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned),
            Item(name: "Sofa, Reclining", category: "Furniture", cost: 500, status: .gone),
        ]

        let csv = CSVCodec.encode(items)
        let decoded = try CSVCodec.decode(csv)

        #expect(decoded.count == 3)
        #expect(decoded[0].name == "Couch")
        #expect(decoded[0].category == "Furniture")
        #expect(decoded[0].cost == 1200.5)
        #expect(decoded[0].status == .owned)
        #expect(decoded[1].cost == nil)
        #expect(decoded[1].status == .planned)
        #expect(decoded[2].name == "Sofa, Reclining")
        #expect(decoded[2].status == .gone)
    }

    @Test("decode accepts lowercase status values")
    func decodeAcceptsLowercaseStatus() throws {
        let csv = "Name,Category,Cost,Status,Date\r\nDesk,Furniture,100,owned,2025-01-01"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].status == .owned)
    }

    @Test("decode throws on missing required columns")
    func decodeThrowsOnMissingColumns() throws {
        let csv = "Name,Category\r\nDesk,Furniture"

        #expect(throws: (any Error).self) {
            try CSVCodec.decode(csv)
        }
    }

    @Test("decode ignores a trailing blank line")
    func decodeIgnoresTrailingBlankLine() throws {
        let csv = "Name,Category,Cost,Status,Date\r\nDesk,Furniture,100,owned,2025-01-01\r\n"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded.count == 1)
    }

    @Test("notes round-trip through encode then decode")
    func notesRoundTrip() throws {
        let item = Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned, notes: "From the #livingroom set")

        let csv = CSVCodec.encode([item])
        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].notes == "From the #livingroom set")
    }

    @Test("decoding a CSV without a Notes column (older export) still works, with nil notes")
    func decodeWithoutNotesColumnStillWorks() throws {
        let csv = "Name,Category,Cost,Status,Date\r\nDesk,Furniture,100,owned,2025-01-01"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded.count == 1)
        #expect(decoded[0].notes == nil)
    }

    @Test("blank notes decode as nil")
    func blankNotesDecodeAsNil() throws {
        let csv = "Name,Category,Cost,Status,Date,Notes\r\nDesk,Furniture,100,owned,2025-01-01,"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].notes == nil)
    }

    @Test("type round-trips through encode then decode")
    func typeRoundTrips() throws {
        let item = Item(name: "Fence", category: "Property Upgrades", cost: 3000, status: .owned, type: .value)

        let csv = CSVCodec.encode([item])
        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[1].contains(",Value"))

        let decoded = try CSVCodec.decode(csv)
        #expect(decoded[0].type == .value)
    }

    @Test("decoding a CSV without a Type column (older export) falls back to moveable")
    func decodeWithoutTypeColumnFallsBackToMoveable() throws {
        let csv = "Name,Category,Cost,Status,Date\r\nDesk,Furniture,100,owned,2025-01-01"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].type == .moveable)
    }

    @Test("disposition and amount recovered round-trip through encode then decode")
    func dispositionAndAmountRecoveredRoundTrip() throws {
        let items = [
            Item(name: "Old Sofa", category: "Furniture", cost: 800, status: .gone, type: .moveable, disposition: .sold, amountRecovered: 150),
            Item(name: "Broken Lamp", category: "Furniture", cost: 40, status: .gone, type: .moveable, disposition: .givenAway),
        ]

        let csv = CSVCodec.encode(items)
        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].disposition == .sold)
        #expect(decoded[0].amountRecovered == 150)
        #expect(decoded[1].disposition == .givenAway)
        #expect(decoded[1].amountRecovered == nil)
    }

    @Test("disposition column accepts the raw enum value as well as the label")
    func dispositionAcceptsRawValue() throws {
        let csv = "Name,Category,Cost,Status,Date,Disposition\r\nOld Sofa,Furniture,800,gone,2025-01-01,givenAway"

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded[0].disposition == .givenAway)
    }

    @Test("a date-only value round-trips to the same calendar day")
    func dateOnlyRoundTripsToSameCalendarDay() throws {
        let item = Item(name: "Rug", category: "Furniture", cost: 200, status: .owned, dateAdded: Self.localDay(2026, 8, 28))

        let csv = CSVCodec.encode([item])
        let decoded = try CSVCodec.decode(csv)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: try #require(decoded[0].dateAdded))
        #expect(components.year == 2026)
        #expect(components.month == 8)
        #expect(components.day == 28)
    }

    @Test("decode throws on a duplicate column header instead of trapping")
    func decodeThrowsOnDuplicateColumns() {
        let csv = "Name,Category,Cost,Cost,Status,Date\r\nDesk,Furniture,100,100,owned,2025-01-01"

        #expect(throws: CSVCodecError.self) {
            try CSVCodec.decode(csv)
        }
    }

    @Test("a short row with a reordered required column is skipped, not a crash")
    func shortRowWithReorderedRequiredColumnIsSkipped() throws {
        // Date is the last (index 6) required column; the second data row
        // has only 5 cells, so there is no cell at index 6.
        let csv = """
        Notes,Type,Name,Category,Cost,Status,Date\r
        ,,Desk,Furniture,100,owned,2025-01-01\r
        ,,Chair,Furniture,50
        """

        let decoded = try CSVCodec.decode(csv)

        #expect(decoded.count == 1)
        #expect(decoded[0].name == "Desk")
    }
}
