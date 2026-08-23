import Testing
@testable import SunkCostCore

@Suite("Hashtag parsing")
struct HashtagParsingTests {
    @Test("finds a single hashtag")
    func findsSingleHashtag() {
        let text = "Bought this for #livingroom"
        let ranges = hashtagRanges(in: text)
        #expect(ranges.map { String(text[$0]) } == ["#livingroom"])
    }

    @Test("finds multiple hashtags")
    func findsMultipleHashtags() {
        let text = "#urgent needs fixing, see #warranty for details"
        let ranges = hashtagRanges(in: text)
        #expect(ranges.map { String(text[$0]) } == ["#urgent", "#warranty"])
    }

    @Test("stops a hashtag at punctuation")
    func stopsAtPunctuation() {
        let text = "Great find! #bargain, wish I'd bought two."
        let ranges = hashtagRanges(in: text)
        #expect(ranges.map { String(text[$0]) } == ["#bargain"])
    }

    @Test("ignores a bare hash with no word characters")
    func ignoresBareHash() {
        let text = "Cost was # 400 approx"
        let ranges = hashtagRanges(in: text)
        #expect(ranges.isEmpty)
    }

    @Test("returns no ranges for text with no hashtags")
    func returnsEmptyForNoHashtags() {
        #expect(hashtagRanges(in: "Plain note, nothing tagged here.").isEmpty)
    }

    @Test("allows digits and underscores in a hashtag")
    func allowsDigitsAndUnderscores() {
        let text = "See #room_2 for details"
        let ranges = hashtagRanges(in: text)
        #expect(ranges.map { String(text[$0]) } == ["#room_2"])
    }
}
