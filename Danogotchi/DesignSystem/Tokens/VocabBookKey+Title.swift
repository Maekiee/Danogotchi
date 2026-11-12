import Foundation

extension VocabBookKey {
    /// 같은 주제의 레벨을 구분하도록 레벨을 붙인다 — "Travel A1", 나의 단어장은 주제 제목 그대로
    var title: String {
        guard let level else { return topic.title }
        return "\(topic.title) \(level.rawValue)"
    }
}
