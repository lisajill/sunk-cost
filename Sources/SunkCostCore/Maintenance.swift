import Foundation

/// A recurring cost bucket (Oil, Electricity, Landscaping...) -- "cost to
/// keep the house running," tracked separately from one-time items. Just
/// the recurring monthly amount itself -- not a payment log against a
/// budget, since that's more detail than is actually wanted here.
public struct MaintenanceCategory: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var monthlyAmount: Decimal
    /// Same plain-text-with-markdown/#hashtag treatment as Item.notes.
    public var notes: String?

    public init(id: UUID = UUID(), name: String, monthlyAmount: Decimal, notes: String? = nil) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.notes = notes
    }
}
