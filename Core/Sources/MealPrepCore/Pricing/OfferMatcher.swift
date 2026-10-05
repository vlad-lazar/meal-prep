import Foundation

public struct OfferMatcher: Sendable {
    public static let minPriceRatio = 0.3
    public static let maxPriceRatio = 3.0

    public var now: Date

    public init(now: Date = .now) {
        self.now = now
    }

    public func matches(_ offer: Offer, _ ingredient: Ingredient) -> Bool {
        guard offer.validUntil > now else { return false }
        let heading = Self.normalize(offer.heading)
        let fullText = heading + " " + Self.normalize(offer.description ?? "")
        guard ingredient.searchTerms.contains(where: { Self.containsWordPrefix(heading, Self.normalize($0)) }) else {
            return false
        }
        guard !ingredient.excludeTerms.contains(where: { Self.containsWordPrefix(fullText, Self.normalize($0)) }) else {
            return false
        }
        guard let price = unitPrice(of: offer, for: ingredient) else { return false }
        let ratio = price / ingredient.typicalUnitPrice
        return ratio >= Self.minPriceRatio - 1e-9 && ratio <= Self.maxPriceRatio + 1e-9
    }

    /// DKK per one `ingredient.typicalPack.unit`, or nil when the offer's unit can't be converted.
    public func unitPrice(of offer: Offer, for ingredient: Ingredient) -> Double? {
        guard let amount = ingredient.converter.convert(offer.purchaseAmount, from: offer.packUnit,
                                                        to: ingredient.typicalPack.unit),
              amount > 0 else { return nil }
        return offer.price / amount
    }

    public func bestOffer(for ingredient: Ingredient, in offers: [Offer]) -> Offer? {
        offers
            .filter { matches($0, ingredient) }
            .min { (unitPrice(of: $0, for: ingredient) ?? .infinity) < (unitPrice(of: $1, for: ingredient) ?? .infinity) }
    }

    static func normalize(_ text: String) -> String {
        text.lowercased(with: Locale(identifier: "da_DK"))
    }

    /// True when `term` occurs in `text` starting at a word boundary (start of text or after a non-letter).
    static func containsWordPrefix(_ text: String, _ term: String) -> Bool {
        guard !term.isEmpty else { return false }
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: term, range: searchRange) {
            if found.lowerBound == text.startIndex || !text[text.index(before: found.lowerBound)].isLetter {
                return true
            }
            searchRange = text.index(after: found.lowerBound)..<text.endIndex
        }
        return false
    }
}
