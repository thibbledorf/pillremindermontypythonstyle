import AVFoundation
import Speech

/// Listens on the microphone for a spoken acknowledgment word ("yes", "yeah",
/// "taken", "done", etc.) for up to `timeout` seconds. Requires Microphone
/// and Speech Recognition permission (Info.plist usage strings, see README).
final class VoiceAckListener {
    private let ackWords: Set<String> = [
        "yes", "yeah", "yep", "yup", "done", "taken", "okay", "ok",
        "confirmed", "aye", "affirmative", "right", "got it", "check",
    ]

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    /// Returns true if an acknowledgment word was heard before the timeout.
    func listen(timeout: TimeInterval) async -> Bool {
        let authStatus = await requestAuthorization()
        guard authStatus else { return false }

        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            self.startListening(timeout: timeout) { heard in
                continuation.resume(returning: heard)
            }
        }
    }

    private func requestAuthorization() async -> Bool {
        let speechAuth = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
        guard speechAuth else { return false }

        let micAuth = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        return micAuth
    }

    private func startListening(timeout: TimeInterval, completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true)

        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer, recognizer.isAvailable else {
            completion(false)
            return
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.audioEngine = engine
        self.recognitionRequest = request

        var resolved = false
        let finish: (Bool) -> Void = { [weak self] heard in
            guard !resolved else { return }
            resolved = true
            self?.stop()
            completion(heard)
        }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            finish(false)
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString.lowercased()
                if self?.ackWords.contains(where: { text.contains($0) }) == true {
                    finish(true)
                }
            }
            if error != nil {
                finish(false)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            finish(false)
        }
    }

    private func stop() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
}
