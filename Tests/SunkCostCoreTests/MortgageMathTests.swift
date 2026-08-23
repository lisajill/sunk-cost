import Testing
import Foundation
@testable import SunkCostCore

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

    @Test("remaining balance with zero months elapsed equals the original principal")
    func remainingBalanceZeroElapsedEqualsPrincipal() {
        let balance = MortgageMath.remainingBalance(
            principal: 300_000, annualRatePercent: 4, termYears: 30, monthsElapsed: 0
        )
        #expect(balance == 300_000)
    }

    @Test("zero-interest remaining balance pays down linearly")
    func zeroInterestRemainingBalancePaysDownLinearly() {
        // Same numbers as the zero-interest monthly payment test: $120,000
        // over 10 years (120 months) at 0% is $1,000/mo, so 12 months in,
        // exactly $12,000 should be paid off.
        let balance = MortgageMath.remainingBalance(
            principal: 120_000, annualRatePercent: 0, termYears: 10, monthsElapsed: 12
        )
        #expect(balance == 108_000)
    }

    @Test("remaining balance is essentially zero once the full term has elapsed")
    func remainingBalanceNearZeroAtFullTerm() {
        let balance = MortgageMath.remainingBalance(
            principal: 300_000, annualRatePercent: 4, termYears: 30, monthsElapsed: 360
        )
        #expect(abs(balance) < 1)
    }

    @Test("remaining balance floors at zero past the loan term")
    func remainingBalanceFloorsAtZeroPastTerm() {
        let balance = MortgageMath.remainingBalance(
            principal: 300_000, annualRatePercent: 4, termYears: 30, monthsElapsed: 372
        )
        #expect(balance == 0)
    }
}
