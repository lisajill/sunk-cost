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
}
