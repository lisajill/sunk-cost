import Foundation

public enum CSVCodecError: Error, LocalizedError {
    case missingColumns([String])
    case duplicateColumns([String])
    case malformedQuoting

    public var errorDescription: String? {
        switch self {
        case .missingColumns(let columns):
            return "This file is missing required column(s): \(columns.joined(separator: ", "))."
        case .duplicateColumns(let columns):
            return "This file has more than one column named: \(columns.joined(separator: ", ")). Give each column a distinct header."
        case .malformedQuoting:
            return "This file has a quoted field that's never closed — a stray \" somewhere is swallowing the rest of the file."
        }
    }
}

/// Reads and writes items as CSV -- the practical way to interoperate with
/// Excel, Numbers, and Google Sheets, all of which open and save CSV
/// natively without needing a real binary .xlsx reader/writer.
public enum CSVCodec {
    public static let header = ["Name", "Category", "Cost", "Status", "Date", "Notes", "Type", "Disposition", "Amount Recovered"]

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Local calendar date, not UTC: a CSV date is a plain calendar day
        // ("2026-08-28"), and the app creates and displays `dateAdded` in
        // local time. A UTC formatter here shifts an evening date to the
        // previous/next day when written or read (e.g. anything past ~8pm
        // US-Eastern lands on the wrong day).
        //
        // Caveat: a CSV *exported* by an older build (which used a UTC
        // formatter) may already carry a date string that was shifted a
        // day; there's no timezone marker in the file to detect and undo
        // that. New exports round-trip correctly.
        formatter.timeZone = TimeZone.current
        return formatter
    }

    public static func encode(_ items: [Item]) -> String {
        let dateFormatter = makeDateFormatter()
        var lines = [header.map(escapeField).joined(separator: ",")]

        for item in items {
            let costField = item.cost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            let dateField = item.dateAdded.map { dateFormatter.string(from: $0) } ?? ""
            let amountRecoveredField = item.amountRecovered.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            let fields = [
                item.name,
                item.category,
                costField,
                item.status.rawValue.capitalized,
                dateField,
                item.notes ?? "",
                item.type.label,
                item.disposition?.label ?? "",
                amountRecoveredField,
            ]
            lines.append(fields.map(escapeField).joined(separator: ","))
        }

        return lines.joined(separator: "\r\n")
    }

    /// Result of a lenient decode: the items that parsed, plus counts of
    /// what was quietly lost or changed so the caller can tell the user
    /// instead of importing damage silently. (`decode` is kept as the
    /// items-only convenience.)
    public struct DecodeResult: Equatable, Sendable {
        public let items: [Item]
        /// Rows that had content but too few cells to fill the required
        /// columns -- dropped.
        public let skippedRowCount: Int
        /// Non-blank cells whose value wasn't recognized and fell back to a
        /// default (unknown status -> Owned, unknown type -> Moveable,
        /// unparseable cost/date/amount -> blank, unknown disposition ->
        /// none).
        public let coercedValueCount: Int
    }

    public static func decode(_ csv: String) throws -> [Item] {
        try decodeReporting(csv).items
    }

    public static func decodeReporting(_ csv: String) throws -> DecodeResult {
        let rows = try parseRows(csv)
        guard let headerRow = rows.first else {
            return DecodeResult(items: [], skippedRowCount: 0, coercedValueCount: 0)
        }

        // Build the column map by hand rather than with
        // `Dictionary(uniqueKeysWithValues:)`, which *traps* on a repeated
        // key -- a duplicate header in a hand-edited file should be a
        // catchable error, not a crash.
        var indices: [String: Int] = [:]
        var duplicates: [String] = []
        for (offset, cell) in headerRow.enumerated() {
            let key = cell.trimmingCharacters(in: .whitespaces).lowercased()
            guard !key.isEmpty else { continue }
            if indices[key] != nil {
                if !duplicates.contains(key) { duplicates.append(key) }
            } else {
                indices[key] = offset
            }
        }
        guard duplicates.isEmpty else {
            throw CSVCodecError.duplicateColumns(duplicates.map { $0.capitalized })
        }

        let required = ["name", "category", "cost", "status", "date"]
        let missing = required.filter { indices[$0] == nil }
        guard missing.isEmpty else {
            throw CSVCodecError.missingColumns(missing.map { $0.capitalized })
        }

        // A required column can sit at any position (columns may be
        // reordered), so a row is only usable if it actually has a cell at
        // every required index -- `row.count >= required.count` doesn't
        // guarantee that and would index out of bounds on a short row.
        let maxRequiredIndex = required.compactMap { indices[$0] }.max() ?? 0

        let dateFormatter = makeDateFormatter()

        var items: [Item] = []
        var skippedRowCount = 0
        var coercedValueCount = 0

        for row in rows.dropFirst() {
            // A lone empty cell is a blank line, not a damaged row.
            if row.count == 1, row[0].isEmpty { continue }
            guard row.count > maxRequiredIndex else {
                skippedRowCount += 1
                continue
            }

            // Trim the scalar cells -- a stray space (e.g. "Planned ") must
            // not silently coerce to a different enum case or fail to parse.
            let name = row[indices["name"]!].trimmingCharacters(in: .whitespaces)
            let category = row[indices["category"]!].trimmingCharacters(in: .whitespaces)
            let costText = row[indices["cost"]!].trimmingCharacters(in: .whitespaces)
            let statusText = row[indices["status"]!].trimmingCharacters(in: .whitespaces).lowercased()
            let dateText = row[indices["date"]!].trimmingCharacters(in: .whitespaces)

            let cost: Decimal?
            if costText.isEmpty {
                cost = nil
            } else if let parsed = Decimal(string: costText) {
                cost = parsed
            } else {
                cost = nil
                coercedValueCount += 1
            }

            let status: Status
            if let parsed = Status(rawValue: statusText) {
                status = parsed
            } else {
                // Status is a required column -- a blank or unrecognized
                // value is a data problem worth reporting, not a silent
                // default like a missing optional.
                status = .owned
                coercedValueCount += 1
            }

            let date: Date?
            if dateText.isEmpty {
                date = nil
            } else if let parsed = dateFormatter.date(from: dateText) {
                date = parsed
            } else {
                date = nil
                coercedValueCount += 1
            }

            // Notes, Type, Disposition, Amount Recovered are all optional --
            // older exported CSVs won't have these columns, and each index
            // is bounds-checked in case a given row is short.
            func optionalCell(_ column: String) -> String? {
                indices[column].flatMap { index in row.indices.contains(index) ? row[index] : nil }
            }

            let notesText = optionalCell("notes")
            let notes = (notesText?.isEmpty ?? true) ? nil : notesText

            let typeTextRaw = optionalCell("type")?.trimmingCharacters(in: .whitespaces)
            let type: ItemType
            if let typeTextRaw, !typeTextRaw.isEmpty {
                if let parsed = ItemType(rawValue: typeTextRaw.lowercased()) {
                    type = parsed
                } else {
                    type = .moveable
                    coercedValueCount += 1
                }
            } else {
                type = .moveable
            }

            // Accept either the human label ("Given Away") or the raw value
            // ("givenAway"), case-insensitively, so a spreadsheet-edited
            // file round-trips.
            let dispositionTextRaw = optionalCell("disposition")?.trimmingCharacters(in: .whitespaces).lowercased()
            let disposition: Disposition?
            if let dispositionTextRaw, !dispositionTextRaw.isEmpty {
                let matched = Disposition.allCases.first {
                    $0.label.lowercased() == dispositionTextRaw || $0.rawValue.lowercased() == dispositionTextRaw
                }
                disposition = matched
                if matched == nil { coercedValueCount += 1 }
            } else {
                disposition = nil
            }

            let amountRecoveredText = optionalCell("amount recovered")?.trimmingCharacters(in: .whitespaces)
            let amountRecovered: Decimal?
            if let amountRecoveredText, !amountRecoveredText.isEmpty {
                if let parsed = Decimal(string: amountRecoveredText) {
                    amountRecovered = parsed
                } else {
                    amountRecovered = nil
                    coercedValueCount += 1
                }
            } else {
                amountRecovered = nil
            }

            items.append(Item(
                name: name,
                category: category,
                cost: cost,
                status: status,
                dateAdded: date,
                notes: notes,
                type: type,
                disposition: disposition,
                amountRecovered: amountRecovered
            ))
        }

        return DecodeResult(items: items, skippedRowCount: skippedRowCount, coercedValueCount: coercedValueCount)
    }

    private static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Parses CSV text into rows of fields, respecting quoted fields that may
    /// contain commas, embedded newlines, or escaped ("") quote characters.
    /// Throws `.malformedQuoting` if a quoted field is never closed -- left
    /// unchecked, one stray `"` silently swallows every following row into
    /// a single field and the import looks clean.
    private static func parseRows(_ csv: String) throws -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var isInsideQuotes = false

        // Swift's Character/grapheme-cluster model treats "\r\n" as a single
        // Character, not two -- normalize line endings first so a plain
        // per-character switch below can treat "\n" as the only line break.
        let normalized = csv
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let characters = Array(normalized)
        var i = 0
        while i < characters.count {
            let character = characters[i]

            if isInsideQuotes {
                if character == "\"" {
                    if i + 1 < characters.count, characters[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    currentField.append(character)
                }
            } else {
                switch character {
                case "\"":
                    isInsideQuotes = true
                case ",":
                    currentRow.append(currentField)
                    currentField = ""
                case "\n":
                    currentRow.append(currentField)
                    currentField = ""
                    rows.append(currentRow)
                    currentRow = []
                default:
                    currentField.append(character)
                }
            }
            i += 1
        }

        guard !isInsideQuotes else { throw CSVCodecError.malformedQuoting }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }
}
