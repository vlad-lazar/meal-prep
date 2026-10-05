import Foundation

/// Pausable countdown for a cooking step, driven by wall-clock dates so it survives view reloads.
public struct CookTimer: Sendable, Hashable {
    public let total: TimeInterval
    public private(set) var endDate: Date?
    public private(set) var pausedRemaining: TimeInterval?

    public init(total: TimeInterval) {
        self.total = total
    }

    public var isRunning: Bool { endDate != nil }

    public func remaining(at now: Date) -> TimeInterval {
        if let endDate { return max(0, endDate.timeIntervalSince(now)) }
        return pausedRemaining ?? total
    }

    public func isFinished(at now: Date) -> Bool { remaining(at: now) <= 0 }

    /// Starts or resumes; restarts from full when finished. Returns seconds until done.
    @discardableResult
    public mutating func start(at now: Date) -> TimeInterval {
        let current = remaining(at: now)
        if isRunning && current > 0 { return current }
        let duration = (!isRunning && current > 0) ? current : total
        endDate = now.addingTimeInterval(duration)
        pausedRemaining = nil
        return duration
    }

    public mutating func pause(at now: Date) {
        guard isRunning else { return }
        pausedRemaining = remaining(at: now)
        endDate = nil
    }

    public mutating func reset() {
        endDate = nil
        pausedRemaining = nil
    }
}
