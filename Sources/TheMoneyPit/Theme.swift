import SwiftUI
import AppKit

/// Visual identity for The Money Pit: a household ledger. Old bookkeeping
/// ledgers were printed on pale green paper -- that's where the summary
/// card's color comes from. Status colors carry meaning rather than being
/// arbitrary: deep green reads as "in the black" (an asset you still hold),
/// terracotta as pending/warm (echoes the app icon), taupe as settled/past.
enum Theme {
    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    static let ledgerPaper = adaptive(
        light: NSColor(calibratedRed: 0.914, green: 0.933, blue: 0.890, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.118, green: 0.169, blue: 0.133, alpha: 1.0)
    )
    static let ledgerBorder = adaptive(
        light: NSColor(calibratedRed: 0.780, green: 0.824, blue: 0.737, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.227, green: 0.290, blue: 0.239, alpha: 1.0)
    )
    static let ink = adaptive(
        light: NSColor(calibratedRed: 0.122, green: 0.165, blue: 0.125, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.918, green: 0.941, blue: 0.894, alpha: 1.0)
    )
    static let inkSecondary = adaptive(
        light: NSColor(calibratedRed: 0.357, green: 0.420, blue: 0.341, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.604, green: 0.682, blue: 0.573, alpha: 1.0)
    )
    static let terracotta = adaptive(
        light: NSColor(calibratedRed: 0.757, green: 0.404, blue: 0.235, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.886, green: 0.537, blue: 0.361, alpha: 1.0)
    )
    static let taupe = adaptive(
        light: NSColor(calibratedRed: 0.541, green: 0.502, blue: 0.447, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.655, green: 0.612, blue: 0.549, alpha: 1.0)
    )
    /// Deep ledger green: doubles as the "positive / in the black" color and
    /// the app's accent/tint, replacing the default system blue.
    static let ledgerGreen = adaptive(
        light: NSColor(calibratedRed: 0.184, green: 0.357, blue: 0.247, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.435, green: 0.796, blue: 0.580, alpha: 1.0)
    )
    /// "In the red" -- classic bookkeeping color for a deficit.
    static let ledgerRed = adaptive(
        light: NSColor(calibratedRed: 0.690, green: 0.227, blue: 0.180, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.878, green: 0.478, blue: 0.431, alpha: 1.0)
    )

    /// Base point sizes this app's text roles use at 1.0 scale -- chosen to
    /// approximate macOS's real system text-style sizes closely enough that
    /// the default (unscaled) look is unchanged from before.
    enum FontSize {
        static let totalNumeral: CGFloat = 24
        static let title2: CGFloat = 17
        static let title3: CGFloat = 15
        static let headline: CGFloat = 13
        static let body: CGFloat = 13
        static let callout: CGFloat = 12
        static let subheadline: CGFloat = 11
        static let caption: CGFloat = 10
        static let caption2: CGFloat = 10
    }

    /// Every font in the app should be built through this so Increase/
    /// Decrease Font Size actually changes what's on screen -- explicit
    /// point-size math, not platform Dynamic Type behavior.
    static func scaledFont(
        _ baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        scale: CGFloat
    ) -> Font {
        .system(size: baseSize * scale, weight: weight, design: design)
    }

    static func totalNumeral(scale: CGFloat) -> Font {
        scaledFont(FontSize.totalNumeral, weight: .bold, design: .serif, scale: scale)
    }

    static func ledgerLabel(scale: CGFloat) -> Font {
        scaledFont(FontSize.caption, weight: .semibold, scale: scale)
    }

    /// Replaces digits with bullets for privacy mode, keeping the currency
    /// symbol/punctuation so the figure still reads as "a dollar amount" in
    /// a screenshot, just not which one.
    static func mask(_ text: String) -> String {
        String(text.map { $0.isNumber ? "•" : $0 })
    }
}
