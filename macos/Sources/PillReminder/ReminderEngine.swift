import AppKit
import Foundation

/// Scheduling and the reminder cycle.
///
/// Fixes for the Windows "silent but not dead" bug:
///  - a dose slot is recorded as handled only when acknowledged or given up, never at
///    fire time — a crash or restart mid-reminder re-fires that dose instead of losing it
///  - due slots are found by comparing against a catch-up window, not "is it exactly
///    HH:MM right now", so sleep, clock changes and slow ticks can't skip a dose
///  - every blocking step (speech, listening, HTTP) has a hard deadline
///  - the scheduler and cycle publish heartbeats that the Watchdog checks; a stall
///    terminates the process so launchd restarts it
final class ReminderEngine {
    static let shared = ReminderEngine()

    struct State: Codable {
        var handled: [String: Date] = [:]   // slot key "yyyy-MM-dd HH:mm" -> when resolved
        var initialized = false
        var lastFire: Date?
        var lastAck: Date?
        var lastAckSource: String?
        var lastGiveUp: Date?
    }

    private let lock = NSLock()
    private let queue = DispatchQueue(label: "scheduler")
    private var timer: DispatchSourceTimer?
    private var state: State
    private var cycleActive = false
    private var acked = false
    private var activeKey: String?
    private var activeSince: Date?

    private(set) var schedulerBeat = Date()
    private(set) var cycleBeat = Date()

    var onChange: (() -> Void)?

    private static let keyFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private init() {
        state = JSONFile.read(State.self, from: Paths.state) ?? State()
    }

    private func saveState() { JSONFile.write(state, to: Paths.state) }

    // MARK: - Lifecycle

    func start() {
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 2, repeating: 5, leeway: .milliseconds(500))
        t.setEventHandler { [weak self] in self?.tick() }
        t.resume()
        timer = t

