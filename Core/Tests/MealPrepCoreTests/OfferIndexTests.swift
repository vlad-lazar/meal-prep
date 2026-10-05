import Foundation
import Testing
@testable import MealPrepCore

struct OfferIndexTests {
    let matcher = OfferMatcher(now: Date(timeIntervalSince1970: 1_790_000_000))
    let offers = [
        makeOffer("n1", "Dansk kyllingebrystfilet", price: 75, amount: 1000, dealer: .netto),
        makeOffer("n2", "Kyllingebrystfilet", price: 60, amount: 1000, dealer: .netto),
        makeOffer("l1", "Kyllingebrystfilet", price: 34.95, amount: 450, dealer: .lidl),
        makeOffer("l2", "Jasminris", price: 15, amount: 1000, dealer: .lidl),
        makeOffer("w1", "Kyllingebryst", price: 20, amount: 500, dealer: .netto, validUntil: Date(timeIntervalSince1970: 1)),
    ]

    @Test func picksBestOfferPerChainAndIngredient() {
        let index = OfferIndex(offers: offers, ingredients: Fixtures.catalog.ingredientList, matcher: matcher)
        #expect(index.best(for: "chicken-breast", chain: .netto)?.id == "n2")
        #expect(index.best(for: "chicken-breast", chain: .lidl)?.id == "l1")
        #expect(index.best(for: "rice", chain: .lidl)?.id == "l2")
        #expect(index.best(for: "rice", chain: .netto) == nil)
        #expect(index.best(for: "chicken-breast", chain: .foetex) == nil)
        #expect(index.chains == [.lidl, .netto])
    }

    @Test func indexedPricingMatchesDirectPricing() {
        let pricer = BasketPricer(catalog: Fixtures.catalog, matcher: matcher)
        let index = OfferIndex(offers: offers, ingredients: Fixtures.catalog.ingredientList, matcher: matcher)
        for chain in [Chain.netto, .lidl, .foetex] {
            for portions in [2, 4, 9] {
                let direct = pricer.price(Fixtures.curry, portions: portions, chain: chain, offers: offers)
                let indexed = pricer.price(Fixtures.curry, portions: portions, chain: chain, index: index)
                #expect(direct == indexed, "\(chain) × \(portions)")
            }
        }
    }

    @Test func indexedQuotesMatchDirectQuotes() {
        let quoter = MealQuoter(pricer: BasketPricer(catalog: Fixtures.catalog, matcher: matcher))
        let index = OfferIndex(offers: offers, ingredients: Fixtures.catalog.ingredientList, matcher: matcher)
        let direct = quoter.quotes(for: [Fixtures.curry], chains: [.netto, .lidl], offers: offers)
        let indexed = quoter.quotes(for: [Fixtures.curry], chains: [.netto, .lidl], index: index)
        #expect(direct == indexed)
    }

    @Test func quotesIncludePantryOverrides() {
        let quoter = MealQuoter(pricer: BasketPricer(catalog: Fixtures.catalog, matcher: matcher))
        let index = OfferIndex(offers: offers, ingredients: Fixtures.catalog.ingredientList, matcher: matcher)
        let without = quoter.quote(Fixtures.curry, chains: [.lidl], index: index)
        let with = quoter.quote(Fixtures.curry, chains: [.lidl], index: index, pantryOverrides: ["rapeseed-oil"])
        #expect(approx(with.costPerPortion - without.costPerPortion, 30.0 / 1000.0 * 25 / 4))
    }

    @Test func emptyIndex() {
        #expect(OfferIndex.empty.best(for: "rice", chain: .netto) == nil)
        #expect(OfferIndex.empty.chains.isEmpty)
    }
}
