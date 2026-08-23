import Testing
@testable import TheMoneyPitCore

@Suite("Status cycling")
struct StatusCycleTests {
    @Test("owned cycles to gone")
    func ownedCyclesToGone() {
        #expect(Status.owned.next() == .gone)
    }

    @Test("gone cycles to planned")
    func goneCyclesToPlanned() {
        #expect(Status.gone.next() == .planned)
    }

    @Test("planned cycles to owned")
    func plannedCyclesToOwned() {
        #expect(Status.planned.next() == .owned)
    }
}
