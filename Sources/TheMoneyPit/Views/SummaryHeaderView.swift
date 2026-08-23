import SwiftUI
import TheMoneyPitCore

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
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("TOTAL SPENT TO DATE")
                    .font(Theme.ledgerLabel)
                    .tracking(1.4)
                    .foregroundStyle(Theme.inkSecondary)

                Text(formatted(store.totals.totalSpent))
                    .font(Theme.totalNumeral)
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)

                // A bookkeeper's double rule under the final total.
                VStack(spacing: 2) {
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                    Rectangle().fill(Theme.ledgerBorder).frame(width: 180, height: 1.25)
                }
                .padding(.top, 2)
            }

            if !isCollapsed {
                HStack(spacing: 0) {
                    statTile(title: "In the House", value: store.totals.inTheHouse, color: Theme.ledgerGreen)
                    ledgerDivider
                    statTile(title: "Gone, Paid For", value: store.totals.goneButPaidFor, color: Theme.taupe)
                    ledgerDivider
                    statTile(title: "Planned Ahead", value: store.totals.plannedNotSpent, color: Theme.terracotta)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                homeValueRow
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(20)
        .frame(maxWidth: 720)
        .background(Theme.ledgerPaper)
        .overlay(alignment: .topTrailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCollapsed.toggle()
                }
            } label: {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.caption.weight(.bold))
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
        .padding([.horizontal, .top], 14)
        .onAppear { syncHomeValueText() }
        .onChange(of: store.homeValue) { _, _ in
            if !isHomeValueFocused { syncHomeValueText() }
        }
    }

    private var ledgerDivider: some View {
        Rectangle()
            .fill(Theme.ledgerBorder)
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    private func statTile(title: String, value: Decimal, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel)
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(formatted(value))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private var homeValueRow: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Text("Home Value")
                    .foregroundStyle(Theme.inkSecondary)
                if store.isPrivacyModeEnabled {
                    Text(homeValueText.isEmpty ? "—" : Theme.mask(homeValueText))
                        .frame(minWidth: 100, idealWidth: 140, maxWidth: 220, alignment: .trailing)
                        .foregroundStyle(Theme.ink)
                        .help("Turn off privacy mode to edit")
                } else {
                    TextField("Enter estimate", text: $homeValueText)
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
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(difference >= 0 ? Theme.ledgerGreen : Theme.ledgerRed)
            }

            if let equity = store.equity {
                Text("Equity: \(formatted(equity))")
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
                    .foregroundStyle(equity >= 0 ? Theme.ledgerGreen : Theme.ledgerRed)
            } else if store.homeValue != nil {
                Text("Add your mortgage balance in Settings to see Equity")
                    .font(.caption)
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
