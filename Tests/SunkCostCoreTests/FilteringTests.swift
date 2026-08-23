import Testing
import Foundation
@testable import SunkCostCore

@Suite("Filtering and categories")
struct FilteringTests {
    let items = [
        Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned),
        Item(name: "Old TV", category: "Furniture", cost: 200, status: .gone),
        Item(name: "Deck", category: "Property Upgrades", cost: 5000, status: .planned),
        Item(name: "Fence", category: "Property Upgrades", cost: 3000, status: .owned)
    ]

    @Test("no filter returns all items")
    func noFilterReturnsAll() {
        let result = items.filtered(by: ItemFilter())
        #expect(result.count == 4)
    }

    @Test("category filter narrows to matching category")
    func categoryFilterNarrowsResults() {
        let result = items.filtered(by: ItemFilter(category: "Furniture"))
        #expect(result.map(\.name).sorted() == ["Couch", "Old TV"])
    }

    @Test("status filter narrows to matching status")
    func statusFilterNarrowsResults() {
        let result = items.filtered(by: ItemFilter(status: .owned))
        #expect(result.map(\.name).sorted() == ["Couch", "Fence"])
    }

    @Test("category and status filters combine")
    func categoryAndStatusFiltersCombine() {
        let result = items.filtered(by: ItemFilter(category: "Property Upgrades", status: .owned))
        #expect(result.map(\.name) == ["Fence"])
    }

    @Test("distinct categories are unique and sorted")
    func distinctCategoriesAreUniqueAndSorted() {
        #expect(items.distinctCategories == ["Furniture", "Property Upgrades"])
    }
}
