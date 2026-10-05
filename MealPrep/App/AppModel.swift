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
    /// Best offer per chain and ingredient, rebuilt off the main thread whenever offers change.
    var offerIndex = OfferIndex.empty
    var quotes: [String: MealQuote] = [:]
    var isLoadingOffers = false
    var hasLoadedOffers = false
    var activePrep: ActivePrep? {
        didSet { try? activePrepStore.save(activePrep) }
    }
    /// Pantry ingredient ids the user usually does NOT have at home; seeds new baskets.
    var pantryOverrides: Set<String> {
        didSet {
            defaults.set(Array(pantryOverrides), forKey: Keys.pantryOverrides)
            requote()
        }
    }
    /// Cook-mode state lives here (not in the cover) so closing cook mode keeps timers and the step.
    let cookTimers = CookTimers()
    var cookStep = 0
    private var refreshGeneration = 0
    private var lastRefresh: Date?
    private var lastRefreshOrigin: Coordinate?

    private enum Keys {
        static let postcode = "fallbackPostcode"
        static let latitude = "fallbackLatitude"
        static let longitude = "fallbackLongitude"
        static let label = "fallbackLabel"
        static let pantryOverrides = "pantryOverrides"
        /// "postcode" when the user chose an area by hand; GPS otherwise.
        static let locationMode = "locationMode"
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
            if defaults.string(forKey: Keys.locationMode) == "postcode", let saved = savedFallback() {
                locationState = .located(saved.coordinate, label: saved.label)
            } else if location.isAuthorized {
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
            defaults.set("gps", forKey: Keys.locationMode)
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
        defaults.set("postcode", forKey: Keys.locationMode)
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

    /// Loads stores and offers for the current location. A newer call (e.g. after picking a postcode
    /// mid-load) supersedes an older one: only the latest generation writes its results.
    func refreshNearby() async {
        guard let origin = coordinate else { return }
        refreshGeneration += 1
        let generation = refreshGeneration
        isLoadingOffers = true
        let search = try? await storeService.nearbyStores(near: origin)
        let radius = search?.radius ?? StoreService.radii[StoreService.radii.count - 1]
        let result = await offerService.offers(for: catalog.ingredientList, near: origin, radius: radius)
        guard generation == refreshGeneration else { return }
        // A failed store lookup keeps the stores we already had for this location.
        let newStores = search?.stores ?? (origin == lastRefreshOrigin ? stores : [])
        let chains = newStores.isEmpty ? Set(result.offers.compactMap(\.chain)) : Set(newStores.map(\.chain))
        let (catalog, quoter, pantry) = (catalog, quoter, pantryOverrides)
        let (index, newQuotes) = await Task.detached(priority: .userInitiated) {
            let index = OfferIndex(offers: result.offers, ingredients: catalog.ingredientList)
            return (index, quoter.quotes(for: catalog.recipes, chains: chains, index: index, pantryOverrides: pantry))
        }.value
        guard generation == refreshGeneration else { return }
        stores = newStores
        offers = result
        offerIndex = index
        lastRefresh = .now
        lastRefreshOrigin = origin
        isLoadingOffers = false
        hasLoadedOffers = true
        withAnimation(.snappy) { quotes = newQuotes }
    }

    /// On returning to the app: reload when offers are over 12 h old or some have expired.
    func refreshIfStale() async {
        guard hasLoadedOffers, !isLoadingOffers, let lastRefresh else { return }
        let expired = offers.offers.contains { $0.validUntil < .now }
        if expired || Date.now.timeIntervalSince(lastRefresh) > 12 * 3600 {
            await refreshNearby()
        }
    }

    private func requote() {
        let (catalog, quoter, index, chains, pantry) = (catalog, quoter, offerIndex, pricingChains, pantryOverrides)
        Task {
            let newQuotes = await Task.detached(priority: .userInitiated) {
                quoter.quotes(for: catalog.recipes, chains: chains, index: index, pantryOverrides: pantry)
            }.value
            withAnimation(.snappy) { quotes = newQuotes }
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
                pricer.price(recipe, portions: portions, chain: $0.chain, store: $0, index: offerIndex,
                             pantryOverrides: pantryOverrides)
            }
        } else if !pricingChains.isEmpty {
            baskets = pricingChains.map {
                pricer.price(recipe, portions: portions, chain: $0, index: offerIndex, pantryOverrides: pantryOverrides)
            }
        } else {
            baskets = [pricer.price(recipe, portions: portions, chain: nil, index: .empty, pantryOverrides: pantryOverrides)]
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
        resetCooking()
        activePrep = ActivePrep(basket: basket)
        selectedTab = .prep
    }

    func discardPrep() {
        resetCooking()
        activePrep = nil
    }

    private func resetCooking() {
        cookTimers.cancelAll()
        cookStep = 0
    }

    func toggleChecked(_ id: String) {
        activePrep?.toggle(id)
    }

    func setHaveAtHome(_ id: String, _ haveAtHome: Bool) {
        activePrep?.setHaveAtHome(id, haveAtHome)
        if haveAtHome { pantryOverrides.remove(id) } else { pantryOverrides.insert(id) }
    }

    func finishPrep() {
        resetCooking()
        activePrep = nil
        selectedTab = .history
    }
}
