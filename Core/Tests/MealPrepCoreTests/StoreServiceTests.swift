import Foundation
import Testing
@testable import MealPrepCore

struct StoreServiceTests {
    let origin = Coordinate(latitude: 55.6867, longitude: 12.5530)

    @Test func widensRadiusWhenEmpty() async throws {
        let small = try fixture("tjek-stores-small")
        let http = FakeHTTP { url in queryItem(url, "r_radius") == "3000" ? Data("[]".utf8) : small }
        let result = try await StoreService(client: TjekClient(http: http)).nearbyStores(near: origin)
        #expect(result.radius == 10000)
        #expect(result.stores.map(\.chain) == [.netto, .rema1000])
    }

    @Test func keepsNearestStorePerChain() async throws {
        let json = """
        [{"id":"netto-far","street":"A","latitude":55.70,"longitude":12.553,"dealer_id":"9ba51"},
         {"id":"netto-near","street":"B","latitude":55.687,"longitude":12.553,"dealer_id":"9ba51"},
         {"id":"lidl","street":"C","latitude":55.69,"longitude":12.553,"dealer_id":"71c90"}]
        """
        let http = FakeHTTP { _ in Data(json.utf8) }
        let result = try await StoreService(client: TjekClient(http: http)).nearbyStores(near: origin)
        #expect(result.radius == 3000)
        #expect(result.stores.map(\.id) == ["netto-near", "lidl"])
    }

    @Test func emptyEverywhereReturnsNoStores() async throws {
        let http = FakeHTTP { _ in Data("[]".utf8) }
        let result = try await StoreService(client: TjekClient(http: http)).nearbyStores(near: origin)
        #expect(result.stores.isEmpty)
        #expect(result.radius == 10000)
        #expect(await http.requests.count == 2)
    }

    @Test func requestsOnlyGroceryDealers() {
        let url = TjekClient(http: FakeHTTP { _ in Data() }).storesURL(near: origin, radius: 3000)
        #expect(queryItem(url, "dealer_ids") == Chain.allDealerIds.joined(separator: ","))
        #expect(queryItem(url, "limit") == "100")
    }

    @Test func networkErrorPropagates() async {
        let http = FakeHTTP { _ in throw HTTPError.status(500) }
        await #expect(throws: HTTPError.status(500)) {
            try await StoreService(client: TjekClient(http: http)).nearbyStores(near: origin)
        }
    }
}
