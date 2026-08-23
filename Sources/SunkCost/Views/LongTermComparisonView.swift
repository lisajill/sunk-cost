import SwiftUI
import SunkCostCore

/// Compare: Stay vs. Rent vs. Buy Elsewhere -- appended below the Sell
/// Scenario breakdown in the same tab. A genuine multi-year projection
/// (home appreciation, mortgage amortization, investment compounding over
/// a chosen horizon), not just today's snapshot. Each scenario's ending
/// net worth is computed independently; month-to-month cash-flow
/// differences between scenarios aren't reinvested into each other --
/// see the plan for why that refinement was left out of this pass.
struct LongTermComparisonView: View {
    @Environment(AppStore.self) private var store

    @State private var yearsText = ""
    @State private var appreciationText = ""
    @State private var investmentReturnText = ""
    @State private var rentText = ""
    @State private var rentIncreaseText = ""
    @State private var newHomePriceText = ""
    @State private var newHomeDownPaymentText = ""
    @State private var newMortgageRateText = ""
    @State private var newMortgageTermText = ""

    private enum Field: Hashable {
        case years, appreciation, investmentReturn, rent, rentIncrease
        case newHomePrice, newHomeDownPayment, newMortgageRate, newMortgageTerm
    }
    @FocusState private var focusedField: Field?

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatted(_ value: Decimal) -> String {
        let text = Self.currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
        return store.isPrivacyModeEnabled ? Theme.mask(text) : text
    }

