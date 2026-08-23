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
    public var newHomePrice: Decimal?
    public var newHomeDownPayment: Decimal?
    public var newMortgageRatePercent: Decimal?
    public var newMortgageTermYears: Int?
    public var propertyTaxPercent: Decimal?
    public var homeownersInsuranceAnnual: Decimal?
    public var newPropertyTaxPercent: Decimal?
    public var newHomeownersInsuranceAnnual: Decimal?
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        projectionYears: Int? = nil,
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
        newHomeownersInsuranceAnnual: Decimal? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.projectionYears = projectionYears
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
        self.notes = notes
    }
}
