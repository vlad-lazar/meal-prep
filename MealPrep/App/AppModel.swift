import SwiftUI
import MealPrepCore

@MainActor
@Observable
final class AppModel {
    enum LocationState: Equatable {
        case unknown
        case locating
        case located(Coordinate, label: String)
        case needsPostcode
    }

    let catalog: Catalog
    let pricer: BasketPricer
    let quoter: MealQuoter
    let nutrition: NutritionCalculator
    private let storeService: StoreService
    private let offerService: OfferService
    private let location = LocationService()
    private let activePrepStore: JSONFileStore<ActivePrep>
    private let defaults = UserDefaults.standard

    var selectedTab: AppTab = .meals
    var locationState: LocationState = .unknown
    var stores: [Store] = []
    var offers = OfferResult(offers: [], freshness: .live)
    var quotes: [String: MealQuote] = [:]
    var isLoadingOffers = false
    var hasLoadedOffers = false
    var activePrep: ActivePrep? {
        didSet { try? activePrepStore.save(activePrep) }
    }
    /// Pantry ingredient ids the user usually does NOT have at home; seeds new baskets.
    var pantryOverrides: Set<String> {
        didSet { defaults.set(Array(pantryOverrides), forKey: Keys.pantryOverrides) }
    }

    private enum Keys {
        static let postcode = "fallbackPostcode"
        static let latitude = "fallbackLatitude"
        static let longitude = "fallbackLongitude"
        static let label = "fallbackLabel"
        static let pantryOverrides = "pantryOverrides"
    }

    init() {
        // Build everything in locals first: `self` can't be read until all stored properties are set.
        let catalog: Catalog
        do {
            catalog = try Catalog.bundled()
        } catch {
            fatalError("Bundled catalog failed to load: \(error)")
        }
        let pricer = BasketPricer(catalog: catalog)
        let quoter = MealQuoter(pricer: pricer)
        let client = TjekClient()
        let prepStore = JSONFileStore<ActivePrep>(url: .applicationSupportDirectory.appending(path: "active-prep.json"))
        self.catalog = catalog
        self.pricer = pricer
        self.quoter = quoter
        nutrition = NutritionCalculator(catalog: catalog)
        storeService = StoreService(client: client)
        offerService = OfferService(client: client, cache: OfferCache(directory: .cachesDirectory.appending(path: "offers")))
        activePrepStore = prepStore
        pantryOverrides = Set(UserDefaults.standard.stringArray(forKey: Keys.pantryOverrides) ?? [])
        activePrep = prepStore.load()
        quotes = quoter.quotes(for: catalog.recipes, chains: [], offers: [])
        #if DEBUG
        if DebugLaunch.tab == "history" { selectedTab = .history }
        if DebugLaunch.tab == "prep" { selectedTab = .prep }
        #endif
    }

    // MARK: - Location

    var coordinate: Coordinate? {
        if case .located(let coordinate, _) = locationState { return coordinate }
        return nil
    }

    var locationLabel: String {
        switch locationState {
        case .located(_, let label): return label
        case .locating: return "Locating…"
        case .unknown, .needsPostcode: return "Set your area"
        }
    }

    /// Called once onboarding is done: resolve a location, then load stores and offers.
    func start() async {
        if coordinate == nil {
            if location.isAuthorized {
                await locate()
            } else if let saved = savedFallback() {
                locationState = .located(saved.coordinate, label: saved.label)
            } else {
                locationState = .needsPostcode
            }
        }
        await refreshNearby()
        #if DEBUG
        if let id = DebugLaunch.startPrep, activePrep == nil, let recipe = catalog.recipe(id),
           let basket = baskets(for: recipe, portions: recipe.basePortions).first {
            startPrep(with: basket)
        }
        #endif
    }

    func locate() async {
        locationState = .locating
        do {
            let coordinate = try await location.currentCoordinate()
            locationState = .located(coordinate, label: await location.label(for: coordinate))
        } catch {
            if let saved = savedFallback() {
                locationState = .located(saved.coordinate, label: saved.label)
            } else {
                locationState = .needsPostcode
            }
        }
    }

    func usePostcode(_ postcode: String) async throws {
        let (coordinate, label) = try await location.geocode(postcode: postcode)
        defaults.set(postcode, forKey: Keys.postcode)
        defaults.set(coordinate.latitude, forKey: Keys.latitude)
        defaults.set(coordinate.longitude, forKey: Keys.longitude)
        defaults.set(label, forKey: Keys.label)
        locationState = .located(coordinate, label: label)
        Task { await refreshNearby() }
    }

    private func savedFallback() -> (coordinate: Coordinate, label: String)? {
        guard defaults.object(forKey: Keys.latitude) != nil else { return nil }
        return (Coordinate(latitude: defaults.double(forKey: Keys.latitude),
                           longitude: defaults.double(forKey: Keys.longitude)),
                defaults.string(forKey: Keys.label) ?? "Your area")
    }

    // MARK: - Stores and offers

    func refreshNearby() async {
        guard let coordinate, !isLoadingOffers else { return }
        isLoadingOffers = true
        defer {
            isLoadingOffers = false
            hasLoadedOffers = true
        }
        let search = (try? await storeService.nearbyStores(near: coordinate))
            ?? StoreSearchResult(stores: [], radius: StoreService.radii[StoreService.radii.count - 1])
        let result = await offerService.offers(for: catalog.ingredientList, near: coordinate, radius: search.radius)
        stores = search.stores
        offers = result
        withAnimation(.snappy) {
            quotes = quoter.quotes(for: catalog.recipes, chains: pricingChains, offers: result.offers)
        }
    }

    /// Chains to price against: nearby stores' chains, or chains seen in offers when no store was found.
    var pricingChains: Set<Chain> {
        stores.isEmpty ? Set(offers.offers.compactMap(\.chain)) : Set(stores.map(\.chain))
    }

    /// Ranked baskets for the store comparison: one per nearby store, else per chain, else typical prices.
    func baskets(for recipe: Recipe, portions: Int) -> [Basket] {
        let baskets: [Basket]
        if !stores.isEmpty {
            baskets = stores.map {
                pricer.price(recipe, portions: portions, chain: $0.chain, store: $0, offers: offers.offers,
                             pantryOverrides: pantryOverrides)
            }
        } else if !pricingChains.isEmpty {
            baskets = pricingChains.map {
                pricer.price(recipe, portions: portions, chain: $0, offers: offers.offers, pantryOverrides: pantryOverrides)
            }
        } else {
            baskets = [pricer.price(recipe, portions: portions, chain: nil, offers: [], pantryOverrides: pantryOverrides)]
        }
        return StoreRanker.rank(baskets)
    }

    var offersBanner: String? {
        switch offers.freshness {
        case .unavailable:
            return "Offers unavailable right now — prices are estimates."
        case .cached(let date):
            return "Offline — showing offers from \(date.formatted(.relative(presentation: .named)))."
        case .live:
            return hasLoadedOffers && stores.isEmpty ? "No stores found nearby — showing chain estimates." : nil
        }
    }

    // MARK: - Prep

    func startPrep(with basket: Basket) {
        activePrep = ActivePrep(basket: basket)
        selectedTab = .prep
    }

    func toggleChecked(_ id: String) {
        activePrep?.toggle(id)
    }

    func setHaveAtHome(_ id: String, _ haveAtHome: Bool) {
        activePrep?.setHaveAtHome(id, haveAtHome)
        if haveAtHome { pantryOverrides.remove(id) } else { pantryOverrides.insert(id) }
    }

    func finishPrep() {
        activePrep = nil
        selectedTab = .history
    }
}
