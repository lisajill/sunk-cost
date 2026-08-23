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
    /// Whether this cost is effectively fixed (utilities) or discretionary
    /// (a service that could be cut to save money). Drives the
    /// Required/Optional savings view in Maintenance.
    public var isRequired: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        monthlyAmount: Decimal,
        notes: String? = nil,
        isRequired: Bool = true
    ) {
        self.id = id
        self.name = name
        self.monthlyAmount = monthlyAmount
        self.notes = notes
        self.isRequired = isRequired
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, monthlyAmount, notes, isRequired
    }

    // Manual decode so JSON predating `isRequired` (every category saved
    // before this feature existed) still loads -- falls back to true, the
    // same "unclassified defaults to the safe assumption" reasoning as
    // Item.type falling back to .moveable.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        monthlyAmount = try container.decode(Decimal.self, forKey: .monthlyAmount)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? true
    }
}
