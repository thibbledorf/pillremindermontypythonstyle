import Foundation

enum Log {
    private static let lock = NSLock()
    private static let maxBytes: UInt64 = 5 * 1024 * 1024
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func info(_ msg: String)  { write("INFO ", msg) }
    static func warn(_ msg: String)  { write("WARN ", msg) }
    static func error(_ msg: String) { write("ERROR", msg) }

    private static func write(_ level: String, _ msg: String) {
        lock.lock(); defer { lock.unlock() }
        let line = "\(formatter.string(from: Date()))  \(level)  \(msg)\n"
        FileHandle.standardError.write(line.data(using: .utf8)!)
        let url = Paths.log
        rotateIfNeeded(url)
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile()
            h.write(line.data(using: .utf8)!)
            try? h.close()
        } else {
            try? line.data(using: .utf8)!.write(to: url)
        }
    }

    private static func rotateIfNeeded(_ url: URL) {
        guard let size = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? UInt64,
              size > maxBytes else { return }
        let old = url.deletingPathExtension().appendingPathExtension("1.log")
        try? FileManager.default.removeItem(at: old)
        try? FileManager.default.moveItem(at: url, to: old)
    }
}
