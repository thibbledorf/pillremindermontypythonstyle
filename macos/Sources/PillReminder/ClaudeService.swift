import Foundation

/// Generates fresh reminder phrases from the configured source:
///   "ollama" — a local or LAN Ollama server (free)
///   "claude" — the Anthropic Messages API (paid; key in Keychain)
///   "off"    — built-in phrases only
enum PhraseGenerator {
    struct Failure: Error {
        let message: String
        let fatal: Bool       // retrying in the same refill run won't help
    }

    private(set) static var lastSource = ""

    static func generate(config cfg: Config, avoid: [String]) -> Result<String, Failure> {
        let prompt = buildPrompt(malady: cfg.malady, avoid: avoid)
        let result: Result<String, Failure>
        switch cfg.phraseSource.lowercased() {
        case "claude":
            result = ClaudeService.generate(prompt: prompt)
        case "off":
            lastSource = "off"
            return .failure(Failure(message: "phrase generation is turned off (phrase_source = off)", fatal: true))
        default:
            result = OllamaService.generate(prompt: prompt, baseURL: cfg.ollamaURL, model: cfg.ollamaModel)
        }
        return result.flatMap(clean)
    }

    private static func buildPrompt(malady: String, avoid: [String]) -> String {
        let condition = malady.trimmingCharacters(in: .whitespaces).isEmpty
            ? "" : "The recipient has \(malady) and must take medication on time. "
        var prompt = """
        Write ONE short, funny Monty Python-style pill reminder (2-4 sentences) to be read aloud by a text-to-speech voice. \
        Reference a specific Monty Python character, quote, or scene in a fresh, creative way. \
        \(condition)Be encouraging, silly, and affectionate — never mean. \
        No emoji, no stage directions in asterisks. \
        Reply with only the reminder text. No quotes, no labels, no explanation.
        """
        if !avoid.isEmpty {
            prompt += "\n\nDo not repeat the jokes or openings used in these recent ones:\n" + avoid.map { "- \($0)" }.joined(separator: "\n")
        }
        return prompt
    }

    /// Strips reasoning blocks, labels, quotes and asterisk actions that local models like to add.
    private static func clean(_ raw: String) -> Result<String, Failure> {
        var t = raw
        while let open = t.range(of: "<think>"), let close = t.range(of: "</think>", range: open.upperBound..<t.endIndex) {
            t.removeSubrange(open.lowerBound..<close.upperBound)
        }
        // Keep emphasized words, drop the asterisks (say would read them aloud).
        t = t.replacingOccurrences(of: "*", with: "")
        t = t.replacingOccurrences(of: #"^(Here('s| is)[^:\n]*:|Reminder:)\s*"#, with: "", options: [.regularExpression, .caseInsensitive])
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 20 else { return .failure(Failure(message: "response too short", fatal: false)) }
        guard t.count <= 700 else { return .failure(Failure(message: "response too long (\(t.count) chars)", fatal: false)) }
        return .success(t)
    }

    fileprivate static func setSource(_ s: String) { lastSource = s }
}

enum OllamaService {
    static func generate(prompt: String, baseURL: String, model: String) -> Result<String, PhraseGenerator.Failure> {
        PhraseGenerator.setSource("ollama \(model) @ \(baseURL)")
        let base = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        guard let url = URL(string: base + "/api/chat") else {
            return .failure(.init(message: "bad ollama_url '\(baseURL)'", fatal: true))
        }
        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "think": false,
            "keep_alive": "5m",
            "options": ["temperature": 1.0, "num_predict": 300],
            "messages": [["role": "user", "content": prompt]],
        ]
        // A cold model load can take a while on first call.
        var req = URLRequest(url: url, timeoutInterval: 180)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, http) = HTTP.send(req, timeout: 185) else {
            return .failure(.init(message: "Ollama not reachable at \(base) (is it running?)", fatal: true))
        }
        guard http.statusCode == 200 else {
            let snippet = String(data: data.prefix(300), encoding: .utf8) ?? ""
            let fatal = http.statusCode == 404 || snippet.contains("not found")
            let hint = fatal ? " — run: ollama pull \(model)" : ""
            return .failure(.init(message: "Ollama HTTP \(http.statusCode): \(snippet)\(hint)", fatal: fatal))
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg = json["message"] as? [String: Any],
              let text = msg["content"] as? String
        else {
            return .failure(.init(message: "unexpected Ollama response shape", fatal: false))
        }
        return .success(text)
    }
}

/// Minimal Anthropic Messages API client (no official Swift SDK).
enum ClaudeService {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let anthropicVersion = "2023-06-01"

    static func generate(prompt: String) -> Result<String, PhraseGenerator.Failure> {
        let (key, source) = Keychain.apiKey()
        PhraseGenerator.setSource("claude (\(source))")
        guard let apiKey = key else { return .failure(.init(message: source, fatal: true)) }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 300,
            "temperature": 1.0,
            "messages": [["role": "user", "content": prompt]],
        ]
        var req = URLRequest(url: endpoint, timeoutInterval: 30)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, http) = HTTP.send(req, timeout: 35) else {
            return .failure(.init(message: "network timeout or no connection", fatal: false))
        }
        guard http.statusCode == 200 else {
            let snippet = String(data: data.prefix(300), encoding: .utf8) ?? ""
            return .failure(.init(message: "HTTP \(http.statusCode): \(snippet)", fatal: http.statusCode == 401 || http.statusCode == 403))
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String
        else {
            return .failure(.init(message: "unexpected response shape", fatal: false))
        }
        return .success(text)
    }
}

/// Synchronous URLSession wrapper with a hard ceiling, so a stuck request can
/// never hold a reminder thread.
enum HTTP {
    private static let session: URLSession = {
        let c = URLSessionConfiguration.ephemeral
        c.timeoutIntervalForRequest = 180
        c.timeoutIntervalForResource = 190
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    static func send(_ req: URLRequest, timeout: TimeInterval) -> (Data, HTTPURLResponse)? {
        let sem = DispatchSemaphore(value: 0)
        var result: (Data, HTTPURLResponse)?
        let task = session.dataTask(with: req) { data, resp, err in
            if let data, let http = resp as? HTTPURLResponse { result = (data, http) }
            else if let err { Log.warn("HTTP \(req.url?.host ?? "?") failed: \(err.localizedDescription)") }
            sem.signal()
        }
        task.resume()
        if sem.wait(timeout: .now() + timeout) == .timedOut {
            task.cancel()
            Log.warn("HTTP \(req.url?.host ?? "?") hard timeout after \(Int(timeout))s")
            return nil
        }
        return result
    }

    static func get(_ url: URL, timeout: TimeInterval = 15) -> Data? {
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.setValue("PillReminder/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        guard let (data, http) = send(req, timeout: timeout + 5), (200..<300).contains(http.statusCode) else { return nil }
        return data
    }
}
