import Testing
import Foundation
@testable import SunkCostCore

@Suite("Backup retention")
struct BackupRetentionTests {
    private func daysAgo(_ n: Int) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 - Double(n) * 86_400)
    }

    @Test("keeps everything when there are fewer backups than the retention count")
    func keepsEverythingWhenUnderLimit() {
        let existing = [daysAgo(0), daysAgo(1)]
        #expect(datesToPrune(existing: existing, keepLast: 5).isEmpty)
    }

    @Test("keeps everything when the count exactly matches the retention limit")
    func keepsEverythingAtExactLimit() {
        let existing = [daysAgo(0), daysAgo(1), daysAgo(2)]
        #expect(datesToPrune(existing: existing, keepLast: 3).isEmpty)
    }

    @Test("prunes the oldest backups beyond the retention count")
    func prunesOldestBeyondLimit() {
        let existing = [daysAgo(0), daysAgo(1), daysAgo(2), daysAgo(3), daysAgo(4)]
        let pruned = datesToPrune(existing: existing, keepLast: 2)
        #expect(Set(pruned) == Set([daysAgo(2), daysAgo(3), daysAgo(4)]))
    }

    @Test("keepLast of zero prunes everything")
    func keepLastZeroPrunesEverything() {
        let existing = [daysAgo(0), daysAgo(1)]
        #expect(Set(datesToPrune(existing: existing, keepLast: 0)) == Set(existing))
    }

    @Test("empty existing list prunes nothing")
    func emptyExistingPrunesNothing() {
        #expect(datesToPrune(existing: [], keepLast: 5).isEmpty)
    }
}
