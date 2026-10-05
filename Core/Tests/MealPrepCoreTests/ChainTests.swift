import Testing
@testable import MealPrepCore

struct ChainTests {
    @Test func dealerIdRoundTrip() {
        for chain in Chain.allCases {
            #expect(Chain(dealerId: chain.dealerId) == chain)
        }
        #expect(Chain(dealerId: "6d6aSE") == nil)
        #expect(Chain.allDealerIds.count == Chain.allCases.count)
    }

    @Test func knownIds() {
        #expect(Chain.netto.dealerId == "9ba51")
        #expect(Chain.rema1000.dealerId == "11deC")
        #expect(Chain.coop365.displayName == "Coop 365")
    }

    @Test func haversineDistance() {
        let a = Coordinate(latitude: 55.6761, longitude: 12.5683)
        let b = Coordinate(latitude: 55.6867, longitude: 12.5530)
        #expect(abs(a.distance(to: b) - 1520) < 30)
        #expect(a.distance(to: a) == 0)
    }
}
