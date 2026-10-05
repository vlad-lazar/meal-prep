import Foundation

public struct BasketPricer: Sendable {
    public let catalog: Catalog
    public let matcher: OfferMatcher

    public init(catalog: Catalog, matcher: OfferMatcher = OfferMatcher()) {
        self.catalog = catalog
        self.matcher = matcher
    }

    /// Prices `recipe` for `portions` at `chain` (nil = typical prices only), matching `offers` directly.
    public func price(_ recipe: Recipe, portions: Int, chain: Chain?, store: Store? = nil,
                      offers: [Offer], pantryOverrides: Set<String> = []) -> Basket {
        let chainOffers = chain.map { chain in offers.filter { $0.dealerId == chain.dealerId } } ?? []
        return price(recipe, portions: portions, chain: chain, store: store, pantryOverrides: pantryOverrides) {
            matcher.matchingOffers(for: $0, in: chainOffers)
        }
    }

    /// Same as above but with offers pre-matched in an `OfferIndex` — a lookup per ingredient.
    public func price(_ recipe: Recipe, portions: Int, chain: Chain?, store: Store? = nil,
                      index: OfferIndex, pantryOverrides: Set<String> = []) -> Basket {
        price(recipe, portions: portions, chain: chain, store: store, pantryOverrides: pantryOverrides) { ingredient in
            chain.map { index.offers(for: ingredient.id, chain: $0) } ?? []
        }
    }

    private func price(_ recipe: Recipe, portions: Int, chain: Chain?, store: Store?, pantryOverrides: Set<String>,
                       candidateOffers: (Ingredient) -> [Offer]) -> Basket {
        let scale = Double(portions) / Double(max(1, recipe.basePortions))
        let lines = recipe.ingredients.compactMap { item -> PricedLine? in
            guard let ingredient = catalog.ingredient(item.ingredientId) else { return nil }
            let needed = item.amount * scale
            let pack = ingredient.typicalPack
            // Each matching offer and the typical pack compete on what you pay at the till for the amount
            // needed — a cheap-per-kg bulk pack only wins when you'd actually need that much.
            let options = candidateOffers(ingredient).compactMap {
                makeLine(ingredient, needed: needed, unit: item.unit, packAmount: $0.purchaseAmount,
                         packUnit: $0.packUnit, packPrice: $0.price, source: .offer($0))
            } + [makeLine(ingredient, needed: needed, unit: item.unit, packAmount: pack.amount,
                          packUnit: pack.unit, packPrice: pack.priceDKK, source: .typical)].compactMap { $0 }
            if let cheapest = options.min(by: { a, b in
                abs(a.lineTotal - b.lineTotal) > 0.005 ? a.lineTotal < b.lineTotal : a.usedCost < b.usedCost
            }) {
                return cheapest
            }
            return PricedLine(ingredient: ingredient, neededAmount: needed, neededUnit: item.unit, packsToBuy: 1,
                              packAmount: pack.amount, packUnit: pack.unit, packPrice: pack.priceDKK,
                              usedCost: pack.priceDKK, source: .typical)
        }
        return Basket(recipeId: recipe.id, portions: portions, chain: chain, store: store, lines: lines,
                      pantryOverrides: pantryOverrides)
    }

    private func makeLine(_ ingredient: Ingredient, needed: Double, unit: MeasureUnit, packAmount: Double,
                          packUnit: MeasureUnit, packPrice: Double, source: PriceSource) -> PricedLine? {
        guard packAmount > 0,
              let neededInPackUnit = ingredient.converter.convert(needed, from: unit, to: packUnit) else { return nil }
        let packs = max(1, Int((neededInPackUnit / packAmount - 1e-9).rounded(.up)))
        return PricedLine(ingredient: ingredient, neededAmount: needed, neededUnit: unit, packsToBuy: packs,
                          packAmount: packAmount, packUnit: packUnit, packPrice: packPrice,
                          usedCost: neededInPackUnit / packAmount * packPrice, source: source)
    }
}
