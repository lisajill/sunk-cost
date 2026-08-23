import SwiftUI
import SunkCostCore

/// Name + Notes editor for a saved Compare scenario -- used both to save
/// the current assumptions as a new scenario (`existingScenario == nil`)
/// and to rename/annotate an existing one afterward. The 13 assumption
/// values themselves aren't editable here -- delete and re-save if those
/// need to change.
struct ScenarioDetailsSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existingScenario: ComparisonScenario?
    @State private var name: String
    @State private var notes: String

    init(existingScenario: ComparisonScenario?) {
        self.existingScenario = existingScenario
        _name = State(initialValue: existingScenario?.name ?? "")
        _notes = State(initialValue: existingScenario?.notes ?? "")
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(existingScenario == nil ? "Save Scenario" : "Edit Scenario")
                .font(Theme.scaledFont(Theme.FontSize.headline, weight: .semibold, scale: store.textScale))
                .foregroundStyle(Theme.ink)

            if existingScenario == nil {
                Text("Saves the Years, appreciation, rent, and new-home assumptions below so you can reload them later.")
                    .font(Theme.scaledFont(Theme.FontSize.callout, scale: store.textScale))
                    .foregroundStyle(Theme.inkSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NAME")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSecondary)
                TextField("e.g. Downsize to condo", text: $name)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NOTES (OPTIONAL)")
                    .font(Theme.ledgerLabel(scale: store.textScale))
                    .tracking(0.6)
                    .foregroundStyle(Theme.inkSecondary)
                TextEditor(text: $notes)
                    .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.ledgerBorder, lineWidth: 1))
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isNameValid)
            }
            .font(Theme.scaledFont(Theme.FontSize.body, scale: store.textScale))
        }
        .padding(20)
        .frame(width: 360)
        // Button(.defaultAction) alone doesn't reliably fire on Return while
        // the Name field has focus -- onSubmit on the container is what
        // actually wires Return to save. Return inside the Notes TextEditor
        // just inserts a newline and doesn't trigger this.
        .onSubmit { save() }
    }

    private func save() {
        guard isNameValid else { return }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesValue = trimmedNotes.isEmpty ? nil : notes
        if let existingScenario {
            store.updateScenarioMetadata(existingScenario, name: name, notes: notesValue)
        } else {
            store.saveCurrentScenarioAsPreset(name: name, notes: notesValue)
        }
        dismiss()
    }
}
