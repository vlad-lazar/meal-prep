import Foundation
import Testing
@testable import MealPrepCore

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

struct TjekParsingTests {
    @Test func edgeFixtureKeepsOnlyUsableOffers() throws {
        let offers = try Tjek.parseOffers(fixture("tjek-offers-edge"))
        #expect(offers.map(\.id) == ["ok-range", "ok-cl-multi"])
    }

    @Test func rangeUsesSmallestSize() throws {
        let offer = try #require(try Tjek.parseOffers(fixture("tjek-offers-edge")).first { $0.id == "ok-range" })
        #expect(offer.packAmount == 1000)
        #expect(offer.packUnit == .g)
        #expect(offer.pieces == 1)
        #expect(offer.price == 64.95)
        #expect(offer.dealerName == "Lidl")
        #expect(offer.chain == .lidl)
        #expect(offer.imageURL?.absoluteString == "https://example.com/a.webp")
        let expected = ISO8601DateFormatter().date(from: "2026-12-31T22:59:59Z")
        #expect(offer.validUntil == expected)
    }

    @Test func multiPieceOfferPurchaseAmount() throws {
        let offer = try #require(try Tjek.parseOffers(fixture("tjek-offers-edge")).first { $0.id == "ok-cl-multi" })
        #expect(offer.packUnit == .cl)
        #expect(offer.pieces == 2)
        #expect(offer.purchaseAmount == 80)
        #expect(offer.prePrice == 40)
        #expect(offer.imageURL == nil)
    }

    @Test func storesKeepOnlyGroceryChains() throws {
        let origin = Coordinate(latitude: 55.6867, longitude: 12.5530)
        let stores = try Tjek.parseStores(fixture("tjek-stores-small"), origin: origin)
        #expect(stores.map(\.chain) == [.netto, .rema1000])
        let netto = stores[0]
        #expect(netto.name == "Netto Nørrebrogade 1")
        #expect(netto.address == "Nørrebrogade 1, 2200 København N")
        #expect(netto.distanceMeters > 200 && netto.distanceMeters < 300)
        #expect(stores[1].address == "Jagtvej 10")
    }

    @Test func recordedResponsesDecode() throws {
        let offers = try Tjek.parseOffers(fixture("tjek-offers-kyllingebryst"))
        #expect(!offers.isEmpty)
        #expect(offers.allSatisfy { $0.price > 0 && $0.packAmount > 0 && !$0.dealerId.isEmpty })
        let stores = try Tjek.parseStores(fixture("tjek-stores-recorded"),
                                          origin: Coordinate(latitude: 55.6867, longitude: 12.5530))
        #expect(!stores.isEmpty)
    }
}
