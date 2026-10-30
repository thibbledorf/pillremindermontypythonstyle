import Foundation

/// Runs a command-line tool with a hard timeout. A hung child is killed, never waited on forever.
enum Shell {
    struct Result { let status: Int32; let output: String; let timedOut: Bool }

    private static let runningLock = NSLock()

    @discardableResult
    static func run(_ path: String, _ args: [String], timeout: TimeInterval,
                    onStart: ((Process) -> Void)? = nil) -> Result {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        let done = DispatchSemaphore(value: 0)
        p.terminationHandler = { _ in done.signal() }
        do { try p.run() } catch {
            Log.error("Could not launch \(path): \(error.localizedDescription)")
            return Result(status: -1, output: "", timedOut: false)
        }
        onStart?(p)
        // Drain output concurrently so a chatty child can't block on a full pipe.
        var data = Data()
        let reader = DispatchQueue.global(qos: .utility)
        let readDone = DispatchSemaphore(value: 0)
        reader.async { data = pipe.fileHandleForReading.readDataToEndOfFile(); readDone.signal() }

        if done.wait(timeout: .now() + timeout) == .timedOut {
            p.terminate()
            if done.wait(timeout: .now() + 2) == .timedOut { kill(p.processIdentifier, SIGKILL) }
            _ = readDone.wait(timeout: .now() + 2)
            return Result(status: -1, output: String(data: data, encoding: .utf8) ?? "", timedOut: true)
        }
        _ = readDone.wait(timeout: .now() + 2)
        return Result(status: p.terminationStatus, output: String(data: data, encoding: .utf8) ?? "", timedOut: false)
    }
}

/// Text-to-speech via /usr/bin/say. Each utterance is a child process with a
/// length-based deadline, so a wedged speech engine is killed and logged rather
/// than silently freezing the reminder loop (the Windows SAPI failure mode).
final class Speaker {
    static let shared = Speaker()

    private let speakLock = NSLock()
    private let procLock = NSLock()
    private var current: Process?
    private var voices: [(name: String, locale: String)] = []
    private var voicesLoaded = Date.distantPast
    private(set) var lastSpokeOK: Date?
    private(set) var lastError: String?

    private static let preferences: [String: [String]] = [
        "male|british":      ["Jamie (Premium)", "Jamie (Enhanced)", "Oliver (Enhanced)", "Daniel (Enhanced)", "Arthur", "Oliver", "Jamie", "Daniel", "Daniel (English (UK))", "Reed (English (UK))", "Rocko (English (UK))", "Eddy (English (UK))"],
        "female|british":    ["Serena (Premium)", "Serena (Enhanced)", "Kate (Enhanced)", "Stephanie (Enhanced)", "Serena", "Kate", "Stephanie", "Martha", "Flo (English (UK))", "Shelley (English (UK))", "Sandy (English (UK))"],
        "male|american":     ["Evan (Premium)", "Evan (Enhanced)", "Nathan (Enhanced)", "Tom (Enhanced)", "Evan", "Nathan", "Tom", "Alex", "Aaron", "Reed (English (US))", "Fred"],
        "female|american":   ["Ava (Premium)", "Zoe (Premium)", "Ava (Enhanced)", "Allison (Enhanced)", "Samantha (Enhanced)", "Ava", "Zoe", "Allison", "Samantha", "Flo (English (US))"],
        "male|australian":   ["Lee (Premium)", "Lee (Enhanced)", "Gordon", "Lee"],
        "female|australian": ["Karen (Premium)", "Karen (Enhanced)", "Matilda (Premium)", "Matilda", "Karen", "Catherine"],
        "male|irish":        [],   // macOS ships no Irish male voice; falls through to British male
        "female|irish":      ["Moira (Enhanced)", "Moira"],
    ]
    private static let localeFor = ["british": "en_GB", "american": "en_US", "australian": "en_AU", "irish": "en_IE"]
    private static let femaleOnly: Set<String> = ["Moira", "Moira (Enhanced)", "Karen", "Karen (Enhanced)", "Karen (Premium)", "Matilda", "Matilda (Premium)", "Catherine"]
    private static let novelty: Set<String> = ["Albert", "Bad News", "Bahh", "Bells", "Boing", "Bubbles", "Cellos", "Wobble",
                                               "Good News", "Jester", "Organ", "Superstar", "Trinoids", "Whisper", "Zarvox", "Junior", "Ralph"]

