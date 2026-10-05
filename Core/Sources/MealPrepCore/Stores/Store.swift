import Foundation

public struct Store: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let chain: Chain
    public let name: String
    public let address: String
    public let coordinate: Coordinate
    public let distanceMeters: Double

    public init(id: String, chain: Chain, name: String, address: String, coordinate: Coordinate, distanceMeters: Double) {
        self.id = id; self.chain = chain; self.name = name; self.address = address
        self.coordinate = coordinate; self.distanceMeters = distanceMeters
    }
}
