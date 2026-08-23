import Testing
import Foundation
@testable import SunkCostCore

@Suite("Comparison scenario")
struct ComparisonScenarioTests {
    @Test("round-trips through JSON")
    func roundTrips() throws {
        let scenario = ComparisonScenario(
            name: "Downsize to condo",
            projectionYears: 10,
            homeAppreciationPercent: 3,
            investmentReturnPercent: 6,
            monthlyRent: 2400,
            rentAnnualIncreasePercent: 3,
            newHomePrice: 300_000,
            newHomeDownPayment: 100_000,
            newMortgageRatePercent: 7,
            newMortgageTermYears: 30,
            propertyTaxPercent: 1.3,
            homeownersInsuranceAnnual: 1500,
            newPropertyTaxPercent: 1.2,
            newHomeownersInsuranceAnnual: 3000,
            notes: "Assumes we refinance the new place at close."
        )
        let data = try JSONEncoder().encode(scenario)
        let decoded = try JSONDecoder().decode(ComparisonScenario.self, from: data)

        #expect(decoded == scenario)
    }

    @Test("fields default to nil when not provided")
    func fieldsDefaultToNil() {
        let scenario = ComparisonScenario(name: "Blank")
        #expect(scenario.projectionYears == nil)
        #expect(scenario.newHomePrice == nil)
        #expect(scenario.notes == nil)
    }
}
