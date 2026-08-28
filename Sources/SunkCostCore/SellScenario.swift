import Foundation

public struct SellScenario: Equatable, Sendable {
    public let sellingCosts: Decimal
    public let netProceeds: Decimal
    /// Gain/loss on the house *as an asset*: `homeValue - sellingCosts -
    /// totalInvested`. Deliberately mortgage-independent -- how the
    /// purchase was financed doesn't change whether the property itself
    /// made or lost money, and folding the payoff in here would
    /// double-count it (it's already netted out of `netProceeds`). Matches
    /// `AppStore.netHouseGain`'s definition, just with selling costs taken
    /// out. nil when `totalInvested` (purchase price + Value spending)
    /// isn't known yet -- net proceeds can still be shown without it.
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
    let netProfitOrLoss = totalInvested.map { homeValue - sellingCosts - $0 }
    return SellScenario(sellingCosts: sellingCosts, netProceeds: netProceeds, netProfitOrLoss: netProfitOrLoss)
}
