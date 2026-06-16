import AVFoundation

/// Wraps AVSpeechSynthesizer for the Monty Python TTS voice.
final class SpeechSynthesizerService: NSObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Speaks text and suspends until speech finishes (so callers can await
    /// it before moving to the next step, e.g. listening for "yes").
    @MainActor
    func speak(_ text: String) async {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.46          // slightly slower = clearer, matches pyttsx3 rate=155
        utterance.pitchMultiplier = 0.92
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")

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
