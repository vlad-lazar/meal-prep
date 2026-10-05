import Foundation
import MealPrepCore

/// Timer state per step, held above the paged step cards so swiping away doesn't lose a running timer.
@MainActor
@Observable
final class CookTimers {
    private(set) var timers: [Int: CookTimer] = [:]

    func timer(for step: Int, total: Int) -> CookTimer {
        timers[step] ?? CookTimer(total: TimeInterval(total))
    }

    func toggle(step: Int, total: Int, label: String) {
        var timer = timer(for: step, total: total)
        let id = "step-\(step)"
        if timer.isRunning && !timer.isFinished(at: .now) {
            timer.pause(at: .now)
            TimerNotifications.cancel(id: id)
        } else {
            let seconds = timer.start(at: .now)
            Task { await TimerNotifications.schedule(id: id, after: seconds, title: "⏰ Timer done", body: label) }
        }
        timers[step] = timer
    }

    func cancelAll() {
        for step in timers.keys { TimerNotifications.cancel(id: "step-\(step)") }
        timers = [:]
    }
}
