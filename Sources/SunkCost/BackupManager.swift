import Foundation
import SunkCostCore

/// Silently keeps a rolling window of daily snapshots of the data file, so
/// a bad edit or an accidental delete has a recent "undo the whole day"
/// recovery path even without the user doing anything. One snapshot per
/// day, taken at the *first* save of that day -- overwriting through the
/// day would defeat the point, since "today's backup" would just mirror
/// whatever mistake happened later that same day.
enum BackupManager {
    static let retentionDays = 14

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        // Local time, not UTC: "one backup per day" should mean the user's
        // calendar day, and the date parsed back out of a filename is
        // shown in the Restore menu in local time -- a UTC formatter here
        // made an evening backup show as (and roll over on) the wrong day.
        formatter.timeZone = .current
        return formatter
    }()

    static func backupsFolder(in storageFolder: URL) -> URL {
        storageFolder.appendingPathComponent(".backups", isDirectory: true)
    }

    /// Best-effort -- a failed backup shouldn't block or fail the actual
    /// save, so errors here are silently swallowed.
    static func snapshot(dataFileURL: URL, storageFolder: URL) {
        let folder = backupsFolder(in: storageFolder)
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

            let todayBackupURL = folder.appendingPathComponent("items-\(dateFormatter.string(from: Date())).json")
            if fileManager.fileExists(atPath: dataFileURL.path), !fileManager.fileExists(atPath: todayBackupURL.path) {
                try fileManager.copyItem(at: dataFileURL, to: todayBackupURL)
            }

            prune(folder: folder, fileManager: fileManager)
        } catch {
            // Silent -- see doc comment above.
        }
    }

    /// The dates and file locations of currently-kept backups, newest
    /// first -- lets the UI offer "restore to this day" without the user
    /// having to go find the file in Finder themselves.
    static func availableBackups(in storageFolder: URL) -> [(date: Date, url: URL)] {
        let folder = backupsFolder(in: storageFolder)
        guard let existingFiles = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return [] }

        var results: [(date: Date, url: URL)] = []
        for fileURL in existingFiles {
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            guard baseName.hasPrefix("items-") else { continue }
            let dateString = String(baseName.dropFirst("items-".count))
            guard let date = dateFormatter.date(from: dateString) else { continue }
            results.append((date, fileURL))
        }
        return results.sorted { $0.date > $1.date }
    }

    private static func prune(folder: URL, fileManager: FileManager) {
        guard let existingFiles = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return }

        var urlsByDate: [Date: URL] = [:]
        for fileURL in existingFiles {
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            guard baseName.hasPrefix("items-") else { continue }
            let dateString = String(baseName.dropFirst("items-".count))
            guard let date = dateFormatter.date(from: dateString) else { continue }
            urlsByDate[date] = fileURL
        }

        for date in datesToPrune(existing: Array(urlsByDate.keys), keepLast: retentionDays) {
            if let url = urlsByDate[date] {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}
