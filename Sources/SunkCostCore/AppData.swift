import Foundation

public struct AppData: Codable, Equatable, Sendable {
    public var items: [Item]
    public var homeValue: Decimal?
    /// What was actually paid for the house -- distinct from Home Value
    /// (today's estimate), lets the app compute real appreciation.
    public var purchasePrice: Decimal?

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

    /// Assumed cost of selling, as percentages of Home Value -- the Sell
    /// Scenario tab's editable inputs. nil until the user sets them, at
    /// which point AppStore falls back to reasonable defaults (6% / 2%)
    /// rather than baking a fabricated default into the data itself.
    public var realtorCommissionPercent: Decimal?
    public var closingCostsPercent: Decimal?

    /// Compare: Stay vs. Rent vs. Buy Elsewhere -- all optional, editable
    /// assumptions for the multi-year projection. nil until the user sets
    /// them; AppStore supplies UI-level suggested defaults rather than
    /// baking fabricated figures into the data itself.
    public var comparisonProjectionYears: Int?
    public var homeAppreciationPercent: Decimal?
    public var investmentReturnPercent: Decimal?
    public var monthlyRent: Decimal?
    public var rentAnnualIncreasePercent: Decimal?
    public var newHomePrice: Decimal?
    public var newHomeDownPayment: Decimal?
    public var newMortgageRatePercent: Decimal?
    public var newMortgageTermYears: Int?

    /// PITI's Taxes and Insurance -- property tax as %/year of home value
    /// (scales with the assumed home value), insurance as a flat $/year.
    /// Separate figures for the current home and the hypothetical new one.
    public var propertyTaxPercent: Decimal?
    public var homeownersInsuranceAnnual: Decimal?
    public var newPropertyTaxPercent: Decimal?
    public var newHomeownersInsuranceAnnual: Decimal?

    public init(
        items: [Item] = [],
        homeValue: Decimal? = nil,
        purchasePrice: Decimal? = nil,
        mortgageOriginalAmount: Decimal? = nil,
        mortgageInterestRatePercent: Decimal? = nil,
        mortgageStartDate: Date? = nil,
        mortgageBalance: Decimal? = nil,
        mortgageTermYears: Int? = nil,
        monthlyPaymentOverride: Decimal? = nil,
        maintenanceCategories: [MaintenanceCategory] = [],
        realtorCommissionPercent: Decimal? = nil,
        closingCostsPercent: Decimal? = nil,
        comparisonProjectionYears: Int? = nil,
        homeAppreciationPercent: Decimal? = nil,
        investmentReturnPercent: Decimal? = nil,
        monthlyRent: Decimal? = nil,
        rentAnnualIncreasePercent: Decimal? = nil,
        newHomePrice: Decimal? = nil,
        newHomeDownPayment: Decimal? = nil,
        newMortgageRatePercent: Decimal? = nil,
        newMortgageTermYears: Int? = nil,
        propertyTaxPercent: Decimal? = nil,
        homeownersInsuranceAnnual: Decimal? = nil,
        newPropertyTaxPercent: Decimal? = nil,
        newHomeownersInsuranceAnnual: Decimal? = nil
    ) {
        self.items = items
        self.homeValue = homeValue
        self.purchasePrice = purchasePrice
        self.mortgageOriginalAmount = mortgageOriginalAmount
        self.mortgageInterestRatePercent = mortgageInterestRatePercent
        self.mortgageStartDate = mortgageStartDate
        self.mortgageBalance = mortgageBalance
        self.mortgageTermYears = mortgageTermYears
        self.monthlyPaymentOverride = monthlyPaymentOverride
        self.maintenanceCategories = maintenanceCategories
        self.realtorCommissionPercent = realtorCommissionPercent
        self.closingCostsPercent = closingCostsPercent
        self.comparisonProjectionYears = comparisonProjectionYears
        self.homeAppreciationPercent = homeAppreciationPercent
        self.investmentReturnPercent = investmentReturnPercent
        self.monthlyRent = monthlyRent
        self.rentAnnualIncreasePercent = rentAnnualIncreasePercent
        self.newHomePrice = newHomePrice
        self.newHomeDownPayment = newHomeDownPayment
        self.newMortgageRatePercent = newMortgageRatePercent
        self.newMortgageTermYears = newMortgageTermYears
        self.propertyTaxPercent = propertyTaxPercent
        self.homeownersInsuranceAnnual = homeownersInsuranceAnnual
        self.newPropertyTaxPercent = newPropertyTaxPercent
        self.newHomeownersInsuranceAnnual = newHomeownersInsuranceAnnual
    }

