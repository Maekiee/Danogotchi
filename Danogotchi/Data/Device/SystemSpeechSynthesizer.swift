import AVFoundation

/// 앱에 하나만 둔다 — 합성기가 여럿이면 발음이 겹친다.
/// AVSpeechSynthesizerDelegate가 Sendable을 요구하지만 호출·콜백 모두 메인 스레드라 unchecked로 둔다
final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing, @unchecked Sendable {
    private let synthesizer = AVSpeechSynthesizer()
    private let broadcaster = AsyncBroadcaster<String?>()
    private var currentText: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    var speakingText: AsyncStream<String?> {
        return broadcaster.stream(current: { self.currentText })
    }

    func speak(_ text: String) {
        update(text)
        let utterance = AVSpeechUtterance(string: text)
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func update(_ text: String?) {
        currentText = text
        broadcaster.send(text)
    }
}

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        update(nil)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        update(nil)
    }
}
