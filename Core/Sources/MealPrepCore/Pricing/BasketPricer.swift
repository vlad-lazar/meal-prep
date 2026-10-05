import Foundation

public struct BasketPricer: Sendable {
    public let catalog: Catalog
    public let matcher: OfferMatcher

    public init(catalog: Catalog, matcher: OfferMatcher = OfferMatcher()) {
        self.catalog = catalog
        self.matcher = matcher
    }

    /// Prices `recipe` for `portions` at `chain` (nil = typical prices only).
    public func price(_ recipe: Recipe, portions: Int, chain: Chain?, store: Store? = nil,
                      offers: [Offer], pantryOverrides: Set<String> = []) -> Basket {
        let chainOffers = chain.map { chain in offers.filter { $0.dealerId == chain.dealerId } } ?? []
        let scale = Double(portions) / Double(max(1, recipe.basePortions))
        let lines = recipe.ingredients.compactMap { item -> PricedLine? in
            guard let ingredient = catalog.ingredient(item.ingredientId) else { return nil }
            let needed = item.amount * scale
            if let offer = matcher.bestOffer(for: ingredient, in: chainOffers),
               let line = makeLine(ingredient, needed: needed, unit: item.unit, packAmount: offer.purchaseAmount,
                                   packUnit: offer.packUnit, packPrice: offer.price, source: .offer(offer)) {
                return line
            }
            let pack = ingredient.typicalPack
            return makeLine(ingredient, needed: needed, unit: item.unit, packAmount: pack.amount,
                            packUnit: pack.unit, packPrice: pack.priceDKK, source: .typical)
                ?? PricedLine(ingredient: ingredient, neededAmount: needed, neededUnit: item.unit, packsToBuy: 1,
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
