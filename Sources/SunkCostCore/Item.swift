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

public enum ItemType: String, Codable, CaseIterable, Sendable {
    /// Stays with the house if sold -- a fence, a deck, a mini-split.
    case value
    /// She'd take it with her if she moved -- furniture, electronics.
    case moveable

    public var label: String {
        switch self {
        case .value: return "Value"
        case .moveable: return "Moveable"
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
    /// Whether this item's cost stays with the house (raises its value) or
    /// leaves with the owner. Drives what counts toward the "vs. Home
    /// Value" comparison.
    public var type: ItemType

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        cost: Decimal?,
        status: Status,
        dateAdded: Date? = Date(),
        notes: String? = nil,
        type: ItemType = .moveable
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cost = cost
        self.status = status
        self.dateAdded = dateAdded
        self.notes = notes
        self.type = type
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, category, cost, status, dateAdded, notes, type
    }

    // Manual decode so JSON/CSV predating the `type` field (every item
    // saved before this feature existed) still loads instead of failing --
    // falls back to .moveable, the same default new items get. Real
    // pre-existing data gets an explicit, correct value from a one-time
    // migration rather than relying on this fallback in practice.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(String.self, forKey: .category)
        cost = try container.decodeIfPresent(Decimal.self, forKey: .cost)
        status = try container.decode(Status.self, forKey: .status)
        dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        type = try container.decodeIfPresent(ItemType.self, forKey: .type) ?? .moveable
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
            lhs.notes == rhs.notes,
            lhs.type == rhs.type
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
