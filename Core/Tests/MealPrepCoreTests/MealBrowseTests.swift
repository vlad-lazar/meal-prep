import Foundation
import Testing
@testable import MealPrepCore

func makeRecipe(_ id: String, _ name: String, cuisine: String = "Danish", minutes: Int = 30,
                difficulty: Difficulty = .easy) -> Recipe {
    Recipe(id: id, name: name, cuisine: cuisine, emoji: "🍲", gradient: ["FF0000", "00FF00"], minutes: minutes,
           difficulty: difficulty, basePortions: 4, ingredients: [], steps: [], storageTip: "")
}

struct MealQuoterTests {
    let quoter = MealQuoter(pricer: BasketPricer(catalog: Fixtures.catalog,
                                                 matcher: OfferMatcher(now: Date(timeIntervalSince1970: 1_790_000_000))))

    @Test func typicalQuoteWithoutChains() {
        let quote = quoter.quote(Fixtures.curry, chains: [], offers: [])
        #expect(quote.chain == nil)
        #expect(!quote.hasOffer)
        #expect(approx(quote.costPerPortion, (54 + 7.2 + 2.4) / 4))
    }

    @Test func picksCheapestChain() {
        let netto = makeOffer("n1", "Dansk kyllingebrystfilet", price: 60, amount: 1000, dealer: .netto)
        let quote = quoter.quote(Fixtures.curry, chains: [.netto, .lidl], offers: [netto])
        #expect(quote.chain == .netto)
        #expect(quote.hasOffer)
        #expect(approx(quote.costPerPortion, (36 + 7.2 + 2.4) / 4))
    }

    @Test func quotesForAllRecipes() {
        let quotes = quoter.quotes(for: [Fixtures.curry], chains: [], offers: [])
        #expect(quotes.keys.sorted() == ["curry"])
    }
}

struct MealFilterTests {
    let recipes = [
        makeRecipe("chili", "Chili con carne", cuisine: "Mexican", minutes: 60, difficulty: .easy),
        makeRecipe("creme", "Crème fraîche pasta", cuisine: "Italian", minutes: 20, difficulty: .medium),
        makeRecipe("lasagne", "Beef lasagne", cuisine: "Italian", minutes: 90, difficulty: .hard),
    ]
    let quotes: [String: MealQuote] = [
        "chili": MealQuote(recipeId: "chili", costPerPortion: 22, chain: .netto, hasOffer: true),
        "creme": MealQuote(recipeId: "creme", costPerPortion: 15, chain: nil, hasOffer: false),
        "lasagne": MealQuote(recipeId: "lasagne", costPerPortion: 35, chain: .lidl, hasOffer: true),
    ]

    func ids(_ filter: MealFilter) -> [String] { filter.apply(recipes, quotes: quotes).map(\.id) }

    @Test func emptyFilterKeepsAll() {
        #expect(ids(MealFilter()) == ["chili", "creme", "lasagne"])
        #expect(!MealFilter().isActive)
    }

    @Test func queryIsCaseAndDiacriticInsensitive() {
        var filter = MealFilter()
        filter.query = "CHILI"
        #expect(ids(filter) == ["chili"])
        filter.query = "creme"
        #expect(ids(filter) == ["creme"])
        filter.query = "italian"
        #expect(ids(filter) == ["creme", "lasagne"])
        #expect(filter.isActive)
    }

    @Test func costTimeDifficultyCuisine() {
        var filter = MealFilter()
        filter.maxCostPerPortion = 25
        #expect(ids(filter) == ["chili", "creme"])
        filter = MealFilter()
        filter.maxMinutes = 60
        #expect(ids(filter) == ["chili", "creme"])
        filter = MealFilter()
        filter.difficulties = [.medium, .hard]
        #expect(ids(filter) == ["creme", "lasagne"])
        filter = MealFilter()
        filter.cuisines = ["Mexican"]
        #expect(ids(filter) == ["chili"])
    }

    @Test func cheapThisWeekOnlyOffersSortedByCost() {
        #expect(MealFilter.cheapThisWeek(recipes, quotes: quotes).map(\.id) == ["chili", "lasagne"])
        #expect(MealFilter.cheapThisWeek(recipes, quotes: quotes, limit: 1).map(\.id) == ["chili"])
    }
}
