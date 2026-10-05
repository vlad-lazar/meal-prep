import Foundation
import Testing
@testable import MealPrepCore

func makeOffer(_ heading: String, price: Double, amount: Double,
               unit: MeasureUnit = .g, pieces: Int = 1, dealer: Chain = .netto,
               description: String? = nil, validUntil: Date = .distantFuture) -> Offer {
    makeOffer(UUID().uuidString, heading, price: price, amount: amount, unit: unit, pieces: pieces,
              dealer: dealer, description: description, validUntil: validUntil)
}

func makeOffer(_ id: String, _ heading: String, price: Double, amount: Double,
               unit: MeasureUnit = .g, pieces: Int = 1, dealer: Chain = .netto,
               description: String? = nil, validUntil: Date = .distantFuture) -> Offer {
    Offer(id: id, heading: heading, description: description, dealerId: dealer.dealerId,
          dealerName: dealer.displayName, price: price, prePrice: nil, packAmount: amount, packUnit: unit,
          pieces: pieces, validUntil: validUntil, imageURL: nil)
}

struct OfferMatcherTests {
    let matcher = OfferMatcher(now: Date(timeIntervalSince1970: 1_790_000_000))
    let chicken = Fixtures.chicken   // 500 g / 45 kr → 0.09 kr/g
    let onion = Fixtures.onion       // 1 kg / 8 kr

    @Test func matchesCompoundAndUppercase() {
        #expect(matcher.matches(makeOffer("MADVÆRKET Kyllingebrystfilet", price: 34.95, amount: 450), chicken))
        #expect(matcher.matches(makeOffer("GESTUS DANSK KYLLINGEBRYSTFILET", price: 159.95, amount: 2, unit: .kg), chicken))
        #expect(matcher.matches(makeOffer("DANSKE LØG", price: 8, amount: 1, unit: .kg), onion))
    }

    @Test func requiresWordStart() {
        #expect(!matcher.matches(makeOffer("Forårsløg", price: 8, amount: 1, unit: .kg), onion))
        #expect(!matcher.matches(makeOffer("Efterårsløg", price: 8, amount: 1, unit: .kg), onion))
        #expect(matcher.matches(makeOffer("Gram Slot Løg eller kartofler", price: 10, amount: 750), onion))
    }

    @Test func excludeTermsOnHeadingAndDescription() {
        #expect(!matcher.matches(makeOffer("PÅLÆGSSLAGTEREN Kyllingebryst", price: 12.95, amount: 120), chicken))
        #expect(!matcher.matches(makeOffer("Xtra! marineret kyllingebryst", price: 35, amount: 375), chicken))
        #expect(!matcher.matches(makeOffer("Kyllingebryst", price: 30, amount: 375, description: "Pålæg i skiver"), chicken))
        #expect(!matcher.matches(makeOffer("Danske rødløg", price: 8, amount: 1, unit: .kg), onion))
    }

    @Test func rejectsExpired() {
        let expired = makeOffer("Kyllingebryst", price: 40, amount: 500, validUntil: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(!matcher.matches(expired, chicken))
    }

    @Test func rejectsUnconvertibleUnit() {
        #expect(!matcher.matches(makeOffer("Nytårsbuffet med kyllingebryst", price: 189, amount: 1, unit: .pcs), chicken))
    }

    @Test func sanityBounds() {
        // 0.01 kr/g is 0.11× typical → too cheap to be real
        #expect(!matcher.matches(makeOffer("Kyllingebryst", price: 10, amount: 1000), chicken))
        // 0.40 kr/g is 4.4× typical → not the same product
        #expect(!matcher.matches(makeOffer("Kyllingebryst", price: 40, amount: 100), chicken))
        // 0.3× and 3× are inclusive edges
        #expect(matcher.matches(makeOffer("Kyllingebryst", price: 27, amount: 1000), chicken))
        #expect(matcher.matches(makeOffer("Kyllingebryst", price: 27, amount: 100), chicken))
    }

    @Test func unitPriceUsesWholePurchase() {
        let multi = makeOffer("Kyllingebryst", price: 50, amount: 400, pieces: 2)
        #expect(approx(matcher.unitPrice(of: multi, for: chicken), 50.0 / 800.0))
        let kilo = makeOffer("Kyllingebryst", price: 75, amount: 1, unit: .kg)
        #expect(approx(matcher.unitPrice(of: kilo, for: chicken), 0.075))
    }

    @Test func bestOfferIsCheapestPerUnit() {
        let lidl = makeOffer("lidl", "Kyllingebrystfilet", price: 34.95, amount: 450, dealer: .lidl)
        let netto = makeOffer("netto", "Dansk kyllingebrystfilet", price: 75, amount: 1000)
        let junk = makeOffer("junk", "Minimum pålæg", price: 12, amount: 100)
        #expect(matcher.bestOffer(for: chicken, in: [lidl, netto, junk])?.id == "netto")
        #expect(matcher.bestOffer(for: chicken, in: [junk]) == nil)
    }
}
