import Foundation

/// All on-disk locations. Data lives in Application Support, logs in ~/Library/Logs.
enum Paths {
    /// PILLREMINDER_DATA_DIR redirects data and logs (used for testing).
    private static let override = ProcessInfo.processInfo.environment["PILLREMINDER_DATA_DIR"].map { URL(fileURLWithPath: $0, isDirectory: true) }

    static let support: URL = {
        let dir = override ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/PillReminder", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let logs: URL = {
        let dir = override?.appendingPathComponent("Logs", isDirectory: true) ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/PillReminder", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static var config: URL           { support.appendingPathComponent("config.json") }
    static var generatedPhrases: URL { support.appendingPathComponent("generated_phrases.json") }
    static var cacheStatus: URL      { support.appendingPathComponent("cache_status.json") }
    static var state: URL            { support.appendingPathComponent("state.json") }
    static var log: URL              { logs.appendingPathComponent("pill_reminder.log") }
}

/// Atomic JSON helpers shared by every persisted file.
enum JSONFile {
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func read<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do { return try decoder.decode(type, from: data) }
        catch {
            Log.warn("Could not parse \(url.lastPathComponent): \(error)")
            return nil
        }
    }

    @discardableResult
    static func write<T: Encodable>(_ value: T, to url: URL) -> Bool {
        do {
            try encoder.encode(value).write(to: url, options: .atomic)
            return true
        } catch {
            Log.error("Could not write \(url.lastPathComponent): \(error)")
            return false
        }
    }
}
