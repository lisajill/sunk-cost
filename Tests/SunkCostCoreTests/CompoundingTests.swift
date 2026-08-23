import Testing
import Foundation
@testable import SunkCostCore

@Suite("Compounding")
struct CompoundingTests {
    @Test("zero years returns the principal unchanged")
    func zeroYearsReturnsPrincipal() {
        #expect(compoundedValue(principal: 100_000, annualRatePercent: 6, years: 0) == 100_000)
    }

    @Test("zero rate returns the principal unchanged regardless of years")
    func zeroRateReturnsPrincipal() {
        #expect(compoundedValue(principal: 100_000, annualRatePercent: 0, years: 10) == 100_000)
    }

    @Test("compounds annually at a known rate")
    func compoundsAtKnownRate() {
        // $100,000 at 10%/year for 2 years -> 100,000 * 1.1 * 1.1 = 121,000
        #expect(compoundedValue(principal: 100_000, annualRatePercent: 10, years: 2) == 121_000)
    }
}
