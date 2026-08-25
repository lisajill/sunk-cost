import Foundation

/// What could be pulled out of a real estate listing's payment-calculator
/// text. Every field is optional and independent -- a source that only
/// shows tax/insurance (no price, no loan terms) still yields a partial,
/// useful result rather than nothing.
public struct ParsedListing: Equatable, Sendable {
    public var homePrice: Decimal?
    public var downPaymentAmount: Decimal?
    public var mortgageRatePercent: Decimal?
    public var mortgageTermYears: Int?
    public var monthlyPropertyTax: Decimal?
    public var monthlyInsurance: Decimal?
    public var monthlyHOA: Decimal?

    public init(
        homePrice: Decimal? = nil,
        downPaymentAmount: Decimal? = nil,
        mortgageRatePercent: Decimal? = nil,
        mortgageTermYears: Int? = nil,
        monthlyPropertyTax: Decimal? = nil,
        monthlyInsurance: Decimal? = nil,
        monthlyHOA: Decimal? = nil
    ) {
        self.homePrice = homePrice
        self.downPaymentAmount = downPaymentAmount
        self.mortgageRatePercent = mortgageRatePercent
        self.mortgageTermYears = mortgageTermYears
        self.monthlyPropertyTax = monthlyPropertyTax
        self.monthlyInsurance = monthlyInsurance
        self.monthlyHOA = monthlyHOA
    }
}

/// Pulls listing numbers out of text copy-pasted from a real estate site's
/// payment calculator (Redfin, Zillow, and similar all show roughly the
/// same fields, worded slightly differently). Deliberately text-parsing
/// only, no network access -- the user pastes what their own browser
/// already shows them, nothing is fetched. Every extraction is best-effort
/// and independent of the others; a field that isn't found or isn't a
/// real number (Zillow shows "N/A" for a missing HOA, for instance) is
/// left nil rather than guessed at, matching this app's rule elsewhere of
/// never fabricating a default for a value that isn't actually known.
public enum ListingParser {
    public static func parse(_ text: String) -> ParsedListing {
        var result = ParsedListing()

        result.homePrice = firstDecimal(pattern: #"(?:Home|List) price\D{0,20}\$?([\d,]+)"#, in: text)
        // A dollar figure can come before or after a "(NN%)" -- Redfin
        // shows "57% ($279,243)", another site shows "$49,800 (20%)" --
        // so this just looks for the first $-prefixed number after the
        // label, not a specific ordering with the percent.
        result.downPaymentAmount = firstDecimal(pattern: #"Down payment[\s\S]{0,30}?\$([\d,]+)"#, in: text)
        result.monthlyPropertyTax = firstDecimal(pattern: #"Property tax(?:es)?\D{0,20}\$?([\d,]+)"#, in: text)
        result.monthlyInsurance = firstDecimal(pattern: #"Home insurance\D{0,20}\$?([\d,]+)"#, in: text)
        result.monthlyHOA = firstDecimal(pattern: #"HOA\D{0,20}\$?([\d,]+)"#, in: text)

        // "30-yr fixed, 6.75%" (Redfin) and "30-year fixed at 6.717%"
        // (another site) both need to match -- "yr"/"year", an optional
        // comma or "at" between the term and the rate.
        if let loanMatch = firstMatch(pattern: #"(\d+)[- ]?(?:yr|year)s?\s+fixed[^\d%]{0,15}([\d.]+)\s*%"#, in: text) {
            result.mortgageTermYears = Int(loanMatch[1])
            result.mortgageRatePercent = Decimal(string: loanMatch[2])
        }

        return result
    }

    /// Runs `pattern` against `text` and returns capture group 1 (with any
    /// thousands-separator commas stripped) as a `Decimal`, or nil if the
    /// pattern doesn't match anywhere or the captured text isn't a number.
    private static func firstDecimal(pattern: String, in text: String) -> Decimal? {
        guard let match = firstMatch(pattern: pattern, in: text) else { return nil }
        return Decimal(string: match[1].replacingOccurrences(of: ",", with: ""))
    }

    /// All capture groups (index 0 is the whole match) of the first place
    /// `pattern` matches in `text`, as plain strings.
    private static func firstMatch(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let fullRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: fullRange) else { return nil }
        return (0..<match.numberOfRanges).map { index in
            guard let range = Range(match.range(at: index), in: text) else { return "" }
            return String(text[range])
        }
    }
}
