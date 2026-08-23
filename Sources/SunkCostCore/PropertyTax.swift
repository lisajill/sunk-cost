import Foundation

/// Property tax as an annual percentage of home value, expressed monthly --
/// scales automatically with whatever home value is assumed, unlike a flat
/// dollar estimate would.
public func monthlyPropertyTax(homeValue: Decimal, annualTaxPercent: Decimal) -> Decimal {
    homeValue * (annualTaxPercent / 100) / 12
}
