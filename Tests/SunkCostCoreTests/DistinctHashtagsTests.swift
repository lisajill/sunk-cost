import Testing
@testable import SunkCostCore

@Suite("Distinct hashtags")
struct DistinctHashtagsTests {
    @Test("collects hashtags from every item's notes")
    func collectsHashtagsFromAllItems() {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned, notes: "From the #livingroom set"),
            Item(name: "Fence", category: "Property Upgrades", cost: 3000, status: .owned, notes: "#urgent, needs #warranty claim"),
        ]

        #expect(items.distinctHashtags == ["#livingroom", "#urgent", "#warranty"])
    }

    @Test("deduplicates and normalizes case")
    func deduplicatesAndNormalizesCase() {
        let items = [
            Item(name: "A", category: "Furniture", cost: 1, status: .owned, notes: "#Urgent"),
            Item(name: "B", category: "Furniture", cost: 1, status: .owned, notes: "#urgent"),
        ]

        #expect(items.distinctHashtags == ["#urgent"])
    }

    @Test("ignores items with no notes or no hashtags")
    func ignoresItemsWithNoHashtags() {
        let items = [
            Item(name: "A", category: "Furniture", cost: 1, status: .owned, notes: nil),
            Item(name: "B", category: "Furniture", cost: 1, status: .owned, notes: "just plain text"),
        ]

        #expect(items.distinctHashtags.isEmpty)
    }
}
