import SwiftUI

@main
struct TheMoneyPitApp: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup("The Money Pit") {
            ContentView()
                .environment(store)
                .environment(\.dynamicTypeSize, store.dynamicTypeSize)
                .preferredColorScheme(store.appearanceMode.colorScheme)
        }
        .defaultSize(width: 720, height: 640)
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
                .environment(\.dynamicTypeSize, store.dynamicTypeSize)
                .preferredColorScheme(store.appearanceMode.colorScheme)
        }
    }
}
