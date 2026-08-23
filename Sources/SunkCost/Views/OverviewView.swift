import SwiftUI

/// The app's real landing screen -- v1 went straight to the item list;
/// this is a proper dashboard instead, the first structural change in
/// the ground-up redesign (see the "redesign" branch / `v1.0` tag for
/// the before). Wraps the existing totals (`SummaryHeaderView`) with the
/// house motif and an actual picture of spending -- the donut chart --
/// so there's something to look at, not just numbers to read.
struct OverviewView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroSection
                SummaryHeaderView()
                if !store.spendByCategory.isEmpty {
                    categoryChartCard
                }
            }
            .padding(.bottom, 24)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .id(store.appearanceMode)
    }

    private var heroSection: some View {
        VStack(spacing: 6) {
            HouseAccent(color: Theme.positive, size: 84, lineWidth: 4)
            Text("Sunk Cost")
                .font(Theme.scaledFont(Theme.FontSize.title2, weight: .heavy, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Text("What your house actually costs.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
        }
        .padding(.top, 20)
    }

    private var categoryChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPEND BY CATEGORY")
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(1.2)
                .foregroundStyle(Theme.inkSecondary)

            CategoryDonutChart(entries: store.spendByCategory)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.ledgerPaper)
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 8)
    }
}
