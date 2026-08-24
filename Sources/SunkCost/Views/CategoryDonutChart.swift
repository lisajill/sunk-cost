import SwiftUI

/// A hand-drawn donut chart (stacked, rotated `Circle().trim` segments --
/// no charting library needed) showing spend by category, with a legend
/// using the same category icons as the item list so the two views read
/// as one visual language.
struct CategoryDonutChart: View {
    @Environment(AppStore.self) private var store
    let entries: [(category: String, total: Decimal)]

    private static let palette: [Color] = [Theme.chartPositive, Theme.chartGold, Theme.chartTaupe, Theme.chartRed]

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

    private var total: Decimal { entries.reduce(0) { $0 + $1.total } }

    private struct Segment {
        let category: String
        let total: Decimal
        let color: Color
        let start: Double
        let end: Double
    }

    private var segments: [Segment] {
        guard total > 0 else { return [] }
        let totalDouble = Double(truncating: total as NSDecimalNumber)
        var cumulative = 0.0
        return entries.enumerated().map { index, entry in
            let fraction = Double(truncating: entry.total as NSDecimalNumber) / totalDouble
            let start = cumulative
            cumulative += fraction
            let baseColor = Self.palette[index % Self.palette.count]
            return Segment(
                category: entry.category,
                total: entry.total,
                color: index < Self.palette.count ? baseColor : baseColor.opacity(0.55),
                start: start,
                end: cumulative
            )
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            Spacer().frame(width: 8)

            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    Circle()
                        .trim(from: segment.start, to: max(segment.end, segment.start + 0.0015))
                        .stroke(segment.color, style: StrokeStyle(lineWidth: 22, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 2) {
                    Text(formatted(total))
                        .font(Theme.scaledFont(Theme.FontSize.callout, weight: .bold, scale: store.textScale))
                        .foregroundStyle(Theme.ink)
                    Text("TOTAL")
                        .font(Theme.scaledFont(Theme.FontSize.caption2, weight: .semibold, scale: store.textScale))
                        .tracking(0.6)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .frame(width: 140, height: 140)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    HStack(spacing: 8) {
                        Image(systemName: CategoryIcon.symbol(for: segment.category))
                            .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                            .foregroundStyle(segment.color)
                            .frame(width: 18)
                        Text(segment.category)
                            .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(formatted(segment.total))
                            .font(Theme.scaledFont(Theme.FontSize.callout, weight: .semibold, scale: store.textScale))
                            .monospacedDigit()
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
