import SwiftUI
import AppKit
import SunkCostCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    @State private var purchasePriceText: String = ""
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
    @State private var showPurchasePriceSavedConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Invisible button bound to Escape. `.onExitCommand` alone
                // was unreliable for closing this window; a button with
                // `.keyboardShortcut(.cancelAction)` is the mechanism macOS
                // actually guarantees works for "Escape = cancel/close",
                // regardless of which control currently has focus.
                Button("") { NSApp.keyWindow?.close() }
                    .keyboardShortcut(.cancelAction)
                    .frame(width: 0, height: 0)
                    .opacity(0)
                    .accessibilityHidden(true)

                appearanceSection
                Divider()
                storageSection
                Divider()
                dataSection
                Divider()
                categoriesSection
                Divider()
                purchasePriceSection
                Divider()
                mortgageSection

                if let error = store.loadError {
                    Text(error)
                        .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 480, idealWidth: 480, minHeight: 620, idealHeight: 620)
        .tint(Theme.positive)
        .environment(\.appTextScale, store.textScale)
        .onAppear {
            populateMortgageFields()
            populatePurchasePriceField()
        }
        .onExitCommand { NSApp.keyWindow?.close() }
        // Same stale-color fix as the main window: Theme's custom
        // NSColor(dynamicProvider:)-based colors can lag behind a live
        // .preferredColorScheme flip. Settings has its own appearance
        // picker, so it needs the same forced-rebuild treatment.
        .id(store.appearanceMode)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            Picker("Appearance", selection: Binding(
                get: { store.appearanceMode },
                set: { store.appearanceMode = $0 }
            )) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            Text("There's also a quick-switch button in the main window's toolbar.")
                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                .foregroundStyle(Theme.inkSecondary)
        }
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Backup & Transfer")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            Text("Export saves everything (items, home value, mortgage) to a single file you choose — for a backup, or to move your data to another Mac. Import loads a file like that back in, replacing what's currently here.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            HStack {
                Button("Export Data (JSON)…") {
                    store.exportData()
                }
                Button("Import Data (JSON)…") {
                    if let picked = store.pickFileToImport() {
                        pendingImport = picked
                    }
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))

            Divider()

            Text("CSV is for opening your items in Excel, Numbers, or Google Sheets. It only carries the item list — not home value or mortgage info.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            HStack {
                Button("Export Data (CSV)…") {
                    store.exportCSV()
                }
                Button("Import Data (CSV)…") {
                    if let picked = store.pickCSVFileToImport() {
                        pendingCSVImport = picked
                    }
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
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
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))

            Text("Your data file is currently stored here:")
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                .foregroundStyle(.secondary)

            Text(store.storageFolderURL.path)
                .font(Theme.scaledFont(Theme.FontSize.body, design: .monospaced, scale: store.textScale))
                .textSelection(.enabled)
                .padding(8)
                .background(Theme.ledgerPaper)
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            Text("By default this is a private, local-only folder on this Mac — nothing leaves your computer. You can point it anywhere you like instead, including a folder in iCloud Drive, if you want it backed up and synced automatically.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            HStack {
                Button("Choose a Different Folder…") {
                    store.chooseNewStorageFolder()
                }
                Button("Use Default Location") {
                    store.resetToDefaultStorageFolder()
                }
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            Text("Rename fixes a typo or merges two categories together. Delete moves a category's items somewhere else, then removes it.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            if store.categoriesWithCounts.isEmpty {
                Text("No categories yet — add an item to create one.")
                    .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.categoriesWithCounts, id: \.category) { entry in
                        HStack {
                            Text(entry.category)
                                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                                .foregroundStyle(Theme.ink)
                            Text("\(entry.count) item\(entry.count == 1 ? "" : "s")")
                                .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                                .foregroundStyle(Theme.inkSecondary)
                            Spacer()
                            Button("Rename…") {
                                categoryBeingRenamed = entry.category
                                newCategoryName = entry.category
                            }
                            .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                            .controlSize(.small)

                            Button("Delete…") {
                                categoryBeingDeleted = entry.category
                            }
                            .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
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

    private var purchasePriceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Home Purchase")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            Text("What you actually paid for the house. Used to show Appreciation (Home Value minus Purchase Price) alongside Equity on the main screen.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            labeledField("Purchase Price") {
                TextField("e.g. 380000", text: $purchasePriceText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            HStack(spacing: 8) {
                Button("Save Purchase Price") {
                    savePurchasePrice()
                }
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))

                if showPurchasePriceSavedConfirmation {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                        .foregroundStyle(Theme.positive)
                        .transition(.opacity)
                }
            }
        }
        .onSubmit { savePurchasePrice() }
    }

    private var mortgageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mortgage")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))

            Text("The current balance is what drives your Equity figure on the main screen. Update it whenever you check a new statement. The other fields are just for your own reference.")
                .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                .foregroundStyle(.secondary)

            labeledField("Current Balance Owed") {
                TextField("e.g. 75000", text: $mortgageBalanceText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Original Loan Amount") {
                TextField("e.g. 100000", text: $mortgageOriginalAmountText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Interest Rate (%)") {
                TextField("e.g. 3.75", text: $mortgageInterestRateText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 140, idealWidth: 200, maxWidth: 280)
            }

            labeledField("Loan Start Date") {
                HStack {
                    Toggle("", isOn: $hasStartDate)
                        .labelsHidden()
                    DatePicker("", selection: $mortgageStartDate, displayedComponents: .date)
                        .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                        .labelsHidden()
                        .disabled(!hasStartDate)
                }
            }

            labeledField("Loan Term (years)") {
                TextField("e.g. 30", text: $mortgageTermYearsText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 100, idealWidth: 140, maxWidth: 200)
            }

            labeledField("Monthly Payment") {
                TextField("Leave blank to auto-calculate", text: $monthlyPaymentText)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 180, idealWidth: 240, maxWidth: 300)

                if monthlyPaymentText.trimmingCharacters(in: .whitespaces).isEmpty,
                   let calculated = store.monthlyPayment {
                    Text("Estimated: \(currencyString(calculated))/mo, based on amount, rate, and term")
                        .font(Theme.scaledFont(Theme.FontSize.caption, scale: store.textScale))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }

            HStack(spacing: 8) {
                Button("Save Mortgage Info") {
                    saveMortgage()
                }
                .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))

                if showMortgageSavedConfirmation {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                        .foregroundStyle(Theme.positive)
                        .transition(.opacity)
                }
            }
        }
        .onSubmit { saveMortgage() }
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

    private func populatePurchasePriceField() {
        if let price = store.purchasePrice {
            purchasePriceText = NSDecimalNumber(decimal: price).stringValue
        }
    }

    private func savePurchasePrice() {
        store.setPurchasePrice(decimal(from: purchasePriceText))

        withAnimation {
            showPurchasePriceSavedConfirmation = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showPurchasePriceSavedConfirmation = false
            }
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
