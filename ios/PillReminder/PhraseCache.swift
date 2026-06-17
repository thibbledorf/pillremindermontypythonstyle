import Foundation

/// Persists Claude-generated phrases to disk so the pool grows over time and
/// phrases are never lost between launches (mirrors generated_phrases.json
/// in the Windows version).
enum PhraseCache {
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("generated_phrases.json")
    }

    static func load() -> [String] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    static func append(_ phrase: String) {
        var phrases = load()
        phrases.append(phrase)
        if let data = try? JSONEncoder().encode(phrases) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// Combined static + generated pool to draw a reminder phrase from.
    static func combinedPool() -> [String] {
        Phrases.reminders + load()
    }
}
