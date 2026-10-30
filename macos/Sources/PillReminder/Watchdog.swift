import Foundation

/// In-process watchdog on its own OS thread (not GCD, so a starved queue can't starve it).
/// If the scheduler, the reminder cycle, or the main thread stops making progress, it
/// logs why and exits non-zero; launchd's KeepAlive relaunches the app and the pending
/// dose re-fires. A separate launchd health-check job covers the case where this
/// thread itself is stuck.
enum Watchdog {
    private static let interval: TimeInterval = 15
    private static let schedulerLimit: TimeInterval = 90
    private static let cycleLimit: TimeInterval = 240
    private static let mainLimit: TimeInterval = 120

    private static let lock = NSLock()
    private static var mainBeat = Date()

    static func start() {
        let th = Thread {
            var last = Date()
            while true {
                Thread.sleep(forTimeInterval: interval)
                let now = Date()
                // Woke from sleep: every heartbeat is stale for a benign reason.
                if now.timeIntervalSince(last) > interval * 3 {
                    Log.info(String(format: "Watchdog: %.0fs gap (system sleep) — resetting heartbeats", now.timeIntervalSince(last)))
                    ReminderEngine.shared.resetHeartbeats()
                    lock.lock(); mainBeat = now; lock.unlock()
                    last = now
                    continue
                }
                last = now

                DispatchQueue.main.async { lock.lock(); mainBeat = Date(); lock.unlock() }

                if let reason = problem(now: now) {
                    Log.error("WATCHDOG: \(reason) — exiting so launchd restarts the service")
                    Thread.sleep(forTimeInterval: 0.5)
                    exit(70)
                }
            }
        }
        th.name = "watchdog"
        th.qualityOfService = .userInitiated
        th.start()
        Log.info("Watchdog started")
    }

    /// nil when healthy; otherwise a human-readable reason.
    static func problem(now: Date = Date()) -> String? {
        let e = ReminderEngine.shared
        let sched = now.timeIntervalSince(e.schedulerBeat)
        if sched > schedulerLimit { return "scheduler stalled for \(Int(sched))s" }
        if e.isActive {
            let cyc = now.timeIntervalSince(e.cycleBeat)
            if cyc > cycleLimit { return "reminder cycle stalled for \(Int(cyc))s" }
        }
        lock.lock(); let m = now.timeIntervalSince(mainBeat); lock.unlock()
        if m > mainLimit { return "main thread unresponsive for \(Int(m))s" }
        return nil
    }
}