    /// Reference-only monthly payment for the hypothetical new mortgage in
    /// Buying Elsewhere -- computed straight from the existing MortgageMath
    /// utility, not fed into the net-worth projection itself.
    private var newMortgagePaymentEstimate: Decimal? {
        guard let newHomePrice = store.newHomePrice else { return nil }
        let downPayment = store.newHomeDownPayment ?? store.sellScenario?.netProceeds ?? 0
        return MortgageMath.monthlyPayment(
            principal: newHomePrice - downPayment,
            annualRatePercent: store.newMortgageRatePercent ?? store.mortgageInterestRatePercent ?? 6,
            termYears: store.newMortgageTermYears ?? 30
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("COMPARE: STAY VS. RENT VS. BUY ELSEWHERE")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSecondary)
                Text("A projection over time, not a snapshot -- assumes home appreciation, mortgage amortization, and investment growth over the years below.")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

            labeledField("Years") {
                HStack(spacing: 4) {
                    TextField("", text: $yearsText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .focused($focusedField, equals: .years)
                        .onSubmit { commit() }
                    Text("years from now")
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                resultCard(
                    title: "Staying",
                    value: store.stayingNetWorthProjection,
                    monthlyCost: (store.monthlyPayment).map { $0 + store.costToKeep },
                    missingHint: "Needs your full mortgage details (original amount, rate, term, start date) in Settings"
                )
                resultCard(
                    title: "Renting",
                    value: store.rentingNetWorthProjection,
                    monthlyCost: store.monthlyRent,
                    missingHint: "Enter an assumed monthly rent below"
                )
                resultCard(
                    title: "Buying Elsewhere",
                    value: store.buyingElsewhereNetWorthProjection,
                    monthlyCost: newMortgagePaymentEstimate,
                    missingHint: "Enter a new home price below"
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                assumptionGroup("Staying") {
                    percentField("Home Appreciation", text: $appreciationText, field: .appreciation)
                }
                assumptionGroup("Renting") {
                    percentField("Investment Return", text: $investmentReturnText, field: .investmentReturn)
                    dollarField("Monthly Rent", text: $rentText, placeholder: "required", field: .rent)
                    percentField("Rent Increase (per year)", text: $rentIncreaseText, field: .rentIncrease)
                }
                assumptionGroup("Buying Elsewhere") {
                    dollarField("New Home Price", text: $newHomePriceText, placeholder: "required", field: .newHomePrice)
                    dollarField("Down Payment", text: $newHomeDownPaymentText, placeholder: "defaults to today's sale proceeds", field: .newHomeDownPayment)
                    percentField("Mortgage Rate", text: $newMortgageRateText, field: .newMortgageRate)
                    HStack(spacing: 4) {
                        Text("MORTGAGE TERM".uppercased())
                            .font(Theme.ledgerLabel(scale: store.textScale))
                            .tracking(0.6)
                            .foregroundStyle(Theme.inkSecondary)
                        TextField("", text: $newMortgageTermText)
                            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                            .focused($focusedField, equals: .newMortgageTerm)
                            .onSubmit { commit() }
                        Text("years")
                            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
        }
        .onAppear { syncFields() }
        // Button(.defaultAction)/.onSubmit alone only fires on Return --
        // committing when focus leaves any field (tabbing/clicking to the
        // next one, not just pressing Return) is what actually saves what
        // was typed. See CLAUDE.md's Return-key/onSubmit note.
        .onChange(of: focusedField) { oldValue, _ in
            if oldValue != nil { commit() }
        }
    }

    private func resultCard(title: String, value: Decimal?, monthlyCost: Decimal?, missingHint: String) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)

            if let value {
                Text(formatted(value))
                    .font(Theme.scaledFont(Theme.FontSize.title3, weight: .semibold, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                if let monthlyCost {
                    Text("\(formatted(monthlyCost))/mo now")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }
            } else {
                Text(missingHint)
                    .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .help("Projected net worth \(store.projectionYears) years from now")
    }

    @ViewBuilder
    private func assumptionGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.terracotta)
            content()
        }
    }

    private func percentField(_ title: String, text: Binding<String>, field: Field) -> some View {
        labeledField(title) {
            HStack(spacing: 4) {
                TextField("", text: text)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .focused($focusedField, equals: field)
                    .onSubmit { commit() }
                Text("%")
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private func dollarField(_ title: String, text: Binding<String>, placeholder: String, field: Field) -> some View {
        labeledField(title) {
            TextField(placeholder, text: text)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .textFieldStyle(.roundedBorder)
                .frame(width: 160)
                .focused($focusedField, equals: field)
                .onSubmit { commit() }
        }
    }

    @ViewBuilder
    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            content()
        }
    }

    private func syncFields() {
        yearsText = String(store.projectionYears)
        appreciationText = NSDecimalNumber(decimal: store.homeAppreciationPercent ?? 3).stringValue
        investmentReturnText = NSDecimalNumber(decimal: store.investmentReturnPercent ?? 6).stringValue
        rentText = store.monthlyRent.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        rentIncreaseText = NSDecimalNumber(decimal: store.rentAnnualIncreasePercent ?? 3).stringValue
        newHomePriceText = store.newHomePrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        newHomeDownPaymentText = store.newHomeDownPayment.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        newMortgageRateText = NSDecimalNumber(decimal: store.newMortgageRatePercent ?? store.mortgageInterestRatePercent ?? 6).stringValue
        newMortgageTermText = String(store.newMortgageTermYears ?? 30)
    }

    private func commit() {
        func decimal(_ text: String) -> Decimal? {
            let digitsAndDot = text.filter { $0.isNumber || $0 == "." }
            return digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)
        }
        func int(_ text: String) -> Int? {
            Int(text.filter { $0.isNumber })
        }

        store.setComparisonAssumptions(
            projectionYears: int(yearsText),
            homeAppreciationPercent: decimal(appreciationText),
            investmentReturnPercent: decimal(investmentReturnText),
            monthlyRent: decimal(rentText),
            rentAnnualIncreasePercent: decimal(rentIncreaseText),
            newHomePrice: decimal(newHomePriceText),
            newHomeDownPayment: decimal(newHomeDownPaymentText),
            newMortgageRatePercent: decimal(newMortgageRateText),
            newMortgageTermYears: int(newMortgageTermText)
        )
        syncFields()
    }
}
