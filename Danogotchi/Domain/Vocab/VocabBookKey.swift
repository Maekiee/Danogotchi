import Foundation

/// 주제×레벨 단어장 1권의 식별자. 레벨이 없으면 나의 단어장
struct VocabBookKey: Hashable {
    let topic: BookTopic
    let level: VocabLevel?

    /// Firestore 문서 ID·접근성 식별자로 같이 쓴다 — "travel_A1", 레벨이 없으면 "myBook"
    var id: String {
        guard let level else { return topic.rawValue }
        return "\(topic.rawValue)_\(level.rawValue)"
    }
}
