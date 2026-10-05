import Foundation

public struct MealQuote: Sendable, Hashable {
    public let recipeId: String
    public let costPerPortion: Double
    public let chain: Chain?
    public let hasOffer: Bool

    public init(recipeId: String, costPerPortion: Double, chain: Chain?, hasOffer: Bool) {
        self.recipeId = recipeId; self.costPerPortion = costPerPortion; self.chain = chain; self.hasOffer = hasOffer
    }
}

/// Browse-screen price: cost of what one portion consumes, at the cheapest nearby chain
/// (typical prices when no chains are known).
public struct MealQuoter: Sendable {
    public let pricer: BasketPricer

    public init(pricer: BasketPricer) {
        self.pricer = pricer
    }

    public func quote(_ recipe: Recipe, chains: Set<Chain>, offers: [Offer]) -> MealQuote {
        let baskets: [Basket] = chains.isEmpty
            ? [pricer.price(recipe, portions: recipe.basePortions, chain: nil, offers: [])]
            : chains.map { pricer.price(recipe, portions: recipe.basePortions, chain: $0, offers: offers) }
        return quote(recipe, baskets: baskets)
    }

    public func quote(_ recipe: Recipe, chains: Set<Chain>, index: OfferIndex,
                      pantryOverrides: Set<String> = []) -> MealQuote {
        let baskets: [Basket] = chains.isEmpty
            ? [pricer.price(recipe, portions: recipe.basePortions, chain: nil, index: .empty,
                            pantryOverrides: pantryOverrides)]
            : chains.map {
                pricer.price(recipe, portions: recipe.basePortions, chain: $0, index: index, pantryOverrides: pantryOverrides)
            }
        return quote(recipe, baskets: baskets)
    }

    private func quote(_ recipe: Recipe, baskets: [Basket]) -> MealQuote {
        let best = baskets.min { $0.costPerPortion < $1.costPerPortion } ?? baskets[0]
        return MealQuote(recipeId: recipe.id, costPerPortion: best.costPerPortion, chain: best.chain,
                         hasOffer: baskets.contains { $0.offerCount > 0 })
    }

    public func quotes(for recipes: [Recipe], chains: Set<Chain>, offers: [Offer]) -> [String: MealQuote] {
        Dictionary(uniqueKeysWithValues: recipes.map { ($0.id, quote($0, chains: chains, offers: offers)) })
    }

    public func quotes(for recipes: [Recipe], chains: Set<Chain>, index: OfferIndex,
                       pantryOverrides: Set<String> = []) -> [String: MealQuote] {
        Dictionary(uniqueKeysWithValues: recipes.map {
            ($0.id, quote($0, chains: chains, index: index, pantryOverrides: pantryOverrides))
        })
    }
}
