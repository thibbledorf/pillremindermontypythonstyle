import AppKit
import Foundation

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var activity: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance (launchd copy wins; a double-clicked second copy just exits).
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id).count > 1 {
            Log.info("Another instance is running — exiting")
            exit(0)
        }

        Log.info("=== Pill Reminder (Monty Python Edition) \(appVersion) starting, pid \(getpid()) ===")
        Log.info("Data: \(Paths.support.path)")

        // Opt out of App Nap and timer coalescing; otherwise macOS throttles a
        // background menu-bar app and the 5 s scheduler tick can stretch to minutes.
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "Medication reminders must fire on time")

        let cfg = Config.current()
        Log.info("Pill times: \(cfg.pillTimes.joined(separator: ", "))")

        setupStatusItem()
        Notifier.setup()
        ReminderEngine.shared.onChange = { [weak self] in self?.refreshIcon() }
        ReminderEngine.shared.start()
        Watchdog.start()
        APIServer.shared.start(port: cfg.apiPort)

        DispatchQueue.global(qos: .utility).async {
            if cfg.voiceAck { _ = VoiceAck.shared.ensureAuthorized() }
            let next = ReminderEngine.shared.nextInfo().map { " Next pills at \(Self.spokenTime($0.time))." } ?? ""
            Speaker.shared.speak("Pill reminder is fully operational!\(next) I am... not dead yet!")
            let count = PhraseCache.shared.status().count
            PhraseCache.shared.refill(count: count < 10 ? 5 : 1, reason: "startup")
        }
    }

    static func spokenTime(_ hhmm: String) -> String {
        let p = hhmm.split(separator: ":").compactMap { Int($0) }
        guard p.count == 2 else { return hhmm }
        let h12 = p[0] % 12 == 0 ? 12 : p[0] % 12
        let ampm = p[0] < 12 ? "A M" : "P M"
        return p[1] == 0 ? "\(h12) \(ampm)" : String(format: "%d %02d %@", h12, p[1], ampm)
    }

    // MARK: - Menu bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshIcon()
    }

    private func refreshIcon() {
        let active = ReminderEngine.shared.isActive
        let img = NSImage(systemSymbolName: active ? "pills.circle.fill" : "pills.fill", accessibilityDescription: "Pill Reminder")
        img?.isTemplate = !active
        statusItem.button?.image = img
        statusItem.button?.contentTintColor = active ? .systemRed : nil
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let e = ReminderEngine.shared

        func info(_ s: String) { let i = NSMenuItem(title: s, action: nil, keyEquivalent: ""); i.isEnabled = false; menu.addItem(i) }
        func action(_ s: String, _ sel: Selector, enabled: Bool = true) {
            let i = NSMenuItem(title: s, action: enabled ? sel : nil, keyEquivalent: "")
            i.target = self
            menu.addItem(i)
        }

        if let n = e.nextInfo() {
            info("Next pills: \(n.time)  (in \(n.minutesUntil / 60)h \(n.minutesUntil % 60)m)")
        }
        if let p = Watchdog.problem() { info("⚠️ \(p)") } else { info(e.isActive ? "Reminder ACTIVE" : "Status: healthy") }
        let s = PhraseCache.shared.status()
        info("Phrase cache: \(s.count)" + (s.lastError != nil ? " — last refill failed" : ""))
        menu.addItem(.separator())
        action("I took my pills", #selector(ack), enabled: e.isActive)
        action("Test reminder now", #selector(test), enabled: !e.isActive)
        action("Get new phrases now", #selector(refill))
        menu.addItem(.separator())
        action("Settings…", #selector(settings))
        action("Open log", #selector(openLog))
        action("Open data folder", #selector(openData))
        menu.addItem(.separator())
        action("Restart Pill Reminder", #selector(restart))
        info("Version \(appVersion)")
    }

    @objc private func ack() { ReminderEngine.shared.acknowledge(source: "menu") }
    @objc private func test() { ReminderEngine.shared.triggerNow() }
    @objc private func refill() { PhraseCache.shared.refill(count: 3, reason: "menu") }
    @objc private func settings() { SettingsWindow.show() }
    @objc private func openLog() { NSWorkspace.shared.open(Paths.log) }
    @objc private func openData() { NSWorkspace.shared.open(Paths.support) }
    @objc private func restart() {
        Log.info("Restart requested from menu")
        exit(0)   // launchd KeepAlive relaunches
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
