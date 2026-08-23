import Testing
import Foundation
@testable import SunkCostCore

@Suite("Totals calculation")
struct TotalsTests {
    @Test("total spent is sum of owned plus gone costs")
    func totalSpentIsOwnedPlusGone() {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned),
            Item(name: "Old TV", category: "Furniture", cost: 200, status: .gone),
            Item(name: "New Deck", category: "Property Upgrades", cost: 5000, status: .planned)
        ]

        let totals = Totals(items: items)

        #expect(totals.totalSpent == 1200)
    }

    @Test("in the house is sum of owned costs only")
    func inTheHouseIsOwnedOnly() {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned),
            Item(name: "Old TV", category: "Furniture", cost: 200, status: .gone)
        ]

        let totals = Totals(items: items)

        #expect(totals.inTheHouse == 1000)
    }

    @Test("gone but paid for is sum of gone costs only")
    func goneButPaidForIsGoneOnly() {
        let items = [
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned),
            Item(name: "Old TV", category: "Furniture", cost: 200, status: .gone)
        ]

        let totals = Totals(items: items)

        #expect(totals.goneButPaidFor == 200)
    }

    @Test("planned not spent is sum of planned costs only")
    func plannedNotSpentIsPlannedOnly() {
        let items = [
            Item(name: "New Deck", category: "Property Upgrades", cost: 5000, status: .planned),
            Item(name: "Couch", category: "Furniture", cost: 1000, status: .owned)
        ]

        let totals = Totals(items: items)

        #expect(totals.plannedNotSpent == 5000)
    }

    @Test("blank cost items contribute zero to every total")
    func blankCostContributesZero() {
        let items = [
            Item(name: "Ceiling Fan", category: "Property Upgrades", cost: nil, status: .planned)
        ]

        let totals = Totals(items: items)

        #expect(totals.totalSpent == 0)
        #expect(totals.plannedNotSpent == 0)
    }

    @Test("empty item list gives all-zero totals")
    func emptyListGivesZeroTotals() {
        let totals = Totals(items: [])

        #expect(totals.totalSpent == 0)
        #expect(totals.inTheHouse == 0)
        #expect(totals.goneButPaidFor == 0)
        #expect(totals.plannedNotSpent == 0)
    }
}
