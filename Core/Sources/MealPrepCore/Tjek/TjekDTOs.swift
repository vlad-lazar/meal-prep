import Foundation

/// Decodes an element if possible, otherwise yields nil — one bad item never fails the array.
struct Lossy<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws { value = try? T(from: decoder) }
}

struct TjekOfferDTO: Decodable {
    struct Dealer: Decodable { let name: String }
    struct Pricing: Decodable { let price: Double?; let prePrice: Double? }
    struct Quantity: Decodable {
        struct UnitDTO: Decodable { let symbol: String }
        struct Range: Decodable { let from: Double?; let to: Double? }
        let unit: UnitDTO?
        let size: Range?
        let pieces: Range?
    }
    struct Images: Decodable { let thumb: String? }

    let id: String
    let heading: String
    let description: String?
    let dealerId: String
    let dealer: Dealer?
    let pricing: Pricing
    let quantity: Quantity?
    let runTill: String
    let images: Images?
}

struct TjekStoreDTO: Decodable {
    let id: String
    let street: String?
    let city: String?
    let zipCode: String?
    let latitude: Double
    let longitude: Double
    let dealerId: String
}
