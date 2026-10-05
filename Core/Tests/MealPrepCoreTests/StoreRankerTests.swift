import Foundation
import Testing
@testable import MealPrepCore

struct StoreRankerTests {
    func basket(_ id: String, chain: Chain, total: Double, distance: Double) -> Basket {
        let ingredient = Ingredient(id: "x-\(id)", name: "X", danishName: "X", searchTerms: ["x"], excludeTerms: [],
                                    section: .dry, isPantry: false, typicalPack: Pack(amount: 1, unit: .pcs, priceDKK: total),
                                    gramsPerPiece: nil, mlDensity: nil, nutritionId: "x")
        let line = PricedLine(ingredient: ingredient, neededAmount: 1, neededUnit: .pcs, packsToBuy: 1, packAmount: 1,
                              packUnit: .pcs, packPrice: total, usedCost: total, source: .typical)
        let store = Store(id: id, chain: chain, name: id, address: "", coordinate: .init(latitude: 0, longitude: 0),
                          distanceMeters: distance)
        return Basket(recipeId: "r", portions: 4, chain: chain, store: store, lines: [line], pantryOverrides: [])
    }

    @Test func sortsByTotalThenDistance() {
        let ranked = StoreRanker.rank([
            basket("far-cheap", chain: .lidl, total: 100, distance: 2000),
            basket("pricey", chain: .foetex, total: 140, distance: 100),
            basket("near-cheap", chain: .netto, total: 100, distance: 500),
        ])
        #expect(ranked.map(\.id) == ["near-cheap", "far-cheap", "pricey"])
    }
}
