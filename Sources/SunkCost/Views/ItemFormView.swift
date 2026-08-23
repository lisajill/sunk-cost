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
    @State private var type: ItemType = .moveable
    @State private var date: Date = Date()
    @State private var hasDate = true
    @State private var notes: String = ""
    @State private var disposition: Disposition = .givenAway
    @State private var amountRecoveredText: String = ""
    @State private var isShowingDeleteConfirmation = false

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

                if status == .gone {
                    labeledField("What Happened to It") {
                        Picker("", selection: $disposition) {
                            ForEach(Disposition.allCases, id: \.self) { disposition in
                                Text(disposition.label).tag(disposition)
                            }
                        }
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .labelsHidden()
                        .pickerStyle(.segmented)

                        if disposition == .sold {
                            TextField("Amount recovered", text: $amountRecoveredText)
                                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                                .textFieldStyle(.roundedBorder)
                                .padding(.top, 4)
                        }
                    }
                }

                labeledField("Type") {
                    Picker("", selection: $type) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    Text(type == .value
                        ? "Stays with the house if sold -- counts toward Home Value comparison"
                        : "Goes with you if you move -- doesn't count toward Home Value comparison")
                        .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }

                labeledField("Date") {
                    HStack {
                        Toggle("", isOn: $hasDate)
                            .labelsHidden()
                            .help(hasDate ? "Turn off if you don't know the date" : "Turn on to set a date")
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                            .labelsHidden()
                            .datePickerStyle(.field)
                            .disabled(!hasDate)
                    }
                }

                labeledField("Notes") {
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $notes)
                            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                            .frame(height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(Theme.ledgerBorder, lineWidth: 1)
                            )

                        Text("Supports **bold**, *italic*, [links](url), and #hashtags")
                            .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                            .foregroundStyle(Theme.inkSecondary)

                        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(NotesFormatting.attributedString(from: notes, hashtagColor: Theme.gold))
                                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Theme.ledgerPaper)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
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
                        isShowingDeleteConfirmation = true
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
        // Button(.defaultAction) alone doesn't reliably fire on Return while
        // a TextField in this sheet has focus -- onSubmit is what actually
        // wires the Return key to the save action. TextEditor (Notes) isn't
        // affected -- Return there just inserts a newline, as it should.
        .onSubmit { save() }
        .confirmationDialog(
            "Delete \"\(name)\"?",
            isPresented: $isShowingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                if let item {
                    store.deleteItem(item)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
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
        type = item.type
        if let itemDate = item.dateAdded {
            date = itemDate
            hasDate = true
        } else {
            hasDate = false
        }
        if let cost = item.cost {
            costText = NSDecimalNumber(decimal: cost).stringValue
        }
        notes = item.notes ?? ""
        disposition = item.disposition ?? .givenAway
        if let amountRecovered = item.amountRecovered {
            amountRecoveredText = NSDecimalNumber(decimal: amountRecovered).stringValue
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedCategory.isEmpty else { return }
        let digitsAndDot = costText.filter { $0.isNumber || $0 == "." }
        let cost = digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)

        let dateAdded = hasDate ? date : nil
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        // Disposition/amount recovered only mean anything for Gone items --
        // clear them if the status isn't (or no longer is) Gone.
        let finalDisposition: Disposition? = status == .gone ? disposition : nil
        let amountRecoveredDigitsAndDot = amountRecoveredText.filter { $0.isNumber || $0 == "." }
        let finalAmountRecovered: Decimal? = (status == .gone && disposition == .sold && !amountRecoveredDigitsAndDot.isEmpty)
            ? Decimal(string: amountRecoveredDigitsAndDot)
            : nil

        if var existing = item {
            existing.name = trimmedName
            existing.category = trimmedCategory
            existing.cost = cost
            existing.status = status
            existing.dateAdded = dateAdded
            existing.notes = finalNotes
            existing.type = type
            existing.disposition = finalDisposition
            existing.amountRecovered = finalAmountRecovered
            store.updateItem(existing)
        } else {
            let newItem = Item(
                name: trimmedName,
                category: trimmedCategory,
                cost: cost,
                status: status,
                dateAdded: dateAdded,
                notes: finalNotes,
                type: type,
                disposition: finalDisposition,
                amountRecovered: finalAmountRecovered
            )
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