        let wc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.sessionDidBecomeActiveNotification] {
            wc.addObserver(forName: name, object: nil, queue: nil) { [weak self] n in
                Log.info("System event: \(n.name.rawValue) — checking schedule")
                self?.resetHeartbeats()
                self?.queue.async { self?.tick() }
            }
        }
        Log.info("Scheduler started")
    }

    func resetHeartbeats() {
        lock.lock(); schedulerBeat = Date(); cycleBeat = Date(); lock.unlock()
    }

    private func beatCycle() { lock.lock(); cycleBeat = Date(); lock.unlock() }

    // MARK: - Scheduling

    private func dueSlots(now: Date, cfg: Config) -> [(key: String, at: Date)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return [] }
        var out: [(String, Date)] = []
        for day in [yesterday, today] {
            for t in cfg.parsedTimes {
                guard let at = cal.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: day) else { continue }
                let key = Self.keyFormat.string(from: at)
                if at <= now, now.timeIntervalSince(at) <= Double(cfg.catchUpMinutes) * 60, state.handled[key] == nil {
                    out.append((key, at))
                }
            }
        }
        return out.sorted { $0.1 < $1.1 }
    }

    private func tick() {
        let now = Date()
        lock.lock()
        schedulerBeat = now
        let busy = cycleActive
        lock.unlock()
        if busy { return }

        let cfg = Config.current()
        let due = dueSlots(now: now, cfg: cfg)

        lock.lock()
        // Prune old entries.
        let cutoff = now.addingTimeInterval(-3 * 86400)
        state.handled = state.handled.filter { $0.value > cutoff }

        if !state.initialized {
            // First run ever: don't nag about doses that passed before install.
            for d in due { state.handled[d.key] = now }
            state.initialized = true
            saveState()
            lock.unlock()
            Log.info("First run — \(due.count) earlier slot(s) today marked as already handled")
            return
        }
        guard let latest = due.last else { lock.unlock(); return }
        // Several missed (long sleep): one reminder for the most recent, the rest are superseded.
        for d in due.dropLast() {
            state.handled[d.key] = now
            Log.warn("Slot \(d.key) superseded by later missed slot \(latest.key)")
        }
        saveState()
        lock.unlock()

        let lateMin = Int(now.timeIntervalSince(latest.at) / 60)
        Log.info("Firing reminder for \(latest.key)\(lateMin > 1 ? " (\(lateMin) min late — missed while asleep/stopped)" : "")")
        fire(key: latest.key)
    }

    // MARK: - Public API

    @discardableResult
    func triggerNow() -> Bool {
        lock.lock(); let busy = cycleActive; lock.unlock()
        if busy { Log.info("Trigger ignored — reminder already active"); return false }
        Log.info("Manual reminder triggered")
        fire(key: nil)
        return true
    }

    @discardableResult
    func acknowledge(source: String) -> Bool {
        lock.lock()
        guard cycleActive, !acked else { lock.unlock(); return false }
        acked = true
        lock.unlock()
        Log.info("Acknowledged via \(source)")
        lock.lock(); state.lastAckSource = source; lock.unlock()
        Speaker.shared.stop()
        return true
    }

    var isActive: Bool { lock.lock(); defer { lock.unlock() }; return cycleActive }

    func nextInfo() -> (time: String, minutesUntil: Int)? {
        let cfg = Config.current()
        let cal = Calendar.current
        let now = Date()
        let nowMin = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        return cfg.parsedTimes.map { t -> (String, Int) in
            var diff = t.hour * 60 + t.minute - nowMin
            if diff <= 0 { diff += 1440 }
            return (t.label, diff)
        }.min { $0.1 < $1.1 }.map { (time: $0.0, minutesUntil: $0.1) }
    }

    func snapshot() -> [String: Any] {
        lock.lock(); defer { lock.unlock() }
        let iso = ISO8601DateFormatter()
        var d: [String: Any] = [
            "reminder_active": cycleActive,
            "scheduler_age_s": Int(Date().timeIntervalSince(schedulerBeat)),
            "cycle_age_s": cycleActive ? Int(Date().timeIntervalSince(cycleBeat)) : 0,
        ]
        if let k = activeKey { d["active_slot"] = k }
        if let s = activeSince { d["active_since"] = iso.string(from: s) }
        if let x = state.lastFire { d["last_fire"] = iso.string(from: x) }
        if let x = state.lastAck { d["last_ack"] = iso.string(from: x) }
        if let x = state.lastAckSource { d["last_ack_source"] = x }
        if let x = state.lastGiveUp { d["last_give_up"] = iso.string(from: x) }
        return d
    }

    // MARK: - Cycle

    private func fire(key: String?) {
        lock.lock()
        cycleActive = true
        acked = false
        activeKey = key
        activeSince = Date()
        cycleBeat = Date()
        state.lastFire = Date()
        saveState()
        lock.unlock()
        DispatchQueue.main.async { self.onChange?() }

        let th = Thread { [weak self] in self?.runCycle(key: key) }
        th.name = "reminder-cycle"
        th.qualityOfService = .userInitiated
        th.start()
    }

    private func isAcked() -> Bool { lock.lock(); defer { lock.unlock() }; return acked }

    private func runCycle(key: String?) {
        let started = Date()
        var attempt = 0
        var gaveUp = false
        AckPanel.show()
        Notifier.postReminder()

        while !isAcked() {
            let cfg = Config.current()
            if Date().timeIntervalSince(started) > Double(cfg.giveUpMinutes) * 60 {
                gaveUp = true
                break
            }
            attempt += 1
            let attemptStart = Date()
            beatCycle()

            Audio.ensureAudible(minVolume: cfg.minVolume)
            Audio.chime()
            let phrase = PhraseCache.shared.pick(config: cfg)
            AckPanel.update(phrase: phrase, attempt: attempt)
            beatCycle()

            if !Speaker.shared.speak(phrase) && !isAcked() {
                Log.error("Reminder speech failed on attempt \(attempt) — panel and notification still showing")
            }
            beatCycle()
            if isAcked() { break }

            Speaker.shared.speak("Say YES, or press the big green button, to confirm you have taken your pills!")
            beatCycle()
            if isAcked() { break }

            if cfg.voiceAck {
                if VoiceAck.shared.listenForYes(seconds: 8, shouldStop: { [weak self] in self?.isAcked() ?? true }) {
                    acknowledge(source: "voice")
                    break
                }
                beatCycle()
            }

            Log.info("No acknowledgment — attempt \(attempt), repeating in \(cfg.repeatSeconds)s")
            let next = attemptStart.addingTimeInterval(Double(max(15, cfg.repeatSeconds)))
            while Date() < next && !isAcked() {
                Thread.sleep(forTimeInterval: 0.5)
                beatCycle()
            }
        }

        AckPanel.hide()
        Notifier.clear()

        lock.lock()
        if let key { state.handled[key] = Date() }
        if gaveUp { state.lastGiveUp = Date() } else { state.lastAck = Date() }
        saveState()
        cycleActive = false
        activeKey = nil
        activeSince = nil
        lock.unlock()
        DispatchQueue.main.async { self.onChange?() }

        if gaveUp {
            Log.warn("Gave up after \(attempt) attempts — dose \(key ?? "manual") NOT acknowledged")
            Notifier.postMissed(slot: key)
            return
        }

        Log.info("Reminder complete after \(attempt) attempt(s)")
        PhraseCache.shared.refill(count: 2, reason: "after acknowledged reminder")
        deliverBriefing()
    }

    private func deliverBriefing() {
        let cfg = Config.current()
        Speaker.shared.speak(Phrases.acknowledgments.randomElement()!)
        guard cfg.newsAndWeather else {
            Speaker.shared.speak("We shall bother you again at the next appointed hour. Farewell!")
            return
        }
        Speaker.shared.speak("Now hear ye the news from the realm. First, the weather! " + NewsWeather.weather(location: cfg.location))
        let heads = NewsWeather.headlines()
        Speaker.shared.speak("And now, the top headlines from Fox News!")
        for (i, h) in heads.enumerated() {
            if isActive { Log.info("Briefing cut short — new reminder started"); return }
            Speaker.shared.speak("Headline \(i + 1): \(h)")
        }
        Speaker.shared.speak("And that concludes today's briefing, brave knight. Always look on the bright side of life! We shall bother you again at the next appointed hour. Farewell!")
    }
}
