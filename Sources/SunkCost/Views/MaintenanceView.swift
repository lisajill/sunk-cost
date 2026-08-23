import SwiftUI
import SunkCostCore

/// "Cost to keep the house running" -- a list of recurring categories (Oil,
/// Electricity, Landscaping...), each expandable inline to its own payment
/// log. Kept in the same single window as Items, no push navigation.
struct MaintenanceView: View {
    @Environment(AppStore.self) private var store
    @State private var isShowingAddCategory = false
    @State private var editingCategory: MaintenanceCategory?
    @State private var expandedCategoryIDs: Set<UUID> = []
    @State private var addingPaymentToCategoryID: UUID?
    @State private var editingPayment: MaintenancePayment?

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private func formatted(_ value: Decimal) -> String {
        let text = Self.currencyFormatter.string(from: value as NSDecimalNumber) ?? "$0"
        return store.isPrivacyModeEnabled ? Theme.mask(text) : text
    }

    var body: some View {
        VStack(spacing: 0) {
            if store.maintenanceCategories.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(store.maintenanceCategoryTotals(), id: \.category.id) { entry in
                        categorySection(for: entry.category, actual: entry.actual)
                    }
                }
                .listStyle(.inset)
                .id(store.appearanceMode)
            }
        }
        .frame(minWidth: 560, minHeight: 480)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddCategory) {
            MaintenanceCategoryFormView(category: nil)
        }
        .sheet(item: $editingCategory) { category in
            MaintenanceCategoryFormView(category: category)
        }
        .sheet(item: Binding(
            get: { addingPaymentToCategoryID.map { PaymentSheetTarget(categoryID: $0) } },
            set: { addingPaymentToCategoryID = $0?.categoryID }
        )) { target in
            MaintenancePaymentFormView(categoryID: target.categoryID, payment: nil)
        }
        .sheet(item: $editingPayment) { payment in
            MaintenancePaymentFormView(categoryID: payment.categoryID, payment: payment)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 34))
                .foregroundStyle(Theme.inkSecondary)
            Text("No Maintenance categories yet")
                .font(Theme.scaledFont(Theme.FontSize.title3, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Text("Add a category like Oil, Electricity, or Landscaping to start logging what it costs to keep the house running.")
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button {
                isShowingAddCategory = true
            } label: {
                Label("Add Category", systemImage: "plus")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func categorySection(for category: MaintenanceCategory, actual: Decimal) -> some View {
        let payments = store.maintenancePayments
            .filter { $0.categoryID == category.id }
            .sorted { $0.date > $1.date }
        let isExpanded = Binding(
            get: { expandedCategoryIDs.contains(category.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategoryIDs.insert(category.id)
                } else {
                    expandedCategoryIDs.remove(category.id)
                }
            }
        )

        return DisclosureGroup(isExpanded: isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                if payments.isEmpty {
                    Text("No payments logged yet")
                        .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(payments) { payment in
                        MaintenancePaymentRowView(payment: payment, formatted: formatted)
                            .contentShape(Rectangle())
                            .onTapGesture { editingPayment = payment }
                            .contextMenu {
                                Button("Edit") { editingPayment = payment }
                                Button("Delete", role: .destructive) {
                                    store.deleteMaintenancePayment(payment)
                                }
                            }
                    }
                }

                Button {
                    addingPaymentToCategoryID = category.id
                } label: {
                    Label("Add Payment", systemImage: "plus")
                }
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 2)
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.name)
                        .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                        .foregroundStyle(Theme.ink)
                    if let expected = category.expectedMonthlyAmount {
                        Text("Expected \(formatted(expected))/mo")
                            .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
                Spacer()
                Text(formatted(actual))
                    .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                    .monospacedDigit()
                    .foregroundStyle(Theme.ink)
                Button {
                    editingCategory = category
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.inkSecondary)
                }
                .buttonStyle(.plain)
                .help("Edit or delete this category")
            }
            .contentShape(Rectangle())
        }
        .padding(.vertical, 4)
    }
}

private struct PaymentSheetTarget: Identifiable {
    let categoryID: UUID
    var id: UUID { categoryID }
}

