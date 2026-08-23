import SwiftUI

/// First-launch introduction -- shown once (tracked by
/// `store.hasCompletedOnboarding`), explaining what the app tracks and
/// how the privacy/storage model works, since a brand-new user otherwise
/// lands on a completely blank app with no context. Offers a one-tap way
/// to see it populated with fake data before typing in anything real.
struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to Sunk Cost")
                    .font(Theme.scaledFont(Theme.FontSize.title2, weight: .semibold, scale: store.textScale))
                    .foregroundStyle(Theme.ink)
                Text("A private, local tracker for what your house actually costs.")
                    .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

            VStack(alignment: .leading, spacing: 14) {
                featureRow(
                    icon: "hammer",
                    title: "Cost to improve",
                    detail: "Track one-time spending on furniture and upgrades."
                )
                featureRow(
                    icon: "wrench.and.screwdriver",
                    title: "Cost to keep",
                    detail: "See what running the house costs month to month."
                )
                featureRow(
                    icon: "house",
                    title: "Cost to leave",
                    detail: "See what you'd walk away with if you sold today."
                )
            }
            .padding(16)
            .background(Theme.ledgerPaper)
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text("Your data lives in a plain file on this Mac. Nothing is ever sent anywhere — you can point storage at any folder you like later, including one that syncs via iCloud Drive or Dropbox, from Settings.")
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)

            HStack {
                Spacer()
                Button("Load Sample Data") {
                    store.loadSampleData()
                    store.hasCompletedOnboarding = true
                    dismiss()
                }
                Button("Start Fresh") {
                    store.hasCompletedOnboarding = true
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
        }
        .padding(28)
        .frame(width: 420)
    }

    @ViewBuilder
    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(Theme.gold)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.scaledFont(Theme.FontSize.callout, weight: .semibold, scale: store.textScale))
                    .foregroundStyle(Theme.ink)
                Text(detail)
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}
