import Foundation

public enum Status: String, Codable, CaseIterable, Sendable {
    case owned
    case gone
    case planned

    public func next() -> Status {
        switch self {
        case .owned: return .gone
        case .gone: return .planned
        case .planned: return .owned
        }
    }
}

public struct Item: Identifiable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var category: String
    public var cost: Decimal?
    public var status: Status
    /// When this item was added, if known. Blank for anything imported
    /// without a real date on record (e.g. from a spreadsheet that didn't
    /// track purchase dates) rather than defaulting to a fabricated one.
    public var dateAdded: Date?
    /// Free-text notes. Stored as plain text (portable for JSON/CSV);
    /// markdown and #hashtag styling are applied only when displaying it.
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        cost: Decimal?,
        status: Status,
        dateAdded: Date? = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cost = cost
        self.status = status
        self.dateAdded = dateAdded
        self.notes = notes
    }
}

extension Item: Equatable {
    // dateAdded is compared to millisecond precision: JSON storage round-trips
    // dates through a fractional-seconds ISO 8601 string, which truncates
    // finer precision than that.
    public static func == (lhs: Item, rhs: Item) -> Bool {
        guard
            lhs.id == rhs.id,
            lhs.name == rhs.name,
            lhs.category == rhs.category,
            lhs.cost == rhs.cost,
            lhs.status == rhs.status,
            lhs.notes == rhs.notes
        else {
            return false
        }
        switch (lhs.dateAdded, rhs.dateAdded) {
        case let (l?, r?):
            return abs(l.timeIntervalSince(r)) < 0.001
        case (nil, nil):
            return true
        default:
            return false
        }
    }
}
