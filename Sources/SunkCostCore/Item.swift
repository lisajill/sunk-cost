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
    public var dateAdded: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        cost: Decimal?,
        status: Status,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cost = cost
        self.status = status
        self.dateAdded = dateAdded
    }
}

extension Item: Equatable {
    // dateAdded is compared to millisecond precision: JSON storage round-trips
    // dates through a fractional-seconds ISO 8601 string, which truncates
    // finer precision than that.
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
            && lhs.name == rhs.name
            && lhs.category == rhs.category
            && lhs.cost == rhs.cost
            && lhs.status == rhs.status
            && abs(lhs.dateAdded.timeIntervalSince(rhs.dateAdded)) < 0.001
    }
}
