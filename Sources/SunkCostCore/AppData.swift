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
    /// One-time move-in costs -- come off the sale proceeds before the
    /// rest is invested, the same way a down payment reduces the leftover
    /// cash invested in Buying Elsewhere. Ongoing pet rent, unlike the
    /// deposits, is monthly and only affects the displayed cost, not the
    /// Ending Net Worth figure -- consistent with Monthly Rent itself.
    public var securityDeposit: Decimal?
    public var petDeposit: Decimal?
    public var petRentMonthly: Decimal?
    public var newHomePrice: Decimal?
    public var newHomeDownPayment: Decimal?
    public var newMortgageRatePercent: Decimal?
    public var newMortgageTermYears: Int?

    /// PITI's Taxes and Insurance -- both flat $/year (property tax used to
    /// be a %-of-home-value so it would auto-scale with the assumed value,
    /// but every real-world source for this number -- listings, loan
    /// estimates, tax bills -- quotes a dollar figure, never a rate, so
    /// that auto-scaling wasn't worth the friction of converting a real
    /// number into a percent by hand every time. Separate figures for the
    /// current home and the hypothetical new one.
    public var propertyTaxAnnual: Decimal?
    public var homeownersInsuranceAnnual: Decimal?
    public var newPropertyTaxAnnual: Decimal?
    public var newHomeownersInsuranceAnnual: Decimal?
    /// HOA dues, already monthly (unlike tax/insurance above) since that's
    /// how every real-world source already quotes it -- no annual/monthly
    /// ambiguity to resolve for this one.
    public var hoaMonthly: Decimal?
    public var newHoaMonthly: Decimal?

    /// Named, saved snapshots of the Compare assumptions -- lets the user
    /// flip between several what-ifs without retyping.
    public var savedComparisonScenarios: [ComparisonScenario]

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
        securityDeposit: Decimal? = nil,
        petDeposit: Decimal? = nil,
        petRentMonthly: Decimal? = nil,
        newHomePrice: Decimal? = nil,
        newHomeDownPayment: Decimal? = nil,
        newMortgageRatePercent: Decimal? = nil,
        newMortgageTermYears: Int? = nil,
        propertyTaxAnnual: Decimal? = nil,
        homeownersInsuranceAnnual: Decimal? = nil,
        newPropertyTaxAnnual: Decimal? = nil,
        newHomeownersInsuranceAnnual: Decimal? = nil,
        hoaMonthly: Decimal? = nil,
        newHoaMonthly: Decimal? = nil,
        savedComparisonScenarios: [ComparisonScenario] = []
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
        self.securityDeposit = securityDeposit
        self.petDeposit = petDeposit
        self.petRentMonthly = petRentMonthly
        self.newHomePrice = newHomePrice
        self.newHomeDownPayment = newHomeDownPayment
        self.newMortgageRatePercent = newMortgageRatePercent
        self.newMortgageTermYears = newMortgageTermYears
        self.propertyTaxAnnual = propertyTaxAnnual
        self.homeownersInsuranceAnnual = homeownersInsuranceAnnual
        self.newPropertyTaxAnnual = newPropertyTaxAnnual
        self.newHomeownersInsuranceAnnual = newHomeownersInsuranceAnnual
        self.hoaMonthly = hoaMonthly
        self.newHoaMonthly = newHoaMonthly
        self.savedComparisonScenarios = savedComparisonScenarios
    }

    private enum CodingKeys: String, CodingKey {
        case items, homeValue, purchasePrice, mortgageOriginalAmount, mortgageInterestRatePercent,
             mortgageStartDate, mortgageBalance, mortgageTermYears, monthlyPaymentOverride,
             maintenanceCategories, realtorCommissionPercent, closingCostsPercent,
             comparisonProjectionYears, homeAppreciationPercent, investmentReturnPercent,
             monthlyRent, rentAnnualIncreasePercent, securityDeposit, petDeposit, petRentMonthly,
             newHomePrice, newHomeDownPayment,
             newMortgageRatePercent, newMortgageTermYears, propertyTaxAnnual,
             homeownersInsuranceAnnual, newPropertyTaxAnnual, newHomeownersInsuranceAnnual,
             hoaMonthly, newHoaMonthly, savedComparisonScenarios
    }

    /// Read-only keys for a schema that no longer exists on the write side
    /// -- property tax used to be stored as a %/year of home value. Kept
    /// only so a JSON file saved before this change still loads with a
    /// sensible number instead of silently losing the assumption; every
    /// save from here on writes `propertyTaxAnnual`/`newPropertyTaxAnnual`
    /// instead, so this enum (deliberately separate from `CodingKeys`,
    /// which also drives the synthesized `encode(to:)`) never gets written.
    private enum LegacyCodingKeys: String, CodingKey {
        case propertyTaxPercent, newPropertyTaxPercent
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
        securityDeposit = try container.decodeIfPresent(Decimal.self, forKey: .securityDeposit)
        petDeposit = try container.decodeIfPresent(Decimal.self, forKey: .petDeposit)
        petRentMonthly = try container.decodeIfPresent(Decimal.self, forKey: .petRentMonthly)
        newHomePrice = try container.decodeIfPresent(Decimal.self, forKey: .newHomePrice)
        newHomeDownPayment = try container.decodeIfPresent(Decimal.self, forKey: .newHomeDownPayment)
        newMortgageRatePercent = try container.decodeIfPresent(Decimal.self, forKey: .newMortgageRatePercent)
        newMortgageTermYears = try container.decodeIfPresent(Int.self, forKey: .newMortgageTermYears)
        homeownersInsuranceAnnual = try container.decodeIfPresent(Decimal.self, forKey: .homeownersInsuranceAnnual)
        newHomeownersInsuranceAnnual = try container.decodeIfPresent(Decimal.self, forKey: .newHomeownersInsuranceAnnual)

        if let annual = try container.decodeIfPresent(Decimal.self, forKey: .propertyTaxAnnual) {
            propertyTaxAnnual = annual
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            if let legacyPercent = try legacy.decodeIfPresent(Decimal.self, forKey: .propertyTaxPercent), let homeValue {
                propertyTaxAnnual = homeValue * legacyPercent / 100
            } else {
                propertyTaxAnnual = nil
            }
        }

        if let annual = try container.decodeIfPresent(Decimal.self, forKey: .newPropertyTaxAnnual) {
            newPropertyTaxAnnual = annual
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            if let legacyPercent = try legacy.decodeIfPresent(Decimal.self, forKey: .newPropertyTaxPercent), let newHomePrice {
                newPropertyTaxAnnual = newHomePrice * legacyPercent / 100
            } else {
                newPropertyTaxAnnual = nil
            }
        }
        hoaMonthly = try container.decodeIfPresent(Decimal.self, forKey: .hoaMonthly)
        newHoaMonthly = try container.decodeIfPresent(Decimal.self, forKey: .newHoaMonthly)
        savedComparisonScenarios = try container.decodeIfPresent([ComparisonScenario].self, forKey: .savedComparisonScenarios) ?? []
    }
}
