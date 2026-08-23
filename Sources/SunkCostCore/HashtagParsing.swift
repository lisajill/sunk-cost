import Foundation

/// Finds `#tag`-style hashtags in free text: a "#" immediately followed by
/// one or more letters, digits, or underscores, ending at the first
/// character that isn't one of those (whitespace, punctuation, etc.).
public func hashtagRanges(in text: String) -> [Range<String.Index>] {
    guard let regex = try? NSRegularExpression(pattern: "#[\\w]+") else { return [] }
    let nsText = text as NSString
    let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

    return matches.compactMap { match in
        Range(match.range, in: text)
    }
}
