import Foundation

public struct Totals: Sendable {
    public let totalSpent: Decimal
    public let inTheHouse: Decimal
    public let goneButPaidFor: Decimal
    public let plannedNotSpent: Decimal

    public init(items: [Item]) {
        func sum(_ status: Status) -> Decimal {
            items
                .filter { $0.status == status }
                .reduce(Decimal(0)) { $0 + ($1.cost ?? 0) }
        }

        self.inTheHouse = sum(.owned)
        self.goneButPaidFor = sum(.gone)
        self.plannedNotSpent = sum(.planned)
        self.totalSpent = inTheHouse + goneButPaidFor
    }
}