    private func loadVoices() {
        guard Date().timeIntervalSince(voicesLoaded) > 3600 || voices.isEmpty else { return }
        let r = Shell.run("/usr/bin/say", ["-v", "?"], timeout: 10)
        var list: [(String, String)] = []
        for line in r.output.split(separator: "\n") {
            // "Daniel (Enhanced)   en_GB    # Hello! My name is Daniel."
            let head = line.split(separator: "#", maxSplits: 1).first.map(String.init) ?? ""
            let parts = head.split(separator: " ", omittingEmptySubsequences: true)
            guard let loc = parts.last, loc.contains("_") else { continue }
            let name = parts.dropLast().joined(separator: " ")
            list.append((name, String(loc)))
        }
        if !list.isEmpty {
            voices = list
            voicesLoaded = Date()
            Log.info("Installed voices (\(list.count)): " + list.filter { $0.1.hasPrefix("en_") }.map { "\($0.0)[\($0.1)]" }.joined(separator: ", "))
        }
    }

    func resolveVoice(_ cfg: Config) -> String? {
        loadVoices()
        let names = Set(voices.map(\.name))
        if !cfg.voiceName.isEmpty {
            if names.contains(cfg.voiceName) { return cfg.voiceName }
            Log.warn("Configured voice_name '\(cfg.voiceName)' not installed — falling back")
        }
        let g = cfg.voiceGender.lowercased(), a = cfg.voiceAccent.lowercased()
        for n in Self.preferences["\(g)|\(a)"] ?? [] where names.contains(n) { return n }
        if let loc = Self.localeFor[a], let any = voices.first(where: {
            $0.locale == loc && !Self.novelty.contains($0.name) && !(g == "male" && Self.femaleOnly.contains($0.name))
        }) { return any.name }
        for n in Self.preferences["\(g)|british"] ?? [] where names.contains(n) { return n }
        return nil   // system default voice
    }

    /// Speaks synchronously. Returns false on failure, timeout, or interruption.
    @discardableResult
    func speak(_ text: String) -> Bool {
        speakLock.lock(); defer { speakLock.unlock() }
        let cfg = Config.current()
        var args: [String] = []
        if let v = resolveVoice(cfg) { args += ["-v", v] }
        args += ["-r", String(max(90, min(320, cfg.speechRate)))]
        args.append(text)

        // ~2.5 words/s worst case + generous slack.
        let words = Double(text.split(separator: " ").count)
        let deadline = max(15, words / 2.0 + 15)
        Log.info("TTS [\(args.count > 3 ? args[1] : "default")]: \(text.prefix(90))")

        let start = Date()
        let r = Shell.run("/usr/bin/say", args, timeout: deadline) { p in
            self.procLock.lock(); self.current = p; self.procLock.unlock()
        }
        procLock.lock(); current = nil; procLock.unlock()

        if r.timedOut {
            lastError = "say hung for \(Int(deadline))s and was killed"
            Log.error("TTS: \(lastError!)")
            return false
        }
        if r.status != 0 && r.status != 15 {   // 15 = SIGTERM from stop()
            lastError = "say exited \(r.status): \(r.output.prefix(200))"
            Log.error("TTS: \(lastError!)")
            return false
        }
        lastSpokeOK = Date()
        lastError = nil
        Log.info(String(format: "TTS done in %.1fs", Date().timeIntervalSince(start)))
        return r.status == 0
    }

    /// Cuts off the current utterance (used when the user acknowledges mid-sentence).
    func stop() {
        procLock.lock(); defer { procLock.unlock() }
        current?.terminate()
    }
}

/// Audible cues and the "is the Mac muted?" guard.
enum Audio {
    static func chime() {
        Shell.run("/usr/bin/afplay", ["-v", "1.0", "/System/Library/Sounds/Glass.aiff"], timeout: 5)
    }

    /// A muted or near-silent Mac is the most common "service is running but I heard
    /// nothing" cause. Unmute and raise to the configured floor before each reminder.
    static func ensureAudible(minVolume: Int) {
        guard minVolume > 0 else { return }
        let muted = Shell.run("/usr/bin/osascript", ["-e", "output muted of (get volume settings)"], timeout: 5)
            .output.trimmingCharacters(in: .whitespacesAndNewlines)
        let vol = Int(Shell.run("/usr/bin/osascript", ["-e", "output volume of (get volume settings)"], timeout: 5)
            .output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? -1
        if muted == "true" {
            Log.warn("Output was muted — unmuting for reminder")
            Shell.run("/usr/bin/osascript", ["-e", "set volume output muted false"], timeout: 5)
        }
        if vol >= 0 && vol < minVolume {
            Log.warn("Output volume \(vol) below floor \(minVolume) — raising")
            Shell.run("/usr/bin/osascript", ["-e", "set volume output volume \(minVolume)"], timeout: 5)
        }
    }
}
