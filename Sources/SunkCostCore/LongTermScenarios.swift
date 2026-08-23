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
public func projectRentingNetWorth(
    netProceedsToday: Decimal,
    investmentReturnPercent: Decimal,
    projectionYears: Int
) -> Decimal {
    compoundedValue(principal: netProceedsToday, annualRatePercent: investmentReturnPercent, years: projectionYears)
}

/// Ending home equity in a new home after `projectionYears`, bought today
/// with `downPayment` toward `newHomePrice` and a fresh mortgage for the
/// rest.
public func projectBuyingElsewhereNetWorth(
    newHomePrice: Decimal,
    downPayment: Decimal,
    appreciationPercent: Decimal,
    newMortgageAnnualRatePercent: Decimal,
    newMortgageTermYears: Int,
    projectionYears: Int
) -> Decimal {
    let appreciatedValue = compoundedValue(principal: newHomePrice, annualRatePercent: appreciationPercent, years: projectionYears)
    let balance = MortgageMath.remainingBalance(
        principal: newHomePrice - downPayment,
        annualRatePercent: newMortgageAnnualRatePercent,
        termYears: newMortgageTermYears,
        monthsElapsed: projectionYears * 12
    )
    return appreciatedValue - balance
}
