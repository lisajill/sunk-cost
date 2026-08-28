import Foundation
import AppKit
import SunkCostCore

/// Which mortgage balance the "Staying" long-term projection amortizes
/// forward from: the figure the user keeps current in Settings, or one
/// reconstructed from the original loan's amortization schedule. A view
/// preference (persisted in `UserDefaults`, like sort order), not part of
/// the data file.
enum StayingBalanceBasis: String, CaseIterable, Sendable {
    case recorded
    case modeled

    var label: String {
        switch self {
        case .recorded: return "Recorded"
        case .modeled: return "Modeled from loan"
        }
    }
}

/// PITI-style monthly cost breakdown for one Compare scenario -- Renting
/// only ever populates `maintenanceOrRent`, since it has no mortgage, tax,
/// or insurance of its own.
struct MonthlyCostBreakdown {
    var principalAndInterest: Decimal = 0
    var propertyTax: Decimal = 0
    var insurance: Decimal = 0
    var hoa: Decimal = 0
    var maintenanceOrRent: Decimal = 0
    var total: Decimal { principalAndInterest + propertyTax + insurance + hoa + maintenanceOrRent }
}

/// Sell Scenario ("Cost to leave") and the Compare: Stay vs. Rent vs. Buy
/// Elsewhere projection -- split out of AppStore.swift once this area grew
/// to be the largest cohesive chunk of the store, so future passes here
/// don't keep making the main file harder to hold in view.
extension AppStore {
    /// What selling today would net, after assumed selling costs pay off
    /// the mortgage -- falls back to 6%/2% commission/closing when the
    /// user hasn't set their own assumptions yet, so the Sell Scenario tab
    /// always shows a usable estimate.
    var sellScenario: SellScenario? {
        computeSellScenario(
            homeValue: homeValue,
            mortgageBalance: mortgageBalance,
            realtorCommissionPercent: realtorCommissionPercent ?? 6,
            closingCostsPercent: closingCostsPercent ?? 2,
            totalInvested: totalInvested
        )
    }

    /// Compare: Stay vs. Rent vs. Buy Elsewhere -- the horizon (years) for
    /// all three projections below.
    var projectionYears: Int { comparisonProjectionYears ?? 10 }

    private var monthsSinceMortgageStart: Int? {
        guard let mortgageStartDate else { return nil }
        let months = Calendar.current.dateComponents([.month], from: mortgageStartDate, to: Date()).month ?? 0
        return max(months, 0)
    }

    /// Today's balance reconstructed from the original loan's amortization
    /// schedule -- what the balance "should" be if every payment landed
    /// exactly on schedule. nil until the full original loan details are
    /// on record.
    var modeledCurrentMortgageBalance: Decimal? {
        guard let mortgageOriginalAmount, let mortgageInterestRatePercent,
              let mortgageTermYears, let monthsSinceMortgageStart else { return nil }
        return MortgageMath.remainingBalance(
            principal: mortgageOriginalAmount,
            annualRatePercent: mortgageInterestRatePercent,
            termYears: mortgageTermYears,
            monthsElapsed: monthsSinceMortgageStart
        )
    }

    /// The balance the Staying projection amortizes forward from, per
    /// `stayingBalanceBasis` -- falling back to whichever figure is
    /// available when the preferred one isn't.
    var stayingProjectionStartBalance: Decimal? {
        switch stayingBalanceBasis {
        case .recorded: return mortgageBalance ?? modeledCurrentMortgageBalance
        case .modeled: return modeledCurrentMortgageBalance ?? mortgageBalance
        }
    }

    /// True only when both the recorded and the modeled balance exist and
    /// differ by more than a dollar -- i.e. when offering the user a choice
    /// between them is actually meaningful. (The modeled figure carries
    /// many fractional cents; a statement balance is rounded, so an exact
    /// comparison would fire on essentially every loan.)
    var stayingBalanceBasisIsSelectable: Bool {
        guard let recorded = mortgageBalance, let modeled = modeledCurrentMortgageBalance else { return false }
        return abs(recorded - modeled) >= 1
    }

