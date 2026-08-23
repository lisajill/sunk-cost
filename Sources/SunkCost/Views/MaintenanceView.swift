import SwiftUI
import SunkCostCore

/// "Cost to keep the house running" -- a flat list of recurring categories
/// (Oil, Electricity, Landscaping...), each just a name and its recurring
/// monthly cost. Kept in the same single window as Items, no push
/// navigation.
struct MaintenanceView: View {
    @Environment(AppStore.self) private var store
    @State private var isShowingAddCategory = false
    @State private var editingCategory: MaintenanceCategory?

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
                    ForEach(store.maintenanceCategories) { category in
                        categoryRow(for: category)
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
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 34))
                .foregroundStyle(Theme.inkSecondary)
            Text("No Maintenance categories yet")
                .font(Theme.scaledFont(Theme.FontSize.title3, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Text("Add a category like Oil, Electricity, or Landscaping with its recurring monthly cost to start tracking what it costs to keep the house running.")
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

    private func categoryRow(for category: MaintenanceCategory) -> some View {
        HStack {
            Text(category.name)
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .medium, scale: store.textScale))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text("\(formatted(category.monthlyAmount))/mo")
                .font(Theme.scaledFont(Theme.FontSize.body, weight: .semibold, scale: store.textScale))
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { editingCategory = category }
    }
}

/// Add/edit a Maintenance category: just a name and its recurring monthly
/// cost.
private struct MaintenanceCategoryFormView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let category: MaintenanceCategory?

    @State private var name: String = ""
    @State private var monthlyAmountText: String = ""

    private var isEditing: Bool { category != nil }

    private var monthlyAmount: Decimal? {
        let digitsAndDot = monthlyAmountText.filter { $0.isNumber || $0 == "." }
        return digitsAndDot.isEmpty ? nil : Decimal(string: digitsAndDot)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && monthlyAmount != nil
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

                labeledField("Monthly Cost") {
                    TextField("e.g. 200", text: $monthlyAmountText)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                if isEditing {
                    Button("Delete", role: .destructive) {
                        if let category {
                            store.deleteMaintenanceCategory(category)
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
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(minWidth: 380, idealWidth: 380)
        .tint(Theme.positive)
        .onAppear {
            guard let category else { return }
            name = category.name
            monthlyAmountText = NSDecimalNumber(decimal: category.monthlyAmount).stringValue
        }
        // Button(.defaultAction) alone doesn't reliably fire on Return while
        // a TextField in this sheet has focus -- onSubmit is what actually
        // wires the Return key to the save action.
        .onSubmit { save() }
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
        guard !trimmedName.isEmpty, let monthlyAmount else { return }

        if var existing = category {
            existing.name = trimmedName
            existing.monthlyAmount = monthlyAmount
            store.updateMaintenanceCategory(existing)
        } else {
            store.addMaintenanceCategory(name: trimmedName, monthlyAmount: monthlyAmount)
        }
        dismiss()
    }
}
