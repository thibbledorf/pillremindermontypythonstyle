import AVFoundation
import Foundation
import Speech

/// Listens briefly for "yes". Everything is bounded: if the audio engine or the
/// recognizer stalls, the caller gets `false` at the deadline and teardown is forced.
final class VoiceAck {
    static let shared = VoiceAck()

    private static let yesWords: Set<String> = [
        "yes", "yeah", "yep", "yup", "done", "taken", "okay", "ok", "confirmed",
        "aye", "affirmative", "right", "check", "took",
    ]

    private var authorized: Bool?
    private let queue = DispatchQueue(label: "voice-ack")

    /// Requests mic + speech permission once. Safe to call repeatedly.
    func ensureAuthorized() -> Bool {
        if let a = authorized { return a }
        let sem = DispatchSemaphore(value: 0)
        var speechOK = false
        SFSpeechRecognizer.requestAuthorization { s in speechOK = (s == .authorized); sem.signal() }
        if sem.wait(timeout: .now() + 60) == .timedOut { Log.warn("Speech permission prompt timed out"); return false }

        var micOK = false
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: micOK = true
        case .notDetermined:
            let s2 = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio) { ok in micOK = ok; s2.signal() }
            if s2.wait(timeout: .now() + 60) == .timedOut { return false }
        default: micOK = false
        }
        authorized = speechOK && micOK
        Log.info("Voice acknowledgment permissions: speech=\(speechOK) mic=\(micOK)")
        if authorized == false {
            Log.warn("Voice 'yes' disabled — grant Microphone and Speech Recognition in System Settings > Privacy & Security, then restart Pill Reminder")
        }
        return authorized!
    }

    /// Blocks up to `seconds`. Returns true if a yes-word was heard, or if `shouldStop` turns true.
    func listenForYes(seconds: TimeInterval, shouldStop: @escaping () -> Bool) -> Bool {
        guard ensureAuthorized() else { return false }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")), recognizer.isAvailable else {
            Log.warn("Speech recognizer unavailable")
            return false
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.contextualStrings = Array(Self.yesWords)
        if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }

        let heard = DispatchSemaphore(value: 0)
        let flagLock = NSLock()
        var gotYes = false

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            Log.warn("No microphone input available")
            return false
        }
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in request.append(buf) }

        let task = recognizer.recognitionTask(with: request) { result, error in
            if let result {
                let words = result.bestTranscription.formattedString.lowercased()
                    .components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
                if words.contains(where: { Self.yesWords.contains($0) }) {
                    flagLock.lock()
                    if !gotYes { gotYes = true; Log.info("Heard: '\(words.joined(separator: " "))'"); heard.signal() }
                    flagLock.unlock()
                }
            }
            if error != nil { heard.signal() }
        }

        do {
            engine.prepare()
            try engine.start()
        } catch {
            Log.warn("Audio engine failed to start: \(error.localizedDescription)")
            input.removeTap(onBus: 0)
            task.cancel()
            return false
        }

        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if heard.wait(timeout: .now() + 0.25) == .success { break }
            if shouldStop() { break }
        }

        // Forced teardown, bounded.
        let torn = DispatchSemaphore(value: 0)
        queue.async {
            engine.stop()
            input.removeTap(onBus: 0)
            request.endAudio()
            task.cancel()
            torn.signal()
        }
        if torn.wait(timeout: .now() + 3) == .timedOut { Log.error("Audio teardown stalled") }

        flagLock.lock(); defer { flagLock.unlock() }
        return gotYes || shouldStop()
    }
}
