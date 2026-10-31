import AVFoundation

enum VoiceOption: String, CaseIterable {
    case usDefault = "en-US"
    case ukDefault = "en-GB"
    case australianEnglish = "en-AU"
    case irishEnglish = "en-IE"

    var displayName: String {
        switch self {
        case .usDefault: "US English"
        case .ukDefault: "British English"
        case .australianEnglish: "Australian English"
        case .irishEnglish: "Irish English"
        }
    }

    var languageCode: String {
        rawValue
    }
}

/// Wraps AVSpeechSynthesizer with language/accent selection.
final class SpeechSynthesizerService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var deadline: DispatchWorkItem?

    static let voiceKey = "selectedLanguage"

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    static var selectedVoice: VoiceOption {
        get {
            let saved = UserDefaults.standard.string(forKey: voiceKey) ?? VoiceOption.usDefault.rawValue
            return VoiceOption(rawValue: saved) ?? .usDefault
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: voiceKey)
        }
    }

    /// Speaks text and suspends until speech finishes.
    @MainActor
    func speak(_ text: String) async {
        // A line started straight after stopSpeaking can be lost with no
        // delegate callback, so let the old line report its end first.
        while !waiters.isEmpty {
            synthesizer.stopSpeaking(at: .immediate)
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                self.waiters.append(cont)
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Continue even if audio session setup fails
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.92
        utterance.volume = 1.0

        let languageCode = Self.selectedVoice.languageCode
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.waiters.append(cont)
            self.armDeadline(for: text)
            self.synthesizer.speak(utterance)
        }
    }

    /// Cuts off the current line. Its caller is released by the delegate.
    @MainActor
    func stop() {
        if !waiters.isEmpty {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// Speech that never reports an end must not hold up the reminder flow,
    /// so each line gets well over the time it needs to be read aloud.
    private func armDeadline(for text: String) {
        let item = DispatchWorkItem { [weak self] in
            self?.synthesizer.stopSpeaking(at: .immediate)
            self?.releaseWaiters()
        }
        deadline = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 10 + Double(text.count) * 0.15, execute: item)
    }

    private func releaseWaiters() {
        deadline?.cancel()
        deadline = nil
        let released = waiters
        waiters = []
        released.forEach { $0.resume() }
    }
}

extension SpeechSynthesizerService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        releaseWaiters()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        releaseWaiters()
    }
}
