import Foundation

public struct ItemFilter: Equatable, Sendable {
    public var category: String?
    public var status: Status?

    public init(category: String? = nil, status: Status? = nil) {
        self.category = category
        self.status = status
    }
}

/// What the status filter should become after tapping a row's status pill
/// for `tapped`: sets it, unless it's already the active filter, in which
/// case tapping again clears back to "All".
public func toggledStatusFilter(current: Status?, tapped: Status) -> Status? {
    current == tapped ? nil : tapped
}

public extension Array where Element == Item {
    func filtered(by filter: ItemFilter) -> [Item] {
        self.filter { item in
            (filter.category == nil || item.category == filter.category)
                && (filter.status == nil || item.status == filter.status)
        }
    }

    func sortedNewestFirst() -> [Item] {
        sorted { $0.dateAdded > $1.dateAdded }
    }

    var distinctCategories: [String] {
        let categories: [String] = self.map { $0.category }
        return Set(categories).sorted()
    }

    func renamingCategory(from oldName: String, to newName: String) -> [Item] {
        map { item in
            var updated = item
            if updated.category == oldName {
                updated.category = newName
            }
            return updated
        }
    }
}
