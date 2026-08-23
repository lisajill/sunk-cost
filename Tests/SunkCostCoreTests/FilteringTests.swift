import Testing
import Foundation
@testable import SunkCostCore

@Suite("Filtering and categories")
struct FilteringTests {
    let items = [
        Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned, notes: "From the #livingroom set"),
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

    @Test("search text matches name case-insensitively")
    func searchMatchesNameCaseInsensitively() {
        let result = items.filtered(by: ItemFilter(searchText: "couch"))
        #expect(result.map(\.name) == ["Couch"])
    }

    @Test("search text matches category")
    func searchMatchesCategory() {
        let result = items.filtered(by: ItemFilter(searchText: "upgrades"))
        #expect(result.map(\.name).sorted() == ["Deck", "Fence"])
    }

    @Test("search text matches notes, including hashtags")
    func searchMatchesNotes() {
        let result = items.filtered(by: ItemFilter(searchText: "livingroom"))
        #expect(result.map(\.name) == ["Couch"])
    }

    @Test("blank search text matches everything")
    func blankSearchMatchesEverything() {
        let result = items.filtered(by: ItemFilter(searchText: "   "))
        #expect(result.count == items.count)
    }

    @Test("search combines with category and status filters")
    func searchCombinesWithOtherFilters() {
        let result = items.filtered(by: ItemFilter(category: "Property Upgrades", status: .owned, searchText: "fence"))
        #expect(result.map(\.name) == ["Fence"])
    }
}
