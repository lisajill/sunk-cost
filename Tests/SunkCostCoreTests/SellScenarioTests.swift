import Testing
import Foundation
@testable import SunkCostCore

@Suite("Sell scenario")
struct SellScenarioTests {
    @Test("computes selling costs, net proceeds, and profit for a normal profit case")
    func normalProfitCase() {
        let scenario = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: 200_000,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 250_000
        )

        #expect(scenario?.sellingCosts == 40_000) // 8% of 500,000
        #expect(scenario?.netProceeds == 260_000) // 500,000 - 40,000 - 200,000
        #expect(scenario?.netProfitOrLoss == 210_000) // 500,000 - 40,000 - 250,000, mortgage-independent
    }

    @Test("computes a loss when the house is worth less than was put in, net of selling costs")
    func lossCase() {
        let scenario = computeSellScenario(
            homeValue: 300_000,
            mortgageBalance: 250_000,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 350_000
        )

        #expect(scenario?.sellingCosts == 24_000) // 8% of 300,000
        #expect(scenario?.netProceeds == 26_000) // 300,000 - 24,000 - 250,000
        #expect(scenario?.netProfitOrLoss == -74_000) // 300,000 - 24,000 - 350,000
    }

    @Test("mortgage financing does not affect property profit/loss")
    func mortgageIndependentProfitLoss() {
        // Buy for 500k, sell immediately for 500k with 40k selling costs.
        // The property lost exactly the selling costs; the size of the
        // mortgage (here 400k, i.e. only 100k down) must not change that.
        let bigMortgage = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: 400_000,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 500_000
        )
        let noMortgage = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: 0,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 500_000
        )

        #expect(bigMortgage?.netProfitOrLoss == -40_000)
        #expect(noMortgage?.netProfitOrLoss == -40_000)
        #expect(bigMortgage?.netProfitOrLoss == noMortgage?.netProfitOrLoss)
    }

    @Test("returns nil when home value is missing")
    func nilWhenHomeValueMissing() {
        let scenario = computeSellScenario(
            homeValue: nil,
            mortgageBalance: 200_000,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 250_000
        )
        #expect(scenario == nil)
    }

    @Test("returns nil when mortgage balance is missing")
    func nilWhenMortgageBalanceMissing() {
        let scenario = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: nil,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: 250_000
        )
        #expect(scenario == nil)
    }

    @Test("net profit or loss is nil when total invested is unknown")
    func netProfitOrLossNilWhenTotalInvestedMissing() {
        let scenario = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: 200_000,
            realtorCommissionPercent: 6,
            closingCostsPercent: 2,
            totalInvested: nil
        )
        #expect(scenario?.netProceeds == 260_000)
        #expect(scenario?.netProfitOrLoss == nil)
    }

    @Test("zero-percent selling costs still computes correctly")
    func zeroPercentSellingCosts() {
        let scenario = computeSellScenario(
            homeValue: 500_000,
            mortgageBalance: 200_000,
            realtorCommissionPercent: 0,
            closingCostsPercent: 0,
            totalInvested: nil
        )
        #expect(scenario?.sellingCosts == 0)
        #expect(scenario?.netProceeds == 300_000)
    }
}
