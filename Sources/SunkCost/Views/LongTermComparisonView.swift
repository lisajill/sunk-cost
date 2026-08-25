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
    @State private var securityDepositText = ""
    @State private var petDepositText = ""
    @State private var petRentText = ""
    @State private var newHomePriceText = ""
    @State private var newHomeDownPaymentText = ""
    @State private var newMortgageRateText = ""
    @State private var newMortgageTermText = ""
    @State private var propertyTaxText = ""
    @State private var insuranceText = ""
    @State private var newPropertyTaxText = ""
    @State private var newInsuranceText = ""
    @State private var hoaText = ""
    @State private var newHoaText = ""
    /// Whether tax/insurance/HOA/rent/pet rent above are being typed as
    /// monthly figures instead of annual -- every real-world source for
    /// these (listings, loan estimates, tax bills) quotes them monthly, so
    /// typing the annual total by hand meant doing that multiplication
    /// yourself every time. Each field's *stored* value stays in whatever
    /// unit is natural for it (tax/insurance annual, HOA/rent/pet rent
    /// monthly, see `annualToDisplayText` vs. `monthlyToDisplayText`); this
    /// only changes what's displayed/typed.
    @State private var isEnteringMonthly = false

    @State private var isShowingSaveScenarioSheet = false
    @State private var isShowingListingImport = false
    @State private var scenarioBeingEdited: ComparisonScenario?
    @State private var scenarioBeingDeleted: ComparisonScenario?

    private enum Field: Hashable {
        case years, appreciation, investmentReturn, rent, rentIncrease
        case newHomePrice, newHomeDownPayment, newMortgageRate, newMortgageTerm
        case propertyTax, insurance, newPropertyTax, newInsurance, hoa, newHoa
        case securityDeposit, petDeposit, petRent
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
    private var entryUnitLabel: String {
        isEnteringMonthly ? "(per month)" : "(per year)"
    }

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
                        isShowingSaveScenarioSheet = true
                    }
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Save the assumptions below as a named snapshot you can reload later.")
                }
            }
            .sheet(isPresented: $isShowingSaveScenarioSheet) {
                ScenarioDetailsSheet(existingScenario: nil)
            }
            .sheet(isPresented: $isShowingListingImport) {
                ListingImportSheet(onApply: applyParsedListing)
            }
            .sheet(item: $scenarioBeingEdited) { scenario in
                ScenarioDetailsSheet(existingScenario: scenario)
            }
            .confirmationDialog(
                "Delete \"\(scenarioBeingDeleted?.name ?? "")\"?",
                isPresented: Binding(
                    get: { scenarioBeingDeleted != nil },
                    set: { if !$0 { scenarioBeingDeleted = nil } }
                ),
                presenting: scenarioBeingDeleted
            ) { scenario in
                Button("Delete", role: .destructive) {
                    store.deleteScenario(scenario)
                    scenarioBeingDeleted = nil
                }
                Button("Cancel", role: .cancel) {
                    scenarioBeingDeleted = nil
                }
            } message: { _ in
                Text("This can't be undone.")
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
                HStack {
                    Text("ASSUMPTIONS")
                        .font(Theme.ledgerLabel(scale: store.textScale))
                        .tracking(0.6)
                        .foregroundStyle(Theme.inkSecondary)
                    Spacer()
                    Picker("Tax & insurance entry", selection: $isEnteringMonthly) {
                        Text("Annual").tag(false)
                        Text("Monthly").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 160)
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .help("Whether Property Tax, Insurance, HOA Dues, and Rent below are typed as monthly or annual figures -- matches what a real estate listing or loan estimate shows.")
                    .onChange(of: isEnteringMonthly) { oldValue, _ in
                        commit(interpretAsMonthly: oldValue)
                    }
                }

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
                        .foregroundStyle(Theme.gold)
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
                dollarField("Property Tax \(entryUnitLabel)", text: $propertyTaxText, placeholder: "e.g. 5000", field: .propertyTax)
                dollarField("Insurance \(entryUnitLabel)", text: $insuranceText, placeholder: "e.g. 1500", field: .insurance)
                dollarField("HOA Dues \(entryUnitLabel)", text: $hoaText, placeholder: "e.g. 0", field: .hoa)
            }
            assumptionGroup("Renting") {
                percentField("Investment Return", text: $investmentReturnText, field: .investmentReturn)
                dollarField("Rent \(entryUnitLabel)", text: $rentText, placeholder: "required", field: .rent)
                Text("Affects the monthly total in the table above, not the Ending Net Worth figure — that only reflects investing today's sale proceeds and letting them grow, not what you spend on rent along the way.")
                    .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                percentField("Rent Increase (per year)", text: $rentIncreaseText, field: .rentIncrease)
                dollarField("Security Deposit", text: $securityDepositText, placeholder: "e.g. 0", field: .securityDeposit)
                dollarField("Pet Deposit(s)", text: $petDepositText, placeholder: "e.g. 0", field: .petDeposit)
                dollarField("Pet Rent \(entryUnitLabel)", text: $petRentText, placeholder: "e.g. 0", field: .petRent)
                Text("Deposits come off your sale proceeds before the rest is invested, same as a down payment does for Buying Elsewhere. Pet rent just adds to the monthly total above, same as Rent.")
                    .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
            assumptionGroup("Buying Elsewhere") {
                Button("Paste from Listing…") {
                    isShowingListingImport = true
                }
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Paste a Redfin/Zillow payment-calculator box to fill in the fields below automatically.")

                dollarField("New Home Price", text: $newHomePriceText, placeholder: "required", field: .newHomePrice)
                dollarField("Down Payment", text: $newHomeDownPaymentText, placeholder: "defaults to today's sale proceeds", field: .newHomeDownPayment)
                if let newLoanAmount {
                    Text("→ Loan Amount: \(formatted(newLoanAmount))")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }
                percentField("Mortgage Rate", text: $newMortgageRateText, field: .newMortgageRate)
                dollarField("Property Tax \(entryUnitLabel)", text: $newPropertyTaxText, placeholder: "e.g. 5000", field: .newPropertyTax)
                dollarField("Insurance \(entryUnitLabel)", text: $newInsuranceText, placeholder: "e.g. 1500", field: .newInsurance)
                dollarField("HOA Dues \(entryUnitLabel)", text: $newHoaText, placeholder: "e.g. 0", field: .newHoa)
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
                tableRow("HOA Dues", keep?.hoa, rent?.hoa, buy?.hoa)
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
                .foregroundStyle(Theme.gold)
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
                HStack(spacing: 2) {
                    Button(scenario.name) {
                        store.loadScenario(scenario)
                        syncFields()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(scenarioTooltip(scenario))

                    // A visible, click-to-open menu -- discoverable without
                    // needing to know that right-clicking a chip does
                    // anything. Right-click still works too, as a bonus for
                    // anyone used to that pattern.
                    Menu {
                        Button("Edit…") {
                            scenarioBeingEdited = scenario
                        }
                        Button("Delete", role: .destructive) {
                            scenarioBeingDeleted = scenario
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 20)
                    .help("Edit or delete this scenario")
                }
                .contextMenu {
                    Button("Edit…") {
                        scenarioBeingEdited = scenario
                    }
                    Button("Delete", role: .destructive) {
                        scenarioBeingDeleted = scenario
                    }
                }
            }
        }
        .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
    }

    private func scenarioTooltip(_ scenario: ComparisonScenario) -> String {
        if let notes = scenario.notes, !notes.isEmpty {
            return notes
        }
        return "Load the \"\(scenario.name)\" scenario"
    }

    /// Formats an annual dollar amount (the store's canonical unit) for
    /// display, converting to monthly first if that's the active entry
    /// mode -- the stored value never changes, only what's shown/typed.
    /// Rounded to the cent: dividing by 12 almost never lands on a clean
    /// number (6500/12 is a repeating decimal), and displaying that
    /// unrounded produced ugly noise like "6499.999999999999999" once it
    /// had been divided and multiplied back through a toggle.
    private func annualToDisplayText(_ annual: Decimal?, defaultAnnual: Decimal) -> String {
        let base = annual ?? defaultAnnual
        var displayed = isEnteringMonthly ? base / 12 : base
        var rounded = Decimal()
        NSDecimalRound(&rounded, &displayed, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }

    /// The inverse: whatever's typed, interpreted under `isMonthly`,
    /// converted back to the annual figure that's actually stored. Takes
    /// the mode explicitly (rather than reading `isEnteringMonthly`
    /// directly) because the one caller that toggles the mode itself
    /// needs to interpret already-typed text under the *old* mode, not
    /// whatever `isEnteringMonthly` has already become by the time it
    /// runs -- getting that backwards silently multiplied/divided the
    /// stored value by 12 on every toggle, while the redisplayed text
    /// coincidentally looked unchanged (X commits as X*12, then displays
    /// back as (X*12)/12 = X), which is exactly why it looked like
    /// toggling "did nothing" instead of visibly corrupting the value.
    private func displayTextToAnnual(_ text: String, isMonthly: Bool) -> Decimal? {
        guard let value = decimal(text) else { return nil }
        return isMonthly ? value * 12 : value
    }

    /// Same idea as `annualToDisplayText`/`displayTextToAnnual` above, but
    /// for fields whose stored value is canonically *monthly* (HOA dues,
    /// rent, pet rent -- all inherently monthly figures) rather than
    /// annual, so the toggle multiplies by 12 for the annual display
    /// instead of dividing by 12 for the monthly one.
    private func monthlyToDisplayText(_ monthly: Decimal?) -> String {
        guard let monthly else { return "" }
        var displayed = isEnteringMonthly ? monthly : monthly * 12
        var rounded = Decimal()
        NSDecimalRound(&rounded, &displayed, 2, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }

    private func displayTextToMonthly(_ text: String, isMonthly: Bool) -> Decimal? {
        guard let value = decimal(text) else { return nil }
        return isMonthly ? value : value / 12
    }

    private func decimal(_ text: String) -> Decimal? {
        let digitsAndDot = text.filter { $0.isNumber || $0 == "." }
        return digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)
    }

    private func int(_ text: String) -> Int? {
        Int(text.filter { $0.isNumber })
    }

    private func syncFields() {
        yearsText = String(store.projectionYears)
        appreciationText = NSDecimalNumber(decimal: store.homeAppreciationPercent ?? 3).stringValue
        investmentReturnText = NSDecimalNumber(decimal: store.investmentReturnPercent ?? 6).stringValue
        rentText = monthlyToDisplayText(store.monthlyRent)
        rentIncreaseText = NSDecimalNumber(decimal: store.rentAnnualIncreasePercent ?? 3).stringValue
        securityDepositText = store.securityDeposit.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        petDepositText = store.petDeposit.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        petRentText = monthlyToDisplayText(store.petRentMonthly)
        newHomePriceText = store.newHomePrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        newHomeDownPaymentText = store.newHomeDownPayment.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
        newMortgageRateText = NSDecimalNumber(decimal: store.newMortgageRatePercent ?? store.mortgageInterestRatePercent ?? 6).stringValue
        newMortgageTermText = String(store.newMortgageTermYears ?? 30)
        propertyTaxText = annualToDisplayText(store.propertyTaxAnnual, defaultAnnual: (store.homeValue ?? 0) * 0.012)
        insuranceText = annualToDisplayText(store.homeownersInsuranceAnnual, defaultAnnual: 1500)
        newPropertyTaxText = annualToDisplayText(store.newPropertyTaxAnnual, defaultAnnual: (store.newHomePrice ?? 0) * 0.012)
        newInsuranceText = annualToDisplayText(store.newHomeownersInsuranceAnnual, defaultAnnual: 1500)
        hoaText = monthlyToDisplayText(store.hoaMonthly)
        newHoaText = monthlyToDisplayText(store.newHoaMonthly)
    }

    /// Fills whichever Buying Elsewhere fields the pasted listing text
    /// actually matched -- a field with nothing found is left untouched,
    /// not cleared, since a partial match is still useful and shouldn't
    /// wipe out something already typed.
    private func applyParsedListing(_ parsed: ParsedListing) {
        if let homePrice = parsed.homePrice {
            newHomePriceText = NSDecimalNumber(decimal: homePrice).stringValue
        }
        if let downPayment = parsed.downPaymentAmount {
            newHomeDownPaymentText = NSDecimalNumber(decimal: downPayment).stringValue
        }
        if let rate = parsed.mortgageRatePercent {
            newMortgageRateText = NSDecimalNumber(decimal: rate).stringValue
        }
        if let term = parsed.mortgageTermYears {
            newMortgageTermText = String(term)
        }
        if let tax = parsed.monthlyPropertyTax {
            newPropertyTaxText = NSDecimalNumber(decimal: isEnteringMonthly ? tax : tax * 12).stringValue
        }
        if let insurance = parsed.monthlyInsurance {
            newInsuranceText = NSDecimalNumber(decimal: isEnteringMonthly ? insurance : insurance * 12).stringValue
        }
        if let hoa = parsed.monthlyHOA {
            newHoaText = NSDecimalNumber(decimal: isEnteringMonthly ? hoa : hoa * 12).stringValue
        }
        commit()
    }

    /// `interpretAsMonthly` defaults to the live toggle state for every
    /// normal call site (typing in a field, tabbing away, a paste-import).
    /// The one exception is the toggle's own onChange, which passes the
    /// *old* mode explicitly -- see `displayTextToAnnual`'s doc comment
    /// for why that distinction is the whole fix for the
    /// toggle-corrupts-the-value bug. Governs every field the Annual/
    /// Monthly toggle affects, not just tax/insurance -- HOA, rent, and
    /// pet rent are canonically monthly (see `displayTextToMonthly`) but
    /// share the same toggle and the same old-value-on-flip requirement.
    private func commit(interpretAsMonthly: Bool? = nil) {
        let isMonthly = interpretAsMonthly ?? isEnteringMonthly
        store.setComparisonAssumptions(
            projectionYears: int(yearsText),
            homeAppreciationPercent: decimal(appreciationText),
            investmentReturnPercent: decimal(investmentReturnText),
            monthlyRent: displayTextToMonthly(rentText, isMonthly: isMonthly),
            rentAnnualIncreasePercent: decimal(rentIncreaseText),
            securityDeposit: decimal(securityDepositText),
            petDeposit: decimal(petDepositText),
            petRentMonthly: displayTextToMonthly(petRentText, isMonthly: isMonthly),
            newHomePrice: decimal(newHomePriceText),
            newHomeDownPayment: decimal(newHomeDownPaymentText),
            newMortgageRatePercent: decimal(newMortgageRateText),
            newMortgageTermYears: int(newMortgageTermText),
            propertyTaxAnnual: displayTextToAnnual(propertyTaxText, isMonthly: isMonthly),
            homeownersInsuranceAnnual: displayTextToAnnual(insuranceText, isMonthly: isMonthly),
            newPropertyTaxAnnual: displayTextToAnnual(newPropertyTaxText, isMonthly: isMonthly),
            newHomeownersInsuranceAnnual: displayTextToAnnual(newInsuranceText, isMonthly: isMonthly),
            hoaMonthly: displayTextToMonthly(hoaText, isMonthly: isMonthly),
            newHoaMonthly: displayTextToMonthly(newHoaText, isMonthly: isMonthly)
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
