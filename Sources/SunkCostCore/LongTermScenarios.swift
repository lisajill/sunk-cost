import Foundation

/// Ending home equity after `projectionYears`, assuming the home
/// appreciates and the existing mortgage continues amortizing on its
/// actual schedule from `monthsAlreadyPaid` in.
public func projectStayingNetWorth(
    homeValue: Decimal,
    appreciationPercent: Decimal,
    mortgageOriginalAmount: Decimal,
    mortgageAnnualRatePercent: Decimal,
    mortgageTermYears: Int,
    monthsAlreadyPaid: Int,
    projectionYears: Int
) -> Decimal {
    let appreciatedValue = compoundedValue(principal: homeValue, annualRatePercent: appreciationPercent, years: projectionYears)
    let balance = MortgageMath.remainingBalance(
        principal: mortgageOriginalAmount,
        annualRatePercent: mortgageAnnualRatePercent,
        termYears: mortgageTermYears,
        monthsElapsed: monthsAlreadyPaid + projectionYears * 12
    )
    return appreciatedValue - balance
}

/// Ending investment balance after `projectionYears`, if today's net sale
/// proceeds were invested instead of buying or renting.
/// `upfrontCosts` -- a security deposit, pet deposit(s), anything paid out
/// of pocket to move in -- comes off the top before the rest is invested,
/// the same way a down payment reduces what's left over to invest in the
/// Buying Elsewhere scenario. Floors at zero rather than going negative if
/// costs happen to exceed the proceeds.
public func projectRentingNetWorth(
    netProceedsToday: Decimal,
    investmentReturnPercent: Decimal,
    projectionYears: Int,
    upfrontCosts: Decimal = 0
) -> Decimal {
    let investedPrincipal = max(netProceedsToday - upfrontCosts, 0)
    return compoundedValue(principal: investedPrincipal, annualRatePercent: investmentReturnPercent, years: projectionYears)
}

/// Ending home equity in a new home after `projectionYears`, bought today
/// with `downPayment` toward `newHomePrice` and a fresh mortgage for the
/// rest -- plus, whenever `netProceedsAvailable` (what selling today
/// actually nets) is more than what actually went into the house, the
/// leftover cash invested and compounding, exactly like the Renting
/// scenario does with its own proceeds. That leftover shows up whenever
/// less than the full sale proceeds is chosen as a down payment (the
/// normal case -- putting 20% down rather than everything), and also
/// when the down payment itself is more than the new home costs.
public func projectBuyingElsewhereNetWorth(
    newHomePrice: Decimal,
    downPayment: Decimal,
    netProceedsAvailable: Decimal,
    appreciationPercent: Decimal,
    newMortgageAnnualRatePercent: Decimal,
    newMortgageTermYears: Int,
    projectionYears: Int,
    leftoverCashInvestmentReturnPercent: Decimal
) -> Decimal {
    let actualDownPayment = min(downPayment, newHomePrice)
    let leftoverCash = max(netProceedsAvailable - actualDownPayment, 0)

    let appreciatedValue = compoundedValue(principal: newHomePrice, annualRatePercent: appreciationPercent, years: projectionYears)
    let balance = MortgageMath.remainingBalance(
        principal: newHomePrice - actualDownPayment,
        annualRatePercent: newMortgageAnnualRatePercent,
        termYears: newMortgageTermYears,
        monthsElapsed: projectionYears * 12
    )
    let compoundedLeftoverCash = compoundedValue(principal: leftoverCash, annualRatePercent: leftoverCashInvestmentReturnPercent, years: projectionYears)

    return appreciatedValue - balance + compoundedLeftoverCash
}
