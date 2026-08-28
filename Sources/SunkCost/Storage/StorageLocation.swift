import Foundation
import AppKit

/// Decides where the app's data file lives, and handles the sandboxed
/// mechanics of remembering a user-chosen folder across launches.
///
/// Default: a folder inside the app's own sandboxed Application Support
/// directory — nothing to configure, nothing leaves the Mac.
///
/// Optional: the user can pick any folder (via `chooseNewFolder`), including
/// one inside iCloud Drive. Sandboxed apps can't just remember an arbitrary
/// path — they have to keep a "security-scoped bookmark" (Apple's mechanism
/// for "the user granted access to this folder, remember that") and re-open
/// access to it on every launch.
enum StorageLocation {
    static let bookmarkKey = "SunkCost.StorageFolderBookmark"
    static let fileName = "items.json"

    static func defaultFolderURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("SunkCost", isDirectory: true)
    }

    /// Resolves whichever folder is currently configured (custom, if the user
    /// picked one and it's still reachable; otherwise the default). Returns a
    /// closure to call when the app is done using that folder for now.
    static func resolveCurrentFolder() -> (url: URL, stopAccessing: (() -> Void)?) {
        if let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) {
            var isStale = false
            if let resolvedURL = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                let started = resolvedURL.startAccessingSecurityScopedResource()
                return (resolvedURL, started ? { resolvedURL.stopAccessingSecurityScopedResource() } : nil)
            }
        }
        let folder = defaultFolderURL()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return (folder, nil)
    }

    static func itemsFileURL(in folder: URL) -> URL {
        folder.appendingPathComponent(fileName)
    }

    /// Shows a folder picker and returns the chosen folder. Persists
    /// nothing -- the caller inspects what's already in that folder and
    /// confirms with the user before `commitFolder` makes the switch
    /// permanent.
    @MainActor
    static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose Folder"
        panel.message = "Choose a folder where Sunk Cost should store its data file. This can be anywhere — including a folder in iCloud Drive if you want it backed up and synced."

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    /// Persists `url` as a security-scoped bookmark so future launches can
    /// reopen it. Returns `false` -- and stores nothing -- if the bookmark
    /// can't be created, since switching to a folder the app can't get
    /// back to next launch would silently strand the data.
    @discardableResult
    static func commitFolder(_ url: URL) -> Bool {
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return false
        }
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
        return true
    }

    static func resetToDefault() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }
}
