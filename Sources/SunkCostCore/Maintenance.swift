import Foundation

/// A recurring cost bucket (Oil, Electricity, Landscaping...) -- "cost to
/// keep the house running," tracked separately from one-time items.
public struct MaintenanceCategory: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    /// Reference only -- shown alongside the actual total, not enforced as
    /// a budget. Avoids date-boundary bookkeeping (which month is "this
    /// month") that wasn't asked for.
    public var expectedMonthlyAmount: Decimal?

    public init(id: UUID = UUID(), name: String, expectedMonthlyAmount: Decimal? = nil) {
        self.id = id
        self.name = name
        self.expectedMonthlyAmount = expectedMonthlyAmount
    }
}

/// One dated payment against a MaintenanceCategory.
public struct MaintenancePayment: Identifiable, Codable, Sendable {
    public var id: UUID
    public var categoryID: UUID
    public var amount: Decimal
    public var date: Date
    /// Same plain-text-with-markdown/#hashtag treatment as Item.notes.
    public var notes: String?

    public init(
        id: UUID = UUID(),
        categoryID: UUID,
        amount: Decimal,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.categoryID = categoryID
        self.amount = amount
        self.date = date
        self.notes = notes
    }
}

extension MaintenancePayment: Equatable {
    // date is compared to millisecond precision: JSON storage round-trips
    // dates through a fractional-seconds ISO 8601 string, which truncates
    // finer precision than that (same reasoning as Item.dateAdded).
    public static func == (lhs: MaintenancePayment, rhs: MaintenancePayment) -> Bool {
        lhs.id == rhs.id
            && lhs.categoryID == rhs.categoryID
            && lhs.amount == rhs.amount
            && lhs.notes == rhs.notes
            && abs(lhs.date.timeIntervalSince(rhs.date)) < 0.001
    }
}
