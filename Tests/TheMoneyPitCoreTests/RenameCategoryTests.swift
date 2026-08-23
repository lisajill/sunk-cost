import Testing
@testable import TheMoneyPitCore

@Suite("Rename category")
struct RenameCategoryTests {
    @Test("renames the category on every matching item")
    func renamesMatchingItems() {
        let items = [
            Item(name: "Couch", category: "Furnature", cost: 1000, status: .owned),
            Item(name: "Chair", category: "Furnature", cost: 200, status: .owned),
        ]

        let renamed = items.renamingCategory(from: "Furnature", to: "Furniture")

        #expect(renamed.allSatisfy { $0.category == "Furniture" })
    }

    @Test("leaves items in other categories untouched")
    func leavesOtherCategoriesUntouched() {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned),
            Item(name: "Fence", category: "Property Upgrades", cost: 3000, status: .owned),
        ]

        let renamed = items.renamingCategory(from: "Furniture", to: "Home Goods")

        #expect(renamed[0].category == "Home Goods")
        #expect(renamed[1].category == "Property Upgrades")
    }

    @Test("renaming into an existing category merges them")
    func renamingIntoExistingCategoryMerges() {
        let items = [
            Item(name: "Couch", category: "Stuff", cost: 1000, status: .owned),
            Item(name: "Chair", category: "Furniture", cost: 200, status: .owned),
        ]

        let renamed = items.renamingCategory(from: "Stuff", to: "Furniture")

        #expect(renamed.distinctCategories == ["Furniture"])
    }
}
