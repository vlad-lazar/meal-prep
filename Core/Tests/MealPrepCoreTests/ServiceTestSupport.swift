import Foundation
@testable import MealPrepCore

actor FakeHTTP: HTTPClient {
    private let handler: @Sendable (URL) throws -> Data
    private(set) var requests: [URL] = []

    init(_ handler: @escaping @Sendable (URL) throws -> Data) {
        self.handler = handler
    }

    func get(_ url: URL) async throws -> Data {
        requests.append(url)
        return try handler(url)
    }
}

final class TestClock: @unchecked Sendable {
    var now: Date
    init(_ now: Date) { self.now = now }
}

func queryItem(_ url: URL, _ name: String) -> String? {
    URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
}

func tjekOffersJSON(_ offers: [(id: String, heading: String, dealer: String, price: Double, grams: Double)]) -> Data {
    let items = offers.map { offer in
        """
        {"id":"\(offer.id)","heading":"\(offer.heading)","dealer_id":"\(offer.dealer)","dealer":{"name":"X"},
         "pricing":{"price":\(offer.price)},
         "quantity":{"unit":{"symbol":"g"},"size":{"from":\(offer.grams),"to":\(offer.grams)}},
         "run_till":"2099-01-01T00:00:00+0000"}
        """
    }
    return Data("[\(items.joined(separator: ","))]".utf8)
}

func tempCacheDirectory() -> URL {
    FileManager.default.temporaryDirectory.appending(path: "offer-cache-\(UUID().uuidString)")
}
