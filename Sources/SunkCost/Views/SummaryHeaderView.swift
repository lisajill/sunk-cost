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
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "house.fill")
                        .foregroundStyle(Theme.positive)
                    Text("TOTAL SPENT TO DATE")
                        .font(Theme.ledgerLabel(scale: store.textScale))
                        .tracking(1.4)
                        .foregroundStyle(Theme.inkSecondary)
                        .infoTooltip("Owned + Gone items — everything you've actually paid for. Planned items aren't counted yet.", scale: store.textScale)
                }

                Text(formatted(store.totals.totalSpent))
                    .font(Theme.totalNumeral(scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                    .help("Owned + Gone items — everything you've actually paid for. Planned items aren't counted yet.")

                Capsule()
                    .fill(Theme.positive)
                    .frame(width: 48, height: 4)
                    .padding(.top, 2)

                costToKeepRow
                    .padding(.top, 4)
            }

            if !isCollapsed {
                HStack(spacing: 10) {
                    statTile(
                        title: "In the House",
                        value: store.totals.inTheHouse,
                        color: Theme.positive,
                        tooltip: "Items marked Owned — still in the house and paid for."
                    )
                    statTile(
                        title: "Gone, Paid For",
                        value: store.totals.goneButPaidFor,
                        color: Theme.taupe,
                        tooltip: "Items marked Gone — paid for, but no longer in the house (sold, replaced, disposed of)."
                    )
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
        .padding(18)
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
            .help(isCollapsed ? "Show spending details" : "Collapse to just the totals")
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Theme.ledgerBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .top], 8)
        .onAppear { syncHomeValueText() }
        .onChange(of: store.homeValue) { _, _ in
            if !isHomeValueFocused { syncHomeValueText() }
        }
    }

    private var costToKeepRow: some View {
        HStack(spacing: 6) {
            Text("COST TO KEEP")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            Text("\(formatted(store.costToKeep))/mo (\(formatted(store.costToKeepAnnual))/yr)")
                .font(Theme.scaledFont(Theme.FontSize.subheadline, weight: .semibold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .infoTooltip("Total recurring monthly (and projected yearly) cost across every Maintenance category — utilities, oil, landscaping, and the like. Kept separate from Total Spent to Date: running the house and improving it are different questions.", scale: store.textScale)
    }

    private func statTile(title: String, value: Decimal, color: Color, tooltip: String) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 3) {
                Text(title.uppercased())
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "info.circle")
                    .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                    .foregroundStyle(color.opacity(0.75))
            }
            Text(formatted(value))
                .font(Theme.scaledFont(Theme.FontSize.title2, weight: .bold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .help(tooltip)
    }

    private var homeValueRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Home Value")
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                    .infoTooltip("Your own estimate of what the house is worth now — type in a number anytime you get a new one (Zillow, appraisal, etc.).", scale: store.textScale)
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

            if let netHouseGain = store.netHouseGain {
                let sign = netHouseGain >= 0 ? "+" : ""
                let color = netHouseGain >= 0 ? Theme.positive : Theme.ledgerRed
                Text("Net Gain: \(sign)\(formatted(netHouseGain))")
                    .font(Theme.scaledFont(Theme.FontSize.subheadline, weight: .bold, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .infoTooltip("Home Value minus everything actually invested in the house as an asset — Purchase Price plus Value-type item spending (things that stay with the house, like a fence or a deck). Moveable items like furniture aren't counted since they don't raise the home's value.", scale: store.textScale)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.14))
                    .clipShape(Capsule())
            } else if store.homeValue != nil {
                Text("Add your Purchase Price in Settings to see Net Gain")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

            if let equity = store.equity {
                let color = equity >= 0 ? Theme.positive : Theme.ledgerRed
                Text("Equity: \(formatted(equity))")
                    .font(Theme.scaledFont(Theme.FontSize.subheadline, weight: .bold, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(color)
                    .infoTooltip("Home Value minus your mortgage balance — the actual stake you'd have if you sold today, before selling costs.", scale: store.textScale)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.14))
                    .clipShape(Capsule())
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
