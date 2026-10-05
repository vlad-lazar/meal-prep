import Foundation
@preconcurrency import UserNotifications

enum TimerNotifications {
    /// Schedules a local notification; asks for permission on first use. Silently does nothing if denied.
    static func schedule(id: String, after seconds: TimeInterval, title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        guard seconds > 0, (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
