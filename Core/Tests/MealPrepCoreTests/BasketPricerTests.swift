import Foundation
import Testing
@testable import MealPrepCore

struct BasketPricerTests {
    let pricer = BasketPricer(catalog: Fixtures.catalog, matcher: OfferMatcher(now: Date(timeIntervalSince1970: 1_790_000_000)))
    let recipe = Fixtures.curry   // base 4: 600 g chicken, 400 g rice, 2 onions, 2 tbsp oil (pantry)

    func line(_ basket: Basket, _ id: String) throws -> PricedLine {
        try #require(basket.lines.first { $0.id == id })
    }

    @Test func typicalPricingAtBasePortions() throws {
        let basket = pricer.price(recipe, portions: 4, chain: nil, offers: [])
        let chicken = try line(basket, "chicken-breast")
        #expect(chicken.packsToBuy == 2)                 // 600 g from 500 g packs
        #expect(approx(chicken.lineTotal, 90))
        #expect(approx(chicken.usedCost, 54))            // 600/500 × 45
        #expect(!chicken.isOffer)
        let onion = try line(basket, "onion")
        #expect(onion.packsToBuy == 1)                   // 2 × 150 g from a 1 kg bag
        #expect(approx(onion.usedCost, 2.4))
    }

    @Test func scalesWithPortions() throws {
        let basket = pricer.price(recipe, portions: 8, chain: nil, offers: [])
        let chicken = try line(basket, "chicken-breast")
        #expect(approx(chicken.neededAmount, 1200))
        #expect(chicken.packsToBuy == 3)
        #expect(approx(chicken.lineTotal, 135))
        #expect(approx(chicken.usedCost, 108))
    }

    @Test func portionExtremes() throws {
        let two = pricer.price(recipe, portions: 2, chain: nil, offers: [])
        #expect(try line(two, "chicken-breast").packsToBuy == 1)
        #expect(approx(try line(two, "chicken-breast").usedCost, 27))
        #expect(two.lines.allSatisfy { $0.packsToBuy >= 1 })
        let twelve = pricer.price(recipe, portions: 12, chain: nil, offers: [])
        #expect(try line(twelve, "chicken-breast").packsToBuy == 4)   // 1800 g
        #expect(try line(twelve, "rice").packsToBuy == 2)             // 1200 g from 1 kg
        #expect(approx(twelve.costPerPortion, two.costPerPortion))    // cost of what's eaten is linear
    }

    @Test func usesChainOfferWhenItMatches() throws {
        let netto = makeOffer("n1", "Dansk kyllingebrystfilet", price: 75, amount: 1000, dealer: .netto)
        let lidl = makeOffer("l1", "Kyllingebrystfilet", price: 20, amount: 450, dealer: .lidl)
        let basket = pricer.price(recipe, portions: 8, chain: .netto, offers: [netto, lidl])
        let chicken = try line(basket, "chicken-breast")
        #expect(chicken.isOffer)
        #expect(chicken.offer?.id == "n1")
        #expect(chicken.packsToBuy == 2)
        #expect(approx(chicken.lineTotal, 150))
        #expect(approx(chicken.usedCost, 90))
        #expect(basket.offerCount == 1)
        #expect(basket.estimateCount == 2)              // rice + onion; oil is pantry
    }

    @Test func pantryExcludedUnlessOverridden() throws {
        let basket = pricer.price(recipe, portions: 4, chain: nil, offers: [])
        #expect(!basket.countedLines.contains { $0.id == "rapeseed-oil" })
        #expect(approx(basket.shoppingTotal, 90 + 18 + 8))
        var overridden = basket
        overridden.pantryOverrides = ["rapeseed-oil"]
        #expect(approx(overridden.shoppingTotal, 90 + 18 + 8 + 25))
        #expect(approx(overridden.mealCost, basket.mealCost + 30.0 / 1000.0 * 25))
    }

    @Test func costPerPortion() {
        let basket = pricer.price(recipe, portions: 4, chain: nil, offers: [])
        #expect(approx(basket.mealCost, 54 + 7.2 + 2.4))
        #expect(approx(basket.costPerPortion, (54 + 7.2 + 2.4) / 4))
    }

    @Test func unconvertibleUnitFallsBackToOnePack() throws {
        let bunch = Ingredient(id: "herb", name: "Herb", danishName: "Krydderurt", searchTerms: ["urt"],
                               excludeTerms: [], section: .produce, isPantry: false,
                               typicalPack: Pack(amount: 1, unit: .pcs, priceDKK: 12), gramsPerPiece: nil,
                               mlDensity: nil, nutritionId: "herb")
        let catalog = Catalog(recipes: [], ingredients: [bunch], nutrition: [])
        let r = Recipe(id: "r", name: "R", cuisine: "X", emoji: "🌿", gradient: ["000000", "FFFFFF"], minutes: 5,
                       difficulty: .easy, basePortions: 2,
                       ingredients: [RecipeIngredient(ingredientId: "herb", amount: 20, unit: .g, note: nil)],
                       steps: [], storageTip: "")
        let basket = BasketPricer(catalog: catalog).price(r, portions: 2, chain: nil, offers: [])
        let herb = try line(basket, "herb")
        #expect(herb.packsToBuy == 1)
        #expect(approx(herb.usedCost, 12))
    }

    @Test func basketIdentity() {
        let store = Store(id: "s1", chain: .netto, name: "Netto X", address: "", coordinate: .init(latitude: 0, longitude: 0), distanceMeters: 1)
        #expect(pricer.price(recipe, portions: 4, chain: .netto, store: store, offers: []).id == "s1")
        #expect(pricer.price(recipe, portions: 4, chain: .lidl, offers: []).id == "lidl")
        #expect(pricer.price(recipe, portions: 4, chain: nil, offers: []).id == "estimate")
    }
}
