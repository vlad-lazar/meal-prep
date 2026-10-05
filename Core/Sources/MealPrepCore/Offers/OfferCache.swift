import Foundation

/// Per-search-term offer cache on disk (plus an in-memory copy). Entries older than `ttl`
/// are stale but still returned by `entry(for:)` so callers can fall back to them offline.
public actor OfferCache {
    public struct Entry: Codable, Sendable {
        public let fetchedAt: Date
        public let offers: [Offer]
    }

    private let directory: URL
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private var memory: [String: Entry] = [:]

    public init(directory: URL, ttl: TimeInterval = 12 * 3600, now: @escaping @Sendable () -> Date = { .now }) {
        self.directory = directory
        self.ttl = ttl
        self.now = now
    }

    public static func key(term: String, near origin: Coordinate) -> String {
        let lat = (origin.latitude * 100).rounded() / 100
        let lng = (origin.longitude * 100).rounded() / 100
        return "\(term)|\(lat)|\(lng)"
    }

    public func entry(for key: String) -> Entry? {
        if let cached = memory[key] { return cached }
        guard let data = try? Data(contentsOf: fileURL(key)),
              let entry = try? JSONDecoder().decode(Entry.self, from: data) else { return nil }
        memory[key] = entry
        return entry
    }

    public func isFresh(_ entry: Entry) -> Bool {
        now().timeIntervalSince(entry.fetchedAt) < ttl
    }

    public func save(_ offers: [Offer], for key: String) {
        let entry = Entry(fetchedAt: now(), offers: offers)
        memory[key] = entry
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(entry) {
            try? data.write(to: fileURL(key), options: .atomic)
        }
    }

    private func fileURL(_ key: String) -> URL {
        let name = Data(key.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return directory.appending(path: "\(name).json")
    }
}
