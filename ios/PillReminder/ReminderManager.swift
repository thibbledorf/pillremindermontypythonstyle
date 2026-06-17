import Foundation
import UserNotifications

@MainActor
final class ReminderManager: ObservableObject {
    static let pillTimes: [(hour: Int, minute: Int)] = [
        (7, 0), (13, 0), (17, 0), (21, 0),
    ]

    /// iOS caps an app at 64 pending local notifications, so we keep a
    /// rolling window of the next N days rather than scheduling forever.
    private static let scheduleDays = 14
    private static let categoryID = "PILL_REMINDER"
    private static let ackActionID = "ACK_ACTION"

    @Published var isReminderFlowActive = false
    @Published var lastStatusMessage = "Ready."
    @Published var hasAPIKey = KeychainHelper.load()?.isEmpty == false

    private let speech = SpeechSynthesizerService()
    private let listener = VoiceAckListener()
    private let newsWeather = NewsWeatherService()

    // MARK: - Setup

    func registerNotificationCategory() {
        let ackAction = UNNotificationAction(
            identifier: Self.ackActionID,
            title: "I Took My Pills ✅",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [ackAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestPermissions() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Tops off the pending-notification queue and, in the background, asks
    /// Claude for a couple of fresh phrases so the pool keeps growing.
    func refreshSchedule() async {
        await topOffNotifications()
        // 1-in-3 chance per app open: mint a new AI phrase so the pool grows
        // without hammering the API every single launch.
        if hasAPIKey, Double.random(in: 0..<1) < 0.33 {
            if let phrase = await ClaudeService.generatePhrase() {
                PhraseCache.append(phrase)
                lastStatusMessage = "Learned a new reminder phrase."
            }
        }
    }

    private func topOffNotifications() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        if pending.count >= Self.pillTimes.count * Self.scheduleDays {
            return
        }

        center.removeAllPendingNotificationRequests()
        let pool = PhraseCache.combinedPool()
        let calendar = Calendar.current

        for dayOffset in 0..<Self.scheduleDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            for time in Self.pillTimes {
                var components = calendar.dateComponents([.year, .month, .day], from: day)
                components.hour = time.hour
                components.minute = time.minute
                guard let fireDate = calendar.date(from: components), fireDate > Date() else { continue }

                let content = UNMutableNotificationContent()
                content.title = "Pill O'Clock!"
                content.body = pool.randomElement() ?? Phrases.reminders[0]
                content.sound = .default
                content.categoryIdentifier = Self.categoryID
                if #available(iOS 15.0, *) {
                    content.interruptionLevel = .timeSensitive
                }

                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "pill-\(fireDate.timeIntervalSince1970)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    // MARK: - Acknowledgment flow

    /// Runs the full speak → listen → acknowledge → news/weather sequence.
    /// Call this when the app opens via a notification tap, the "I Took My
    /// Pills" action, or a manual "Trigger now" button.
    func runReminderFlow(promptText: String? = nil) async {
        isReminderFlowActive = true
        defer { isReminderFlowActive = false }

        let phrase = promptText ?? PhraseCache.combinedPool().randomElement() ?? Phrases.reminders[0]
        lastStatusMessage = "Speaking reminder..."
        await speech.speak(phrase)
        await speech.speak("Say YES, or tap Acknowledge, to confirm you have taken your pills.")

        lastStatusMessage = "Listening for acknowledgment..."
        let heard = await listener.listen(timeout: 20)

        if heard {
            await acknowledge()
        } else {
            lastStatusMessage = "No acknowledgment heard. Tap Acknowledge when ready."
        }
    }

    func acknowledge() async {
        lastStatusMessage = "Acknowledged — fetching news and weather..."
        await speech.speak(Phrases.acknowledgments.randomElement() ?? Phrases.acknowledgments[0])

        let weather = await newsWeather.fetchWeatherText()
        await speech.speak("First, the weather! \(weather)")

        let headlines = await newsWeather.fetchHeadlines()
        await speech.speak("And now, the top headlines from Fox News!")
        for (index, headline) in headlines.enumerated() {
            await speech.speak("Headline \(index + 1): \(headline)")
        }

        await speech.speak(
            "And that concludes today's briefing, brave knight. Always look on the bright side of life! We shall bother you again at the next appointed hour. Farewell!"
        )
        lastStatusMessage = "Done. See you at the next pill time!"
    }

    func saveAPIKey(_ key: String) {
        KeychainHelper.save(key)
        hasAPIKey = !key.isEmpty
    }
}
