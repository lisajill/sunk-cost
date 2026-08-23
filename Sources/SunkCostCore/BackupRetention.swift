import Foundation

/// Given the dates of existing daily backups and how many to keep, returns
/// which dates should be deleted -- oldest first, keeping the most recent
/// `keepLast`. Pure logic so the actual file deletion (the app-layer
/// backup manager) can be tested without touching disk.
public func datesToPrune(existing: [Date], keepLast: Int) -> [Date] {
    let sorted = existing.sorted(by: >) // newest first
    guard sorted.count > keepLast else { return [] }
    return Array(sorted.dropFirst(max(keepLast, 0)))
}