    private enum CodingKeys: String, CodingKey {
        case items, homeValue, purchasePrice, mortgageOriginalAmount, mortgageInterestRatePercent,
             mortgageStartDate, mortgageBalance, mortgageTermYears, monthlyPaymentOverride,
             maintenanceCategories, realtorCommissionPercent, closingCostsPercent,
             comparisonProjectionYears, homeAppreciationPercent, investmentReturnPercent,
             monthlyRent, rentAnnualIncreasePercent, newHomePrice, newHomeDownPayment,
             newMortgageRatePercent, newMortgageTermYears, propertyTaxPercent,
             homeownersInsuranceAnnual, newPropertyTaxPercent, newHomeownersInsuranceAnnual
    }

    // Manual decode so JSON saved before Maintenance existed (every data
    // file up to this point) still loads -- `items` etc. default via
    // decodeIfPresent, same pattern as Item's manual decode for `type`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([Item].self, forKey: .items) ?? []
        homeValue = try container.decodeIfPresent(Decimal.self, forKey: .homeValue)
        purchasePrice = try container.decodeIfPresent(Decimal.self, forKey: .purchasePrice)
        mortgageOriginalAmount = try container.decodeIfPresent(Decimal.self, forKey: .mortgageOriginalAmount)
        mortgageInterestRatePercent = try container.decodeIfPresent(Decimal.self, forKey: .mortgageInterestRatePercent)
        mortgageStartDate = try container.decodeIfPresent(Date.self, forKey: .mortgageStartDate)
        mortgageBalance = try container.decodeIfPresent(Decimal.self, forKey: .mortgageBalance)
        mortgageTermYears = try container.decodeIfPresent(Int.self, forKey: .mortgageTermYears)
        monthlyPaymentOverride = try container.decodeIfPresent(Decimal.self, forKey: .monthlyPaymentOverride)
        maintenanceCategories = try container.decodeIfPresent([MaintenanceCategory].self, forKey: .maintenanceCategories) ?? []
        realtorCommissionPercent = try container.decodeIfPresent(Decimal.self, forKey: .realtorCommissionPercent)
        closingCostsPercent = try container.decodeIfPresent(Decimal.self, forKey: .closingCostsPercent)
        comparisonProjectionYears = try container.decodeIfPresent(Int.self, forKey: .comparisonProjectionYears)
        homeAppreciationPercent = try container.decodeIfPresent(Decimal.self, forKey: .homeAppreciationPercent)
        investmentReturnPercent = try container.decodeIfPresent(Decimal.self, forKey: .investmentReturnPercent)
        monthlyRent = try container.decodeIfPresent(Decimal.self, forKey: .monthlyRent)
        rentAnnualIncreasePercent = try container.decodeIfPresent(Decimal.self, forKey: .rentAnnualIncreasePercent)
        newHomePrice = try container.decodeIfPresent(Decimal.self, forKey: .newHomePrice)
        newHomeDownPayment = try container.decodeIfPresent(Decimal.self, forKey: .newHomeDownPayment)
        newMortgageRatePercent = try container.decodeIfPresent(Decimal.self, forKey: .newMortgageRatePercent)
        newMortgageTermYears = try container.decodeIfPresent(Int.self, forKey: .newMortgageTermYears)
        propertyTaxPercent = try container.decodeIfPresent(Decimal.self, forKey: .propertyTaxPercent)
        homeownersInsuranceAnnual = try container.decodeIfPresent(Decimal.self, forKey: .homeownersInsuranceAnnual)
        newPropertyTaxPercent = try container.decodeIfPresent(Decimal.self, forKey: .newPropertyTaxPercent)
        newHomeownersInsuranceAnnual = try container.decodeIfPresent(Decimal.self, forKey: .newHomeownersInsuranceAnnual)
    }
}
