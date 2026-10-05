import Foundation
import MealPrepCore

// Usage: swift run mealprep-cli [lat] [lng]   (defaults to Nørrebro, Copenhagen)
// Prints nearby stores, the best matching offer per chain for each ingredient (✓), offers that
// mention a search term but were rejected (✗), and each recipe's typical vs. live kr/portion.

func fmt(_ value: Double) -> String { String(format: "%.2f", value) }

let numbers = CommandLine.arguments.dropFirst().compactMap(Double.init)
let origin = numbers.count == 2
    ? Coordinate(latitude: numbers[0], longitude: numbers[1])
    : Coordinate(latitude: 55.6867, longitude: 12.5530)

let catalog = try Catalog.bundled()
let client = TjekClient()
let nearby = try await StoreService(client: client).nearbyStores(near: origin)
print("== Stores within \(nearby.radius) m")
for store in nearby.stores { print("  \(Int(store.distanceMeters)) m  \(store.name)") }

let cache = OfferCache(directory: FileManager.default.temporaryDirectory.appending(path: "mealprep-cli-cache"))
let result = await OfferService(client: client, cache: cache)
    .offers(for: catalog.ingredientList, near: origin, radius: nearby.radius)
print("== \(result.offers.count) grocery offers (\(result.freshness))")

let matcher = OfferMatcher()
let chains = Set(nearby.stores.map(\.chain))
for ingredient in catalog.ingredientList where !ingredient.isPantry {
    let typical = ingredient.typicalUnitPrice
    print("\n\(ingredient.id)  typical \(fmt(typical)) kr/\(ingredient.typicalPack.unit.rawValue)")
    for chain in chains.sorted(by: { $0.rawValue < $1.rawValue }) {
        let chainOffers = result.offers.filter { $0.dealerId == chain.dealerId }
        if let best = matcher.bestOffer(for: ingredient, in: chainOffers),
           let unitPrice = matcher.unitPrice(of: best, for: ingredient) {
            print("  ✓ \(chain.displayName): \(best.heading) — \(fmt(best.price)) kr (\(fmt(unitPrice / typical))× typical)")
        }
    }
    let rejected = result.offers.filter { offer in
        ingredient.searchTerms.contains { offer.heading.lowercased().contains($0) } && !matcher.matches(offer, ingredient)
    }
    for offer in rejected.prefix(3) { print("  ✗ \(offer.dealerName): \(offer.heading)") }
}

let quoter = MealQuoter(pricer: BasketPricer(catalog: catalog))
print("\n== Recipes (kr/portion: typical → best nearby)")
for recipe in catalog.recipes {
    let typical = quoter.quote(recipe, chains: [], offers: [])
    let live = quoter.quote(recipe, chains: chains, offers: result.offers)
    print("  \(recipe.emoji) \(recipe.name): \(fmt(typical.costPerPortion)) → \(fmt(live.costPerPortion)) at \(live.chain?.displayName ?? "-")")
}
