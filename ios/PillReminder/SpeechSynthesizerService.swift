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
    private var continuation: CheckedContinuation<Void, Never>?

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

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            self.continuation = cont
            self.synthesizer.speak(utterance)
        }
    }
}

extension SpeechSynthesizerService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        continuation?.resume()
        continuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        continuation?.resume()
        continuation = nil
    }
}
