import Foundation

/// Best matching offer per (chain, ingredient), computed once after offers load so pricing is a lookup
/// instead of re-running text matching over every offer.
public struct OfferIndex: Sendable, Equatable {
    private let bestByDealer: [String: [String: Offer]]

    public static let empty = OfferIndex(bestByDealer: [:])

    private init(bestByDealer: [String: [String: Offer]]) {
        self.bestByDealer = bestByDealer
    }

    public init(offers: [Offer], ingredients: [Ingredient], matcher: OfferMatcher = OfferMatcher()) {
        var result: [String: [String: Offer]] = [:]
        for (dealerId, chainOffers) in Dictionary(grouping: offers, by: \.dealerId) {
            var best: [String: Offer] = [:]
            for ingredient in ingredients {
                if let offer = matcher.bestOffer(for: ingredient, in: chainOffers) {
                    best[ingredient.id] = offer
                }
            }
            if !best.isEmpty { result[dealerId] = best }
        }
        bestByDealer = result
    }

    public func best(for ingredientId: String, chain: Chain) -> Offer? {
        bestByDealer[chain.dealerId]?[ingredientId]
    }

    /// Chains with at least one matched offer, sorted by raw value.
    public var chains: [Chain] {
        bestByDealer.keys.compactMap(Chain.init(dealerId:)).sorted { $0.rawValue < $1.rawValue }
    }
}
