import Foundation

public struct TjekClient: Sendable {
    let http: any HTTPClient
    let baseURL: URL

    public init(http: any HTTPClient = URLSessionHTTPClient(),
                baseURL: URL = URL(string: "https://squid-api.tjek.com/v2")!) {
        self.http = http
        self.baseURL = baseURL
    }

    public func stores(near origin: Coordinate, radius: Int) async throws -> [Store] {
        try Tjek.parseStores(try await http.get(storesURL(near: origin, radius: radius)), origin: origin)
    }

    public func searchOffers(_ query: String, near origin: Coordinate, radius: Int) async throws -> [Offer] {
        try Tjek.parseOffers(try await http.get(offersURL(query: query, near: origin, radius: radius)))
    }

    func storesURL(near origin: Coordinate, radius: Int) -> URL {
        url("stores", [
            URLQueryItem(name: "r_lat", value: String(origin.latitude)),
            URLQueryItem(name: "r_lng", value: String(origin.longitude)),
            URLQueryItem(name: "r_radius", value: String(radius)),
            URLQueryItem(name: "limit", value: "100"),
            URLQueryItem(name: "dealer_ids", value: Chain.allDealerIds.joined(separator: ",")),
        ])
    }

    func offersURL(query: String, near origin: Coordinate, radius: Int) -> URL {
        url("offers/search", [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "r_lat", value: String(origin.latitude)),
            URLQueryItem(name: "r_lng", value: String(origin.longitude)),
            URLQueryItem(name: "r_radius", value: String(radius)),
            URLQueryItem(name: "limit", value: "50"),
        ])
    }

    private func url(_ path: String, _ items: [URLQueryItem]) -> URL {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)!
        components.queryItems = items
        return components.url!
    }
}
