import SwiftUI
import TheMoneyPitCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    @State private var mortgageOriginalAmountText: String = ""
    @State private var mortgageInterestRateText: String = ""
    @State private var mortgageStartDate: Date = Date()
    @State private var mortgageBalanceText: String = ""
    @State private var mortgageTermYearsText: String = ""
    @State private var monthlyPaymentText: String = ""
    @State private var hasStartDate = false

    @State private var categoryBeingRenamed: String?
    @State private var newCategoryName: String = ""
    @State private var categoryBeingDeleted: String?

    @State private var pendingImport: (url: URL, data: AppData)?
    @State private var pendingCSVImport: (url: URL, items: [Item])?

    @State private var showMortgageSavedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                appearanceSection
                Divider()
                storageSection
                Divider()
                dataSection
                Divider()
                categoriesSection
                Divider()
                mortgageSection

                if let error = store.loadError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .frame(width: 480, height: 620)
        .tint(Theme.ledgerGreen)
        .environment(\.dynamicTypeSize, store.dynamicTypeSize)
        .onAppear { populateMortgageFields() }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Picker("Appearance", selection: Binding(
                get: { store.appearanceMode },
                set: { store.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            Text("There's also a quick-switch button in the main window's toolbar.")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup & Transfer")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Text("Export saves everything (items, home value, mortgage) to a single file you choose — for a backup, or to move your data to another Mac. Import loads a file like that back in, replacing what's currently here.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Export Data…") {
                    store.exportData()
                }
                Button("Import Data…") {
                    if let picked = store.pickFileToImport() {
                        pendingImport = picked
                    }
                }
            }

            Divider()

            Text("CSV is for opening your items in Excel, Numbers, or Google Sheets. It only carries the item list — not home value or mortgage info.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Export CSV…") {
                    store.exportCSV()
                }
                Button("Import CSV…") {
                    if let picked = store.pickCSVFileToImport() {
                        pendingCSVImport = picked
                    }
                }
            }
        }
        .alert(
            "Replace Current Data?",
            isPresented: Binding(
                get: { pendingImport != nil },
                set: { if !$0 { pendingImport = nil } }
            ),
            presenting: pendingImport
        ) { pending in
            Button("Replace", role: .destructive) {
                store.applyImportedData(pending.data)
                pendingImport = nil
            }
            Button("Cancel", role: .cancel) {
                pendingImport = nil
            }
        } message: { pending in
            Text("This replaces your current \(store.items.count) item\(store.items.count == 1 ? "" : "s") with \(pending.data.items.count) from \"\(pending.url.lastPathComponent)\". This can't be undone.")
        }
        .alert(
            "Replace Current Items?",
            isPresented: Binding(
                get: { pendingCSVImport != nil },
                set: { if !$0 { pendingCSVImport = nil } }
            ),
            presenting: pendingCSVImport
        ) { pending in
            Button("Replace", role: .destructive) {
                store.applyImportedCSVItems(pending.items)
                pendingCSVImport = nil
            }
            Button("Cancel", role: .cancel) {
                pendingCSVImport = nil
            }
        } message: { pending in
            Text("This replaces your current \(store.items.count) item\(store.items.count == 1 ? "" : "s") with \(pending.items.count) from \"\(pending.url.lastPathComponent)\". Home value and mortgage info are untouched. This can't be undone.")
        }
    }

    private var storageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Location")
                .font(.headline)

            Text("Your data file is currently stored here:")
                .foregroundStyle(.secondary)

            Text(store.storageFolderURL.path)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .background(Theme.ledgerPaper)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text("By default this is a private, local-only folder on this Mac — nothing leaves your computer. You can point it anywhere you like instead, including a folder in iCloud Drive, if you want it backed up and synced automatically.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                Button("Choose a Different Folder…") {
                    store.chooseNewStorageFolder()
                }
                Button("Use Default Location") {
                    store.resetToDefaultStorageFolder()
                }
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Text("Rename fixes a typo or merges two categories together. Delete moves a category's items somewhere else, then removes it.")
                .font(.callout)
                .foregroundStyle(.secondary)

            if store.categoriesWithCounts.isEmpty {
                Text("No categories yet — add an item to create one.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.categoriesWithCounts, id: \.category) { entry in
                        HStack {
                            Text(entry.category)
                                .foregroundStyle(Theme.ink)
                            Text("\(entry.count) item\(entry.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(Theme.inkSecondary)
                            Spacer()
                            Button("Rename…") {
                                categoryBeingRenamed = entry.category
                                newCategoryName = entry.category
                            }
                            .controlSize(.small)

                            Button("Delete…") {
                                categoryBeingDeleted = entry.category
                            }
                            .controlSize(.small)
                            .disabled(otherCategories(than: entry.category).isEmpty)
                            .help(
                                otherCategories(than: entry.category).isEmpty
                                    ? "Add another category first — this is the only one, and every item needs one."
                                    : "Move this category's items elsewhere, then remove it"
                            )
                        }
                        .padding(.vertical, 6)

                        if entry.category != store.categoriesWithCounts.last?.category {
                            Divider()
                        }
                    }
                }
            }
        }
        .alert(
            "Rename Category",
            isPresented: Binding(
                get: { categoryBeingRenamed != nil },
                set: { if !$0 { categoryBeingRenamed = nil } }
            ),
            presenting: categoryBeingRenamed
        ) { oldName in
            TextField("Category name", text: $newCategoryName)
            Button("Rename") {
                store.renameCategory(from: oldName, to: newCategoryName)
                categoryBeingRenamed = nil
            }
            Button("Cancel", role: .cancel) {
                categoryBeingRenamed = nil
            }
        } message: { oldName in
            Text("This updates every item currently in \"\(oldName)\". Renaming it to match another existing category merges them.")
        }
        .confirmationDialog(
            "Delete \"\(categoryBeingDeleted ?? "")\"?",
            isPresented: Binding(
                get: { categoryBeingDeleted != nil },
                set: { if !$0 { categoryBeingDeleted = nil } }
            ),
            presenting: categoryBeingDeleted
        ) { oldName in
            ForEach(otherCategories(than: oldName), id: \.self) { destination in
                Button("Move items to \"\(destination)\"") {
                    store.renameCategory(from: oldName, to: destination)
                    categoryBeingDeleted = nil
                }
            }
            Button("Cancel", role: .cancel) {
                categoryBeingDeleted = nil
            }
        } message: { oldName in
            let count = store.categoriesWithCounts.first(where: { $0.category == oldName })?.count ?? 0
            Text("\"\(oldName)\" has \(count) item\(count == 1 ? "" : "s"). Every item needs a category, so choose where these should go before it's removed.")
        }
    }

    private func otherCategories(than category: String) -> [String] {
        store.availableCategories.filter { $0 != category }
    }

    private var mortgageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mortgage")
                .font(.headline)

            Text("The current balance is what drives your Equity figure on the main screen. Update it whenever you check a new statement. The other fields are just for your own reference.")
                .font(.callout)
                .foregroundStyle(.secondary)

            labeledField("Current Balance Owed") {
                TextField("e.g. 75000", text: $mortgageBalanceText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Original Loan Amount") {
                TextField("e.g. 100000", text: $mortgageOriginalAmountText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Interest Rate (%)") {
                TextField("e.g. 3.75", text: $mortgageInterestRateText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Loan Start Date") {
                HStack {
                    Toggle("", isOn: $hasStartDate)
                        .labelsHidden()
                    DatePicker("", selection: $mortgageStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .disabled(!hasStartDate)
                }
            }

            labeledField("Loan Term (years)") {
                TextField("e.g. 30", text: $mortgageTermYearsText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 100, idealWidth: 140, maxWidth: 200)
            }

            labeledField("Monthly Payment") {
                TextField("Leave blank to auto-calculate", text: $monthlyPaymentText)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180, idealWidth: 240, maxWidth: 300)

                if monthlyPaymentText.trimmingCharacters(in: .whitespaces).isEmpty,
                   let calculated = store.monthlyPayment {
                    Text("Estimated: \(currencyString(calculated))/mo, based on amount, rate, and term")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            HStack(spacing: 8) {
                Button("Save Mortgage Info") {
                    saveMortgage()
                }

                if showMortgageSavedConfirmation {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.ledgerGreen)
                        .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Theme.ledgerLabel)
                .tracking(0.6)
                .foregroundStyle(Theme.inkSecondary)
            content()
        }
    }

    private func populateMortgageFields() {
        if let amount = store.mortgageOriginalAmount {
            mortgageOriginalAmountText = NSDecimalNumber(decimal: amount).stringValue
        }
        if let rate = store.mortgageInterestRatePercent {
            mortgageInterestRateText = NSDecimalNumber(decimal: rate).stringValue
        }
        if let balance = store.mortgageBalance {
            mortgageBalanceText = NSDecimalNumber(decimal: balance).stringValue
        }
        if let startDate = store.mortgageStartDate {
            mortgageStartDate = startDate
            hasStartDate = true
        }
        if let termYears = store.mortgageTermYears {
            mortgageTermYearsText = String(termYears)
        }
        if let override = store.monthlyPaymentOverride {
            monthlyPaymentText = NSDecimalNumber(decimal: override).stringValue
        }
    }

    private func currencyString(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }

    private func decimal(from text: String) -> Decimal? {
        let digitsAndDot = text.filter { $0.isNumber || $0 == "." }
        guard !digitsAndDot.isEmpty else { return nil }
        return Decimal(string: digitsAndDot)
    }

    private func saveMortgage() {
        let termYears = Int(mortgageTermYearsText.trimmingCharacters(in: .whitespaces))
        store.setMortgage(
            originalAmount: decimal(from: mortgageOriginalAmountText),
            interestRatePercent: decimal(from: mortgageInterestRateText),
            startDate: hasStartDate ? mortgageStartDate : nil,
            balance: decimal(from: mortgageBalanceText),
            termYears: termYears,
            monthlyPaymentOverride: decimal(from: monthlyPaymentText)
        )

        withAnimation {
            showMortgageSavedConfirmation = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showMortgageSavedConfirmation = false
            }
        }
    }
}
