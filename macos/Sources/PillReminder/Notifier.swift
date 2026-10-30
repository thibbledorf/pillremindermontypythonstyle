import Foundation
import UserNotifications

/// Notification Center banners (visible on the lock screen) with an "I took them" action.
/// Best effort: an ad-hoc-signed app can be refused notification permission, so the
/// on-screen panel and speech never depend on this.
enum Notifier {
    private static let reminderID = "pill-reminder-active"
    private static let delegate = Delegate()

    private final class Delegate: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound, .list])
        }

        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                    withCompletionHandler completionHandler: @escaping () -> Void) {
            if response.actionIdentifier == "TAKEN" {
                ReminderEngine.shared.acknowledge(source: "notification")
            } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                AckPanel.show()
            }
            completionHandler()
        }
    }

    static func setup() {
        let c = UNUserNotificationCenter.current()
        c.delegate = delegate
        let taken = UNNotificationAction(identifier: "TAKEN", title: "I took them", options: [])
        c.setNotificationCategories([UNNotificationCategory(identifier: "PILL", actions: [taken], intentIdentifiers: [])])
        c.requestAuthorization(options: [.alert, .sound]) { ok, err in
            if let err { Log.warn("Notifications unavailable: \(err.localizedDescription) (panel + speech still work)") }
            else { Log.info("Notifications authorized: \(ok)") }
        }
    }

    static func postReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Pill O'Clock!"
        content.body = "Time to take your pills, brave knight."
        content.sound = .default
        content.categoryIdentifier = "PILL"
        content.interruptionLevel = .timeSensitive
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: reminderID, content: content, trigger: nil)) { err in
            if let err { Log.warn("Notification post failed: \(err.localizedDescription)") }
        }
    }

    static func postMissed(slot: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Pill reminder NOT acknowledged"
        content.body = "No confirmation was received for the \(slot ?? "manual") dose. Check whether it was taken."
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "missed-\(slot ?? "manual")", content: content, trigger: nil))
    }

    static func clear() {
        let c = UNUserNotificationCenter.current()
        c.removeDeliveredNotifications(withIdentifiers: [reminderID])
        c.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
