import SwiftUI

/// The steps available via Increase/Decrease Font Size. Capped below the
/// most extreme accessibility sizes so fixed-width chrome (the sheet widths,
/// the window's minimum size) still holds up without needing per-size
/// layout overrides.
enum TextSizeControl {
    // Coarser jumps than the full DynamicTypeSize range so each click of
    // Increase/Decrease Font Size produces an obviously visible change,
    // rather than the barely-perceptible steps between adjacent sizes.
    static let steps: [DynamicTypeSize] = [
        .small, .large, .xxLarge, .accessibility1, .accessibility2, .accessibility3,
    ]
    static let defaultIndex = steps.firstIndex(of: .large) ?? 1
    static let userDefaultsKey = "TheMoneyPit.TextSizeIndex"
}
