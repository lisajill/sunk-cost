import Testing
import Foundation
@testable import SunkCostCore

@Suite("Listing parser")
struct ListingParserTests {
    // Verbatim paste from a real Redfin "Payment calculator" box.
    private static let redfinText = """
    Payment calculator
    $1,869 per month
    Principal and interest$1,366
    Property taxes
    $429
    HOA dues
    $0
    Home insurance
    $73
    Utilities
    Add
    Down payment
    57% ($279,243)
    Home price
    $489,900
    Loan details
    30-yr fixed, 6.75%
    """

    // Verbatim paste from a real Zillow "Payment breakdown" box -- note it
    // has *both* "Mortgage insurance" and "Home insurance" as separate
    // lines, and HOA is "N/A" rather than a dollar figure.
    private static let zillowBreakdownText = """
    Payment breakdown
    Explore the cost of this home by adjusting the details. Changes won't be saved.

    Principal & interest
    $1,222

    Mortgage insurance
    $0

    Property taxes
    $458

    Home insurance
    $77

    HOA fees
    N/A

    Utilities
    Not included

    All calculations are estimates and provided by Zillow, Inc. for informational purposes only. Actual amounts may vary.

    HOA fees may include property taxes on listings classified as Co-Ops. Contact the listing agent and/or owner for fee details.
    """

    // Verbatim paste from a real Zillow "BuyAbility" box -- no home price
    // or loan-term text at all, down payment is an empty input field.
    private static let zillowBuyAbilityText = """
    BuyAbility℠ payment

    Est. payment
    $1,757/mo
    Principal & interest:
    $1222
    Property taxes:
    $458
    Home insurance:
    $77
    Know your BuyAbility℠
    See what you can afford and get personalized payments for every home.

    Down payment
    $

    Credit score
    """

    @Test("parses a Redfin payment calculator paste")
    func parsesRedfin() {
        let result = ListingParser.parse(Self.redfinText)

        #expect(result.homePrice == 489_900)
        #expect(result.downPaymentAmount == 279_243)
        #expect(result.mortgageRatePercent == 6.75)
        #expect(result.mortgageTermYears == 30)
        #expect(result.monthlyPropertyTax == 429)
        #expect(result.monthlyInsurance == 73)
        #expect(result.monthlyHOA == 0)
    }

    @Test("parses a Zillow payment breakdown paste, not confusing mortgage insurance with home insurance")
    func parsesZillowBreakdown() {
        let result = ListingParser.parse(Self.zillowBreakdownText)

        #expect(result.monthlyPropertyTax == 458)
        #expect(result.monthlyInsurance == 77)
        #expect(result.monthlyHOA == nil)
        #expect(result.homePrice == nil)
        #expect(result.downPaymentAmount == nil)
        #expect(result.mortgageRatePercent == nil)
        #expect(result.mortgageTermYears == nil)
    }

    @Test("parses a Zillow BuyAbility paste with no price or loan terms present")
    func parsesZillowBuyAbility() {
        let result = ListingParser.parse(Self.zillowBuyAbilityText)

        #expect(result.monthlyPropertyTax == 458)
        #expect(result.monthlyInsurance == 77)
        #expect(result.homePrice == nil)
        #expect(result.downPaymentAmount == nil)
        #expect(result.mortgageRatePercent == nil)
        #expect(result.mortgageTermYears == nil)
    }

    // Verbatim paste from a real "RealCost"-style listing (a third site,
    // different from Redfin/Zillow) -- "List price" not "Home price",
    // down payment shows dollar-then-percent ("$49,800 (20%)", the
    // reverse of Redfin's percent-then-dollar), and "30-year fixed at
    // 6.717%" instead of "30-yr fixed, 6.75%".
    private static let realCostText = """
    Monthly Payment
    RealCostTM for this home
    Apply veterans benefits



    $1,880
    /month
    List price
    $249,000
    $49,800 (20%) down
    30-year fixed at 6.717%

    Edit payment
    Principal & interest
    $1,288
    Property tax
    $478
    Home insurance
    $114
    Compare home insurance rates
    Total due at close
    $59,760
    Down payment
    $49,800 (20%)
    Est. closing cost
    $9,960 (4%)
    """

    @Test("parses a RealCost-style listing with different wording and down-payment ordering")
    func parsesRealCostStyleListing() {
        let result = ListingParser.parse(Self.realCostText)

        #expect(result.homePrice == 249_000)
        #expect(result.downPaymentAmount == 49_800)
        #expect(result.mortgageRatePercent == 6.717)
        #expect(result.mortgageTermYears == 30)
        #expect(result.monthlyPropertyTax == 478)
        #expect(result.monthlyInsurance == 114)
    }

    @Test("empty text yields every field nil, not an error")
    func emptyTextYieldsNothing() {
        let result = ListingParser.parse("")

        #expect(result == ParsedListing())
    }
}
