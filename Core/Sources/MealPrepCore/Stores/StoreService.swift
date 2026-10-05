import Foundation

public struct StoreSearchResult: Sendable, Equatable {
    public let stores: [Store]
    public let radius: Int

    public init(stores: [Store], radius: Int) {
        self.stores = stores
        self.radius = radius
    }
}

public struct StoreService: Sendable {
    public static let radii = [3000, 10000]
    let client: TjekClient

    public init(client: TjekClient) {
        self.client = client
    }

    /// Nearest store of each grocery chain, closest first; widens the radius when nothing is found.
    public func nearbyStores(near origin: Coordinate) async throws -> StoreSearchResult {
        for radius in Self.radii {
            let stores = Self.nearestPerChain(try await client.stores(near: origin, radius: radius))
            if !stores.isEmpty { return StoreSearchResult(stores: stores, radius: radius) }
        }
        return StoreSearchResult(stores: [], radius: Self.radii[Self.radii.count - 1])
    }

    static func nearestPerChain(_ stores: [Store]) -> [Store] {
        Dictionary(grouping: stores, by: \.chain)
            .compactMap { $0.value.min { $0.distanceMeters < $1.distanceMeters } }
            .sorted { $0.distanceMeters < $1.distanceMeters }
    }
}
