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
    @State private var propertyTaxText = ""
    @State private var insuranceText = ""
    @State private var newPropertyTaxText = ""
    @State private var newInsuranceText = ""

    private enum Field: Hashable {
        case years, appreciation, investmentReturn, rent, rentIncrease
        case newHomePrice, newHomeDownPayment, newMortgageRate, newMortgageTerm
        case propertyTax, insurance, newPropertyTax, newInsurance
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

            comparisonTable

            Text("ASSUMPTIONS")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)

            HStack(alignment: .top, spacing: 24) {
                assumptionGroup("Staying") {
                    percentField("Home Appreciation", text: $appreciationText, field: .appreciation)
                    percentField("Property Tax (per year)", text: $propertyTaxText, field: .propertyTax)
                    dollarField("Insurance (per year)", text: $insuranceText, placeholder: "e.g. 1500", field: .insurance)
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
                    percentField("Property Tax (per year)", text: $newPropertyTaxText, field: .newPropertyTax)
                    dollarField("Insurance (per year)", text: $newInsuranceText, placeholder: "e.g. 1500", field: .newInsurance)
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

    private var comparisonTable: some View {
        let keep = store.stayingMonthlyBreakdown
        let rent = store.rentingMonthlyBreakdown
        let buy = store.buyingElsewhereMonthlyBreakdown

        return VStack(alignment: .leading, spacing: 10) {
            Grid(alignment: .trailing, horizontalSpacing: 24, verticalSpacing: 6) {
                GridRow {
                    Text("")
                    columnHeader("Keep")
                    columnHeader("Rent")
                    columnHeader("Buy")
                }

                Divider().gridCellColumns(4)

                tableRow("Principal & Interest", keep?.principalAndInterest, rent?.principalAndInterest, buy?.principalAndInterest)
                tableRow("Property Tax", keep?.propertyTax, rent?.propertyTax, buy?.propertyTax)
                tableRow("Insurance", keep?.insurance, rent?.insurance, buy?.insurance)
                tableRow("Maintenance / Rent", keep?.maintenanceOrRent, rent?.maintenanceOrRent, buy?.maintenanceOrRent)

                Divider().gridCellColumns(4)

                tableRow("Total Monthly", keep?.total, rent?.total, buy?.total, bold: true)

                Color.clear.gridCellUnsizedAxes([.horizontal, .vertical]).frame(height: 6).gridCellColumns(4)

                tableRow(
                    "Ending Net Worth (\(store.projectionYears) yr)",
                    store.stayingNetWorthProjection,
                    store.rentingNetWorthProjection,
                    store.buyingElsewhereNetWorthProjection,
                    bold: true
                )
            }

            VStack(alignment: .leading, spacing: 2) {
                if keep == nil {
                    Text("Keep needs your full mortgage details (original amount, rate, term, start date) in Settings.")
                }
                if rent == nil {
                    Text("Rent needs an assumed monthly rent below.")
                }
                if buy == nil {
                    Text("Buy needs a new home price below.")
                }
                Text("Buy's Maintenance/Rent reuses today's Maintenance total as a stand-in for the new home's upkeep.")
                Text("Buy's Ending Net Worth also invests any of today's sale proceeds not put toward the down payment, same as Rent does with its own proceeds.")
            }
            .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
            .foregroundStyle(Theme.inkSecondary)
        }
    }

    private func columnHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(Theme.ledgerLabel(scale: store.textScale))
            .tracking(0.6)
            .foregroundStyle(Theme.inkSecondary)
    }

    private func tableRow(_ label: String, _ keep: Decimal?, _ rent: Decimal?, _ buy: Decimal?, bold: Bool = false) -> some View {
        GridRow {
            Text(label)
                .font(Theme.scaledFont(Theme.FontSize.callout, weight: bold ? .semibold : .regular, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
                .gridColumnAlignment(.leading)
            tableCell(keep, bold: bold)
            tableCell(rent, bold: bold)
            tableCell(buy, bold: bold)
        }
    }

    private func tableCell(_ value: Decimal?, bold: Bool) -> some View {
        Text(value.map(formatted) ?? "—")
            .font(Theme.scaledFont(Theme.FontSize.callout, weight: bold ? .semibold : .regular, scale: store.textScale))
            .monospacedDigit()
            .foregroundStyle(value == nil ? Theme.inkSecondary : Theme.ink)
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
        .frame(maxWidth: .infinity, alignment: .leading)
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
        propertyTaxText = NSDecimalNumber(decimal: store.propertyTaxPercent ?? 1.2).stringValue
        insuranceText = NSDecimalNumber(decimal: store.homeownersInsuranceAnnual ?? 1500).stringValue
        newPropertyTaxText = NSDecimalNumber(decimal: store.newPropertyTaxPercent ?? 1.2).stringValue
        newInsuranceText = NSDecimalNumber(decimal: store.newHomeownersInsuranceAnnual ?? 1500).stringValue
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
            newMortgageTermYears: int(newMortgageTermText),
            propertyTaxPercent: decimal(propertyTaxText),
            homeownersInsuranceAnnual: decimal(insuranceText),
            newPropertyTaxPercent: decimal(newPropertyTaxText),
            newHomeownersInsuranceAnnual: decimal(newInsuranceText)
        )
        syncFields()
    }
}