    /// Ending home equity if she stays -- the home appreciates while the
    /// mortgage amortizes forward from `stayingProjectionStartBalance`.
    /// nil until there's a balance to start from; a paid-off balance needs
    /// nothing more, otherwise a monthly payment and rate are required too
    /// (there's no sensible default for someone's real loan the way there
    /// is for a general assumption like appreciation rate).
    var stayingNetWorthProjection: Decimal? {
        guard let homeValue, let startBalance = stayingProjectionStartBalance else { return nil }
        let appreciation = homeAppreciationPercent ?? 3
        guard startBalance > 0 else {
            // Paid off: ending net worth is just the appreciated home value.
            return compoundedValue(principal: homeValue, annualRatePercent: appreciation, years: projectionYears)
        }
        guard let mortgageInterestRatePercent, let monthlyPayment else { return nil }
        return projectStayingNetWorth(
            homeValue: homeValue,
            appreciationPercent: appreciation,
            currentMortgageBalance: startBalance,
            monthlyPayment: monthlyPayment,
            mortgageAnnualRatePercent: mortgageInterestRatePercent,
            projectionYears: projectionYears
        )
    }

    /// Cash a scenario would need from savings -- an underwater sale, or
    /// deposits/down payment beyond the sale's usable proceeds -- shown as
    /// a positive figure, nil when there's no gap. The projections already
    /// charge this (see `outsideCashUsed`); these expose it so the UI can
    /// say so out loud rather than just showing a quietly lower number.
    var rentingOutsideCashFromSavings: Decimal? {
        guard rentingNetWorthProjection != nil else { return nil }
        let gap = -outsideCashUsed(
            netProceeds: sellScenario?.netProceeds ?? 0,
            committed: (securityDeposit ?? 0) + (petDeposit ?? 0)
        )
        return gap > 0 ? gap : nil
    }

    var buyingElsewhereOutsideCashFromSavings: Decimal? {
        guard buyingElsewhereNetWorthProjection != nil, let newHomePrice else { return nil }
        let netProceeds = sellScenario?.netProceeds ?? 0
        let downPayment = min(max(newHomeDownPayment ?? max(netProceeds, 0), 0), newHomePrice)
        let gap = -outsideCashUsed(netProceeds: netProceeds, committed: downPayment)
        return gap > 0 ? gap : nil
    }

    /// Ending investment balance if she sells and rents -- nil until a
    /// rent figure is entered, since no generic default is meaningful
    /// (unlike the investment-return assumption, which does get one).
    var rentingNetWorthProjection: Decimal? {
        guard monthlyRent != nil, let netProceeds = sellScenario?.netProceeds else { return nil }
        return projectRentingNetWorth(
            netProceedsToday: netProceeds,
            investmentReturnPercent: investmentReturnPercent ?? 6,
            projectionYears: projectionYears,
            upfrontCosts: (securityDeposit ?? 0) + (petDeposit ?? 0)
        )
    }

    /// Ending home equity in a new home if she sells and buys elsewhere --
    /// nil until a new home price is entered; down payment/rate/term all
    /// fall back to reasonable suggestions (today's sale proceeds, her
    /// current mortgage's rate, a 30-year term).
    var buyingElsewhereNetWorthProjection: Decimal? {
        guard let newHomePrice else { return nil }
        let netProceeds = sellScenario?.netProceeds ?? 0
        return projectBuyingElsewhereNetWorth(
            newHomePrice: newHomePrice,
            // Default the down payment to the sale proceeds, but never a
            // negative one (an underwater sale) -- the projection clamps
            // it too, this just keeps the suggested figure sane.
            downPayment: newHomeDownPayment ?? max(netProceeds, 0),
            netProceedsAvailable: netProceeds,
            appreciationPercent: homeAppreciationPercent ?? 3,
            newMortgageAnnualRatePercent: newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6,
            newMortgageTermYears: newMortgageTermYears ?? 30,
            projectionYears: projectionYears,
            leftoverCashInvestmentReturnPercent: investmentReturnPercent ?? 6
        )
    }

