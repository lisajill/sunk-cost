import Testing
@testable import SunkCostCore

@Suite("Status filter toggle")
struct StatusFilterToggleTests {
    @Test("tapping a status when no filter is active sets that filter")
    func tappingSetsFilterWhenNoneActive() {
        #expect(toggledStatusFilter(current: nil, tapped: .gone) == .gone)
    }

    @Test("tapping the already-active status clears the filter")
    func tappingActiveStatusClearsFilter() {
        #expect(toggledStatusFilter(current: .gone, tapped: .gone) == nil)
    }

    @Test("tapping a different status switches the filter")
    func tappingDifferentStatusSwitchesFilter() {
        #expect(toggledStatusFilter(current: .gone, tapped: .owned) == .owned)
    }
}
