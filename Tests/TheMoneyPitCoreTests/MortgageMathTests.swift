import Testing
import Foundation
@testable import TheMoneyPitCore

@Suite("Mortgage math")
struct MortgageMathTests {
    @Test("calculates a standard 30-year fixed monthly payment")
    func calculatesStandard30YearPayment() {
        // $300,000 at 4% for 30 years -> a well-known reference payment of ~$1,432.25
        let payment = MortgageMath.monthlyPayment(principal: 300_000, annualRatePercent: 4, termYears: 30)

        let expected = Decimal(1432.25)
        let difference = abs((payment ?? 0) - expected)
        #expect(difference < 1)
    }

    @Test("zero interest divides principal evenly across payments")
    func zeroInterestDividesEvenly() {
        let payment = MortgageMath.monthlyPayment(principal: 120_000, annualRatePercent: 0, termYears: 10)

        #expect(payment == 1000)
    }

    @Test("returns nil when principal is missing or non-positive")
    func returnsNilForNonPositivePrincipal() {
        #expect(MortgageMath.monthlyPayment(principal: 0, annualRatePercent: 4, termYears: 30) == nil)
        #expect(MortgageMath.monthlyPayment(principal: -100, annualRatePercent: 4, termYears: 30) == nil)
    }

    @Test("returns nil when term is zero or negative")
    func returnsNilForNonPositiveTerm() {
        #expect(MortgageMath.monthlyPayment(principal: 100_000, annualRatePercent: 4, termYears: 0) == nil)
    }
}
