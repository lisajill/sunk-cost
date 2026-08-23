import SwiftUI
import Foundation

/// Renders a note's raw text (markdown source, #hashtags) as styled
/// SwiftUI-displayable text.
enum NotesFormatting {
    static func attributedString(from text: String, hashtagColor: Color) -> AttributedString {
        var attributed = (try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)

        // Hashtags are found directly against the parsed AttributedString's
        // own character sequence (not the original markdown source) --
        // markdown parsing can shift character positions by removing syntax
        // markers like "**", so ranges from the raw source wouldn't line up.
        let plainText = String(attributed.characters)
        guard let regex = try? NSRegularExpression(pattern: "#[\\w]+") else { return attributed }
        let nsText = plainText as NSString
        let matches = regex.matches(in: plainText, range: NSRange(location: 0, length: nsText.length))

        for match in matches {
            guard let range = Range(match.range, in: attributed) else { continue }
            attributed[range].foregroundColor = hashtagColor
            attributed[range].font = .body.weight(.semibold)
        }

        return attributed
    }
}
