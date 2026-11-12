import Foundation

/// Firestore `topics/{topic}_{level}` 문서
struct TopicDTO: Decodable {
    let topic: String
    let level: String
    let order: Int
    let wordCount: Int

    /// 앱이 모르는 주제·레벨이면 nil — 서버에 새 단어장이 올라가도 구버전 앱 목록에서 빠진다
    func toDomain() -> RemoteVocabBook? {
        guard let topic = BookTopic(rawValue: topic), topic != .myBook,
              let level = VocabLevel(rawValue: level) else { return nil }
        return RemoteVocabBook(key: VocabBookKey(topic: topic, level: level), wordCount: wordCount, order: order)
    }
}
