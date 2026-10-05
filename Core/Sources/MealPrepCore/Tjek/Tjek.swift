import Foundation

public enum Tjek {
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }

    static func unit(fromSymbol symbol: String) -> MeasureUnit? {
        switch symbol.lowercased() {
        case "g": return .g
        case "kg": return .kg
        case "ml": return .ml
        case "cl": return .cl
        case "l": return .l
        case "pcs", "stk": return .pcs
        default: return nil
        }
    }

    public static func parseOffers(_ data: Data) throws -> [Offer] {
        let formatter = makeDateFormatter()
        return try makeDecoder().decode([Lossy<TjekOfferDTO>].self, from: data)
            .compactMap { $0.value.flatMap { offer(from: $0, formatter: formatter) } }
    }

    public static func parseStores(_ data: Data, origin: Coordinate) throws -> [Store] {
        try makeDecoder().decode([Lossy<TjekStoreDTO>].self, from: data).compactMap { item in
            guard let dto = item.value, let chain = Chain(dealerId: dto.dealerId) else { return nil }
            let coordinate = Coordinate(latitude: dto.latitude, longitude: dto.longitude)
            let street = dto.street ?? ""
            let place = [dto.zipCode, dto.city].compactMap { $0 }.joined(separator: " ")
            return Store(
                id: dto.id, chain: chain,
                name: street.isEmpty ? chain.displayName : "\(chain.displayName) \(street)",
                address: [street, place].filter { !$0.isEmpty }.joined(separator: ", "),
                coordinate: coordinate,
                distanceMeters: origin.distance(to: coordinate))
        }
    }

    static func offer(from dto: TjekOfferDTO, formatter: DateFormatter) -> Offer? {
        guard let price = dto.pricing.price, price > 0,
              let symbol = dto.quantity?.unit?.symbol, let unit = unit(fromSymbol: symbol),
              let size = dto.quantity?.size?.from ?? dto.quantity?.size?.to, size > 0,
              let until = formatter.date(from: dto.runTill) else { return nil }
        return Offer(
            id: dto.id, heading: dto.heading, description: dto.description,
            dealerId: dto.dealerId, dealerName: dto.dealer?.name ?? "",
            price: price, prePrice: dto.pricing.prePrice,
            packAmount: size, packUnit: unit,
            pieces: max(1, Int(dto.quantity?.pieces?.from ?? 1)),
            validUntil: until,
            imageURL: dto.images?.thumb.flatMap(URL.init(string:)))
    }
}
