import Foundation

public struct SellScenario: Equatable, Sendable {
    public let sellingCosts: Decimal
    public let netProceeds: Decimal
    /// nil when `totalInvested` (purchase price + Value spending) isn't
    /// known yet -- net proceeds can still be shown without it.
    public let netProfitOrLoss: Decimal?
}

/// What selling the house today would net, after realtor commission and
/// closing costs (both assumed percentages of Home Value) pay off the
/// mortgage balance. nil when Home Value or the mortgage balance isn't
/// known yet.
public func computeSellScenario(
    homeValue: Decimal?,
    mortgageBalance: Decimal?,
    realtorCommissionPercent: Decimal,
    closingCostsPercent: Decimal,
    totalInvested: Decimal?
) -> SellScenario? {
    guard let homeValue, let mortgageBalance else { return nil }
    let sellingCosts = homeValue * (realtorCommissionPercent + closingCostsPercent) / 100
    let netProceeds = homeValue - sellingCosts - mortgageBalance
    let netProfitOrLoss = totalInvested.map { netProceeds - $0 }
    return SellScenario(sellingCosts: sellingCosts, netProceeds: netProceeds, netProfitOrLoss: netProfitOrLoss)
}
