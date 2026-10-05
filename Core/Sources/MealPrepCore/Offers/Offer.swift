import Foundation

public struct Offer: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let heading: String
    public let description: String?
    public let dealerId: String
    public let dealerName: String
    /// Price for the whole offer (`pieces` × `packAmount`).
    public let price: Double
    public let prePrice: Double?
    /// Size of one piece in `packUnit` (smallest size when Tjek gives a range).
    public let packAmount: Double
    public let packUnit: MeasureUnit
    public let pieces: Int
    public let validUntil: Date
    public let imageURL: URL?

    public init(id: String, heading: String, description: String?, dealerId: String, dealerName: String,
                price: Double, prePrice: Double?, packAmount: Double, packUnit: MeasureUnit, pieces: Int,
                validUntil: Date, imageURL: URL?) {
        self.id = id; self.heading = heading; self.description = description; self.dealerId = dealerId
        self.dealerName = dealerName; self.price = price; self.prePrice = prePrice; self.packAmount = packAmount
        self.packUnit = packUnit; self.pieces = pieces; self.validUntil = validUntil; self.imageURL = imageURL
    }

    /// Total amount bought for `price`, in `packUnit`.
    public var purchaseAmount: Double { packAmount * Double(pieces) }
    public var chain: Chain? { Chain(dealerId: dealerId) }
}
