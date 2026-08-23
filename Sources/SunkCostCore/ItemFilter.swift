import Foundation

public struct ItemFilter: Equatable, Sendable {
    public var category: String?
    public var status: Status?
    public var searchText: String?

    public init(category: String? = nil, status: Status? = nil, searchText: String? = nil) {
        self.category = category
        self.status = status
        self.searchText = searchText
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
        let trimmedSearch = filter.searchText?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let search = (trimmedSearch?.isEmpty ?? true) ? nil : trimmedSearch

        return self.filter { item in
            (filter.category == nil || item.category == filter.category)
                && (filter.status == nil || item.status == filter.status)
                && (search == nil || matches(item, search: search!))
        }
    }

    var distinctCategories: [String] {
        let categories: [String] = self.map { $0.category }
        return Set(categories).sorted()
    }

    private func matches(_ item: Item, search: String) -> Bool {
        item.name.lowercased().contains(search)
            || item.category.lowercased().contains(search)
            || (item.notes?.lowercased().contains(search) ?? false)
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
