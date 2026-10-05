import Foundation

public enum Freshness: Sendable, Equatable {
    /// Fetched now or from a cache entry younger than the TTL.
    case live
    /// Network failed; showing offers fetched at this time.
    case cached(Date)
    /// Network failed and nothing cached — prices are estimates.
    case unavailable
}

public struct OfferResult: Sendable {
    public let offers: [Offer]
    public let freshness: Freshness

    public init(offers: [Offer], freshness: Freshness) {
        self.offers = offers
        self.freshness = freshness
    }
}

public struct OfferService: Sendable {
    let client: TjekClient
    let cache: OfferCache
    let maxConcurrent: Int
    /// After this many failures with no success at all, the network is treated as down and the remaining
    /// terms are served from cache only (a captive portal would otherwise cost terms × timeout).
    let giveUpAfterFailures = 6

    public init(client: TjekClient, cache: OfferCache, maxConcurrent: Int = 4) {
        self.client = client
        self.cache = cache
        self.maxConcurrent = maxConcurrent
    }

    enum TermOutcome: Sendable {
        case live([Offer])
        case cached([Offer], Date)
        case failed
    }

    /// Grocery-chain offers for every search term of the non-pantry `ingredients`, deduped by id.
    public func offers(for ingredients: [Ingredient], near origin: Coordinate, radius: Int) async -> OfferResult {
        let terms = Array(Set(ingredients.filter { !$0.isPantry }.flatMap(\.searchTerms))).sorted()
        var outcomes: [TermOutcome] = []
        await withTaskGroup(of: TermOutcome.self) { group in
            var pending = terms.makeIterator()
            var failures = 0, successes = 0
            for _ in 0..<maxConcurrent {
                guard let term = pending.next() else { break }
                group.addTask { await fetch(term, near: origin, radius: radius) }
            }
            while let outcome = await group.next() {
                outcomes.append(outcome)
                if case .live = outcome { successes += 1 } else { failures += 1 }
                if let term = pending.next() {
                    let networkLooksDown = successes == 0 && failures >= giveUpAfterFailures
                    group.addTask { await fetch(term, near: origin, radius: radius, cacheOnly: networkLooksDown) }
                }
            }
        }
        return merge(outcomes)
    }

    func fetch(_ term: String, near origin: Coordinate, radius: Int, cacheOnly: Bool = false) async -> TermOutcome {
        let key = OfferCache.key(term: term, near: origin)
        let cached = await cache.entry(for: key)
        if let cached, await cache.isFresh(cached) { return .live(cached.offers) }
        if cacheOnly {
            if let cached { return .cached(cached.offers, cached.fetchedAt) }
            return .failed
        }
        do {
            let offers = try await client.searchOffers(term, near: origin, radius: radius)
                .filter { Chain(dealerId: $0.dealerId) != nil }
            await cache.save(offers, for: key)
            return .live(offers)
        } catch {
            if let cached { return .cached(cached.offers, cached.fetchedAt) }
            return .failed
        }
    }

    func merge(_ outcomes: [TermOutcome]) -> OfferResult {
        var byId: [String: Offer] = [:]
        var oldestCache: Date?
        var failures = 0
        for outcome in outcomes {
            switch outcome {
            case .live(let offers):
                offers.forEach { byId[$0.id] = $0 }
            case .cached(let offers, let date):
                offers.forEach { byId[$0.id] = $0 }
                oldestCache = min(oldestCache ?? date, date)
            case .failed:
                failures += 1
            }
        }
        let freshness: Freshness
        if !outcomes.isEmpty && failures == outcomes.count {
            freshness = .unavailable
        } else if let oldestCache {
            freshness = .cached(oldestCache)
        } else {
            freshness = .live
        }
        return OfferResult(offers: byId.values.sorted { $0.id < $1.id }, freshness: freshness)
    }
}
