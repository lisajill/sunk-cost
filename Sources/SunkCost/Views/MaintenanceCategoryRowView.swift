import SwiftUI
import SunkCostCore

/// Extracted from `MaintenanceView` so search results can show the exact
/// same row styling as the real Maintenance page, instead of a
/// stripped-down summary -- matches `ItemRowView` existing for the same
/// reason on the Items side.
struct MaintenanceCategoryRowView: View {
    @Environment(AppStore.self) private var store

    let category: MaintenanceCategory
    let onTap: () -> Void

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
        HStack {
            HStack(spacing: 5) {
                Text(category.name)
                    .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                    .foregroundStyle(Theme.ink)
                if let notes = category.notes, !notes.isEmpty {
                    Image(systemName: "note.text")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                        .help(notes)
                }
                if !category.isRequired {
                    Text("OPTIONAL")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .semibold, scale: store.textScale))
                        .tracking(0.5)
                        .foregroundStyle(Theme.gold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.15))
                        .clipShape(Capsule())
                        .help("Discretionary -- counted out when viewing Required Only")
                }
            }
            Spacer()
            Text("\(formatted(category.monthlyAmount))/mo")
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
