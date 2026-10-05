import Foundation

/// Matching offers per (chain, ingredient), cheapest per unit first, computed once after offers load so
/// pricing is a lookup instead of re-running text matching over every offer.
public struct OfferIndex: Sendable, Equatable {
    private let byDealer: [String: [String: [Offer]]]

    public static let empty = OfferIndex(byDealer: [:])

    private init(byDealer: [String: [String: [Offer]]]) {
        self.byDealer = byDealer
    }

    public init(offers: [Offer], ingredients: [Ingredient], matcher: OfferMatcher = OfferMatcher()) {
        var result: [String: [String: [Offer]]] = [:]
        for (dealerId, chainOffers) in Dictionary(grouping: offers, by: \.dealerId) {
            var matched: [String: [Offer]] = [:]
            for ingredient in ingredients {
                let offers = matcher.matchingOffers(for: ingredient, in: chainOffers)
                if !offers.isEmpty { matched[ingredient.id] = offers }
            }
            if !matched.isEmpty { result[dealerId] = matched }
        }
        byDealer = result
    }

    public func offers(for ingredientId: String, chain: Chain) -> [Offer] {
        byDealer[chain.dealerId]?[ingredientId] ?? []
    }

    public func best(for ingredientId: String, chain: Chain) -> Offer? {
        offers(for: ingredientId, chain: chain).first
    }

    /// Chains with at least one matched offer, sorted by raw value.
    public var chains: [Chain] {
        byDealer.keys.compactMap(Chain.init(dealerId:)).sorted { $0.rawValue < $1.rawValue }
    }
}
