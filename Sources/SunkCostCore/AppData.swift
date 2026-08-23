import Foundation

public struct AppData: Codable, Equatable, Sendable {
    public var items: [Item]
    public var homeValue: Decimal?

    // Original loan details are kept for reference; the balance is what
    // actually feeds the equity calculation, and is meant to be updated by
    // hand whenever the user checks their latest mortgage statement.
    public var mortgageOriginalAmount: Decimal?
    public var mortgageInterestRatePercent: Decimal?
    public var mortgageStartDate: Date?
    public var mortgageBalance: Decimal?
    public var mortgageTermYears: Int?
    /// A manually-entered monthly payment, if the user wants to enter their
    /// real statement figure instead of the calculated estimate.
    public var monthlyPaymentOverride: Decimal?

    public var maintenanceCategories: [MaintenanceCategory]
    public var maintenancePayments: [MaintenancePayment]

    public init(
        items: [Item] = [],
        homeValue: Decimal? = nil,
        mortgageOriginalAmount: Decimal? = nil,
        mortgageInterestRatePercent: Decimal? = nil,
        mortgageStartDate: Date? = nil,
        mortgageBalance: Decimal? = nil,
        mortgageTermYears: Int? = nil,
        monthlyPaymentOverride: Decimal? = nil,
        maintenanceCategories: [MaintenanceCategory] = [],
        maintenancePayments: [MaintenancePayment] = []
    ) {
        self.items = items
        self.homeValue = homeValue
        self.mortgageOriginalAmount = mortgageOriginalAmount
        self.mortgageInterestRatePercent = mortgageInterestRatePercent
        self.mortgageStartDate = mortgageStartDate
        self.mortgageBalance = mortgageBalance
        self.mortgageTermYears = mortgageTermYears
        self.monthlyPaymentOverride = monthlyPaymentOverride
        self.maintenanceCategories = maintenanceCategories
        self.maintenancePayments = maintenancePayments
    }

    private enum CodingKeys: String, CodingKey {
        case items, homeValue, mortgageOriginalAmount, mortgageInterestRatePercent,
             mortgageStartDate, mortgageBalance, mortgageTermYears, monthlyPaymentOverride,
             maintenanceCategories, maintenancePayments
    }

    // Manual decode so JSON saved before Maintenance existed (every data
    // file up to this point) still loads -- `items` etc. default via
    // decodeIfPresent, same pattern as Item's manual decode for `type`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([Item].self, forKey: .items) ?? []
        homeValue = try container.decodeIfPresent(Decimal.self, forKey: .homeValue)
        mortgageOriginalAmount = try container.decodeIfPresent(Decimal.self, forKey: .mortgageOriginalAmount)
        mortgageInterestRatePercent = try container.decodeIfPresent(Decimal.self, forKey: .mortgageInterestRatePercent)
        mortgageStartDate = try container.decodeIfPresent(Date.self, forKey: .mortgageStartDate)
        mortgageBalance = try container.decodeIfPresent(Decimal.self, forKey: .mortgageBalance)
        mortgageTermYears = try container.decodeIfPresent(Int.self, forKey: .mortgageTermYears)
        monthlyPaymentOverride = try container.decodeIfPresent(Decimal.self, forKey: .monthlyPaymentOverride)
        maintenanceCategories = try container.decodeIfPresent([MaintenanceCategory].self, forKey: .maintenanceCategories) ?? []
        maintenancePayments = try container.decodeIfPresent([MaintenancePayment].self, forKey: .maintenancePayments) ?? []
    }
}
