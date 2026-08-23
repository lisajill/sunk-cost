import SwiftUI
import SunkCostCore

/// Phase 3: "Cost to Leave" -- what selling the house today would actually
/// net, after paying off the mortgage and assumed selling costs. A "check
/// when you want it" scenario tool, kept in its own tab rather than the
/// summary card.
struct SellScenarioView: View {
    @Environment(AppStore.self) private var store
    @State private var commissionText: String = ""
    @State private var closingText: String = ""
    @FocusState private var isCommissionFocused: Bool
    @FocusState private var isClosingFocused: Bool

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
        ScrollView {
            if let scenario = store.sellScenario {
                breakdown(scenario)
            } else {
                missingDataState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { syncAssumptionFields() }
        .onChange(of: store.realtorCommissionPercent) { _, _ in if !isCommissionFocused { syncAssumptionFields() } }
        .onChange(of: store.closingCostsPercent) { _, _ in if !isClosingFocused { syncAssumptionFields() } }
    }

    private var missingDataState: some View {
        VStack(spacing: 10) {
            Image(systemName: "house.and.flag")
                .font(.system(size: 34))
                .foregroundStyle(Theme.inkSecondary)
            Text("Add Home Value and Mortgage Balance to see this")
                .font(Theme.scaledFont(Theme.FontSize.title3, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Text("Cost to Leave estimates what selling today would net you, after paying off the mortgage and covering selling costs. It needs Home Value (set at the top of the Items tab) and Mortgage Balance (Settings) to work.")
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding()
    }

    private func breakdown(_ scenario: SellScenario) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 3) {
                Text("NET PROCEEDS IF SOLD TODAY")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkSecondary)

                Text(formatted(scenario.netProceeds))
                    .font(Theme.totalNumeral(scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)

                VStack(spacing: 2) {
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                }
                .padding(.top, 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                breakdownLine("Home Value", formatted(store.homeValue ?? 0))
                breakdownLine("− Mortgage Payoff", formatted(store.mortgageBalance ?? 0))
                breakdownLine("− Selling Costs", formatted(scenario.sellingCosts))
            }
            .frame(maxWidth: 360)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Theme.ledgerPaper)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let netProfitOrLoss = scenario.netProfitOrLoss {
                let sign = netProfitOrLoss >= 0 ? "+" : ""
                VStack(spacing: 2) {
                    Text(netProfitOrLoss >= 0 ? "PROFIT VS. TOTAL INVESTED" : "LOSS VS. TOTAL INVESTED")
                        .font(Theme.ledgerLabel(scale: store.textScale))
                        .tracking(0.6)
                        .foregroundStyle(Theme.inkSecondary)
                    Text("\(sign)\(formatted(netProfitOrLoss))")
                        .font(Theme.scaledFont(Theme.FontSize.title2, weight: .semibold, scale: store.textScale))
                        .monospacedDigit()
                        .foregroundStyle(netProfitOrLoss >= 0 ? Theme.positive : Theme.ledgerRed)
                }
                .help("Net Proceeds if Sold Today minus everything actually invested in the house (Purchase Price plus Value-type item spending).")
            } else {
                Text("Add your Purchase Price in Settings to see profit or loss vs. what you put in")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

            assumptionsSection
        }
        .padding(24)
    }

    private func breakdownLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
            Spacer()
            Text(value)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
    }

    private var assumptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELLING COST ASSUMPTIONS")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)

            HStack(spacing: 20) {
                labeledPercentField("Realtor Commission", text: $commissionText, isFocused: $isCommissionFocused)
                labeledPercentField("Closing Costs", text: $closingText, isFocused: $isClosingFocused)
            }

            Text("Defaults to 6% / 2% until you enter your own. Both are just estimates -- edit them anytime.")
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: 360, alignment: .leading)
    }

    private func labeledPercentField(_ title: String, text: Binding<String>, isFocused: FocusState<Bool>.Binding) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            HStack(spacing: 4) {
                TextField("", text: text)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                    .focused(isFocused)
                    .onSubmit { commitAssumptions() }
                    .onChange(of: isFocused.wrappedValue) { wasFocused, isNowFocused in
                        if wasFocused && !isNowFocused { commitAssumptions() }
                    }
                Text("%")
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private func syncAssumptionFields() {
        commissionText = NSDecimalNumber(decimal: store.realtorCommissionPercent ?? 6).stringValue
        closingText = NSDecimalNumber(decimal: store.closingCostsPercent ?? 2).stringValue
    }

    private func commitAssumptions() {
        func parse(_ text: String) -> Decimal? {
            let digitsAndDot = text.filter { $0.isNumber || $0 == "." }
            return digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)
        }
        store.setSellingCostAssumptions(
            commissionPercent: parse(commissionText),
            closingPercent: parse(closingText)
        )
        syncAssumptionFields()
    }
}
