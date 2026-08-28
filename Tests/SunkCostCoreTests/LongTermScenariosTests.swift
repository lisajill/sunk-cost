import Testing
import Foundation
@testable import SunkCostCore

@Suite("Long-term scenario projections")
struct LongTermScenariosTests {
    @Test("staying net worth: appreciated home value minus the mortgage amortized forward")
    func stayingNetWorth() {
        // $348,000 balance today, $1,000/mo at 0% -> after a 1-year
        // projection (12 payments) $336,000 remains. 0% appreciation keeps
        // the home value flat at $360,000.
        let netWorth = projectStayingNetWorth(
            homeValue: 360_000,
            appreciationPercent: 0,
            currentMortgageBalance: 348_000,
            monthlyPayment: 1_000,
            mortgageAnnualRatePercent: 0,
            projectionYears: 1
        )
        #expect(netWorth == 24_000) // 360,000 - 336,000
    }

    @Test("staying net worth reflects a fully paid-off mortgage once the horizon exceeds the payoff")
    func stayingNetWorthMortgagePaidOff() {
        // $360,000 balance at $6,000/mo (0%) is paid off in 60 months; a
        // 10-year projection runs well past that, so the balance floors at
        // zero rather than going negative.
        let netWorth = projectStayingNetWorth(
            homeValue: 360_000,
            appreciationPercent: 0,
            currentMortgageBalance: 360_000,
            monthlyPayment: 6_000,
            mortgageAnnualRatePercent: 0,
            projectionYears: 10
        )
        #expect(netWorth == 360_000) // mortgage long paid off, full home value
    }

    @Test("staying net worth amortizes from the passed-in balance, not a reconstructed schedule")
    func stayingNetWorthRespectsCurrentBalance() {
        // Two identical loans except the second has had extra principal
        // thrown at it -- a lower current balance -> higher ending equity.
        let onSchedule = projectStayingNetWorth(
            homeValue: 400_000, appreciationPercent: 0,
            currentMortgageBalance: 200_000, monthlyPayment: 2_000,
            mortgageAnnualRatePercent: 0, projectionYears: 1
        )
        let paidAhead = projectStayingNetWorth(
            homeValue: 400_000, appreciationPercent: 0,
            currentMortgageBalance: 170_000, monthlyPayment: 2_000,
            mortgageAnnualRatePercent: 0, projectionYears: 1
        )
        #expect(onSchedule == 224_000) // 400k - (200k - 24k)
        #expect(paidAhead == 254_000) // 400k - (170k - 24k)
    }

    @Test("renting net worth is the sale proceeds compounded at the investment return")
    func rentingNetWorth() {
        let netWorth = projectRentingNetWorth(netProceedsToday: 100_000, investmentReturnPercent: 10, projectionYears: 2)
        #expect(netWorth == 121_000) // 100,000 * 1.1 * 1.1
    }

    @Test("renting net worth subtracts upfront move-in costs (deposits) before investing the rest")
    func rentingNetWorthSubtractsUpfrontCosts() {
        // $100,000 proceeds minus $5,000 in deposits = $95,000 invested,
        // compounded at 10% for 2 years.
        let netWorth = projectRentingNetWorth(
            netProceedsToday: 100_000,
            investmentReturnPercent: 10,
            projectionYears: 2,
            upfrontCosts: 5_000
        )
        #expect(netWorth == 114_950) // 95,000 * 1.1 * 1.1
    }

    @Test("renting net worth charges deposits paid from savings beyond the sale proceeds")
    func rentingNetWorthChargesDepositsFromSavings() {
        // $3,000 proceeds, $5,000 in deposits: nothing left to invest, and
        // the $2,000 gap comes out of savings -- carried as a compounding
        // negative balance, not floored away.
        let netWorth = projectRentingNetWorth(
            netProceedsToday: 3_000,
            investmentReturnPercent: 10,
            projectionYears: 2,
            upfrontCosts: 5_000
        )
        #expect(netWorth == -2_420) // -2,000 * 1.1 * 1.1
    }

    @Test("renting net worth stacks an underwater sale and deposits both paid from savings")
    func rentingNetWorthStacksUnderwaterSaleAndDeposits() {
        // -$5,000 proceeds (cash to closing) plus $3,000 deposits, all from
        // savings: an $8,000 hole, compounded at 10% for 2 years.
        let netWorth = projectRentingNetWorth(
            netProceedsToday: -5_000,
            investmentReturnPercent: 10,
            projectionYears: 2,
            upfrontCosts: 3_000
        )
        #expect(netWorth == -9_680) // -8,000 * 1.1 * 1.1
    }

    @Test("renting net worth carries an underwater sale as a compounding negative balance")
    func rentingNetWorthCarriesUnderwaterSale() {
        // Selling costs $20,000 more than the house is worth -- that cash
        // goes to closing instead of staying invested, so it drags the
        // ending balance down, compounded at the investment return.
        let netWorth = projectRentingNetWorth(
            netProceedsToday: -20_000,
            investmentReturnPercent: 10,
            projectionYears: 2
        )
        #expect(netWorth == -24_200) // -20,000 * 1.1 * 1.1
    }

