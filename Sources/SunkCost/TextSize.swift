import SwiftUI

/// Explicit point-size multipliers for Increase/Decrease Font Size.
///
/// This deliberately does NOT use SwiftUI's `DynamicTypeSize`/
/// `\.dynamicTypeSize` environment mechanism -- in practice it did not
/// visibly resize this app's text on macOS. A plain multiplier applied
/// directly to explicit font point sizes (see `Theme.scaledFont`) is
/// guaranteed to work because it's just arithmetic, not dependent on
/// platform text-style scaling behavior.
enum TextSizeControl {
    static let scales: [CGFloat] = [0.85, 1.0, 1.15, 1.35, 1.6, 1.9]
    static let defaultIndex = scales.firstIndex(of: 1.0) ?? 1
    static let userDefaultsKey = "SunkCost.TextSizeIndex"
}

private struct AppTextScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var appTextScale: CGFloat {
        get { self[AppTextScaleKey.self] }
        set { self[AppTextScaleKey.self] = newValue }
    }
}
