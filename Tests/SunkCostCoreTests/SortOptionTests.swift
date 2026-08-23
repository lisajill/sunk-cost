import Testing
import Foundation
@testable import SunkCostCore

@Suite("Sort options")
struct SortOptionTests {
    private let items: [Item] = [
        Item(name: "Banana Chair", category: "Furniture", cost: 200, status: .owned, dateAdded: Date(timeIntervalSince1970: 2000)),
        Item(name: "Apple Desk", category: "Furniture", cost: 500, status: .owned, dateAdded: Date(timeIntervalSince1970: 1000)),
        Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned, dateAdded: Date(timeIntervalSince1970: 3000)),
    ]

    @Test("dateNewest orders by dateAdded descending")
    func dateNewestOrdersDescending() {
        let result = items.sorted(using: .dateNewest)
        #expect(result.map(\.name) == ["Ceiling Fan", "Banana Chair", "Apple Desk"])
    }

    @Test("dateOldest orders by dateAdded ascending")
    func dateOldestOrdersAscending() {
        let result = items.sorted(using: .dateOldest)
        #expect(result.map(\.name) == ["Apple Desk", "Banana Chair", "Ceiling Fan"])
    }

    @Test("nameAZ orders alphabetically ascending")
    func nameAZOrdersAscending() {
        let result = items.sorted(using: .nameAZ)
        #expect(result.map(\.name) == ["Apple Desk", "Banana Chair", "Ceiling Fan"])
    }

    @Test("nameZA orders alphabetically descending")
    func nameZAOrdersDescending() {
        let result = items.sorted(using: .nameZA)
        #expect(result.map(\.name) == ["Ceiling Fan", "Banana Chair", "Apple Desk"])
    }

    @Test("costHighLow orders by cost descending, blank costs last")
    func costHighLowOrdersDescendingBlankLast() {
        let result = items.sorted(using: .costHighLow)
        #expect(result.map(\.name) == ["Apple Desk", "Banana Chair", "Ceiling Fan"])
    }

    @Test("costLowHigh orders by cost ascending, blank costs last")
    func costLowHighOrdersAscendingBlankLast() {
        let result = items.sorted(using: .costLowHigh)
        #expect(result.map(\.name) == ["Banana Chair", "Apple Desk", "Ceiling Fan"])
    }

    @Test("dateNewest puts items with no date on record last")
    func dateNewestPutsBlankDatesLast() {
        let withBlank: [Item] = [
            Item(name: "No Date", category: "Furniture", cost: 1, status: .owned, dateAdded: nil),
            Item(name: "Has Date", category: "Furniture", cost: 1, status: .owned, dateAdded: Date(timeIntervalSince1970: 1000)),
        ]

        let result = withBlank.sorted(using: .dateNewest)

        #expect(result.map(\.name) == ["Has Date", "No Date"])
    }

    @Test("dateOldest also puts items with no date on record last")
    func dateOldestPutsBlankDatesLast() {
        let withBlank: [Item] = [
            Item(name: "No Date", category: "Furniture", cost: 1, status: .owned, dateAdded: nil),
            Item(name: "Has Date", category: "Furniture", cost: 1, status: .owned, dateAdded: Date(timeIntervalSince1970: 1000)),
        ]

        let result = withBlank.sorted(using: .dateOldest)

        #expect(result.map(\.name) == ["Has Date", "No Date"])
    }

    @Test("tapping the Date column while already newest-first switches to oldest-first")
    func tappingDateColumnTogglesFromNewestToOldest() {
        #expect(toggledSortOption(current: .dateNewest, tapped: .date) == .dateOldest)
    }

    @Test("tapping the Date column from any other sort defaults to newest-first")
    func tappingDateColumnFromOtherSortDefaultsToNewest() {
        #expect(toggledSortOption(current: .nameAZ, tapped: .date) == .dateNewest)
        #expect(toggledSortOption(current: .dateOldest, tapped: .date) == .dateNewest)
    }

    @Test("tapping the Item column while already A-Z switches to Z-A")
    func tappingItemColumnTogglesFromAZToZA() {
        #expect(toggledSortOption(current: .nameAZ, tapped: .item) == .nameZA)
    }

    @Test("tapping the Item column from any other sort defaults to A-Z")
    func tappingItemColumnFromOtherSortDefaultsToAZ() {
        #expect(toggledSortOption(current: .dateNewest, tapped: .item) == .nameAZ)
        #expect(toggledSortOption(current: .nameZA, tapped: .item) == .nameAZ)
    }

    @Test("tapping the Amount column while already high-to-low switches to low-to-high")
    func tappingAmountColumnTogglesFromHighLowToLowHigh() {
        #expect(toggledSortOption(current: .costHighLow, tapped: .amount) == .costLowHigh)
    }

    @Test("tapping the Amount column from any other sort defaults to high-to-low")
    func tappingAmountColumnFromOtherSortDefaultsToHighLow() {
        #expect(toggledSortOption(current: .dateNewest, tapped: .amount) == .costHighLow)
        #expect(toggledSortOption(current: .costLowHigh, tapped: .amount) == .costHighLow)
    }
}
