import SwiftUI
import SunkCostCore

struct ItemFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: Item?

    @State private var name: String = ""
    @State private var category: String = ""
    @State private var costText: String = ""
    @State private var status: Status = .owned
    @State private var date: Date = Date()

    private var isEditing: Bool { item != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Item" : "Add Item")
                .font(Theme.scaledFont(Theme.FontSize.title2, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 14) {
                labeledField("Name") {
                    TextField("", text: $name)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }

                labeledField("Category") {
                    TextField("", text: $category)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }

                labeledField("Cost") {
                    TextField("Leave blank if not spent yet", text: $costText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }

                labeledField("Status") {
                    Picker("", selection: $status) {
                        ForEach(Status.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                labeledField("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .labelsHidden()
                        .datePickerStyle(.field)
                }

                if !store.availableCategories.isEmpty {
                    labeledField("Existing categories") {
                        FlowingCategoryButtons(
                            categories: store.availableCategories,
                            textScale: store.textScale
                        ) { existing in
                            category = existing
                        }
                    }
                }
            }

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let item {
                            store.deleteItem(item)
                        }
                        dismiss()
                    }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                }

                Spacer()

                Button("Cancel") { dismiss() }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                Button(isEditing ? "Save" : "Add") {
                    save()
                }
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                .keyboardShortcut(.defaultAction)
                .disabled(
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding(24)
        .frame(minWidth: 440, idealWidth: 440)
        .tint(Theme.positive)
        .onAppear { populateFieldsIfEditing() }
    }

    @ViewBuilder
    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel(scale: store.textScale))
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            content()
        }
    }

    private func populateFieldsIfEditing() {
        guard let item else { return }
        name = item.name
        category = item.category
        status = item.status
        date = item.dateAdded
        if let cost = item.cost {
            costText = NSDecimalNumber(decimal: cost).stringValue
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let digitsAndDot = costText.filter { $0.isNumber || $0 == "." }
        let cost = digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)

        if var existing = item {
            existing.name = trimmedName
            existing.category = trimmedCategory
            existing.cost = cost
            existing.status = status
            existing.dateAdded = date
            store.updateItem(existing)
        } else {
            let newItem = Item(name: trimmedName, category: trimmedCategory, cost: cost, status: status, dateAdded: date)
            store.addItem(newItem)
        }
        dismiss()
    }
}

/// A simple left-to-right wrapping row of category buttons. Avoids an
/// HStack's hard requirement that everything fit on one line -- with enough
/// categories, an HStack would push the sheet wider or clip, the same class
/// of bug as the old Form layout.
private struct FlowingCategoryButtons: View {
    let categories: [String]
    let textScale: CGFloat
    let onTap: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(categories, id: \.self) { category in
                Button(category) { onTap(category) }
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: textScale))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
