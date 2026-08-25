import SwiftUI
import SunkCostCore

/// Paste the payment-calculator box off a real estate listing (Redfin,
/// Zillow, similar) and have it fill in the Buying Elsewhere fields.
/// Deliberately paste-based, not a URL fetch -- no network call is made
/// here or anywhere else in the app; this only reads text the user
/// already copied out of their own browser.
struct ListingImportSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onApply: (ParsedListing) -> Void

    @State private var pastedText = ""

    private var parsed: ParsedListing {
        ListingParser.parse(pastedText)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatted(_ value: Decimal) -> String {
        Self.currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    private var hasAnyMatch: Bool {
        parsed != ParsedListing()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Paste from Listing")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            Text("Copy the payment calculator box from a Redfin or Zillow listing (or similar) and paste it below. Nothing is fetched or sent anywhere -- this only reads what you paste.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)

            TextEditor(text: $pastedText)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .frame(height: 140)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.ledgerBorder, lineWidth: 1))

            if !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                previewSection
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Apply") {
                    onApply(parsed)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!hasAnyMatch)
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
        }
        .padding(20)
        .frame(width: 420)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FOUND")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)

            if hasAnyMatch {
                VStack(alignment: .leading, spacing: 3) {
                    previewRow("Home Price", parsed.homePrice.map(formatted))
                    previewRow("Down Payment", parsed.downPaymentAmount.map(formatted))
                    previewRow("Mortgage", loanSummary)
                    previewRow("Property Tax", parsed.monthlyPropertyTax.map { "\(formatted($0))/mo" })
                    previewRow("Insurance", parsed.monthlyInsurance.map { "\(formatted($0))/mo" })
                    previewRow("HOA", parsed.monthlyHOA.map { "\(formatted($0))/mo" })
                }
            } else {
                Text("Nothing recognized in that text yet -- double check it's the payment calculator section.")
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
        .padding(12)
        .background(Theme.ledgerPaper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var loanSummary: String? {
        guard parsed.mortgageTermYears != nil || parsed.mortgageRatePercent != nil else { return nil }
        var parts: [String] = []
        if let term = parsed.mortgageTermYears { parts.append("\(term)-yr") }
        if let rate = parsed.mortgageRatePercent { parts.append("\(NSDecimalNumber(decimal: rate))%") }
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private func previewRow(_ label: String, _ value: String?) -> some View {
        if let value {
            HStack {
                Text(label)
                    .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                Spacer()
                Text(value)
                    .font(Theme.scaledFont(Theme.FontSize.callout, weight: .semibold, scale: store.textScale))
                    .foregroundStyle(Theme.ink)
            }
        }
    }
}
