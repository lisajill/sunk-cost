import Testing
import Foundation
@testable import SunkCost
@testable import SunkCostCore

/// `final class` so `init`/`deinit` can snapshot and restore the real
/// `UserDefaults` keys that a folder switch writes -- these tests exercise
/// the custom-folder commit path, which persists a bookmark.
private let onboardingDefaultsKey = "SunkCost.HasCompletedOnboarding"

@MainActor
final class StorageSwitchTests {
    private let savedBookmark: Data?
    private let hadOnboardingKey: Bool
    private let onboardingValue: Bool

    init() {
        savedBookmark = UserDefaults.standard.data(forKey: StorageLocation.bookmarkKey)
        hadOnboardingKey = UserDefaults.standard.object(forKey: onboardingDefaultsKey) != nil
        onboardingValue = UserDefaults.standard.bool(forKey: onboardingDefaultsKey)
        UserDefaults.standard.removeObject(forKey: StorageLocation.bookmarkKey)
    }

    deinit {
        if let savedBookmark {
            UserDefaults.standard.set(savedBookmark, forKey: StorageLocation.bookmarkKey)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageLocation.bookmarkKey)
        }
        if hadOnboardingKey {
            UserDefaults.standard.set(onboardingValue, forKey: onboardingDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: onboardingDefaultsKey)
        }
    }

    // MARK: inspect

    @Test("inspect reports an empty folder, a folder with data, and an unreadable one")
    func inspectClassifiesTarget() {
        let origin = TempFolder()
        let store = AppStore(storageOverrideForTesting: origin.url)

        let empty = TempFolder()
        let emptyPending = store.inspectStorageTarget(folder: empty.url, isDefault: false)
        #expect(emptyPending.existingData == nil)
        #expect(!emptyPending.hasUnreadableFile)

        let populated = TempFolder()
        populated.writeItemsFile(AppData(items: [sampleItem("x")], homeValue: 1))
        let populatedPending = store.inspectStorageTarget(folder: populated.url, isDefault: false)
        #expect(populatedPending.existingData?.homeValue == 1)
        #expect(!populatedPending.hasUnreadableFile)

        let broken = TempFolder()
        broken.writeRawItemsFile("nonsense")
        let brokenPending = store.inspectStorageTarget(folder: broken.url, isDefault: false)
        #expect(brokenPending.existingData == nil)
        #expect(brokenPending.hasUnreadableFile)
    }

    // MARK: adopt

    @Test("adopt an empty folder: switches, keeps an empty list")
    func adoptEmptyFolder() {
        let origin = TempFolder()
        let target = TempFolder()

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.addItem(sampleItem("stays in origin"))

        store.adoptStorageFolder(store.inspectStorageTarget(folder: target.url, isDefault: false))

        #expect(sameFolder(store.storageFolderURL, target.url))
        #expect(store.items.isEmpty)
        #expect(store.loadError == nil)
    }

    @Test("adopt a folder with data: switches and loads that data")
    func adoptFolderWithData() {
        let origin = TempFolder()
        let target = TempFolder()
        target.writeItemsFile(AppData(items: [sampleItem("from target")], homeValue: 500_000))

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.addItem(sampleItem("from origin"))

        store.adoptStorageFolder(store.inspectStorageTarget(folder: target.url, isDefault: false))

        #expect(sameFolder(store.storageFolderURL, target.url))
        #expect(store.items.map(\.name) == ["from target"])
        #expect(store.homeValue == 500_000)
    }

    @Test("adopt aborts on an unreadable file in the target, leaving the store put")
    func adoptAbortsOnUnreadableTarget() {
        let origin = TempFolder()
        let target = TempFolder()
        target.writeRawItemsFile("{ not valid json")

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.setHomeValue(123_456)

        let pending = store.inspectStorageTarget(folder: target.url, isDefault: false)
        store.adoptStorageFolder(pending)

        #expect(sameFolder(store.storageFolderURL, origin.url)) // did NOT switch
        #expect(store.homeValue == 123_456)           // memory untouched
        #expect(store.loadError != nil)
    }

    // MARK: replace

    @Test("replace an empty folder: switches and writes current data in")
    func replaceEmptyFolder() {
        let origin = TempFolder()
        let target = TempFolder()

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.addItem(sampleItem("carried over"))
        store.setHomeValue(400_000)

        let reprompt = store.replaceDataAtStorageFolder(
            store.inspectStorageTarget(folder: target.url, isDefault: false)
        )

        #expect(reprompt == nil)
        #expect(sameFolder(store.storageFolderURL, target.url))
        let onDisk = try! ItemStore.load(from: target.itemsFileURL)
        #expect(onDisk.items.map(\.name) == ["carried over"])
        #expect(onDisk.homeValue == 400_000)
    }

    @Test("replace re-prompts and doesn't overwrite when a file appeared since inspection")
    func replaceRepromptsOnRace() {
        let origin = TempFolder()
        let target = TempFolder()

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.addItem(sampleItem("mine"))

        let pending = store.inspectStorageTarget(folder: target.url, isDefault: false)
        #expect(pending.existingData == nil)

        // A file syncs in after inspection, before the write.
        target.writeItemsFile(AppData(items: [sampleItem("theirs")], homeValue: 999))

        let reprompt = store.replaceDataAtStorageFolder(pending)

        #expect(reprompt != nil)
        #expect(reprompt?.existingData?.homeValue == 999)
        #expect(sameFolder(store.storageFolderURL, origin.url)) // did NOT switch
        let onDisk = try! ItemStore.load(from: target.itemsFileURL)
        #expect(onDisk.items.map(\.name) == ["theirs"]) // target untouched
    }

    @Test("replace proceeds when the target still matches what was inspected")
    func replaceProceedsWhenUnchanged() {
        let origin = TempFolder()
        let target = TempFolder()
        target.writeItemsFile(AppData(items: [sampleItem("old target data")]))

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.addItem(sampleItem("replacement"))

        let pending = store.inspectStorageTarget(folder: target.url, isDefault: false)
        let reprompt = store.replaceDataAtStorageFolder(pending)

        #expect(reprompt == nil)
        #expect(sameFolder(store.storageFolderURL, target.url))
        let onDisk = try! ItemStore.load(from: target.itemsFileURL)
        #expect(onDisk.items.map(\.name) == ["replacement"])
    }

    @Test("a failed write to the target leaves the store where it was")
    func replaceFailedWriteIsInert() {
        let origin = TempFolder()
        let target = TempFolder()

        let store = AppStore(storageOverrideForTesting: origin.url)
        store.setHomeValue(321)

        let pending = store.inspectStorageTarget(folder: target.url, isDefault: false)
        target.setWritable(false)
        defer { target.setWritable(true) }

        let reprompt = store.replaceDataAtStorageFolder(pending)

        #expect(reprompt == nil)
        #expect(sameFolder(store.storageFolderURL, origin.url)) // did NOT switch
        #expect(store.homeValue == 321)
        #expect(store.loadError != nil)
    }
}
