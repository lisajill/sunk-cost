import SwiftUI

@main
struct SunkCostApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup("Sunk Cost") {
            ContentView()
                .environment(store)
                .environment(\.appTextScale, store.textScale)
                .preferredColorScheme(store.appearanceMode.colorScheme)
        }
        .defaultSize(width: 720, height: 780)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Increase Font Size") { store.increaseTextSize() }
                    .keyboardShortcut("=", modifiers: .command)
                Button("Decrease Font Size") { store.decreaseTextSize() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Reset Font Size") { store.resetTextSize() }
                    .keyboardShortcut("0", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(store)
                .environment(\.appTextScale, store.textScale)
                .preferredColorScheme(store.appearanceMode.colorScheme)
        }
    }
}
