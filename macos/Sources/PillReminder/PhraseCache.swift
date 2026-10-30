import Foundation

/// Persistent pool of Claude-generated reminder phrases.
///
/// Fixes for the Windows "cache never updates" bug:
///  - generation runs after EVERY acknowledged reminder and at startup, not on a 20% coin flip
///  - phrases come from local Ollama (free) or Claude (key in the Keychain, not an env var)
///  - every failure is logged with the HTTP status and recorded in cache_status.json / GET /cache
///  - AI phrases get a fixed share of picks so new entries are actually heard
///  - writes are atomic, entries are de-duplicated, and the pool is capped (oldest dropped)
final class PhraseCache {
    static let shared = PhraseCache()

    struct Entry: Codable {
        var text: String
        var created: Date
        var timesUsed: Int
    }

    struct Status: Codable {
        var count = 0
        var lastAttempt: Date?
        var lastSuccess: Date?
        var lastError: String?
        var consecutiveFailures = 0
        var totalGenerated = 0
        var keySource = ""
    }

    private let lock = NSLock()
    private let workQueue = DispatchQueue(label: "phrase-cache.refill")
    private var refilling = false
    private var recent: [String] = []          // last spoken phrases, to avoid repeats

    // MARK: - Storage

    func entries() -> [Entry] {
        lock.lock(); defer { lock.unlock() }
        return loadUnlocked()
    }

    private func loadUnlocked() -> [Entry] {
        if let e = JSONFile.read([Entry].self, from: Paths.generatedPhrases) { return e }
        // Accept the Windows/iOS format (plain string array) if someone copies it over.
        if let s = JSONFile.read([String].self, from: Paths.generatedPhrases) {
            return s.map { Entry(text: $0, created: Date(), timesUsed: 0) }
        }
        return []
    }

    func status() -> Status {
        var s = JSONFile.read(Status.self, from: Paths.cacheStatus) ?? Status()
        s.count = entries().count
        return s
    }

    private func updateStatus(_ change: (inout Status) -> Void) {
        lock.lock(); defer { lock.unlock() }
        var s = JSONFile.read(Status.self, from: Paths.cacheStatus) ?? Status()
        change(&s)
        s.count = loadUnlocked().count
        JSONFile.write(s, to: Paths.cacheStatus)
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Returns false if it was a duplicate.
    private func add(_ text: String, max: Int) -> Bool {
        lock.lock(); defer { lock.unlock() }
        var all = loadUnlocked()
        let key = Self.normalize(text)
        let staticKeys = Set(Phrases.reminders.map(Self.normalize))
        if staticKeys.contains(key) || all.contains(where: { Self.normalize($0.text) == key }) { return false }
        all.append(Entry(text: text, created: Date(), timesUsed: 0))
        if all.count > max { all.removeFirst(all.count - max) }
        return JSONFile.write(all, to: Paths.generatedPhrases)
    }

    private func markUsed(_ text: String) {
        lock.lock(); defer { lock.unlock() }
        var all = loadUnlocked()
        if let i = all.firstIndex(where: { $0.text == text }) {
            all[i].timesUsed += 1
            JSONFile.write(all, to: Paths.generatedPhrases)
        }
    }

    // MARK: - Picking

    func pick(config: Config) -> String {
        let generated = entries()
        let recentSet = Set(recent)
        var phrase: String
        var fromAI = false

        if !generated.isEmpty && Double.random(in: 0..<1) < config.aiPhraseShare {
            // Least-used first, so freshly generated phrases are heard promptly.
            let fresh = generated.filter { !recentSet.contains($0.text) }
            let pool = fresh.isEmpty ? generated : fresh
            let minUse = pool.map(\.timesUsed).min() ?? 0
            phrase = pool.filter { $0.timesUsed == minUse }.randomElement()!.text
            fromAI = true
        } else {
            let pool = Phrases.reminders.filter { !recentSet.contains($0) }
            phrase = (pool.isEmpty ? Phrases.reminders : pool).randomElement()!
        }

        recent.append(phrase)
        if recent.count > 15 { recent.removeFirst(recent.count - 15) }
        if fromAI { markUsed(phrase) }
        Log.info("Phrase picked (\(fromAI ? "AI cache" : "built-in"); cache size \(generated.count))")
        return Phrases.personalize(phrase, malady: config.malady)
    }

    // MARK: - Refill

    /// Generate `count` new phrases in the background. Safe to call often.
    func refill(count: Int, reason: String) {
        workQueue.async { [self] in
            lock.lock()
            if refilling { lock.unlock(); return }
            refilling = true
            lock.unlock()
            defer { lock.lock(); refilling = false; lock.unlock() }

            let cfg = Config.current()
            Log.info("Phrase cache refill: \(count) requested (\(reason))")
            var added = 0
            var attempts = 0
            while added < count && attempts < count + 3 {
                attempts += 1
                let examples = entries().suffix(5).map(\.text)
                let result = PhraseGenerator.generate(config: cfg, avoid: examples)
                switch result {
                case .success(let text):
                    if add(text, max: cfg.cacheMax) {
                        added += 1
                        updateStatus {
                            $0.lastAttempt = Date(); $0.lastSuccess = Date(); $0.lastError = nil
                            $0.consecutiveFailures = 0; $0.totalGenerated += 1; $0.keySource = PhraseGenerator.lastSource
                        }
                        Log.info("Phrase cache: added 1 (now \(entries().count))")
                    } else {
                        Log.info("Phrase cache: duplicate discarded")
                    }
                case .failure(let err):
                    updateStatus {
                        $0.lastAttempt = Date(); $0.lastError = err.message
                        $0.consecutiveFailures += 1; $0.keySource = PhraseGenerator.lastSource
                    }
                    Log.error("Phrase cache refill failed: \(err.message)")
                    if err.fatal { return }        // no key / auth error: retrying won't help
                    Thread.sleep(forTimeInterval: 5)
                }
            }
        }
    }
}
