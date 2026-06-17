import Foundation

/// Calls the Anthropic Messages API directly over HTTPS (there is no official
/// Anthropic Swift SDK, so this uses URLSession per Anthropic's REST docs).
enum ClaudeService {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let anthropicVersion = "2023-06-01"

    struct APIError: Error { let message: String }

    /// Generates one fresh Monty Python pill-reminder line. Returns nil (rather
    /// than throwing) on any failure so callers can silently fall back to the
    /// static phrase pool.
    static func generatePhrase() async -> String? {
        guard let apiKey = KeychainHelper.load(), !apiKey.isEmpty else { return nil }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let prompt = """
        Write ONE short, funny Monty Python-style pill reminder (2-4 sentences). \
        Reference a specific Monty Python character, quote, or scene in a fresh, creative way. \
        The recipient has Parkinson's disease and must take medication on time. \
        Be encouraging, silly, and affectionate — never mean. \
        Reply with only the reminder text. No quotes, no labels, no explanation.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 200,
            "messages": [["role": "user", "content": prompt]],
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let content = json["content"] as? [[String: Any]],
                let first = content.first,
                let text = first["text"] as? String
            else {
                return nil
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
            return nil
        }
    }
}
