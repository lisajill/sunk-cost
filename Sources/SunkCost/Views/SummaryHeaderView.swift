import SwiftUI
import SunkCostCore

struct SummaryHeaderView: View {
    @Environment(AppStore.self) private var store
    @State private var homeValueText: String = ""
    @FocusState private var isHomeValueFocused: Bool
    @State private var isCollapsed = false

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
        VStack(spacing: 10) {
            VStack(spacing: 3) {
                Text("TOTAL SPENT TO DATE")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkSecondary)

                Text(formatted(store.totals.totalSpent))
                    .font(Theme.totalNumeral(scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .help("Owned + Gone items — everything you've actually paid for. Planned items aren't counted yet.")

                // A bookkeeper's double rule under the final total.
                VStack(spacing: 2) {
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                }
                .padding(.top, 1)
            }

            if !isCollapsed {
                HStack(spacing: 0) {
                    statTile(
                        title: "In the House",
                        value: store.totals.inTheHouse,
                        color: Theme.positive,
                        tooltip: "Items marked Owned — still in the house and paid for."
                    )
                    ledgerDivider
                    statTile(
                        title: "Gone, Paid For",
                        value: store.totals.goneButPaidFor,
                        color: Theme.taupe,
                        tooltip: "Items marked Gone — paid for, but no longer in the house (sold, replaced, disposed of)."
                    )
                    ledgerDivider
                    statTile(
                        title: "Planned Ahead",
                        value: store.totals.plannedNotSpent,
                        color: Theme.terracotta,
                        tooltip: "Items marked Planned — not spent yet, so not counted in Total Spent to Date."
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                homeValueRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .frame(maxWidth: 720)
        .background(Theme.ledgerPaper)
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(Theme.scaledFont(Theme.FontSize.caption, weight: .bold, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "Show spending details" : "Collapse to just the total")
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Theme.ledgerBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .top], 8)
        .onAppear { syncHomeValueText() }
        .onChange(of: store.homeValue) { _, _ in
            if !isHomeValueFocused { syncHomeValueText() }
        }
    }

    private var ledgerDivider: some View {
        // An unconstrained Rectangle expands to fill all available height in
        // an HStack -- without this cap, the divider was stretching the
        // whole card open to fill the window, leaving a huge gap of empty
        // paper between the stat row and Home Value below it.
        Rectangle()
            .fill(Theme.ledgerBorder)
            .frame(width: 1, height: 40 * store.textScale)
    }

    private func statTile(title: String, value: Decimal, color: Color, tooltip: String) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(formatted(value))
                .font(Theme.scaledFont(Theme.FontSize.title3, weight: .semibold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .help(tooltip)
    }

    private var homeValueRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Home Value")
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                    .help("Your own estimate of what the house is worth now — type in a number anytime you get a new one (Zillow, appraisal, etc.).")
                if store.isPrivacyModeEnabled {
                    Text(homeValueText.isEmpty ? "—" : Theme.mask(homeValueText))
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .frame(minWidth: 100, idealWidth: 140, maxWidth: 220, alignment: .trailing)
                        .foregroundStyle(Theme.ink)
                        .help("Turn off privacy mode to edit")
                } else {
                    TextField("Enter estimate", text: $homeValueText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 100, idealWidth: 140, maxWidth: 220)
                        .multilineTextAlignment(.trailing)
                        .focused($isHomeValueFocused)
                        .onSubmit { commitHomeValue() }
                        .onChange(of: isHomeValueFocused) { wasFocused, isFocused in
                            if wasFocused && !isFocused { commitHomeValue() }
                        }
                }
            }

            if let homeValue = store.homeValue {
                let difference = homeValue - store.totals.totalSpent
                let sign = difference >= 0 ? "+" : ""
                Text("\(sign)\(formatted(difference)) vs. spent")
                    .font(Theme.scaledFont(Theme.FontSize.subheadline, weight: .medium, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(difference >= 0 ? Theme.positive : Theme.ledgerRed)
                    .help("Home Value minus Total Spent to Date. Positive means the house is worth more than you've put into it.")
            }

            if let equity = store.equity {
                Text("Equity: \(formatted(equity))")
                    .font(Theme.scaledFont(Theme.FontSize.subheadline, weight: .medium, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(equity >= 0 ? Theme.positive : Theme.ledgerRed)
                    .help("Home Value minus your mortgage balance — the actual stake you'd have if you sold today, before selling costs.")
            } else if store.homeValue != nil {
                Text("Add your mortgage balance in Settings to see Equity")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }

    private func syncHomeValueText() {
        if let homeValue = store.homeValue {
            homeValueText = Self.currencyFormatter.string(from: homeValue as NSDecimalNumber) ?? ""
        } else {
            homeValueText = ""
        }
    }

    private func commitHomeValue() {
        let digitsAndDot = homeValueText.filter { $0.isNumber || $0 == "." }
        if digitsAndDot.isEmpty {
            store.setHomeValue(nil)
        } else if let value = Decimal(string: digitsAndDot) {
            store.setHomeValue(value)
        }
        syncHomeValueText()
    }
}
