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

    @Test("category notes round-trip through JSON")
    func categoryNotesRoundTrip() throws {
        let category = MaintenanceCategory(name: "Oil", monthlyAmount: 200, notes: "Delivered by #AcmeOil, **call ahead**")
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: data)

        #expect(decoded.notes == "Delivered by #AcmeOil, **call ahead**")
    }

    @Test("category with no notes decodes as nil")
    func categoryWithoutNotesDecodesAsNil() throws {
        let category = MaintenanceCategory(name: "Oil", monthlyAmount: 200)
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: data)

        #expect(decoded.notes == nil)
    }

    @Test("decoding JSON saved before notes existed gives nil notes")
    func decodingPreNotesJSONGivesNil() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "name": "Oil",
            "monthlyAmount": 200
        }
        """
        let decoded = try JSONDecoder().decode(MaintenanceCategory.self, from: Data(json.utf8))

        #expect(decoded.notes == nil)
    }
}
