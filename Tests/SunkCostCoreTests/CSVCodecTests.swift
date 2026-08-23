import Testing
import Foundation
@testable import SunkCostCore

@Suite("CSV import/export")
struct CSVCodecTests {
    @Test("encodes a header row and one item row")
    func encodesHeaderAndRow() {
        let date = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 UTC
        let item = Item(name: "Couch", category: "Furniture", cost: 1200.5, status: .owned, dateAdded: date)

        let csv = CSVCodec.encode([item])

        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[0] == "Name,Category,Cost,Status,Date,Notes,Type")
        #expect(lines[1] == "Couch,Furniture,1200.5,Owned,2025-01-01,,Moveable")
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
        #expect(lines[1] == "TV,Furniture,999,Owned,,,Moveable")

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
}
