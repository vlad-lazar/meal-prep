import Foundation
import Testing
@testable import MealPrepCore

struct OfferServiceTests {
    let origin = Coordinate(latitude: 55.6867, longitude: 12.5530)
    let chickenJSON = tjekOffersJSON([(id: "a", heading: "Kyllingebryst", dealer: "9ba51", price: 75, grams: 1000)])

    @Test func fetchesEachTermOnceFiltersDealersAndSkipsPantry() async {
        let http = FakeHTTP { url in
            switch queryItem(url, "query") {
            case "kyllingebryst":
                return tjekOffersJSON([(id: "a", heading: "Kyllingebryst", dealer: "9ba51", price: 75, grams: 1000),
                                       (id: "w", heading: "Kyllingebryst", dealer: "WOLT01", price: 40, grams: 450)])
            case "jasminris":
                return tjekOffersJSON([(id: "b", heading: "Jasminris", dealer: "71c90", price: 15, grams: 1000),
                                       (id: "a", heading: "Kyllingebryst", dealer: "9ba51", price: 75, grams: 1000)])
            default:
                return Data("[]".utf8)
            }
        }
        let service = OfferService(client: TjekClient(http: http), cache: OfferCache(directory: tempCacheDirectory()))
        let result = await service.offers(for: [Fixtures.chicken, Fixtures.rice, Fixtures.oil], near: origin, radius: 3000)
        #expect(result.freshness == .live)
        #expect(Set(result.offers.map(\.id)) == ["a", "b"])
        let requests = await http.requests
        let queries = requests.compactMap { queryItem($0, "query") }.sorted()
        #expect(queries == ["jasminris", "kyllingebryst", "ris"])
    }

    @Test func freshCacheAvoidsNetwork() async {
        let directory = tempCacheDirectory()
        let json = chickenJSON
        let ok = FakeHTTP { _ in json }
        _ = await OfferService(client: TjekClient(http: ok), cache: OfferCache(directory: directory))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        let failing = FakeHTTP { _ in throw HTTPError.status(503) }
        let result = await OfferService(client: TjekClient(http: failing), cache: OfferCache(directory: directory))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        #expect(result.freshness == .live)
        #expect(result.offers.map(\.id) == ["a"])
        #expect(await failing.requests.isEmpty)
    }

    @Test func staleCacheUsedWhenNetworkFails() async {
        let directory = tempCacheDirectory()
        let clock = TestClock(Date(timeIntervalSince1970: 1_790_000_000))
        let fetchedAt = clock.now
        let json = chickenJSON
        _ = await OfferService(client: TjekClient(http: FakeHTTP { _ in json }),
                               cache: OfferCache(directory: directory, now: { clock.now }))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        clock.now = fetchedAt.addingTimeInterval(13 * 3600)
        let result = await OfferService(client: TjekClient(http: FakeHTTP { _ in throw HTTPError.status(429) }),
                                        cache: OfferCache(directory: directory, now: { clock.now }))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        #expect(result.freshness == .cached(fetchedAt))
        #expect(result.offers.map(\.id) == ["a"])
    }

    @Test func staleCacheRefreshedWhenNetworkWorks() async {
        let directory = tempCacheDirectory()
        let clock = TestClock(Date(timeIntervalSince1970: 1_790_000_000))
        let json = chickenJSON
        _ = await OfferService(client: TjekClient(http: FakeHTTP { _ in json }),
                               cache: OfferCache(directory: directory, now: { clock.now }))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        clock.now = clock.now.addingTimeInterval(13 * 3600)
        let newer = tjekOffersJSON([(id: "b", heading: "Kyllingebryst", dealer: "71c90", price: 70, grams: 1000)])
        let result = await OfferService(client: TjekClient(http: FakeHTTP { _ in newer }),
                                        cache: OfferCache(directory: directory, now: { clock.now }))
            .offers(for: [Fixtures.chicken], near: origin, radius: 3000)
        #expect(result.freshness == .live)
        #expect(result.offers.map(\.id) == ["b"])
    }

    @Test func offlineWithoutCacheIsUnavailable() async {
        let service = OfferService(client: TjekClient(http: FakeHTTP { _ in throw URLError(.notConnectedToInternet) }),
                                   cache: OfferCache(directory: tempCacheDirectory()))
        let result = await service.offers(for: [Fixtures.chicken, Fixtures.rice], near: origin, radius: 3000)
        #expect(result.freshness == .unavailable)
        #expect(result.offers.isEmpty)
    }

    @Test func givesUpQuicklyWhenEveryRequestFails() async {
        let ingredients = (0..<20).map { i in
            Ingredient(id: "i\(i)", name: "I\(i)", danishName: "I\(i)", searchTerms: ["term\(i)"], excludeTerms: [],
                       section: .dry, isPantry: false, typicalPack: Pack(amount: 1, unit: .kg, priceDKK: 10),
                       gramsPerPiece: nil, mlDensity: nil, nutritionId: "x")
        }
        let http = FakeHTTP { _ in throw URLError(.timedOut) }
        let result = await OfferService(client: TjekClient(http: http), cache: OfferCache(directory: tempCacheDirectory()))
            .offers(for: ingredients, near: origin, radius: 3000)
        #expect(result.freshness == .unavailable)
        let requests = await http.requests.count
        #expect(requests < 12, "made \(requests) requests on a dead network")
    }

    @Test func keepsGoingWhenSomeRequestsSucceed() async {
        let ingredients = (0..<20).map { i in
            Ingredient(id: "i\(i)", name: "I\(i)", danishName: "I\(i)", searchTerms: ["term\(i)"], excludeTerms: [],
                       section: .dry, isPantry: false, typicalPack: Pack(amount: 1, unit: .kg, priceDKK: 10),
                       gramsPerPiece: nil, mlDensity: nil, nutritionId: "x")
        }
        // Every third term fails; the rest succeed — no bail-out.
        let http = FakeHTTP { url in
            let n = Int(queryItem(url, "query")?.dropFirst(4) ?? "") ?? 0
            if n % 3 == 0 { throw HTTPError.status(500) }
            return Data("[]".utf8)
        }
        _ = await OfferService(client: TjekClient(http: http), cache: OfferCache(directory: tempCacheDirectory()))
            .offers(for: ingredients, near: origin, radius: 3000)
        #expect(await http.requests.count == 20)
    }

    @Test func offersURLHasQueryAndLocation() {
        let url = TjekClient(http: FakeHTTP { _ in Data() }).offersURL(query: "løg", near: origin, radius: 3000)
        #expect(url.absoluteString.hasPrefix("https://squid-api.tjek.com/v2/offers/search?"))
        #expect(queryItem(url, "query") == "løg")
        #expect(queryItem(url, "r_lat") == "55.6867")
        #expect(queryItem(url, "r_radius") == "3000")
    }
}
