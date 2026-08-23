import Testing
@testable import SunkCostCore

@Suite("Equity calculation")
struct EquityTests {
    @Test("equity is home value minus mortgage balance when both are set")
    func equityIsHomeValueMinusMortgageBalance() {
        #expect(computeEquity(homeValue: 450_000, mortgageBalance: 75_000) == 375_000)
    }

    @Test("equity is nil when home value is missing")
    func equityIsNilWhenHomeValueMissing() {
        #expect(computeEquity(homeValue: nil, mortgageBalance: 75_000) == nil)
    }

    @Test("equity is nil when mortgage balance is missing")
    func equityIsNilWhenMortgageBalanceMissing() {
        #expect(computeEquity(homeValue: 450_000, mortgageBalance: nil) == nil)
    }

    @Test("equity can be negative when underwater")
    func equityCanBeNegative() {
        #expect(computeEquity(homeValue: 50_000, mortgageBalance: 75_000) == -25_000)
    }
}
