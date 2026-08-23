import Testing
import Foundation
@testable import SunkCostCore

@Suite("Maintenance category")
struct MaintenanceTests {
    @Test("category round-trips through JSON")
    func categoryRoundTrips() throws {
        let category = MaintenanceCategory(name: "Oil", monthlyAmount: 200)
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: data)

        #expect(decoded.name == "Oil")
        #expect(decoded.monthlyAmount == 200)
    }
}
