import Testing
import Foundation
@testable import SunkCostCore

@Suite("Property tax")
struct PropertyTaxTests {
    @Test("computes a monthly amount from an annual percent of home value")
    func computesMonthlyAmount() {
        // $400,000 at 1.2%/year = $4,800/year = $400/month
        let tax = monthlyPropertyTax(homeValue: 400_000, annualTaxPercent: 1.2)
        #expect(tax == 400)
    }

    @Test("zero percent gives zero tax")
    func zeroPercentGivesZero() {
        #expect(monthlyPropertyTax(homeValue: 400_000, annualTaxPercent: 0) == 0)
    }
}