    /// Today's PITI breakdown for each Compare scenario -- nil under the
    /// same gating as the net-worth projections above (this is about
    /// *today's* monthly cost, so it doesn't need the projection horizon).
    var stayingMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let homeValue else { return nil }
        let principalAndInterest: Decimal
        if let startBalance = stayingProjectionStartBalance, startBalance <= 0 {
            principalAndInterest = 0 // paid off -- no P&I, but tax/insurance/upkeep still apply
        } else if let payment = monthlyPayment {
            principalAndInterest = payment
        } else {
            return nil
        }
        return MonthlyCostBreakdown(
            principalAndInterest: principalAndInterest,
            propertyTax: (propertyTaxAnnual ?? homeValue * 0.012) / 12,
            insurance: (homeownersInsuranceAnnual ?? 1500) / 12,
            hoa: hoaMonthly ?? 0,
            maintenanceOrRent: costToKeep
        )
    }

    var rentingMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let monthlyRent else { return nil }
        return MonthlyCostBreakdown(maintenanceOrRent: monthlyRent + (petRentMonthly ?? 0))
    }

    /// Maintenance reuses today's `costToKeep` as a stand-in for the new
    /// home's upkeep -- a second full Maintenance estimate for a home she
    /// hasn't picked wasn't part of what was scoped.
    var buyingElsewhereMonthlyBreakdown: MonthlyCostBreakdown? {
        guard let newHomePrice else { return nil }
        let downPayment = min(max(newHomeDownPayment ?? sellScenario?.netProceeds ?? 0, 0), newHomePrice)
        let principalAndInterest = MortgageMath.monthlyPayment(
            principal: newHomePrice - downPayment,
            annualRatePercent: newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6,
            termYears: newMortgageTermYears ?? 30
        ) ?? 0
        return MonthlyCostBreakdown(
            principalAndInterest: principalAndInterest,
            propertyTax: (newPropertyTaxAnnual ?? newHomePrice * 0.012) / 12,
            insurance: (newHomeownersInsuranceAnnual ?? 1500) / 12,
            hoa: newHoaMonthly ?? 0,
            maintenanceOrRent: costToKeep
        )
    }

    /// Plain-text dump of the Sell Scenario and Compare numbers -- inputs
    /// and results both -- meant for pasting into a chat (with Claude or
    /// anyone else) to play with the numbers outside the app, without
    /// wiring any actual network access into the app itself.
    func compareSummaryText() -> String {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD"
        currencyFormatter.maximumFractionDigits = 0

        func fmt(_ value: Decimal?) -> String {
            guard let value else { return "—" }
            return currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
        }
        func pct(_ value: Decimal?) -> String {
            guard let value else { return "—" }
            return "\(NSDecimalNumber(decimal: value).stringValue)%"
        }

        var lines: [String] = ["Sunk Cost — Cost to Leave Summary", ""]

        if let scenario = sellScenario {
            lines += [
                "SELL SCENARIO (today)",
                "Home Value: \(fmt(homeValue))",
                "Mortgage Payoff: \(fmt(mortgageBalance))",
                "Selling Costs: \(fmt(scenario.sellingCosts)) (\(pct(realtorCommissionPercent ?? 6)) commission + \(pct(closingCostsPercent ?? 2)) closing)",
                "Net Proceeds if Sold Today: \(fmt(scenario.netProceeds))",
            ]
            if let totalInvested {
                lines.append("Total Invested (Purchase Price + Value spending): \(fmt(totalInvested))")
            }
            if let netProfitOrLoss = scenario.netProfitOrLoss {
                lines.append("Profit/Loss vs. Total Invested: \(fmt(netProfitOrLoss))")
            }
            lines.append("")
        }

        lines += ["COMPARE: STAY VS. RENT VS. BUY ELSEWHERE (\(projectionYears) years)", ""]

        lines.append("STAYING")
        lines.append("Home Appreciation: \(pct(homeAppreciationPercent ?? 3))/yr")
        lines.append("Property Tax: \(fmt(propertyTaxAnnual ?? (homeValue.map { $0 * 0.012 })))/yr, Insurance: \(fmt(homeownersInsuranceAnnual ?? 1500))/yr")
        if let breakdown = stayingMonthlyBreakdown {
            lines.append("Monthly: P&I \(fmt(breakdown.principalAndInterest)), Tax \(fmt(breakdown.propertyTax)), Insurance \(fmt(breakdown.insurance)), HOA \(fmt(breakdown.hoa)), Maintenance \(fmt(breakdown.maintenanceOrRent)) → Total \(fmt(breakdown.total))/mo")
        }
        if stayingBalanceBasisIsSelectable {
            lines.append("Mortgage Balance Basis: \(stayingBalanceBasis.label) (recorded \(fmt(mortgageBalance)) vs. modeled \(fmt(modeledCurrentMortgageBalance)))")
        }
        lines.append("Ending Net Worth: \(stayingNetWorthProjection.map(fmt) ?? "needs Home Value plus a mortgage balance, monthly payment, and rate (or the original loan amount, rate, term, and start date) in Settings")")
        lines.append("")

        lines.append("RENTING")
        lines.append("Investment Return: \(pct(investmentReturnPercent ?? 6))/yr")
        lines.append("Monthly Rent: \(fmt(monthlyRent)), Rent Increase: \(pct(rentAnnualIncreasePercent ?? 3))/yr")
        if let breakdown = rentingMonthlyBreakdown {
            lines.append("Monthly Total: \(fmt(breakdown.total))/mo")
        }
        if let fromSavings = rentingOutsideCashFromSavings {
            lines.append("Deposits paid from savings (beyond sale proceeds): \(fmt(fromSavings)) — charged to Ending Net Worth with the investment growth it would have earned")
        }
        lines.append("Ending Net Worth: \(rentingNetWorthProjection.map(fmt) ?? "needs a monthly rent figure")")
        lines.append("")

        lines.append("BUYING ELSEWHERE")
        let buyDownPayment = newHomeDownPayment ?? sellScenario.map { max($0.netProceeds, 0) }
        lines.append("New Home Price: \(fmt(newHomePrice)), Down Payment: \(fmt(buyDownPayment))")
        if let newHomePrice {
            let downPayment = min(max(buyDownPayment ?? 0, 0), newHomePrice)
            lines.append("Loan Amount: \(fmt(newHomePrice - downPayment))")
        }
        lines.append("Mortgage Rate: \(pct(newMortgageRatePercent ?? mortgageInterestRatePercent ?? 6)), Term: \(newMortgageTermYears ?? 30) years")
        lines.append("Property Tax: \(fmt(newPropertyTaxAnnual ?? (newHomePrice.map { $0 * 0.012 })))/yr, Insurance: \(fmt(newHomeownersInsuranceAnnual ?? 1500))/yr")
        if let breakdown = buyingElsewhereMonthlyBreakdown {
            lines.append("Monthly: P&I \(fmt(breakdown.principalAndInterest)), Tax \(fmt(breakdown.propertyTax)), Insurance \(fmt(breakdown.insurance)), HOA \(fmt(breakdown.hoa)), Maintenance \(fmt(breakdown.maintenanceOrRent)) → Total \(fmt(breakdown.total))/mo")
        }
        if let fromSavings = buyingElsewhereOutsideCashFromSavings {
            lines.append("Down payment paid from savings (beyond sale proceeds): \(fmt(fromSavings)) — charged to Ending Net Worth with the investment growth it would have earned")
        }
        lines.append("Ending Net Worth: \(buyingElsewhereNetWorthProjection.map(fmt) ?? "needs a new home price")")

        return lines.joined(separator: "\n")
    }

    func copyCompareSummaryToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(compareSummaryText(), forType: .string)
    }

    func setSellingCostAssumptions(commissionPercent: Decimal?, closingPercent: Decimal?) {
        mutate {
            realtorCommissionPercent = commissionPercent
            closingCostsPercent = closingPercent
        }
    }

    func setComparisonAssumptions(
        projectionYears: Int?,
        homeAppreciationPercent: Decimal?,
        investmentReturnPercent: Decimal?,
        monthlyRent: Decimal?,
        rentAnnualIncreasePercent: Decimal?,
        securityDeposit: Decimal?,
        petDeposit: Decimal?,
        petRentMonthly: Decimal?,
        newHomePrice: Decimal?,
        newHomeDownPayment: Decimal?,
        newMortgageRatePercent: Decimal?,
        newMortgageTermYears: Int?,
        propertyTaxAnnual: Decimal?,
        homeownersInsuranceAnnual: Decimal?,
        newPropertyTaxAnnual: Decimal?,
        newHomeownersInsuranceAnnual: Decimal?,
        hoaMonthly: Decimal?,
        newHoaMonthly: Decimal?
    ) {
        mutate {
            self.comparisonProjectionYears = projectionYears
            self.homeAppreciationPercent = homeAppreciationPercent
            self.investmentReturnPercent = investmentReturnPercent
            self.monthlyRent = monthlyRent
            self.rentAnnualIncreasePercent = rentAnnualIncreasePercent
            self.securityDeposit = securityDeposit
            self.petDeposit = petDeposit
            self.petRentMonthly = petRentMonthly
            self.newHomePrice = newHomePrice
            self.newHomeDownPayment = newHomeDownPayment
            self.newMortgageRatePercent = newMortgageRatePercent
            self.newMortgageTermYears = newMortgageTermYears
            self.propertyTaxAnnual = propertyTaxAnnual
            self.homeownersInsuranceAnnual = homeownersInsuranceAnnual
            self.newPropertyTaxAnnual = newPropertyTaxAnnual
            self.newHomeownersInsuranceAnnual = newHomeownersInsuranceAnnual
            self.hoaMonthly = hoaMonthly
            self.newHoaMonthly = newHoaMonthly
        }
    }

    /// Saves the 13 live Compare assumption fields as a named, reloadable
    /// snapshot -- lets the user flip between several what-ifs without
    /// retyping. Doesn't capture Home Value, mortgage balance, Purchase
    /// Price, or Sell Scenario's selling-cost percentages, which are facts
    /// about the house/sale rather than "what-if" assumptions.
    func saveCurrentScenarioAsPreset(name: String, notes: String? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let scenario = ComparisonScenario(
            name: trimmedName,
            projectionYears: comparisonProjectionYears,
            homeAppreciationPercent: homeAppreciationPercent,
            investmentReturnPercent: investmentReturnPercent,
            monthlyRent: monthlyRent,
            rentAnnualIncreasePercent: rentAnnualIncreasePercent,
            securityDeposit: securityDeposit,
            petDeposit: petDeposit,
            petRentMonthly: petRentMonthly,
            newHomePrice: newHomePrice,
            newHomeDownPayment: newHomeDownPayment,
            newMortgageRatePercent: newMortgageRatePercent,
            newMortgageTermYears: newMortgageTermYears,
            propertyTaxAnnual: propertyTaxAnnual,
            homeownersInsuranceAnnual: homeownersInsuranceAnnual,
            newPropertyTaxAnnual: newPropertyTaxAnnual,
            newHomeownersInsuranceAnnual: newHomeownersInsuranceAnnual,
            hoaMonthly: hoaMonthly,
            newHoaMonthly: newHoaMonthly,
            notes: notes
        )
        mutate { savedComparisonScenarios.append(scenario) }
    }

    /// Renames a saved scenario and/or replaces its notes -- the 13
    /// assumption values themselves aren't editable here; delete and
    /// re-save if those need to change.
    func updateScenarioMetadata(_ scenario: ComparisonScenario, name: String, notes: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, let index = savedComparisonScenarios.firstIndex(where: { $0.id == scenario.id }) else { return }
        mutate {
            savedComparisonScenarios[index].name = trimmedName
            savedComparisonScenarios[index].notes = notes
        }
    }

    /// Overwrites the 13 live Compare assumption fields from a saved
    /// scenario, so the table/results update immediately.
    func loadScenario(_ scenario: ComparisonScenario) {
        mutate {
            comparisonProjectionYears = scenario.projectionYears
            homeAppreciationPercent = scenario.homeAppreciationPercent
            investmentReturnPercent = scenario.investmentReturnPercent
            monthlyRent = scenario.monthlyRent
            rentAnnualIncreasePercent = scenario.rentAnnualIncreasePercent
            securityDeposit = scenario.securityDeposit
            petDeposit = scenario.petDeposit
            petRentMonthly = scenario.petRentMonthly
            newHomePrice = scenario.newHomePrice
            newHomeDownPayment = scenario.newHomeDownPayment
            newMortgageRatePercent = scenario.newMortgageRatePercent
            newMortgageTermYears = scenario.newMortgageTermYears
            propertyTaxAnnual = scenario.propertyTaxAnnual
            homeownersInsuranceAnnual = scenario.homeownersInsuranceAnnual
            newPropertyTaxAnnual = scenario.newPropertyTaxAnnual
            newHomeownersInsuranceAnnual = scenario.newHomeownersInsuranceAnnual
            hoaMonthly = scenario.hoaMonthly
            newHoaMonthly = scenario.newHoaMonthly
        }
    }

    func deleteScenario(_ scenario: ComparisonScenario) {
        mutate { savedComparisonScenarios.removeAll { $0.id == scenario.id } }
    }
}
