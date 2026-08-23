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

    public init(
        items: [Item] = [],
        homeValue: Decimal? = nil,
        mortgageOriginalAmount: Decimal? = nil,
        mortgageInterestRatePercent: Decimal? = nil,
        mortgageStartDate: Date? = nil,
        mortgageBalance: Decimal? = nil,
        mortgageTermYears: Int? = nil,
        monthlyPaymentOverride: Decimal? = nil
    ) {
        self.items = items
        self.homeValue = homeValue
        self.mortgageOriginalAmount = mortgageOriginalAmount
        self.mortgageInterestRatePercent = mortgageInterestRatePercent
        self.mortgageStartDate = mortgageStartDate
        self.mortgageBalance = mortgageBalance
        self.mortgageTermYears = mortgageTermYears
        self.monthlyPaymentOverride = monthlyPaymentOverride
    }
}
