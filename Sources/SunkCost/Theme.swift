import SwiftUI
import AppKit

/// Visual identity for Sunk Cost, v2 ("redesign" branch): vibrant, warm,
/// and rounded, in deliberate contrast to v1's muted ledger-paper look
/// (tagged `v1.0` -- see that tag/the `main` branch to compare). Same
/// symbol names as before on purpose: every view already reads its colors
/// and fonts through `Theme`, so redefining the values here re-skins the
/// whole app without touching each view file individually.
///
/// Status colors still carry meaning rather than being arbitrary:
/// `positive` reads as "in the black" (an asset you still hold),
/// terracotta as pending/warm (echoes the app icon), taupe as
/// settled/past -- same semantics as v1, just turned up in saturation
/// and brightness.
///
/// `positive` is a rich indigo/violet, not blue -- Lisa's favorite color,
/// and it's the app's main accent (house graphic, tint, "Owned" status),
/// so this one choice makes purple show up everywhere at once. Still
/// colorblind-safe: a *blue-leaning* violet reads mostly through the same
/// blue channel that made plain blue safe in v1, staying well clear of
/// the red/orange/yellow cluster that's genuinely risky for red-green
/// colorblindness. A red-leaning purple (magenta, orchid) would have
/// been the wrong choice here -- that's the one to avoid.
///
/// The status trio (`positive` / taupe / terracotta) is still chosen to
/// stay distinguishable under protanopia, deuteranopia, and tritanopia --
/// deliberately not red-vs-green, which is the one pairing colorblind
/// users most often can't tell apart. Color is also never the only
/// signal: every status has a text label alongside it. `terracotta` and
/// `ledgerRed` sit closer together in hue (both warm), which is fine
/// since they're never shown as adjacent choices needing direct
/// discrimination -- terracotta is a status color, ledgerRed only
/// appears on a net-loss figure.
enum Theme {
    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }

    static let ledgerPaper = adaptive(
        light: NSColor(calibratedRed: 0.984, green: 0.965, blue: 0.937, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.145, green: 0.125, blue: 0.161, alpha: 1.0)
    )
    static let ledgerBorder = adaptive(
        light: NSColor(calibratedRed: 0.914, green: 0.867, blue: 0.847, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.271, green: 0.231, blue: 0.278, alpha: 1.0)
    )
    static let ink = adaptive(
        light: NSColor(calibratedRed: 0.114, green: 0.106, blue: 0.129, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.961, green: 0.949, blue: 0.933, alpha: 1.0)
    )
    static let inkSecondary = adaptive(
        light: NSColor(calibratedRed: 0.420, green: 0.396, blue: 0.443, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.686, green: 0.655, blue: 0.702, alpha: 1.0)
    )
    static let terracotta = adaptive(
        light: NSColor(calibratedRed: 1.000, green: 0.475, blue: 0.208, alpha: 1.0),
        dark: NSColor(calibratedRed: 1.000, green: 0.616, blue: 0.376, alpha: 1.0)
    )
    static let taupe = adaptive(
        light: NSColor(calibratedRed: 0.588, green: 0.545, blue: 0.573, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.722, green: 0.686, blue: 0.710, alpha: 1.0)
    )
    /// "Positive / in the black" color, and the app's accent/tint -- see
    /// the type-level doc comment for why this is a blue-leaning violet
    /// rather than plain blue or green.
    static let positive = adaptive(
        light: NSColor(calibratedRed: 0.424, green: 0.310, blue: 0.820, alpha: 1.0),
        dark: NSColor(calibratedRed: 0.667, green: 0.557, blue: 0.980, alpha: 1.0)
    )
    /// "In the red" -- classic bookkeeping color for a deficit. Blue-vs-red
    /// stays distinguishable even for red-green colorblind users, since it's
    /// not a hue pair that relies on the red/green channel confusion.
    static let ledgerRed = adaptive(
        light: NSColor(calibratedRed: 0.925, green: 0.204, blue: 0.302, alpha: 1.0),
        dark: NSColor(calibratedRed: 1.000, green: 0.416, blue: 0.478, alpha: 1.0)
    )

    /// Base point sizes this app's text roles use at 1.0 scale -- bumped up
    /// noticeably from v1 as part of the "vibrant, easy, accessible"
    /// redesign: bigger text reads as friendlier *and* is more legible,
    /// not just a style choice.
    enum FontSize {
        static let totalNumeral: CGFloat = 32
        static let title2: CGFloat = 20
        static let title3: CGFloat = 17
        static let headline: CGFloat = 15
        static let body: CGFloat = 14
        static let callout: CGFloat = 13
        static let subheadline: CGFloat = 12
        static let caption: CGFloat = 11
        static let caption2: CGFloat = 11
    }

    /// Every font in the app should be built through this so Increase/
    /// Decrease Font Size actually changes what's on screen -- explicit
    /// point-size math, not platform Dynamic Type behavior. Defaults to
    /// `.rounded` (SwiftUI's built-in rounded system font, no external
    /// dependency) -- this one change is what makes every screen in the
    /// app read as friendlier, since every call site already goes through
    /// here without specifying a design.
    static func scaledFont(
        _ baseSize: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded,
        scale: CGFloat
    ) -> Font {
        .system(size: baseSize * scale, weight: weight, design: design)
    }

    static func totalNumeral(scale: CGFloat) -> Font {
        scaledFont(FontSize.totalNumeral, weight: .heavy, scale: scale)
    }

    static func ledgerLabel(scale: CGFloat) -> Font {
        scaledFont(FontSize.caption, weight: .bold, scale: scale)
    }

    /// Replaces digits with bullets for privacy mode, keeping the currency
    /// symbol/punctuation so the figure still reads as "a dollar amount" in
    /// a screenshot, just not which one.
    static func mask(_ text: String) -> String {
        String(text.map { $0.isNumber ? "•" : $0 })
    }
}

extension View {
    /// Appends a small "hover for more" info icon and attaches the tooltip
    /// to the whole group. For plain text/number displays specifically --
    /// unlike a button or picker, a bare `.help()` on static text gives no
    /// visual hint that hovering does anything.
    func infoTooltip(_ text: String, scale: CGFloat) -> some View {
        HStack(spacing: 3) {
            self
            Image(systemName: "info.circle")
                .font(Theme.scaledFont(Theme.FontSize.caption2, scale: scale))
                .foregroundStyle(Theme.inkSecondary)
        }
        .help(text)
    }
}