private struct MaintenancePaymentRowView: View {
    @Environment(AppStore.self) private var store
    let payment: MaintenancePayment
    let formatted: (Decimal) -> String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM-d-yyyy"
        return formatter
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.dateFormatter.string(from: payment.date))
                    .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
                if let notes = payment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(Theme.scaledFont(Theme.FontSize.caption2, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(formatted(payment.amount))
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Add/edit a Maintenance category. Deleting a category that already has
/// payments requires picking another category to reassign them to first --
/// same "don't silently orphan data" stance as the rest of the app.
private struct MaintenanceCategoryFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let category: MaintenanceCategory?

    @State private var name: String = ""
    @State private var expectedAmountText: String = ""
    @State private var reassignTargetID: UUID?

    private var isEditing: Bool { category != nil }

    private var hasPayments: Bool {
        guard let category else { return false }
        return store.maintenancePayments.contains { $0.categoryID == category.id }
    }

    private var otherCategories: [MaintenanceCategory] {
        store.maintenanceCategories.filter { $0.id != category?.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Category" : "Add Category")
                .font(Theme.scaledFont(Theme.FontSize.title2, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 14) {
                labeledField("Name") {
                    TextField("", text: $name)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }

                labeledField("Expected Monthly Amount") {
                    TextField("Optional, for reference only", text: $expectedAmountText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }

                if isEditing && hasPayments {
                    labeledField("Reassign payments to (required to delete)") {
                        Picker("", selection: $reassignTargetID) {
                            Text("Choose a category").tag(UUID?.none)
                            ForEach(otherCategories) { other in
                                Text(other.name).tag(UUID?.some(other.id))
                            }
                        }
                        .labelsHidden()
                        .disabled(otherCategories.isEmpty)
                    }
                    if otherCategories.isEmpty {
                        Text("Add another category first, or delete this one's payments individually, to delete it.")
                            .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                }
            }

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let category {
                            store.deleteMaintenanceCategory(category, reassigningPaymentsTo: reassignTargetID)
                        }
                        dismiss()
                    }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .disabled(hasPayments && reassignTargetID == nil)
                }

                Spacer()

                Button("Cancel") { dismiss() }
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                Button(isEditing ? "Save" : "Add") {
                    save()
                }
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 420, idealWidth: 420)
        .tint(Theme.positive)
        .onAppear {
            guard let category else { return }
            name = category.name
            if let expected = category.expectedMonthlyAmount {
                expectedAmountText = NSDecimalNumber(decimal: expected).stringValue
            }
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

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let digitsAndDot = expectedAmountText.filter { $0.isNumber || $0 == "." }
        let expected = digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)

        if var existing = category {
            existing.name = trimmedName
            existing.expectedMonthlyAmount = expected
            store.updateMaintenanceCategory(existing)
        } else {
            store.addMaintenanceCategory(name: trimmedName, expectedMonthlyAmount: expected)
        }
        dismiss()
    }
}

/// Add/edit a single dated payment against a Maintenance category.
private struct MaintenancePaymentFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let categoryID: UUID
    let payment: MaintenancePayment?

    @State private var amountText: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    private var isEditing: Bool { payment != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isEditing ? "Edit Payment" : "Add Payment")
                .font(Theme.scaledFont(Theme.FontSize.title2, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            VStack(alignment: .leading, spacing: 14) {
                labeledField("Amount") {
                    TextField("", text: $amountText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }

                labeledField("Date") {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .labelsHidden()
                        .datePickerStyle(.field)
                }

                labeledField("Notes") {
                    TextField("Optional", text: $notes)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let payment {
                            store.deleteMaintenancePayment(payment)
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
                .disabled(Decimal(string: amountText.filter { $0.isNumber || $0 == "." }) == nil)
            }
        }
        .padding(24)
        .frame(minWidth: 380, idealWidth: 380)
        .tint(Theme.positive)
        .onAppear {
            guard let payment else { return }
            amountText = NSDecimalNumber(decimal: payment.amount).stringValue
            date = payment.date
            notes = payment.notes ?? ""
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

    private func save() {
        let digitsAndDot = amountText.filter { $0.isNumber || $0 == "." }
        guard let amount = Decimal(string: digitsAndDot) else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        if var existing = payment {
            existing.amount = amount
            existing.date = date
            existing.notes = finalNotes
            store.updateMaintenancePayment(existing)
        } else {
            store.addMaintenancePayment(
                MaintenancePayment(categoryID: categoryID, amount: amount, date: date, notes: finalNotes)
            )
        }
        dismiss()
    }
}
