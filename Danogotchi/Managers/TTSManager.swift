import AVFoundation
import RxSwift
import RxCocoa

final class TTSManager: NSObject {
    static let shared = TTSManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let disposeBag = DisposeBag()
    
    private let _currentSpeakingText = BehaviorRelay<String?>(value: nil)
    
    var currentSpeakingText: Observable<String?> {
        return _currentSpeakingText.asObservable()
    }
    
    enum SpeechEvent {
        case started
        case finished
        case paused
        case continued
        case cancelled
    }
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    
    func speak(_ text: String, language: String = "en-US", rate: Float = 0.5) {
        _currentSpeakingText.accept(text)
        let utterance = AVSpeechUtterance(string: text)
        utterance.pitchMultiplier = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }
    
    func resume() {
        synthesizer.continueSpeaking()
    }
}

extension TTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
//        _isSpeaking.accept(true)
//        _speechEvent.accept(.started)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        _isSpeaking.accept(false)
//        _speechEvent.accept(.finished)
        _currentSpeakingText.accept(nil)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
//        _speechEvent.accept(.paused)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
//        _speechEvent.accept(.continued)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        _currentSpeakingText.accept(nil)
//        _isSpeaking.accept(false)
//        _speechEvent.accept(.cancelled)
    }
}
