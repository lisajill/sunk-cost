import Foundation

public func computeEquity(homeValue: Decimal?, mortgageBalance: Decimal?) -> Decimal? {
    guard let homeValue, let mortgageBalance else { return nil }
    return homeValue - mortgageBalance
}
