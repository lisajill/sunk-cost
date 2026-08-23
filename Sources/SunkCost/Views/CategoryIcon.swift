import SwiftUI

/// Best-guess icon for a free-text category name, so the item list and
/// spend-by-category chart are scannable by shape, not just words.
/// Categories are whatever the user types (not a fixed enum), so this
/// matches on keywords with a sensible fallback rather than requiring an
/// exact name -- a new/unrecognized category still gets a reasonable icon
/// instead of nothing.
enum CategoryIcon {
    private static let keywordMap: [(keywords: [String], symbol: String)] = [
        (["furniture", "sofa", "couch", "chair", "table"], "sofa.fill"),
        (["kitchen", "appliance"], "fork.knife"),
        (["bath", "shower", "plumbing"], "shower.fill"),
        (["bedroom", "bed"], "bed.double.fill"),
        (["electric", "wiring", "light"], "bolt.fill"),
        (["heat", "hvac", "furnace", "air condition"], "flame.fill"),
        (["yard", "garden", "landscap", "exterior", "outdoor"], "leaf.fill"),
        (["garage", "car", "driveway"], "car.fill"),
        (["paint"], "paintbrush.fill"),
        (["electronic", "tv", "entertainment"], "tv.fill"),
        (["roof"], "house.fill"),
        (["upgrade", "renovation", "improvement", "property"], "hammer.fill"),
        (["repair", "maintenance"], "wrench.and.screwdriver.fill"),
    ]

    static func symbol(for category: String) -> String {
        let lowered = category.lowercased()
        for entry in keywordMap where entry.keywords.contains(where: { lowered.contains($0) }) {
            return entry.symbol
        }
        return "square.grid.2x2.fill"
    }
}
