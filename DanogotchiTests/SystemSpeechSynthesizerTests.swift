import AVFoundation
import XCTest
@testable import Danogotchi

/// 실제 음성 출력 완료는 시뮬레이터 음성 유무에 좌우되므로 종료 전이는 delegate를 직접 호출해 확인한다
final class SystemSpeechSynthesizerTests: XCTestCase {
    func test_speakingTextStartsNilThenFollowsSpeakAndFinish() async {
        let synthesizer = SystemSpeechSynthesizer()
        defer { synthesizer.stop() }
        var iterator = synthesizer.speakingText.makeAsyncIterator()

        let initial = await iterator.next()
        XCTAssertEqual(initial, .some(nil), "구독 즉시 현재 값(발음 없음)을 보낸다")

        synthesizer.speak("apple")
        let speaking = await iterator.next()
        XCTAssertEqual(speaking, .some("apple"), "speak는 음성 출력 전에 상태를 먼저 바꾼다")

        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didFinish: AVSpeechUtterance(string: "apple"))
        let finished = await iterator.next()
        XCTAssertEqual(finished, .some(nil))
    }

    func test_cancelClearsSpeakingText() async {
        let synthesizer = SystemSpeechSynthesizer()
        defer { synthesizer.stop() }
        var iterator = synthesizer.speakingText.makeAsyncIterator()
        _ = await iterator.next()

        synthesizer.speak("banana")
        _ = await iterator.next()

        synthesizer.speechSynthesizer(AVSpeechSynthesizer(), didCancel: AVSpeechUtterance(string: "banana"))
        let cancelled = await iterator.next()
        XCTAssertEqual(cancelled, .some(nil))
    }

    func test_lateSubscriberReceivesCurrentlySpeakingText() async {
        let synthesizer = SystemSpeechSynthesizer()
        defer { synthesizer.stop() }
        synthesizer.speak("cherry")

        // 셀이 재사용되어 늦게 구독해도 현재 발음 중인 단어를 바로 안다
        var iterator = synthesizer.speakingText.makeAsyncIterator()
        let current = await iterator.next()
        XCTAssertEqual(current, .some("cherry"))
    }
}
