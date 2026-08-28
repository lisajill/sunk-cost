import Foundation

/// Ending home equity after `projectionYears`: the home appreciates while
/// the mortgage amortizes forward from `currentMortgageBalance`, paying
/// `monthlyPayment` each month at `mortgageAnnualRatePercent`. The balance
/// floors at zero once the loan is paid off within the horizon.
///
/// Amortizing from the *current* balance -- rather than reconstructing it
/// from the original loan amount and a payment count -- means a
/// hand-updated balance is respected: extra principal payments, a recast,
/// or a missed payment all show up as a different starting point. The
/// caller decides whether "current balance" is the figure the user
/// maintains by hand or one modeled from the original loan's schedule.
public func projectStayingNetWorth(
    homeValue: Decimal,
    appreciationPercent: Decimal,
    currentMortgageBalance: Decimal,
    monthlyPayment: Decimal,
    mortgageAnnualRatePercent: Decimal,
    projectionYears: Int
) -> Decimal {
    let appreciatedValue = compoundedValue(principal: homeValue, annualRatePercent: appreciationPercent, years: projectionYears)

    let monthlyRate = (mortgageAnnualRatePercent / 100) / 12
    var balance = currentMortgageBalance
    for _ in 0..<max(projectionYears * 12, 0) {
        guard balance > 0 else { break }
        balance = balance * (1 + monthlyRate) - monthlyPayment
    }

    return appreciatedValue - max(balance, 0)
}

/// Ending investment balance after `projectionYears`, if today's net sale
/// proceeds were invested instead of buying or renting.
/// `upfrontCosts` -- a security deposit, pet deposit(s), anything paid out
/// of pocket to move in -- comes off the top before the rest is invested,
/// the same way a down payment reduces what's left over to invest in the
/// Buying Elsewhere scenario. The invested principal floors at zero rather
/// than going negative if move-in costs exceed the proceeds.
///
/// If the *sale itself* is underwater -- `netProceedsToday` is negative,
/// i.e. cash has to be brought to closing -- that shortfall is carried as
/// a separate negative balance compounding at the same investment return,
/// on the reasoning that the cash would otherwise have stayed invested.
/// (This is a modeling choice; a flat, non-compounding shortfall would
/// also be defensible.)
public func projectRentingNetWorth(
    netProceedsToday: Decimal,
    investmentReturnPercent: Decimal,
    projectionYears: Int,
    upfrontCosts: Decimal = 0
) -> Decimal {
    let usableProceeds = max(netProceedsToday, 0)
    let investedPrincipal = max(usableProceeds - upfrontCosts, 0)
    let closingShortfall = min(netProceedsToday, 0)
    return compoundedValue(principal: investedPrincipal, annualRatePercent: investmentReturnPercent, years: projectionYears)
        + compoundedValue(principal: closingShortfall, annualRatePercent: investmentReturnPercent, years: projectionYears)
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
    // Clamp the down payment into [0, newHomePrice]: a negative figure
    // (which the caller can produce by defaulting it to underwater sale
    // proceeds) would otherwise inflate the new mortgage above the home's
    // price.
    let actualDownPayment = min(max(downPayment, 0), newHomePrice)
    let usableProceeds = max(netProceedsAvailable, 0)
    let leftoverCash = max(usableProceeds - actualDownPayment, 0)
    // Underwater sale: cash brought to closing, carried as a negative
    // balance compounding at the investment return -- same treatment as
    // the Renting scenario. See `projectRentingNetWorth`.
    let closingShortfall = min(netProceedsAvailable, 0)

    let appreciatedValue = compoundedValue(principal: newHomePrice, annualRatePercent: appreciationPercent, years: projectionYears)
    let balance = MortgageMath.remainingBalance(
        principal: newHomePrice - actualDownPayment,
        annualRatePercent: newMortgageAnnualRatePercent,
        termYears: newMortgageTermYears,
        monthsElapsed: projectionYears * 12
    )
    let compoundedLeftoverCash = compoundedValue(principal: leftoverCash, annualRatePercent: leftoverCashInvestmentReturnPercent, years: projectionYears)
    let compoundedShortfall = compoundedValue(principal: closingShortfall, annualRatePercent: leftoverCashInvestmentReturnPercent, years: projectionYears)

    return appreciatedValue - balance + compoundedLeftoverCash + compoundedShortfall
}
