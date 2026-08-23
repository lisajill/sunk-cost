import Foundation

public enum MortgageMath {
    /// Standard fixed-rate amortization formula, computed with Decimal
    /// throughout (via repeated multiplication for the exponent, since
    /// Decimal has no built-in pow) to avoid floating-point drift on
    /// currency figures.
    public static func monthlyPayment(
        principal: Decimal,
        annualRatePercent: Decimal,
        termYears: Int
    ) -> Decimal? {
        guard principal > 0, termYears > 0 else { return nil }

        let numberOfPayments = termYears * 12
        let monthlyRate = (annualRatePercent / 100) / 12

        guard monthlyRate > 0 else {
            return principal / Decimal(numberOfPayments)
        }

        var growthFactor = Decimal(1)
        let onePlusRate = 1 + monthlyRate
        for _ in 0..<numberOfPayments {
            growthFactor *= onePlusRate
        }

        return principal * monthlyRate * growthFactor / (growthFactor - 1)
    }

    /// How much principal is still owed after `monthsElapsed` payments on a
    /// standard fixed-rate loan -- floored at 0 once the term is exceeded,
    /// since the closed-form amortization formula isn't guaranteed to land
    /// on exactly 0 (or could dip slightly negative) past the loan's own
    /// term length.
    public static func remainingBalance(
        principal: Decimal,
        annualRatePercent: Decimal,
        termYears: Int,
        monthsElapsed: Int
    ) -> Decimal {
        let numberOfPayments = termYears * 12
        guard monthsElapsed < numberOfPayments else { return 0 }
        guard monthsElapsed > 0 else { return principal }

        let monthlyRate = (annualRatePercent / 100) / 12
        guard monthlyRate > 0 else {
            let payment = principal / Decimal(numberOfPayments)
            return principal - payment * Decimal(monthsElapsed)
        }

        var growthFactor = Decimal(1)
        let onePlusRate = 1 + monthlyRate
        for _ in 0..<monthsElapsed {
            growthFactor *= onePlusRate
        }

        let payment = monthlyPayment(principal: principal, annualRatePercent: annualRatePercent, termYears: termYears) ?? 0
        let balance = principal * growthFactor - payment * (growthFactor - 1) / monthlyRate
        return max(balance, 0)
    }
}
