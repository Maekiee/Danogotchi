import Foundation

protocol SpeechSynthesizing: AnyObject {
    /// 구독 즉시 현재 값을 보내고, 발음 시작·종료마다 갱신한다. 발음 중이 아니면 nil.
    var speakingText: AsyncStream<String?> { get }
    func speak(_ text: String)
    func stop()
}
