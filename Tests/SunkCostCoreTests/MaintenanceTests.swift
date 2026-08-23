import Testing
import Foundation
@testable import SunkCostCore

@Suite("Maintenance category and payment")
struct MaintenanceTests {
    @Test("category round-trips through JSON, including optional expected amount")
    func categoryRoundTrips() throws {
        let category = MaintenanceCategory(name: "Oil", expectedMonthlyAmount: 200)
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: data)

        #expect(decoded.name == "Oil")
        #expect(decoded.expectedMonthlyAmount == 200)
    }

    @Test("category with no expected amount round-trips as nil")
    func categoryWithoutExpectedAmountRoundTrips() throws {
        let category = MaintenanceCategory(name: "Landscaping", expectedMonthlyAmount: nil)
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: data)

        #expect(decoded.expectedMonthlyAmount == nil)
    }

    @Test("payment round-trips through JSON, including optional notes")
    func paymentRoundTrips() throws {
        let categoryID = UUID()
        let payment = MaintenancePayment(
            categoryID: categoryID,
            amount: 185.50,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            notes: "November delivery, #winter"
        )
        let data = try JSONEncoder().encode(payment)
        let decoded = try JSONDecoder().decode(MaintenancePayment.self, from: data)

        #expect(decoded.categoryID == categoryID)
        #expect(decoded.amount == 185.50)
        #expect(decoded.notes == "November delivery, #winter")
    }
}
