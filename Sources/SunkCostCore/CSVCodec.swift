import Foundation

public enum CSVCodecError: Error, LocalizedError {
    case missingColumns([String])

    public var errorDescription: String? {
        switch self {
        case .missingColumns(let columns):
            return "This file is missing required column(s): \(columns.joined(separator: ", "))."
        }
    }
}

/// Reads and writes items as CSV -- the practical way to interoperate with
/// Excel, Numbers, and Google Sheets, all of which open and save CSV
/// natively without needing a real binary .xlsx reader/writer.
public enum CSVCodec {
    public static let header = ["Name", "Category", "Cost", "Status", "Date"]

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    public static func encode(_ items: [Item]) -> String {
        let dateFormatter = makeDateFormatter()
        var lines = [header.map(escapeField).joined(separator: ",")]

        for item in items {
            let costField = item.cost.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            let dateField = item.dateAdded.map { dateFormatter.string(from: $0) } ?? ""
            let fields = [
                item.name,
                item.category,
                costField,
                item.status.rawValue.capitalized,
                dateField,
            ]
            lines.append(fields.map(escapeField).joined(separator: ","))
        }

        return lines.joined(separator: "\r\n")
    }

    public static func decode(_ csv: String) throws -> [Item] {
        let rows = parseRows(csv)
        guard let headerRow = rows.first else { return [] }

        let indices: [String: Int] = Dictionary(
            uniqueKeysWithValues: headerRow.enumerated().map { ($1.lowercased(), $0) }
        )
        let required = ["name", "category", "cost", "status", "date"]
        let missing = required.filter { indices[$0] == nil }
        guard missing.isEmpty else {
            throw CSVCodecError.missingColumns(missing.map { $0.capitalized })
        }

        let dateFormatter = makeDateFormatter()

        return rows.dropFirst().compactMap { row -> Item? in
            guard row.count >= required.count, !(row.count == 1 && row[0].isEmpty) else { return nil }

            let name = row[indices["name"]!]
            let category = row[indices["category"]!]
            let costText = row[indices["cost"]!]
            let statusText = row[indices["status"]!].lowercased()
            let dateText = row[indices["date"]!]

            let cost = costText.isEmpty ? nil : Decimal(string: costText)
            let status = Status(rawValue: statusText) ?? .owned
            let date = dateText.isEmpty ? nil : dateFormatter.date(from: dateText)

            return Item(name: name, category: category, cost: cost, status: status, dateAdded: date)
        }
    }

    private static func escapeField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    /// Parses CSV text into rows of fields, respecting quoted fields that may
    /// contain commas, embedded newlines, or escaped ("") quote characters.
    private static func parseRows(_ csv: String) -> [[String]] {
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

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }
}
