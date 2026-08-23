import Testing
import Foundation
@testable import TheMoneyPitCore

@Suite("CSV import/export")
struct CSVCodecTests {
    @Test("encodes a header row and one item row")
    func encodesHeaderAndRow() {
        let date = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01 UTC
        let item = Item(name: "Couch", category: "Furniture", cost: 1200.5, status: .owned, dateAdded: date)

        let csv = CSVCodec.encode([item])

        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[0] == "Name,Category,Cost,Status,Date")
        #expect(lines[1] == "Couch,Furniture,1200.5,Owned,2025-01-01")
    }

    @Test("blank cost encodes as an empty field")
    func blankCostEncodesEmpty() {
        let item = Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned)

        let csv = CSVCodec.encode([item])

        let lines = csv.components(separatedBy: "\r\n")
        #expect(lines[1].hasPrefix("Ceiling Fan,Property Upgrades,,Planned,"))
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
}
