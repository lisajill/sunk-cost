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

    @State private var isShowingSaveScenarioAlert = false
    @State private var newScenarioName = ""

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

    /// A short, plain-language walkthrough of what's driving each number
    /// above -- generated from the same figures already on screen, not a
    /// separate/hardcoded explanation that could drift out of sync with
    /// them.
    private var explanationLines: [String] {
        var lines: [String] = []

        let results: [(name: String, value: Decimal?)] = [
            ("Staying", store.stayingNetWorthProjection),
            ("Renting", store.rentingNetWorthProjection),
            ("Buying elsewhere", store.buyingElsewhereNetWorthProjection),
        ]
        let available = results.compactMap { entry in entry.value.map { (entry.name, $0) } }
        if let winner = available.max(by: { $0.1 < $1.1 }) {
            lines.append("Over \(store.projectionYears) years, \(winner.0) comes out ahead in this projection, at \(formatted(winner.1)).")
        }

        if store.stayingNetWorthProjection != nil {
            lines.append("Staying grows your net worth two ways: your home's value goes up (the appreciation assumption), and your mortgage balance goes down as you keep paying it off.")
        }

        if store.rentingNetWorthProjection != nil {
            lines.append("Renting doesn't build any home equity — all of its growth comes from investing today's sale proceeds and letting that grow instead.")
        }

        if store.buyingElsewhereNetWorthProjection != nil {
            let netProceeds = store.sellScenario?.netProceeds ?? 0
            let newHomePrice = store.newHomePrice ?? 0
            let downPaymentUsed = min(store.newHomeDownPayment ?? netProceeds, newHomePrice)
            let leftover = max(netProceeds - downPaymentUsed, 0)
            if leftover > 0 {
                lines.append("Buying elsewhere grows two ways too: the new home's own equity, plus \(formatted(leftover)) of today's sale proceeds that isn't going toward the down payment — invested right alongside it, the same way Renting invests its proceeds. That leftover cash can end up doing more of the work than the new mortgage itself.")
            } else {
                lines.append("Buying elsewhere grows the same way Staying does — home appreciation plus mortgage paydown — just on a different home and a different loan.")
            }
        }

        return lines
    }

    /// New Home Price minus the down payment actually applied to it -- the
    /// size of the new mortgage itself, so the P&I figure above can
    /// actually be sanity-checked instead of requiring mental subtraction.
    private var newLoanAmount: Decimal? {
        guard let newHomePrice = store.newHomePrice else { return nil }
        let downPayment = store.newHomeDownPayment ?? store.sellScenario?.netProceeds ?? 0
        return max(newHomePrice - min(downPayment, newHomePrice), 0)
    }

    private var principalAndInterestTooltip: String? {
        var parts: [String] = []
        if let mortgageOriginalAmount = store.mortgageOriginalAmount {
            parts.append("Keep is on your \(formatted(mortgageOriginalAmount)) original loan.")
        }
        if let newLoanAmount {
            parts.append("Buy is on a \(formatted(newLoanAmount)) new loan (New Home Price minus Down Payment).")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
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

                    Spacer()

                    Button("Save Scenario") {
                        newScenarioName = ""
                        isShowingSaveScenarioAlert = true
                    }
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Save the assumptions below as a named snapshot you can reload later.")
                }
            }
            .alert("Save Scenario", isPresented: $isShowingSaveScenarioAlert) {
                TextField("Scenario name", text: $newScenarioName)
                Button("Save") {
                    store.saveCurrentScenarioAsPreset(name: newScenarioName)
                    newScenarioName = ""
                }
                Button("Cancel", role: .cancel) {
                    newScenarioName = ""
                }
            } message: {
                Text("Saves the Years, appreciation, rent, and new-home assumptions below so you can reload them later.")
            }

            if !store.savedComparisonScenarios.isEmpty {
                savedScenariosRow
            }

            comparisonTable
                .padding(20)
                .background(Theme.ledgerPaper)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 16) {
                Text("ASSUMPTIONS")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSecondary)

                assumptionColumns
            }
            .padding(20)
            .background(Theme.ledgerPaper.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !explanationLines.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("IN PLAIN ENGLISH")
                        .font(Theme.ledgerLabel(scale: store.textScale))
                        .tracking(0.6)
                        .foregroundStyle(Theme.terracotta)
                    ForEach(explanationLines, id: \.self) { line in
                        Text(line)
                            .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
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

    private var assumptionColumns: some View {
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
                if let newLoanAmount {
                    Text("→ Loan Amount: \(formatted(newLoanAmount))")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }
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

                tableRow(
                    "Principal & Interest",
                    keep?.principalAndInterest,
                    rent?.principalAndInterest,
                    buy?.principalAndInterest,
                    tooltip: principalAndInterestTooltip
                )
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

    private func tableRow(_ label: String, _ keep: Decimal?, _ rent: Decimal?, _ buy: Decimal?, bold: Bool = false, tooltip: String? = nil) -> some View {
        GridRow {
            Text(label)
                .font(Theme.scaledFont(Theme.FontSize.callout, weight: bold ? .semibold : .regular, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
                .gridColumnAlignment(.leading)
            tableCell(keep, bold: bold)
            tableCell(rent, bold: bold)
            tableCell(buy, bold: bold)
        }
        .modifier(OptionalHelp(tooltip))
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

    private var savedScenariosRow: some View {
        FlowLayout(spacing: 6) {
            ForEach(store.savedComparisonScenarios) { scenario in
                Button(scenario.name) {
                    store.loadScenario(scenario)
                    syncFields()
                }
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Load the \"\(scenario.name)\" scenario")
                .contextMenu {
                    Button("Delete", role: .destructive) {
                        store.deleteScenario(scenario)
                    }
                }
            }
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

private struct OptionalHelp: ViewModifier {
    let text: String?
    init(_ text: String?) { self.text = text }
    func body(content: Content) -> some View {
        if let text {
            content.help(text)
        } else {
            content
        }
    }
}
