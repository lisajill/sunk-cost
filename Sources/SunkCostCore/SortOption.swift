import Foundation

public enum SortOption: String, CaseIterable, Sendable {
    case dateNewest
    case dateOldest
    case nameAZ
    case nameZA
    case costHighLow
    case costLowHigh

    public var label: String {
        switch self {
        case .dateNewest: return "Newest First"
        case .dateOldest: return "Oldest First"
        case .nameAZ: return "Name (A–Z)"
        case .nameZA: return "Name (Z–A)"
        case .costHighLow: return "Cost (High to Low)"
        case .costLowHigh: return "Cost (Low to High)"
        }
    }
}

public extension Array where Element == Item {
    /// Named `sorted(using:)` rather than `sorted(by:)` to avoid colliding
    /// with the standard library's closure-based overload.
    func sorted(using option: SortOption) -> [Item] {
        switch option {
        case .dateNewest:
            return sorted { blankLastOrder($0.dateAdded, $1.dateAdded, ascending: false) }
        case .dateOldest:
            return sorted { blankLastOrder($0.dateAdded, $1.dateAdded, ascending: true) }
        case .nameAZ:
            return sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .nameZA:
            return sorted { $0.name.localizedStandardCompare($1.name) == .orderedDescending }
        case .costHighLow:
            return sorted { blankLastOrder($0.cost, $1.cost, ascending: false) }
        case .costLowHigh:
            return sorted { blankLastOrder($0.cost, $1.cost, ascending: true) }
        }
    }
}

/// Blank values (no cost yet, no date on record) always sort to the end,
/// regardless of direction -- there's no meaningful "high"/"low" or
/// "newest"/"oldest" for something that isn't set.
private func blankLastOrder<T: Comparable>(_ lhs: T?, _ rhs: T?, ascending: Bool) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return ascending ? l < r : l > r
    case (nil, .some):
        return false
    case (.some, nil):
        return true
    case (nil, nil):
        return false
    }
}
