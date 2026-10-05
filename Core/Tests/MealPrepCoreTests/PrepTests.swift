import Foundation
import Testing
@testable import MealPrepCore

struct ActivePrepTests {
    func makePrep() -> ActivePrep {
        let basket = BasketPricer(catalog: Fixtures.catalog).price(Fixtures.curry, portions: 4, chain: nil, offers: [])
        return ActivePrep(basket: basket, startedAt: Date(timeIntervalSince1970: 0))
    }

    @Test func togglingTracksProgress() {
        var prep = makePrep()
        #expect(prep.shoppingLines.map(\.id) == ["chicken-breast", "rice", "onion"])
        #expect(prep.remainingCount == 3)
        prep.toggle("chicken-breast")
        #expect(prep.remainingCount == 2)
        #expect(approx(prep.progress, 1.0 / 3.0))
        prep.toggle("chicken-breast")
        #expect(prep.remainingCount == 3)
    }

    @Test func pantryItemNotAtHomeJoinsTheList() {
        var prep = makePrep()
        prep.setHaveAtHome("rapeseed-oil", false)
        #expect(prep.shoppingLines.count == 4)
        prep.toggle("rapeseed-oil")
        prep.setHaveAtHome("rapeseed-oil", true)
        #expect(prep.shoppingLines.count == 3)
        #expect(!prep.checked.contains("rapeseed-oil"))
    }

    @Test func fileStoreRoundTripAndDelete() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "prep-\(UUID().uuidString)/active.json")
        let store = JSONFileStore<ActivePrep>(url: url)
        #expect(store.load() == nil)
        var prep = makePrep()
        prep.toggle("rice")
        try store.save(prep)
        #expect(store.load() == prep)
        try store.save(nil)
        #expect(store.load() == nil)
    }
}

struct CookTimerTests {
    let t0 = Date(timeIntervalSince1970: 1000)

    @Test func runsPausesAndResumes() {
        var timer = CookTimer(total: 300)
        #expect(!timer.isRunning)
        #expect(timer.remaining(at: t0) == 300)
        #expect(timer.start(at: t0) == 300)
        #expect(timer.remaining(at: t0 + 30) == 270)
        timer.pause(at: t0 + 30)
        #expect(!timer.isRunning)
        #expect(timer.remaining(at: t0 + 100) == 270)
        #expect(timer.start(at: t0 + 100) == 270)
        #expect(timer.isFinished(at: t0 + 370))
        #expect(timer.remaining(at: t0 + 400) == 0)
    }

    @Test func restartsAfterFinishing() {
        var timer = CookTimer(total: 60)
        timer.start(at: t0)
        #expect(timer.start(at: t0 + 120) == 60)
        #expect(timer.remaining(at: t0 + 150) == 30)
        timer.reset()
        #expect(timer.remaining(at: t0 + 150) == 60)
    }

    @Test func startWhileRunningIsNoOp() {
        var timer = CookTimer(total: 60)
        timer.start(at: t0)
        #expect(timer.start(at: t0 + 10) == 50)
        #expect(timer.remaining(at: t0 + 10) == 50)
    }
}

struct SpendStatsTests {
    @Test func sumsOnlyTheReferenceMonth() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        func date(_ s: String) -> Date { ISO8601DateFormatter().date(from: s)! }
        let entries = [
            (date: date("2026-09-30T23:00:00Z"), amount: 100.0),
            (date: date("2026-10-01T08:00:00Z"), amount: 120.0),
            (date: date("2026-10-31T20:00:00Z"), amount: 80.0),
        ]
        #expect(SpendStats.total(inMonthOf: date("2026-10-05T12:00:00Z"), entries: entries, calendar: calendar) == 200)
    }
}
