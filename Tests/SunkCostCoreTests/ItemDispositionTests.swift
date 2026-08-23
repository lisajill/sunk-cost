import Testing
import Foundation
@testable import SunkCostCore

@Suite("Item disposition")
struct ItemDispositionTests {
    @Test("defaults to no disposition and no amount recovered")
    func defaultsToNil() {
        let item = Item(name: "Old Couch", category: "Furniture", cost: 500, status: .gone)
        #expect(item.disposition == nil)
        #expect(item.amountRecovered == nil)
    }

    @Test("disposition and amount recovered round-trip through JSON")
    func roundTrips() throws {
        let item = Item(name: "Old Couch", category: "Furniture", cost: 500, status: .gone, disposition: .sold, amountRecovered: 50)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(Item.self, from: data)

        #expect(decoded.disposition == .sold)
        #expect(decoded.amountRecovered == 50)
    }

    @Test("givenAway and trashed dispositions round-trip without an amount")
    func nonSoldDispositionsRoundTrip() throws {
        let givenAway = Item(name: "Old Chair", category: "Furniture", cost: 100, status: .gone, disposition: .givenAway)
        let trashed = Item(name: "Broken Lamp", category: "Furniture", cost: 20, status: .gone, disposition: .trashed)

        let decodedGivenAway = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(givenAway))
        let decodedTrashed = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(trashed))

        #expect(decodedGivenAway.disposition == .givenAway)
        #expect(decodedGivenAway.amountRecovered == nil)
        #expect(decodedTrashed.disposition == .trashed)
    }

    @Test("decoding JSON saved before disposition existed gives nil disposition and amount")
    func decodingPreDispositionJSONGivesNil() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Old Couch",
            "category": "Furniture",
            "cost": 500,
            "status": "gone"
        }
        """
        let decoded = try JSONDecoder().decode(Item.self, from: Data(json.utf8))

        #expect(decoded.disposition == nil)
        #expect(decoded.amountRecovered == nil)
    }

    @Test("items differing only in disposition are not equal")
    func equatableAccountsForDisposition() {
        let sold = Item(name: "Old Couch", category: "Furniture", cost: 500, status: .gone, disposition: .sold)
        let trashed = Item(name: "Old Couch", category: "Furniture", cost: 500, status: .gone, disposition: .trashed)

        #expect(sold != trashed)
    }
}
