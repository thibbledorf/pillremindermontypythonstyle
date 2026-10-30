import Foundation
import Network

/// Localhost-only HTTP API (same endpoints as the Windows build, plus /health and /cache).
/// Default port 5055 — macOS's AirPlay Receiver already owns 5000.
final class APIServer {
    static let shared = APIServer()
    private let queue = DispatchQueue(label: "api-server")
    private var listener: NWListener?

    func start(port: Int) {
        guard let p = NWEndpoint.Port(rawValue: UInt16(clamping: port)) else { return }
        let params = NWParameters.tcp
        params.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: p)
        params.allowLocalEndpointReuse = true
        do {
            let l = try NWListener(using: params)
            l.newConnectionHandler = { [weak self] c in self?.handle(c) }
            l.stateUpdateHandler = { [weak self] st in
                switch st {
                case .ready: Log.info("HTTP API listening on http://127.0.0.1:\(port)/")
                case .failed(let e):
                    Log.error("HTTP API failed: \(e) — retrying in 30s")
                    self?.listener?.cancel()
                    self?.queue.asyncAfter(deadline: .now() + 30) { self?.start(port: port) }
                default: break
                }
            }
            l.start(queue: queue)
            listener = l
        } catch {
            Log.error("HTTP API could not start: \(error)")
        }
    }

    private func handle(_ c: NWConnection) {
        c.start(queue: queue)
        c.receive(minimumIncompleteLength: 1, maximumLength: 16384) { [weak self] data, _, _, _ in
            guard let self, let data, let req = String(data: data, encoding: .utf8) else { c.cancel(); return }
            let first = req.split(separator: "\r\n").first?.split(separator: " ") ?? []
            let method = first.count > 0 ? String(first[0]) : ""
            let path = first.count > 1 ? String(first[1].split(separator: "?").first ?? "/") : "/"
            let (status, body) = self.route(method: method, path: path)
            let json = (try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted, .sortedKeys])) ?? Data("{}".utf8)
            let reason = [200: "OK", 404: "Not Found", 503: "Service Unavailable"][status] ?? "OK"
            var resp = Data("HTTP/1.1 \(status) \(reason)\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: \(json.count)\r\nConnection: close\r\n\r\n".utf8)
            resp.append(json)
            c.send(content: resp, completion: .contentProcessed { _ in c.cancel() })
        }
    }

    private func route(method: String, path: String) -> (Int, [String: Any]) {
        let e = ReminderEngine.shared
        let iso = ISO8601DateFormatter()
        switch (method, path) {
        case ("GET", "/health"):
            var d = e.snapshot()
            if let p = Watchdog.problem() { d["ok"] = false; d["problem"] = p; return (503, d) }
            d["ok"] = true
            if let t = Speaker.shared.lastSpokeOK { d["last_speech_ok"] = iso.string(from: t) }
            if let err = Speaker.shared.lastError { d["last_speech_error"] = err }
            return (200, d)
        case ("GET", "/status"):
            var d = e.snapshot()
            d["pill_times"] = Config.current().pillTimes
            d["current_time"] = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: Date()) }()
            return (200, d)
        case ("GET", "/next"):
            guard let n = e.nextInfo() else { return (200, ["next": NSNull()]) }
            return (200, ["next": ["time": n.time, "minutes_until": n.minutesUntil]])
        case ("POST", "/acknowledge"):
            return (200, ["status": e.acknowledge(source: "api") ? "acknowledged" : "no_active_reminder"])
        case ("POST", "/trigger"):
            return (200, ["status": e.triggerNow() ? "triggered" : "already_active"])
        case ("GET", "/cache"):
            let s = PhraseCache.shared.status()
            var d: [String: Any] = ["count": s.count, "consecutive_failures": s.consecutiveFailures,
                                    "total_generated": s.totalGenerated, "source": s.keySource]
            if let x = s.lastAttempt { d["last_attempt"] = iso.string(from: x) }
            if let x = s.lastSuccess { d["last_success"] = iso.string(from: x) }
            if let x = s.lastError { d["last_error"] = x }
            return (200, d)
        case ("POST", "/cache/refill"):
            PhraseCache.shared.refill(count: 3, reason: "API request")
            return (200, ["status": "refill_started"])
        default:
            return (404, ["error": "not found",
                          "endpoints": ["GET /health", "GET /status", "GET /next", "GET /cache",
                                        "POST /acknowledge", "POST /trigger", "POST /cache/refill"]])
        }
    }
}
