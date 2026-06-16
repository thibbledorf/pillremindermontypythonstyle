import SwiftUI
import UserNotifications

@main
struct PillReminderApp: App {
    @StateObject private var manager = ReminderManager()
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .task {
                    notificationDelegate.manager = manager
                    manager.registerNotificationCategory()
                    await manager.requestPermissions()
                    await manager.refreshSchedule()
                }
        }
    }
}

/// Routes notification taps and the "I Took My Pills" action into the
/// reminder flow, including when the app was not already running.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    weak var manager: ReminderManager?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let phrase = response.notification.request.content.body
        Task { @MainActor in
            if response.actionIdentifier == "ACK_ACTION" {
                await manager?.acknowledge()
            } else {
                await manager?.runReminderFlow(promptText: phrase)
            }
            completionHandler()
        }
    }
}
