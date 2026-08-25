import Foundation

/// A named, saved snapshot of the Compare tab's assumption fields --
/// lets the user try several what-ifs and flip between them without
/// retyping. Deliberately doesn't capture Home Value, mortgage balance,
/// Purchase Price, or Sell Scenario's selling-cost percentages -- those
/// are facts about the actual house/sale, not "what-if" assumptions, and
/// stay shared across every saved scenario.
public struct ComparisonScenario: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var projectionYears: Int?
    public var homeAppreciationPercent: Decimal?
    public var investmentReturnPercent: Decimal?
    public var monthlyRent: Decimal?
    public var rentAnnualIncreasePercent: Decimal?
    public var securityDeposit: Decimal?
    public var petDeposit: Decimal?
    public var petRentMonthly: Decimal?
    public var newHomePrice: Decimal?
    public var newHomeDownPayment: Decimal?
    public var newMortgageRatePercent: Decimal?
    public var newMortgageTermYears: Int?
    public var propertyTaxAnnual: Decimal?
    public var homeownersInsuranceAnnual: Decimal?
    public var newPropertyTaxAnnual: Decimal?
    public var newHomeownersInsuranceAnnual: Decimal?
    public var hoaMonthly: Decimal?
    public var newHoaMonthly: Decimal?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        projectionYears: Int? = nil,
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
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.projectionYears = projectionYears
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
        self.notes = notes
    }
}
