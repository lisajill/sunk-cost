import Foundation

/// Simple annual compound growth -- `principal * (1 + rate)^years`, computed
/// via repeated multiplication (Decimal has no built-in pow), same
/// technique already used in `MortgageMath`.
public func compoundedValue(principal: Decimal, annualRatePercent: Decimal, years: Int) -> Decimal {
    guard years > 0 else { return principal }
    let annualRate = annualRatePercent / 100
    var value = principal
    for _ in 0..<years {
        value *= (1 + annualRate)
    }
    return value
}
