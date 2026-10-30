import Foundation

/// User settings. Re-read from disk whenever the file changes, so edits from the
/// Settings window or a text editor take effect without a restart.
struct Config: Codable, Equatable {
    var pillTimes: [String] = ["07:00", "13:00", "17:00", "21:00"]
    var malady = "Parkinson's"
    var voiceGender = "male"            // male | female
    var voiceAccent = "british"         // british | american | australian | irish
    var voiceName = ""                  // exact `say` voice name; overrides gender/accent
    var speechRate = 175                // words per minute for `say`
    var location = ""                   // e.g. "Tampa, FL"; empty = IP lookup
    var voiceAck = true                 // listen for "yes"
    var newsAndWeather = true
    var minVolume = 50                  // raise output volume to at least this (0 = leave alone)
    var repeatSeconds = 60
    var giveUpMinutes = 90              // stop nagging after this long unacknowledged
    var catchUpMinutes = 180            // fire a missed reminder if found within this window
    var aiPhraseShare = 0.6             // chance a reminder uses an AI-generated phrase
    var cacheMax = 200
    var apiPort = 5055                  // 5000 is taken by macOS AirPlay Receiver
    var phraseSource = "claude"         // claude | ollama | off
    var ollamaURL = "http://127.0.0.1:11434"
    var ollamaModel = "gemma3:12b"

    enum CodingKeys: String, CodingKey {
        case pillTimes = "pill_times", malady, voiceGender = "voice_gender"
        case voiceAccent = "voice_accent", voiceName = "voice_name", speechRate = "speech_rate"
        case location, voiceAck = "voice_ack", newsAndWeather = "news_and_weather"
        case minVolume = "min_volume", repeatSeconds = "repeat_seconds"
        case giveUpMinutes = "give_up_minutes", catchUpMinutes = "catch_up_minutes"
        case aiPhraseShare = "ai_phrase_share", cacheMax = "cache_max", apiPort = "api_port"
        case phraseSource = "phrase_source", ollamaURL = "ollama_url", ollamaModel = "ollama_model"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Config()
        pillTimes      = (try? c.decodeIfPresent([String].self, forKey: .pillTimes)) ?? d.pillTimes
        malady         = (try? c.decodeIfPresent(String.self, forKey: .malady)) ?? d.malady
        voiceGender    = (try? c.decodeIfPresent(String.self, forKey: .voiceGender)) ?? d.voiceGender
        voiceAccent    = (try? c.decodeIfPresent(String.self, forKey: .voiceAccent)) ?? d.voiceAccent
        voiceName      = (try? c.decodeIfPresent(String.self, forKey: .voiceName)) ?? d.voiceName
        speechRate     = (try? c.decodeIfPresent(Int.self, forKey: .speechRate)) ?? d.speechRate
        location       = (try? c.decodeIfPresent(String.self, forKey: .location)) ?? d.location
        voiceAck       = (try? c.decodeIfPresent(Bool.self, forKey: .voiceAck)) ?? d.voiceAck
        newsAndWeather = (try? c.decodeIfPresent(Bool.self, forKey: .newsAndWeather)) ?? d.newsAndWeather
        minVolume      = (try? c.decodeIfPresent(Int.self, forKey: .minVolume)) ?? d.minVolume
        repeatSeconds  = (try? c.decodeIfPresent(Int.self, forKey: .repeatSeconds)) ?? d.repeatSeconds
        giveUpMinutes  = (try? c.decodeIfPresent(Int.self, forKey: .giveUpMinutes)) ?? d.giveUpMinutes
        catchUpMinutes = (try? c.decodeIfPresent(Int.self, forKey: .catchUpMinutes)) ?? d.catchUpMinutes
        aiPhraseShare  = (try? c.decodeIfPresent(Double.self, forKey: .aiPhraseShare)) ?? d.aiPhraseShare
        cacheMax       = (try? c.decodeIfPresent(Int.self, forKey: .cacheMax)) ?? d.cacheMax
        apiPort        = (try? c.decodeIfPresent(Int.self, forKey: .apiPort)) ?? d.apiPort
        phraseSource   = (try? c.decodeIfPresent(String.self, forKey: .phraseSource)) ?? d.phraseSource
        ollamaURL      = (try? c.decodeIfPresent(String.self, forKey: .ollamaURL)) ?? d.ollamaURL
        ollamaModel    = (try? c.decodeIfPresent(String.self, forKey: .ollamaModel)) ?? d.ollamaModel
    }

    /// Valid (hour, minute) pairs, sorted.
    var parsedTimes: [(label: String, hour: Int, minute: Int)] {
        pillTimes.compactMap { s in
            let p = s.split(separator: ":")
            guard p.count == 2, let h = Int(p[0]), let m = Int(p[1]),
                  (0..<24).contains(h), (0..<60).contains(m) else { return nil }
            return (String(format: "%02d:%02d", h, m), h, m)
        }.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    // MARK: - Cached load

    private static let lock = NSLock()
    private static var cached = Config()
    private static var cachedMtime: Date?

    static func current() -> Config {
        lock.lock(); defer { lock.unlock() }
        let url = Paths.config
        guard let mtime = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date else {
            // First run: write defaults so the user has a file to edit.
            let d = Config()
            JSONFile.write(d, to: url)
            cached = d
            cachedMtime = nil
            return d
        }
        if mtime != cachedMtime {
            if let loaded = JSONFile.read(Config.self, from: url) {
                if loaded != cached { Log.info("Config loaded: times=\(loaded.pillTimes) voice=\(loaded.voiceGender)/\(loaded.voiceAccent)") }
                cached = loaded
            }
            cachedMtime = mtime
        }
        return cached
    }

    func save() {
        Config.lock.lock(); defer { Config.lock.unlock() }
        JSONFile.write(self, to: Paths.config)
        Config.cached = self
        Config.cachedMtime = (try? FileManager.default.attributesOfItem(atPath: Paths.config.path))?[.modificationDate] as? Date
        Log.info("Config saved: times=\(pillTimes)")
    }
}