    @Test("buying elsewhere net worth: appreciated new home value minus remaining new mortgage balance")
    func buyingElsewhereNetWorth() {
        // $400,000 new home, $100,000 down -> $300,000 mortgage over 25
        // years (300 months) at 0% is exactly $1,000/mo. 2-year projection
        // = 24 months elapsed -> $24,000 paid off, $276,000 remaining.
        // Net proceeds available exactly match the down payment used, so
        // there's no leftover cash to credit.
        let netWorth = projectBuyingElsewhereNetWorth(
            newHomePrice: 400_000,
            downPayment: 100_000,
            netProceedsAvailable: 100_000,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 0,
            newMortgageTermYears: 25,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        #expect(netWorth == 124_000) // 400,000 - 276,000
    }

    @Test("buying elsewhere credits leftover cash when a smaller down payment than the sale proceeds is chosen")
    func buyingElsewhereNetWorthWithChosenSmallerDownPayment() {
        // The realistic case: selling nets $250,000, but only $100,000 is
        // put down on a $340,000 home (a $240,000 mortgage) -- the other
        // $150,000 doesn't just vanish, it's still hers, invested.
        // $240,000 over 20 years (240 months) at 0% is exactly $1,000/mo;
        // 24 months elapsed -> $24,000 paid off, $216,000 remaining.
        // Appreciated home value at 0% stays $340,000 -> $124,000 equity.
        // $150,000 leftover compounds at 10% for 2 years: 150,000 * 1.1 *
        // 1.1 = 181,500. Total: 305,500.
        let netWorth = projectBuyingElsewhereNetWorth(
            newHomePrice: 340_000,
            downPayment: 100_000,
            netProceedsAvailable: 250_000,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 0,
            newMortgageTermYears: 20,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        #expect(netWorth == 305_500)
    }

    @Test("buying elsewhere charges the part of the down payment topped up from savings")
    func buyingElsewhereNetWorthChargesDownPaymentToppedUpFromSavings() {
        // Same house/mortgage as the first test, but the sale nets only
        // $80,000 against a $100,000 down payment -- the $20,000 gap comes
        // from savings, so it's carried as a compounding negative balance
        // ($20,000 * 1.1 * 1.1 = $24,200) rather than appearing for free.
        let netWorth = projectBuyingElsewhereNetWorth(
            newHomePrice: 400_000,
            downPayment: 100_000,
            netProceedsAvailable: 80_000,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 0,
            newMortgageTermYears: 25,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        #expect(netWorth == 99_800) // 124,000 - 24,200
    }

    @Test("outsideCashUsed: zero when the sale covers what's committed, negative for any gap")
    func outsideCashUsedCases() {
        #expect(outsideCashUsed(netProceeds: 100_000, committed: 20_000) == 0)
        #expect(outsideCashUsed(netProceeds: 100_000, committed: 100_000) == 0)
        #expect(outsideCashUsed(netProceeds: 80_000, committed: 100_000) == -20_000)
        #expect(outsideCashUsed(netProceeds: -5_000, committed: 0) == -5_000)
        #expect(outsideCashUsed(netProceeds: -5_000, committed: 3_000) == -8_000)
    }

    @Test("buying elsewhere clamps a negative down payment and carries the closing shortfall")
    func buyingElsewhereNetWorthUnderwaterSale() {
        // The caller can hand this an underwater default (down payment ==
        // negative sale proceeds). The down payment must clamp to 0 (so the
        // new mortgage is the full home price, not more), and the negative
        // proceeds ride along as a compounding shortfall.
        let underwater = projectBuyingElsewhereNetWorth(
            newHomePrice: 300_000,
            downPayment: -25_000,
            netProceedsAvailable: -25_000,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 0,
            newMortgageTermYears: 30,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        let baseline = projectBuyingElsewhereNetWorth(
            newHomePrice: 300_000,
            downPayment: 0,
            netProceedsAvailable: 0,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 0,
            newMortgageTermYears: 30,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        // Same home, same (zero) down payment, same mortgage -- the only
        // difference is the $25,000 brought to closing, compounded at 10%.
        #expect(baseline - underwater == 30_250) // 25,000 * 1.1 * 1.1
    }

    @Test("buying elsewhere credits leftover cash when the down payment exceeds the new home's price")
    func buyingElsewhereNetWorthWithLeftoverCash() {
        // A $300,000 down payment on a $250,000 home means $50,000 never
        // goes into the house -- paid outright in cash, no mortgage, and
        // that $50,000 should still count, invested and compounding same
        // as it would in the Renting scenario.
        let netWorth = projectBuyingElsewhereNetWorth(
            newHomePrice: 250_000,
            downPayment: 300_000,
            netProceedsAvailable: 300_000,
            appreciationPercent: 0,
            newMortgageAnnualRatePercent: 5,
            newMortgageTermYears: 30,
            projectionYears: 2,
            leftoverCashInvestmentReturnPercent: 10
        )
        // No mortgage (paid outright): home value stays $250,000 (0%
        // appreciation). Leftover $50,000 compounds at 10% for 2 years:
        // 50,000 * 1.1 * 1.1 = 60,500. Total: 310,500.
        #expect(netWorth == 310_500)
    }
}
