import Testing
import Foundation
@testable import SunkCostCore

@Suite("Item type")
struct ItemTypeTests {
    @Test("new items default to moveable when type isn't specified")
    func newItemsDefaultToMoveable() {
        let item = Item(name: "Couch", category: "Furniture", cost: 500, status: .owned)
        #expect(item.type == .moveable)
    }

    @Test("type round-trips through JSON")
    func typeRoundTripsThroughJSON() throws {
        let item = Item(name: "Fence", category: "Property Upgrades", cost: 8500, status: .owned, type: .value)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(Item.self, from: data)
        #expect(decoded.type == .value)
    }

    @Test("decoding JSON with no type key at all falls back to moveable")
    func decodingWithoutTypeKeyFallsBackToMoveable() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Old Item",
            "category": "Furniture",
            "cost": 100,
            "status": "owned"
        }
        """
        let decoded = try JSONDecoder().decode(Item.self, from: Data(json.utf8))
        #expect(decoded.type == .moveable)
    }

    @Test("Equatable compares type")
    func equatableComparesType() {
        let a = Item(name: "Fence", category: "Property Upgrades", cost: 100, status: .owned, type: .value)
        let b = Item(name: "Fence", category: "Property Upgrades", cost: 100, status: .owned, type: .moveable)
        #expect(a != b)
    }
}
